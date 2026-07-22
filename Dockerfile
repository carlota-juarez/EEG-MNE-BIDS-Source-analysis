FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1

# 1. Instalar dependencias del sistema operativo, Perl (para MNI) y librerías gráficas/C++
RUN apt-get update && apt-get install -y --no-install-recommends \
    bc \
    curl \
    tar \
    gzip \
    unzip \
    tcsh \
    perl \
    perl-modules \
    libxml-parser-perl \
    libgomp1 \
    libglu1-mesa \
    libgl1 \
    libgl1-mesa-dri \
    libosmesa6 \
    libxmu6 \
    libxt6 \
    libsm6 \
    libice6 \
    libx11-dev \
    libxext-dev \
    ca-certificates \
    bzip2 \
    git \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# 2. Descargar e instalar FreeSurfer 7.4.1 (versión compatible con Ubuntu 22.04 / jammy)
RUN echo "Downloading FreeSurfer 7.4.1 ..." \
    && mkdir -p /opt/freesurfer \
    && curl -fL https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.4.1/freesurfer-linux-ubuntu22_amd64-7.4.1.tar.gz \
    | tar -xz -C /opt/freesurfer --strip-components 1 \
         --exclude='average/mult-comp-cor' \
         --exclude='lib/cuda' \
         --exclude='lib/qt' \
         --exclude='subjects/V1_average' \
         --exclude='subjects/bert' \
         --exclude='subjects/cvs_avg35' \
         --exclude='subjects/cvs_avg35_inMNI152' \
         --exclude='subjects/fsaverage3' \
         --exclude='subjects/fsaverage4' \
         --exclude='subjects/fsaverage5' \
         --exclude='subjects/fsaverage6' \
         --exclude='subjects/fsaverage_sym' \
         --exclude='trctrain'

# 3. Configurar Miniconda y dependencias de Python
ENV CONDA_DIR="/opt/miniconda-latest"
RUN echo "Downloading Miniconda installer ..." \
    && conda_installer="/tmp/miniconda.sh" \
    && curl -fsSL -o "$conda_installer" https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash "$conda_installer" -b -p /opt/miniconda-latest \
    && rm -f "$conda_installer" \
    && export PATH="/opt/miniconda-latest/bin:$PATH" \
    && conda update -yq -nbase conda \
    && conda install -yq -nbase conda-libmamba-solver \
    && conda config --set solver libmamba \
    && conda config --system --prepend channels conda-forge \
    && conda config --system --set channel_priority strict \
    && conda install -y --name base "pandas=1.5.3" "nibabel" \
    && conda clean --all --yes

# 4. Instalar bids-validator
RUN npm install -g bids-validator@1.12.0

# 5. Definir variables de entorno limpias y sin rutas duplicadas
ENV OS="Linux" \
    FREESURFER_HOME="/opt/freesurfer" \
    SUBJECTS_DIR="/opt/freesurfer/subjects" \
    LOCAL_DIR="/opt/freesurfer/local" \
    FSFAST_HOME="/opt/freesurfer/fsfast" \
    MINC_BIN_DIR="/opt/freesurfer/mni/bin" \
    MINC_LIB_DIR="/opt/freesurfer/mni/lib" \
    MNI_DIR="/opt/freesurfer/mni" \
    MNI_DATAPATH="/opt/freesurfer/mni/data" \
    PERL5LIB="/opt/freesurfer/mni/lib/perl5" \
    MNI_PERL5LIB="/opt/freesurfer/mni/lib/perl5" \
    PATH="/opt/miniconda-latest/bin:/opt/freesurfer/bin:/opt/freesurfer/fsfast/bin:/opt/freesurfer/tktools:/opt/freesurfer/mni/bin:$PATH"

# 6. Directorios de trabajo y scripts de ejecución
RUN mkdir -p /root/matlab && touch /root/matlab/startup.m \
    && mkdir -p /scratch /local-scratch /work

# Corregir enlace simbólico de sh a bash por seguridad en subprocesos
RUN rm -f /bin/sh && ln -s /bin/bash /bin/sh

COPY ["run.py", "/run.py"]
RUN chmod +x /run.py

COPY ["version", "/version"]

WORKDIR /work
ENTRYPOINT ["python", "/run.py"]
