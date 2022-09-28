// I run my own local registry like this:
// docker run -d -p 5001:5000 --restart=always --name myregistry registry:2

package cloak

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"universe.dagger.io/bash"
)

dagger.#Plan & {
	client: {
		env: DHTKN: dagger.#Secret
	}
	actions: {
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
						apt-get update && apt-get install -y lsb-release
						apt-get install curl -y
						apt-get install git -y
						
						### Build cloak
						git clone --depth 1 --branch cloak https://github.com/dagger/dagger /cloak
						cd /cloak
						go build ./cmd/cloak
						ln -sf "$(pwd)/cloak" /usr/local/bin
						ln -sf "$(pwd)/cloak" /usr/local/bin/dagger
						dagger version
						"""
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

						apt-get install jq

						### For dagger/cloak to be able to use
						### mounted docker socket as jenkins user
						touch /var/run/docker.sock && chmod 666 /var/run/docker.sock
						"""#
				}
			}
			push: docker.#Push & {
				dest:  "jeremyatdockerhub/cloak-jenkins-agent:4"
				image: buildAgent.output
				auth: {
					username: "jeremyatdockerhub"
					secret:   client.env.DHTKN
				}
			}
		}
	}
}
