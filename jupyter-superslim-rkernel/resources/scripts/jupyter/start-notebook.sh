#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

lab_or_notebook="notebook"
if [[ -n "${JUPYTER_ENABLE_LAB}" ]]; then
    lab_or_notebook="lab"
fi

if [[ -n "${JUPYTERHUB_API_TOKEN}" ]]; then
    # launched by JupyterHub, use single-user entrypoint
    exec /usr/local/bin/start-singleuser.sh "$@"
else
    # shellcheck disable=SC1091
    if [[ "${RESTARTABLE}" == "yes" ]]; then
        while true; do
            flock -n /tmp/jupyter_notebook.lock . /usr/local/bin/start.sh jupyter ${lab_or_notebook} -y "$@"
        done
    else
        . /usr/local/bin/start.sh jupyter ${lab_or_notebook} -y "$@"
    fi
fi
