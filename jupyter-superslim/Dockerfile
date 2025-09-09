ARG AZLINUX_BASE_VERSION=master

FROM quay.io/cdis/amazonlinux-base:${AZLINUX_BASE_VERSION}

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
LABEL name="jupyter-superslim-base"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install minimal dependencies for Jupyter
RUN yum -y update && \
    yum install -y python3-pip shadow-utils && \
    yum clean all

# Configure environment
ARG NB_USER="jovyan"
ARG NB_UID="1010"
ARG NB_GID="100"
ENV NB_USER="${NB_USER}" \
    NB_UID="${NB_UID}" \
    NB_GID="${NB_GID}" \
    HOME="/home/${NB_USER}"

# Create user
RUN useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}"

USER ${NB_UID}

# Install Jupyter with pip (minimal installation)
RUN python3 -m pip install --no-cache-dir \
    jupyter \
    jupyterlab


# Add user's local bin to PATH
ENV PATH="/home/${NB_USER}/.local/bin:${PATH}"

EXPOSE 8888

WORKDIR "${HOME}"

# Copy startup script
COPY resources/scripts/jupyter/ /usr/local/bin/


# Start Jupyter Lab directly
CMD ["start-notebook.sh"]
