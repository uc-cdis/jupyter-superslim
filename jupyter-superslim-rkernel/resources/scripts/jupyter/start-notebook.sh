#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

# shellcheck disable=SC1091
. /usr/local/bin/start.sh jupyter lab -y "$@"
