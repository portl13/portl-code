#!/bin/sh
ENVIRONMENT=$(echo ${CONTEXT} | cut -d'/' -f 4)

echo "Rendering Configuration..."
/usr/bin/python /usr/bin/render_config /usr/share/portl-api/conf/${ENVIRONMENT}.conf.j2 /usr/share/portl-api/conf/application.conf

# Starting Application
echo "Starting Application..."
/usr/share/portl-api/bin/portl-api -Dlogging.graylog.env=${ENVIRONMENT}
