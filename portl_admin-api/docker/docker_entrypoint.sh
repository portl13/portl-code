#!/bin/sh

ENVIRONMENT=$(echo ${CONTEXT} | cut -d'/' -f 4)

echo "Render Site Config... "
/usr/bin/python /usr/bin/render_config /usr/share/admin-api/conf/${ENVIRONMENT}.conf.j2 /usr/share/admin-api/conf/application.conf

echo "Starting Application..."
/usr/share/admin-api/bin/admin-api -Dlogging.graylog.env=${ENVIRONMENT}
