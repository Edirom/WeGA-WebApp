FROM stadlerpeter/existdb

ENV WEGA_HOME /opt/wega 

USER root:root
RUN apk --update add apache-ant

ADD https://github.com/Edirom/WeGA-WebApp/releases/download/v3.2.1/WeGA-WebApp-3.2.1.xar ${EXIST_HOME}/autodeploy/
ADD https://github.com/Edirom/WeGA-WebApp/releases/download/v3.2.0/WeGA-WebApp-lib-1.0.0.xar ${EXIST_HOME}/autodeploy/
ADD https://github.com/Edirom/WeGA-WebApp/releases/download/v3.2.0/WeGA-data-16280-samples.xar ${EXIST_HOME}/autodeploy/

WORKDIR ${WEGA_HOME}

COPY . . 

RUN chown -R wegajetty:wegajetty ${EXIST_HOME}/autodeploy . \
    && chmod 755 Docker/entrypoint.sh

USER wegajetty:wegajetty

CMD ["Docker/entrypoint.sh"]
