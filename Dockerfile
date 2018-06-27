#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM openjdk:8-jdk as builder
LABEL maintainer="Peter Stadler"

ENV WEGA_BUILD_HOME="/opt/wega"
ENV WEGALIB_BUILD_HOME="/opt/wega-lib"
ARG YUICOMPRESSOR_URL="https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar"

ADD ${YUICOMPRESSOR_URL} /tmp/yuicompressor.jar
ADD https://deb.nodesource.com/setup_8.x /tmp/nodejs_setup 

# installing Saxon, Node and Git
RUN apt-get update \
    && apt-get install -y --force-yes apt-transport-https ant git libsaxonhe-java\
    # installing nodejs
    && chmod 755 /tmp/nodejs_setup \
    && chmod 644 /tmp/yuicompressor.jar \
    && /tmp/nodejs_setup \
    && apt-get install -y nodejs \
    && ln -s /usr/bin/nodejs /usr/local/bin/node 


# first building WeGA-WebApp-lib
WORKDIR ${WEGALIB_BUILD_HOME}
RUN git clone https://github.com/Edirom/WeGA-WebApp-lib.git . \
    && ant -lib /usr/share/java


# now building the main WeGA-WebApp
WORKDIR ${WEGA_BUILD_HOME}
COPY . .
RUN npm install bower less \
    && addgroup wegabuilder \
    && adduser wegabuilder --ingroup wegabuilder --disabled-password --system \
    && chown -R wegabuilder:wegabuilder ${WEGA_BUILD_HOME}

# running the main build script as non-root user
USER wegabuilder:wegabuilder
RUN ant -lib /usr/share/java 

#CMD ["/bin/bash"]

#########################
# Now running the eXist-db
# and adding our freshly built xar-package
#########################
FROM stadlerpeter/existdb:3.3.0

ADD https://github.com/Edirom/WeGA-WebApp-lib/releases/download/v1.0.0/WeGA-WebApp-lib-1.0.0.xar ${EXIST_HOME}/autodeploy/
COPY --chown=wegajetty --from=builder /opt/wega-lib/build/*.xar ${EXIST_HOME}/autodeploy/
COPY --chown=wegajetty --from=builder /opt/wega/build/*.xar ${EXIST_HOME}/autodeploy/
