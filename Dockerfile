#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM node:20-bookworm AS builder

ENV WEGA_BUILD_HOME="/opt/wega"
ENV WEGALIB_BUILD_HOME="/opt/wega-lib"


# installing Saxon and ANT
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-transport-https ant libsaxonhe-java 


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
FROM stadlerpeter/existdb:6
LABEL org.opencontainers.image.authors="Peter Stadler"

ADD --chown=wegajetty https://weber-gesamtausgabe.de/downloads/WeGA-data-testing-31471.xar ${EXIST_HOME}/autodeploy/
COPY --from=builder /opt/wega-lib/build/*.xar ${EXIST_HOME}/autodeploy/
COPY --from=builder /opt/wega/build/*.xar ${EXIST_HOME}/autodeploy/
