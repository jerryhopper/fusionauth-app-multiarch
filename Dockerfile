FROM ubuntu:bionic


###### get build-arguments  #########
ARG FUSIONAUTH_VERSION
#ENV FUSIONAUTH_VERSION=1.17.5

RUN echo "FusionAuth version :  $FUSIONAUTH_VERSION"
CMD echo "Running on $(uname -m)"
CMD echo "Architecture: $TARGETARCH"

###### Install stuff we need and then cleanup cache #################
RUN apt update && apt install unzip curl -y && apt-get clean

###### Using multiple FROM in a buildx enviroment doesnt seem to work as expected.

############################################################################
##### Get the appropreate openjdk and link it into /opt/java/openjdk
##### these lines come from the adoptopenjdk:14-jdk-hotspot-bionic
##### https://hub.docker.com/layers/adoptopenjdk/library/adoptopenjdk/14-jdk-hotspot-bionic/images/sha256-f44b21b19cce0de37bc575a5dfeda3cfd9ad1d4a979726e8a4b273746c950a88?context=explore
RUN /bin/sh -c set -eux;\
   ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in\
    aarch64|arm64)\
        ESUM='81ca31ad90f9bd789a2ca1753d6d83d10f4927876b4a4b9f4b1c4c8cbce85feb';\
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jdk-14.0.1%2B7/OpenJDK14U-jdk_aarch64_linux_hotspot_14.0.1_7.tar.gz';\
        ;;\
    armhf|armv7l)\
        ESUM='458d091756500dc3013737aa182a14752b3d4ffc358d09532201874ffb8cae22';\
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jdk-14.0.1%2B7/OpenJDK14U-jdk_arm_linux_hotspot_14.0.1_7.tar.gz';\
        ;;\
    ppc64el|ppc64le)\
        ESUM='bfdd77112d81256d4e1a859a465dd4dcb670019a5d6cf8260c30e24a0e5947e4';\
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jdk-14.0.1%2B7/OpenJDK14U-jdk_ppc64le_linux_hotspot_14.0.1_7.tar.gz';\
        ;;\
    s390x)\
        ESUM='c13545924e92cb9d495282e95270f299a28d5466f9741c67791f131c38ebbd0c';\
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jdk-14.0.1%2B7/OpenJDK14U-jdk_s390x_linux_hotspot_14.0.1_7.tar.gz';\
        ;;\
    amd64|x86_64)\
        ESUM='9ddf9b35996fbd784a53fff3e0d59920a7d5acf1a82d4c8d70906957ac146cd1';\
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jdk-14.0.1%2B7/OpenJDK14U-jdk_x64_linux_hotspot_14.0.1_7.tar.gz';\
        ;;\
    *)\
        echo "Unsupported arch: ${ARCH}";\
        exit 1;\
        ;;\
    esac;\
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL};\
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -;\
    mkdir -p /tmp/java/openjdk;\
    cd /tmp/java/openjdk;\
    tar -xf /tmp/openjdk.tar.gz --strip-components=1;\
    rm -rf /tmp/openjdk.tar.gz; \
    /tmp/java/openjdk/bin/jlink --compress=2 \
     --module-path /opt/java/openjdk/jmods/ \
     --add-modules java.base,java.compiler,java.desktop,java.instrument,java.management,java.naming,java.rmi,java.security.jgss,java.security.sasl,java.sql,java.xml.crypto,jdk.attach,jdk.crypto.ec,jdk.jdi,jdk.localedata,jdk.scripting.nashorn,jdk.unsupported \
     --output /opt/java/openjdk; \
    rm -rf /tmp/java



########################################################
###### set enviroment variables ########################
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV JAVA_VERSION=jdk-14.0.1+7
ENV JAVA_HOME=/opt/java/openjdk/
ENV PATH=$PATH:$JAVA_HOME/bin




#####################################################################
###### Get and install FusionAuth App Bundle ########################
RUN curl -Sk --progress-bar https://storage.googleapis.com/inversoft_products_j098230498/products/fusionauth/${FUSIONAUTH_VERSION}/fusionauth-app-${FUSIONAUTH_VERSION}.zip -o fusionauth-app.zip \
  && mkdir -p /usr/local/fusionauth/fusionauth-app \
  && unzip -nq fusionauth-app.zip -d /usr/local/fusionauth ; \
  rm -rf fusionauth-app.zip; \
  rm -rf /var/lib/apt/lists/*
  

#############################################################
###### create user  #########################################
RUN groupadd fusionauth
RUN useradd -r -s /bin/sh -g fusionauth -u 1001 fusionauth

#############################################################
###### copy fusionauth into contaner ########################
RUN chown -R fusionauth:fusionauth /usr/local/fusionauth




#####################################################################
###### Start FusionAuth App #########################################
LABEL description="Create an image running FusionAuth App. Installs FusionAuth App"
LABEL maintainer="FusionAuth-community <hopper.jerry@gmail.com>"
EXPOSE 9011
USER fusionauth
ENV FUSIONAUTH_USE_GLOBAL_JAVA=1
CMD ["/usr/local/fusionauth/fusionauth-app/apache-tomcat/bin/catalina.sh", "run"]
