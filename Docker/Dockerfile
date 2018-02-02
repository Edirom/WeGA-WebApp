#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM java:8-jdk as builder
LABEL maintainer="Peter Stadler"

ENV WEGA_BUILD_HOME="/opt/wega"
ARG SAXON_URL="http://downloads.sourceforge.net/project/saxon/Saxon-HE/9.6/SaxonHE9-6-0-7J.zip"

ADD ${SAXON_URL} /tmp/saxon.zip
ADD https://github.com/Edirom/WeGA-WebApp-lib/archive/master.zip /tmp/WeGA-WebApp-lib.zip

WORKDIR ${WEGA_BUILD_HOME}

RUN apt-get update \
    && apt-get install -y --force-yes ant npm \
    && unzip /tmp/saxon.zip -d ${WEGA_BUILD_HOME}/saxon \
    && unzip /tmp/WeGA-WebApp-lib.zip -d ${WEGA_BUILD_HOME}/ \
    && npm install bower less \
    && ln -s /usr/bin/nodejs /usr/local/bin/node

#ADD https://github.com/Edirom/WeGA-WebApp/releases/download/v3.2.0/WeGA-data-16280-samples.xar ${EXIST_HOME}/autodeploy/

COPY . WeGA-WebApp/

RUN addgroup wegabuilder \
    && adduser wegabuilder --ingroup wegabuilder --disabled-password --system \
    && chown -R wegabuilder:wegabuilder ${WEGA_BUILD_HOME}

USER wegabuilder:wegabuilder

RUN ant -lib saxon -f WeGA-WebApp-lib-master/build.xml
RUN ant -lib saxon -f WeGA-WebApp/build.xml




CMD ["/bin/bash"]
