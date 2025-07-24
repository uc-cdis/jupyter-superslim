ARG AZLINUX_BASE_VERSION=master

# For local development
FROM quay.io/cdis/amazonlinux-base:${AZLINUX_BASE_VERSION}

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
LABEL name="jupyter-superslim-base"


# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# ---- Miniforge installer ----
# Default values can be overridden at build time
# (ARGS are in lower case to distinguish them from ENV)
# Check https://github.com/conda-forge/miniforge/releases
# Conda version
ARG conda_version="24.7.1"
# Miniforge installer patch version
ARG miniforge_patch_number="2"
# Package Manager and Python implementation to use (https://github.com/conda-forge/miniforge)
ARG miniforge_python="Miniforge3"
# Miniforge archive to install
ARG miniforge_version="${conda_version}-${miniforge_patch_number}"


# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)

# tini per https://github.com/krallin/tini?tab=readme-ov-file#using-tini
ENV TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN yum -y update
RUN yum install -y \
    wget \
    git \
    ca-certificates \
    sudo \
    gzip \
    glibc-langpack-en \
    glibc-common \
    findutils \
    which \
    tar \
    vim && \
    yum clean all

# Configure environment
ARG NB_USER="jovyan"
# Bump UID to 1010. On Amazon Linux 2 the UID=1000 is reserved for 'ec2-user'
# https://docs.aws.amazon.com/linux/al2023/ug/al2023-reserved-users-list.html
ARG NB_UID="1010"
ARG NB_GID="100"
ENV NB_USER="${NB_USER}"
ENV NB_UID="${NB_UID}"
ENV NB_GID="${NB_GID}"
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    R_BASE_VERSION=4.3.3

ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}" \
    CONDA_VERSION="${conda_version}" \
    MINIFORGE_VERSION="${miniforge_version}"

# Copy a script that we will use to correct permissions after running certain commands
COPY resources/scripts/fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
    # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
    echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc


# Create NB_USER with name jovyan user with UID=2000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "${HOME}" && \
    fix-permissions "${CONDA_DIR}"

USER ${NB_UID}
ARG PYTHON_VERSION=3.9

# Install conda as jovyan and check the sha256 sum provided on the download site
WORKDIR /tmp

# Prerequisites installation: conda, pip
RUN set -x && \
    # Miniforge installer
    miniforge_arch=$(uname -m) && \
    export miniforge_arch && \
    if [ "$miniforge_arch" == "aarm64" ]; then \
    miniforge_arch="arm64"; \
    fi; \
    miniforge_installer="${miniforge_python}-${miniforge_version}-Linux-${miniforge_arch}.sh" && \
    export miniforge_installer && \
    wget --quiet "https://github.com/conda-forge/miniforge/releases/download/${miniforge_version}/${miniforge_installer}" && \
    /bin/bash "${miniforge_installer}" -f -b -p "${CONDA_DIR}" && \
    rm "${miniforge_installer}" && \
    # Conda configuration see https://conda.io/projects/conda/en/latest/configuration.html
    echo "conda ${CONDA_VERSION}" >> "${CONDA_DIR}/conda-meta/pinned" && \
    conda update -n base -c defaults conda && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    if [[ "${PYTHON_VERSION}" != "default" ]]; then conda install --yes python="${PYTHON_VERSION}"; fi && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    conda install --quiet --yes \
    "conda=${CONDA_VERSION}" \
    "python=${PYTHON_VERSION}" \
    'pip' && \
    conda update --all --quiet --yes && \
    conda clean --all -f -y && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Use overrides.json file to change the default settings
RUN mkdir -p /opt/conda/share/jupyter/lab/settings
COPY resources/overrides.json /opt/conda/share/jupyter/lab/settings

# Install Jupyter Notebook, Lab, Hub and R packages
# R packages including IRKernel which gets installed globally.
# See https://github.com/rocker-org/rocker/blob/master/r-base/Dockerfile
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
RUN conda install --quiet --yes python="${PYTHON_VERSION}" \
    'notebook' \
    'jupyterhub' \
    'jupyterlab' \
    'rpy2' \
    "r-base=$R_BASE_VERSION" \
    'r-irkernel' \
    'r-plyr' \
    'r-devtools' \
    'r-tidyverse' \
    'r-shiny' \
    'r-rmarkdown' \
    'r-forecast' \
    'r-rsqlite' \
    'r-reshape2' \
    'r-nycflights13' \
    'r-caret' \
    'r-rcurl' \
    'r-crayon' \
    'r-randomforest' \
    'r-rmysql' \
    'r-gplots' \
    'r-gtools' \
    'r-catools' \
    'jupyterhub-base' \
    'jupyter_server' \
    && conda clean --all -f -y && \
    npm cache clean --force && \
    jupyter notebook --generate-config && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

EXPOSE 8888


# Copy local files as late as possible to avoid cache busting
COPY resources/scripts/jupyter/ /usr/local/bin/
# Currently need to have both jupyter_notebook_config and jupyter_server_config to support classic and lab
COPY resources/jupyter_notebook_config.py /etc/jupyter/
# Do not open notebooks in a new tab: https://github.com/jupyter/notebook/issues/4115
COPY resources/custom.js /home/$NB_USER/.jupyter/custom/

COPY pyproject.toml pyproject.toml
COPY poetry.lock poetry.lock
RUN pip3 install poetry
RUN poetry install -vv --no-interaction

# Fix permissions on /etc/jupyter as root
USER root

# Prepare upgrade to JupyterLab V3.0 #1205
RUN sed -re "s/c.NotebookApp/c.ServerApp/g" \
    /etc/jupyter/jupyter_notebook_config.py > /etc/jupyter/jupyter_server_config.py && \
    fix-permissions /etc/jupyter/

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

WORKDIR "${HOME}"

# Configure container startup
ENTRYPOINT ["/tini", "-g", "--"]
CMD ["start-notebook.sh"]
