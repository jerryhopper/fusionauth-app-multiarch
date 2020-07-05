# fusionauth-app-multiarch
 dockerfile for building Multiarchitecture FusionAuth container for use with docker.
 
 
## What is this?
 this is a dockerfile that builds a fusionauth instance for multiple architectures and pushes the multi-arch docker container to dockerhub.
 

## Usage
 Use the below command to build the containers, make sure to adjust the version and the target-repo!
 
<pre>docker buildx build --build-arg FUSIONAUTH_VERSION=1.17.3 --force-rm --platform linux/arm/v7,linux/arm64,linux/amd64 -t jerryhopper/demo-multiarch:fusionauth --push .</pre>

## Dockerhub
 https://hub.docker.com/repository/docker/jerryhopper/fusionauth-app
