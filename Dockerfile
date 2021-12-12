#
# FusionAuth App Dockerfile
#
# Build:
#   > docker pull ubuntu:latest
#   > docker build -t fusionauth/fusionauth-app:1.21.0 .
#   > docker build -t fusionauth/fusionauth-app:latest .
#
# Run:
#  > docker run -p 9011:9011 -it fusionauth/fusionauth-app
#
# Publish:
#   > docker push fusionauth/fusionauth-app:1.21.0
#   > docker push fusionauth/fusionauth-app:latest
#

###### Setup the java and fusionauth-app base #####################################################
FROM ubuntu:bionic as build

ARG JDK_MODULES=java.base,java.compiler,java.desktop,java.instrument,java.management,java.naming,java.rmi,java.security.jgss,java.security.sasl,java.sql,java.xml.crypto,jdk.attach,jdk.crypto.ec,jdk.jdi,jdk.localedata,jdk.scripting.nashorn,jdk.unsupported
ARG FUSIONAUTH_VERSION=0
RUN ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in\
    aarch64|arm64)\
        ESUM='ea2de929e02f2e8bd3470ee8345a63299d81dfd086ee2f0af402239a8a9615f9';\
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk17-binaries/releases/download/jdk-2021-05-07-13-31/OpenJDK-jdk_aarch64_linux_hotspot_2021-05-06-23-30.tar.gz';\
        ;;\
    armhf|armv7l|armel)\
        ESUM='9fc0eada46dbf34f1583670521051a86599dabc9897c213bfbc6d7e2bfcd2bf7';\
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk17-binaries/releases/download/jdk-2021-05-07-13-31/OpenJDK-jdk_arm_linux_hotspot_2021-05-06-23-30.tar.gz';\
        ;;\
    ppc64el|ppc64le)\
        ESUM='dcc626fc1c25460d5f37a4b0c015dc88de732fdbb08772344c36585982802704';\
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk17-binaries/releases/download/jdk-2021-05-07-13-31/OpenJDK-jdk_ppc64le_linux_hotspot_2021-05-06-23-30.tar.gz';\
        ;;\
    s390x)\
        ESUM='5d690755935f7fc43417660505a8ce6d5a7a85c51817c96780d2e2e6193fc28b';\
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk17-binaries/releases/download/jdk-2021-05-07-13-31/OpenJDK-jdk_s390x_linux_hotspot_2021-05-06-23-30.tar.gz';\
        ;;\
    amd64|x86_64)\
        ESUM='01343d891b63c03bf00eb205987e4816feb25b9249204ebf996ef7cbc94ec4a2';\
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk17-binaries/releases/download/jdk-2021-05-07-13-31/OpenJDK-jdk_x64_linux_hotspot_2021-05-06-23-30.tar.gz';\
        ;;\
    *)\
        echo "Unsupported arch: ${ARCH}";\
        exit 1;\
        ;;\
    esac \
    && apt update \
    && apt install -y curl unzip \
    && curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL} \
    && echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c - \
    && mkdir -p /tmp/openjdk \
    && cd /tmp/openjdk \
    && tar -xf /tmp/openjdk.tar.gz --strip-components=1 \
    && /tmp/openjdk/bin/jlink --compress=2 \
       --module-path /tmp/openjdk/jmods/ \
       --add-modules ${JDK_MODULES} \
       --output /opt/openjdk \
     && curl -LfsSo /tmp/fusionauth-app.zip https://files.fusionauth.io/products/fusionauth/${FUSIONAUTH_VERSION}/fusionauth-app-${FUSIONAUTH_VERSION}.zip \
     && mkdir -p /usr/local/fusionauth/fusionauth-app \
     && unzip -nq /tmp/fusionauth-app.zip -d /usr/local/fusionauth

###### Use Ubuntu latest and only copy in what we need to reduce the layer size ###################
FROM ubuntu:bionic
RUN useradd -d /usr/local/fusionauth -U fusionauth
COPY --from=build /opt/openjdk /opt/openjdk
COPY --chown=fusionauth:fusionauth --from=build /usr/local/fusionauth /usr/local/fusionauth

###### Connect the log file to stdout #############################################################
RUN mkdir -p /usr/local/fusionauth/logs \
  && touch /usr/local/fusionauth/logs/fusionauth-app.log \
  && ln -sf /dev/stdout /usr/local/fusionauth/logs/fusionauth-app.log

###### Start FusionAuth App #######################################################################
LABEL description="Create an image running FusionAuth App. Installs FusionAuth App"
LABEL maintainer="FusionAuth Community <hopper.jerry@gmail.com>"
EXPOSE 9011
USER fusionauth
ENV FUSIONAUTH_USE_GLOBAL_JAVA=1
ENV JAVA_HOME=/opt/openjdk
ENV PATH=$PATH:$JAVA_HOME/bin
CMD ["/usr/local/fusionauth/fusionauth-app/apache-tomcat/bin/catalina.sh", "run"]
