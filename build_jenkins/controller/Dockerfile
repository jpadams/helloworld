FROM jenkins/jenkins:2.361.1-lts-jdk11
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN apt-get install git -y
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean:1.25.8 docker:1.2.9:https://updates.jenkins.io/download/plugins/docker-plugin/1.2.9/docker-plugin.hpi"
