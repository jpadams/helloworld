// I run my own local registry like this:
// docker run -d -p 5001:5000 --restart=always --name myregistry registry:2

// needs these env vars set before running:
// $SSH_AUTH_SOCK (by ssh agent running and identity added, used in --with below)
// dagger do --with "actions: sshSock64: \"$(echo -n $SSH_AUTH_SOCK | base64)\"" run --log-format plain

// note: I had trouble with the gnarly SSH_AUTH_SOCK string in CUE, so base64 encode/decode it. Decode has weirdness of using bytes vs string, so use yaml.Unmarshal to turn into string
package cloak

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"universe.dagger.io/bash"
	"encoding/base64"
	"encoding/yaml"
)

dagger.#Plan & {
	client: {
		env: DHTKN: dagger.#Secret
		network: {
			(actions.sshSock): connect: dagger.#Socket
		}
	}
	actions: {
		sshSock64: string
		sshSock:   "unix://" + yaml.Unmarshal(base64.Decode(null, sshSock64))

		run: {
			buildCloak: {
				_golang: docker.#Pull & {
					source: "golang:1.19.1"
				}
				bash.#Run & {
					input: _golang.output
					//always: true
					script: contents: """
						mkdir ~/.ssh
						ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
						apt-get update && apt-get install -y lsb-release
						apt-get install curl -y
						apt-get install git -y
						
						### Build cloak
						git clone --depth 1 --branch main git@github.com:dagger/cloak.git /cloak
						cd /cloak
						go build ./cmd/cloak
						ln -sf "$(pwd)/cloak" /usr/local/bin
						#cloak version
						"""
					env: {
						SSH_AUTH_SOCK: "/var/ssh_sock"
					}
					mounts: {
						ssh_sock: {
							dest:     "/var/ssh_sock"
							contents: client.network[sshSock].connect
						}
					}
					export: directories: "/cloak": _
				}
			}
			buildAgent: {
				_agent: docker.#Pull & {
					source: "jenkins/agent"
				}
				_agentCloak: docker.#Copy & {
					input:    _agent.output
					contents: buildCloak.export.directories."/cloak"
					dest:     "/cloak"
				}
				bash.#Run & {
					input: _agentCloak.output
					user:  "root"
					script: contents: #"""
						apt-get update && apt-get install -y lsb-release
						apt-get install curl -y
						ln -sf /cloak/cloak /usr/local/bin
						curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
							https://download.docker.com/linux/debian/gpg
						echo "deb [arch=$(dpkg --print-architecture) \
							signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
							https://download.docker.com/linux/debian \
							$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
						apt-get update && apt-get install -y docker-ce-cli

						### Install dagger
						cd /usr/local
						curl -L https://dl.dagger.io/dagger/install.sh | sh

						### For cloak and dagger to be able to use
						### mounted docker socket as jenkins user
						touch /var/run/docker.sock && chmod 666 /var/run/docker.sock
						"""#
				}
			}
			push: docker.#Push & {
				dest:  "jeremyatdockerhub/cloak-jenkins-agent:2"
				image: buildAgent.output
				auth: {
					username: "jeremyatdockerhub"
					secret:   client.env.DHTKN
				}
			}
		}
	}
}
