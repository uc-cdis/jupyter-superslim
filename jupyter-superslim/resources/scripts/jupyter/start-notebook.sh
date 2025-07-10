#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

if [[ -n "${JUPYTERHUB_API_TOKEN}" ]]; then
    # launched by JupyterHub, use single-user entrypoint
    exec /usr/local/bin/start-singleuser.sh "$@"
elif [[ -n "${JUPYTER_ENABLE_LAB}" ]]; then

    if [[ "${RESTARTABLE}" == "yes" ]]; then
        while true; do
            # shellcheck disable=SC1091
            flock -n /tmp/jupyter_notebook.lock . /usr/local/bin/start.sh jupyter lab -y "$@"
        done
    else
        # shellcheck disable=SC1091
        . /usr/local/bin/start.sh jupyter lab -y "$@"
    fi
else
    echo "WARN: Jupyter Notebook deprecation notice https://github.com/jupyter/docker-stacks#jupyter-notebook-deprecation-notice."
    if [[ "${RESTARTABLE}" == "yes" ]]; then
        while true; do
            # shellcheck disable=SC1091
            flock -n /tmp/jupyter_notebook.lock . /usr/local/bin/start.sh jupyter notebook -y "$@"
        done
    else
        # shellcheck disable=SC1091
        . /usr/local/bin/start.sh jupyter notebook -y "$@"
    fi
fi
