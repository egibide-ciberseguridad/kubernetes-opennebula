#!/bin/sh

# shellcheck disable=SC2091
$(terraform -chdir=/terraform output --raw "$1")
