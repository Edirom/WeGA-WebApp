#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM openjdk:8-jdk as builder
LABEL maintainer="Peter Stadler"

ENV WEGA_BUILD_HOME="/opt/wega"
ARG SAXON_URL="http://downloads.sourceforge.net/project/saxon/Saxon-HE/9.6/SaxonHE9-6-0-7J.zip"
ARG YUICOMPRESSOR_URL="https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar"

ADD ${SAXON_URL} /tmp/saxon.zip
ADD ${YUICOMPRESSOR_URL} /tmp/yuicompressor.jar
ADD https://deb.nodesource.com/setup_8.x /tmp/nodejs_setup 

WORKDIR ${WEGA_BUILD_HOME}

COPY . .

RUN apt-get update \
    && apt-get install -y --force-yes apt-transport-https ant \
    && unzip /tmp/saxon.zip -d ${WEGA_BUILD_HOME}/saxon \
    # installing nodejs
    && chmod 755 /tmp/nodejs_setup \
    && chmod 644 /tmp/yuicompressor.jar \
    && /tmp/nodejs_setup \
    && apt-get install -y nodejs \
    && npm install bower less \
    && ln -s /usr/bin/nodejs /usr/local/bin/node 

#ADD https://github.com/Edirom/WeGA-WebApp/releases/download/v3.2.0/WeGA-data-16280-samples.xar ${EXIST_HOME}/autodeploy/

RUN addgroup wegabuilder \
    && adduser wegabuilder --ingroup wegabuilder --disabled-password --system \
    && chown -R wegabuilder:wegabuilder ${WEGA_BUILD_HOME}

# running the main build script as non-root user
USER wegabuilder:wegabuilder
RUN ant -lib saxon -f build.xml

#CMD ["/bin/bash"]

#########################
# Now running the eXist-db
# and adding our freshly built xar-package
#########################
FROM stadlerpeter/existdb

ADD https://github.com/Edirom/WeGA-WebApp-lib/releases/download/v1.0.0/WeGA-WebApp-lib-1.0.0.xar ${EXIST_HOME}/autodeploy/
COPY --from=builder /opt/wega/build/*.xar ${EXIST_HOME}/autodeploy/

USER root
RUN chmod 644 ${EXIST_HOME}/autodeploy/*.xar

USER wegajetty