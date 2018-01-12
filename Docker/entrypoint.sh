#!/bin/bash

# calling the entrypoint script from the stadlerpeter/existdb docker image
cd ${EXIST_HOME}
./entrypoint.sh &


sleep 25
cd ${WEGA_HOME}
/usr/bin/ant test 