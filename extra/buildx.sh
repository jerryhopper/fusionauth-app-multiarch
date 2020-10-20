#!/bin/bash

# this script requires a proper buildx enviroment.

docker buildx build --force-rm --platform linux/arm/v7,linux/arm64,linux/amd64 -t jerryhopper/fusionauth-app:latest https://github.com/jerryhopper/fusionauth-app-multiarch.git
