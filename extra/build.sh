#!/bin/bash

# Basic buildscript for (single architecture) build 

docker build --force-rm -t jerryhopper/fusionauth-app:latest https://github.com/jerryhopper/fusionauth-app-multiarch.git
