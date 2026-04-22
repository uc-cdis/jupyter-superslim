ARG AZLINUX_BASE_VERSION=master

# For local development
FROM quay.io/cdis/amazonlinux-base:${AZLINUX_BASE_VERSION}

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
LABEL name="jupyter-superslim-base"

# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

ARG conda_version="26.1.0"
ARG miniforge_patch_number="0"
ARG miniforge_python="Miniforge3"
ARG miniforge_version="${conda_version}-${miniforge_patch_number}"
ARG NB_USER="jovyan"
ARG NB_UID="1010"
ARG NB_GID="100"
ARG PYTHON_VERSION=3.13
ARG R_BASE_VERSION=4.5.3


# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)

# tini per https://github.com/krallin/tini?tab=readme-ov-file#using-tini
ENV TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN yum -y update
RUN yum -y groupinstall "Development Tools"
RUN yum install -y \
    wget \
    git \
    ca-certificates \
    sudo \
    gzip \
    glibc-langpack-en \
    glibc-common \
    python3-devel \
    findutils \
    which \
    tar \
    vim && \
    yum clean all && \
    rm -rf /var/cache/yum

# Configure environment
ENV NB_USER="${NB_USER}" \
    NB_UID="${NB_UID}" \
    NB_GID="${NB_GID}" \
    CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    CONDA_VERSION="${conda_version}" \
    MINIFORGE_VERSION="${miniforge_version}"

ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

# Copy a script that we will use to correct permissions after running certain commands
COPY resources/scripts/fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
    # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
    echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc


# Create NB_USER with name jovyan user with UID=1010 and in the 'users' group
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
# Install conda as jovyan and check the sha256 sum provided on the download site
WORKDIR /tmp

RUN set -x && \
    miniforge_arch=$(uname -m) && \
    [ "$miniforge_arch" = "aarm64" ] && miniforge_arch="arm64"; \
    miniforge_installer="${miniforge_python}-${miniforge_version}-Linux-${miniforge_arch}.sh" && \
    wget --quiet "https://github.com/conda-forge/miniforge/releases/download/${miniforge_version}/${miniforge_installer}" && \
    /bin/bash "${miniforge_installer}" -f -b -p "${CONDA_DIR}" && \
    rm "${miniforge_installer}" && \
    echo "conda ${CONDA_VERSION}" >> "${CONDA_DIR}/conda-meta/pinned" && \
    conda config --system --add channels conda-forge && \
    conda config --system --set channel_priority strict && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    conda install --quiet --yes -c conda-forge \
        "python=${PYTHON_VERSION}" \
        pip \
        notebook \
        jupyterlab \
        jupyterhub-base \
        jupyter_server \
        nodejs \
        rpy2 \
        "r-base=${R_BASE_VERSION}" \
        r-irkernel \
        r-tidyverse \
        r-rmarkdown && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    conda clean --all -f -y && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Use overrides.json file to change the default settings
RUN mkdir -p /opt/conda/share/jupyter/lab/settings
COPY resources/overrides.json /opt/conda/share/jupyter/lab/settings

EXPOSE 8888


# Copy local files as late as possible to avoid cache busting
COPY resources/scripts/jupyter/ /usr/local/bin/
# Currently need to have both jupyter_notebook_config and jupyter_server_config to support classic and lab
COPY resources/jupyter_notebook_config.py /etc/jupyter/
# Do not open notebooks in a new tab: https://github.com/jupyter/notebook/issues/4115
COPY resources/custom.js /home/${NB_USER}/.jupyter/custom/

COPY pyproject.toml pyproject.toml
COPY poetry.lock poetry.lock
RUN pip install --no-cache-dir poetry && \
    poetry config virtualenvs.create false && \
    poetry install -vv --no-interaction

# Fix permissions on /etc/jupyter as root
USER root

# Extend the existing permissions fix to cover the whole .jupyter tree
RUN mkdir -p /home/${NB_USER}/.jupyter/lab/workspaces && \
    chown -R ${NB_UID}:${NB_GID} /home/${NB_USER}/.jupyter

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
