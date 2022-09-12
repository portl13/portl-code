#!/bin/sh

MONGO=$1
SCHEMA=$2
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
JSPATH="$SCRIPTPATH/createSchema.js"

if [ -z "$2" ]
then
    SCHEMA="$SCRIPTPATH/../main/resources/schema.json"
    echo "using default schema"
fi

echo "mongo connection uri: $MONGO"
echo "schema path: $SCHEMA"
echo "mongo script: $JSPATH"

mongo $MONGO --eval "const schemaPath = '$SCHEMA'" $JSPATH
