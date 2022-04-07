#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM openjdk:17-jdk-bullseye as builder
LABEL maintainer="Peter Stadler"

ENV WEGA_BUILD_HOME="/opt/wega"
ENV WEGALIB_BUILD_HOME="/opt/wega-lib"


# installing Saxon, Node and Git
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-transport-https ant git libsaxonhe-java npm \
    && npm install -g yarn


# first building WeGA-WebApp-lib
WORKDIR ${WEGALIB_BUILD_HOME}
RUN git clone https://github.com/Edirom/WeGA-WebApp-lib.git . \
    && ant -lib /usr/share/java


# now building the main WeGA-WebApp
WORKDIR ${WEGA_BUILD_HOME}
COPY . .


# running the main build script
RUN ant -lib /usr/share/java 


#########################
# Now running the eXist-db
# and adding our freshly built xar-package
#########################
FROM existdb/existdb:6.0.1

ADD https://weber-gesamtausgabe.de/downloads/WeGA-data-testing-29470.xar ${EXIST_HOME}/autodeploy/
COPY --from=builder /opt/wega-lib/build/*.xar ${EXIST_HOME}/autodeploy/
COPY --from=builder /opt/wega/build/*.xar ${EXIST_HOME}/autodeploy/
