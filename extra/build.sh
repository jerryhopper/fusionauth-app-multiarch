#!/bin/bash

# Basic buildscript for (single architecture) build 

docker build --force-rm --build-arg FUSIONAUTH_VERSION=1.20.1 -t jerryhopper/fusionauth-app:latest https://github.com/jerryhopper/fusionauth-app-multiarch.git
