# docker exec -it jenkins-docker /bin/sh

docker run -d -p 5001:5000 --restart=always --name myregistry registry:2
apk add curl
curl -s  http://localhost:5001/v2/_catalog
docker pull jeremyatdockerhub/cloak-jenkins-agent:2
docker tag jeremyatdockerhub/cloak-jenkins-agent:2 localhost:5001/cloak-jenkins-agent:2
docker push localhost:5001/cloak-jenkins-agent:2

# docker run --privileged --name dagger-buildkitd -d moby/buildkit:latest
# docker run -it --rm --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock --network=container:dagger-buildkitd localhost:5001/cloak-jenkins-agent:2 /bin/bash
# docker run -it --rm --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock jeremyatdockerhub/cloak-jenkins-agent:2 /bin/bash
