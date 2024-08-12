#!/bin/bash

script_dir="$(dirname "$0")"
source $script_dir/env.profile
if [ ! -n "$LOADBALANCE_VIP" ]; then 
    echo "'$script_dir/env.profile' not load"
    exit 1
fi
