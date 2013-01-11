#! /bin/bash

PID_FILE=/tmp/test-varnish.pid

if [ -f $PID_FILE ]; then
    kill -9 `cat $PID_FILE`
fi

varnishd \
-a :3001 \
-f varnish.vcl \
-n test \
-P /tmp/test-varnish.pid \
-T 127.0.0.1:3002 \
&& echo "Varnish started."
