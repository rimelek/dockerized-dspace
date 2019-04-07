#!/usr/bin/env bash

getenv() {
    echo "${1}" | awk '{print ENVIRON[$1]}'
}

getenvKeys() {
    awk '
        END {
            for (name in ENVIRON) {
                print name
            }
         }
    ' < /dev/null
}

getConfigKeys() {
    getenvKeys | awk '$0 ~ /^config\./'
}

getConfigMap() {
    getConfigKeys | sort | awk '{key=gensub(/^config\./, "", "g", $1); print key"="ENVIRON[$1]}'
}