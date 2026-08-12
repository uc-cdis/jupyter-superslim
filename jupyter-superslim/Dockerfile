ARG AZLINUX_BASE_VERSION=master

FROM quay.io/cdis/amazonlinux-base:${AZLINUX_BASE_VERSION}

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
LABEL name="jupyter-superslim-base"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install minimal dependencies for Jupyter
# Symlink into /usr/local/bin, which precedes /usr/bin on PATH. Do not overwrite
# /usr/bin/python3: it is owned by the python3 RPM and dnf hardcodes it in its
# shebang (`head -1 /usr/bin/dnf-3`), so repointing it breaks yum for anything
# built on this image. See #69.
RUN yum -y update && \
    yum install -y python3.14 python3.14-pip shadow-utils && \
    yum clean all && \
    ln -sf /usr/bin/python3.14 /usr/local/bin/python3 && \
    ln -sf /usr/bin/pip3.14 /usr/local/bin/pip3 && \
    ln -sf /usr/bin/pip3.14 /usr/local/bin/pip

# Configure environment
ARG NB_USER="jovyan"
ARG NB_UID="1010"
ARG NB_GID="100"
ENV NB_USER="${NB_USER}" \
    NB_UID="${NB_UID}" \
    NB_GID="${NB_GID}" \
    HOME="/home/${NB_USER}"

# Create user
RUN useradd -m -s /bin/bash -u "${NB_UID}" "${NB_USER}"

USER ${NB_UID}

# Install Jupyter with pip (minimal installation) and ensure it's in PATH
RUN python3 -m pip install --no-cache-dir --user \
    jupyter \
    jupyterlab

# Add user's local bin to PATH
ENV PATH="/home/${NB_USER}/.local/bin:${PATH}"

COPY pyproject.toml pyproject.toml
COPY poetry.lock poetry.lock
RUN python3 -m pip install --user poetry && \
    poetry config virtualenvs.create false && \
    poetry install -vv --no-interaction

EXPOSE 8888

# Copy startup script
COPY resources/scripts/jupyter/ /usr/local/bin/
# Copy Jupyter configuration
COPY resources/jupyter_notebook_config.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root
RUN mkdir -p /etc/jupyter && \
    chown -R ${NB_USER}:${NB_GID} /etc/jupyter
# Extend the existing permissions fix to cover the whole .jupyter tree
RUN mkdir -p /home/${NB_USER}/.jupyter/lab/workspaces && \
    chown -R ${NB_UID}:${NB_GID} /home/${NB_USER}/.jupyter
USER ${NB_UID}

WORKDIR "${HOME}"

# Start Jupyter Lab directly
CMD ["start-notebook.sh"]
