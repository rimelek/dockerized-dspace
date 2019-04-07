#!/usr/bin/env bash

cd /dspace/bin/

./dspace index-discovery
./dspace filter-media
./dspace oai import