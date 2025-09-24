#!/bin/bash

if [[ -z "$1" || -z "$2" ]]
  then
    echo "Two arguments required: url prefix and run name, e.g. \`request_fnoc.sh https://opendap.earthdata.nasa.gov run1\`";
    exit 1
fi

export verbose=true; 

export URL_PREFIX=$1
export RUN_NAME=$2

for num in {1..1000}; do
    rm ~/.edl_cookies; 
    turl -s -o /dev/null "${URL_PREFIX}/hyrax/data/nc/fnoc1.nc.dds" >> ${RUN_NAME}_log; 
done
cat ${RUN_NAME}_log | grep '{' | jq '.cURL.TTFB' >> ${RUN_NAME}.txt

echo
echo "Request responses (if most responses aren't 200, something went wrong!!):"
echo "Count Response"
cat ${RUN_NAME}_log | grep '{' | jq '.cURL.status' | sort | uniq -c
echo
