#!/usr/bin/env bash

# Check the availability of 'bc' utility
command -v bc >/dev/null 2>&1 || \
    { echo >&2 "This script requires 'bc' but it's not installed.  Aborting.";
      exit 1; }
COLOR_RESET='\e[0m'
COLOR_GREEN='\e[0;32m';
COLOR_RED='\e[0;31m';

# Transfer the self-defined representation to real number
fromfixed() {
    local ret=$1
    local ans=${2}
    local NAN_INT=31
    local INF_INT=47
    local is_eq=0
    local scale=""

    num=$(($ret >> 4))
    frac=$(($ret & 15))
    neg=$((($frac & 8) >> 3))

    [[ $neg -eq 1 ]] && frac=$((-((~$frac & 15) + 1))) && scale="scale=$((-(${frac})));"

    if [ "$ret" -eq "$NAN_INT" ]
    then
        ret="NAN_INT"
        [[ "${ret}" == "${ans}" ]] && is_eq="1"
    elif [ "$ret" -eq "$INF_INT" ]
    then
        ret="INF_INT"
        [[ "${ret}" == "${ans}" ]] && is_eq="1"
    else
        ret="`echo \"${scale} $num*(10^$frac)\" | bc -l`"
        is_eq="`echo \"${scale} ($num*(10^$frac) == (${ans}))\" | bc -l`"
        ans="`echo \"${scale} ${ans}\" | bc -l`"
    fi

    if [ "${is_eq}" != "1" ]
    then
        echo -e "${COLOR_RED} Failed: ${COLOR_RESET} ret = ${ret} ans = ${ans}"
    else
        echo -e "${COLOR_GREEN} PASS: ${COLOR_RESET} ret = ${ret}"
    fi
}
