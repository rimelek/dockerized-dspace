#!/usr/bin/env bash

cd /app/dspace/bin/

./dspace index-discovery
./dspace filter-media
./dspace oai import