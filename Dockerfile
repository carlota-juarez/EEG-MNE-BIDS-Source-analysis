FROM debian:bookworm-slim AS freesurfer-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        tar \
        gzip \
    && rm -rf /var/lib/apt/lists/*

# 1. Separar la descarga y descompresión
RUN curl -fsSL https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.4.1/freesurfer-linux-ubuntu22_amd64-7.4.1.tar.gz \
    | tar -xz -C /opt

# 2. Separar la limpieza de carpetas innecesarias
RUN rm -rf \
        /opt/freesurfer/subjects/fsaverage3 \
        /opt/freesurfer/subjects/fsaverage4 \
        /opt/freesurfer/subjects/fsaverage5 \
        /opt/freesurfer/subjects/fsaverage6 \
        /opt/freesurfer/subjects/cv90 \
        /opt/freesurfer/subjects/bert \
        /opt/freesurfer/subjects/sample \
        /opt/freesurfer/subjects/V1_average \
        /opt/freesurfer/subjects/fsaverage_sym \
        /opt/freesurfer/subjects/cvs_avg35 \
        /opt/freesurfer/subjects/cvs_avg35_inMNI152 \
        /opt/freesurfer/trctrain \
        /opt/freesurfer/fsfast \
        /opt/freesurfer/matlab \
        /opt/freesurfer/docs

# 3. Comprobar los archivos individualmente para ver cuál falla
RUN test -f /opt/freesurfer/mni/lib/perl5/MNI/Startup.pm
RUN test -x /opt/freesurfer/bin/recon-all
# subir version a github 
FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    QT_QPA_PLATFORM=offscreen \
    MNE_BROWSER_BACKEND=matplotlib \
    MPLBACKEND=Agg \
    PYVISTA_OFF_SCREEN=true \
    MNE_3D_OPTION_ANTIALIAS=false \
    LIBGL_ALWAYS_SOFTWARE=1 \
    MNE_3D_BACKEND=pyvistaqt \
    OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    NUMEXPR_NUM_THREADS=1 \
    VECLIB_MAXIMUM_THREADS=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        libgl1 \
        libglib2.0-0 \
        curl \
        ca-certificates \
        xvfb \
        libgl1-mesa-dri \
        libosmesa6 \
        libegl1 \
        tcsh \
        bc \
        tar \
        gzip \
        unzip \
        libgomp1 \
        libgsl-dev \
        libfontconfig1 \
        libfreetype6 \
        libxkbcommon0 \
        libxkbcommon-x11-0 \
        libdbus-1-3 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-sync1 \
        libxcb-xfixes0 \
        libxcb-xinerama0 \
        libx11-xcb1 \
        libsm6 \
        libice6 \
        libxrender1 \
        perl \
        libxml-parser-perl \
        libjpeg62-turbo \
        libpng16-16 \
        libtiff6 \
        libxmu6 \
        libxi6 \
        libxt6 \
        libxext6 \
        libx11-6 \
        libncurses6 \
        liblapack3 \
        libblas3 \
        libquadmath0 \
        libatomic1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN pip install --no-cache-dir \
        "numpy<2" \
        "scipy" \
        "matplotlib" \
        "scikit-learn" \
        "PyQt5" \
        pyvista==0.46.3 \
        pyvistaqt==0.11.3 \
        nest_asyncio \
        ipyevents \
        ipywidgets \
        trame \
        trame-vtk \
        trame-vuetify \
        mne \
        mne-bids \
        mne-bids-pipeline==1.10.1 \
    && pip uninstall -y vtk \
    && pip install --no-cache-dir --extra-index-url https://wheels.vtk.org vtk-osmesa \
    && find /usr/local/lib/python3.11 -type d -name "__pycache__" -exec rm -rf {} + \
    && find /usr/local/lib/python3.11 -type d \( -name "tests" -o -name "test" \) -exec rm -rf {} + \
    && rm -rf /root/.cache /tmp/*

# Copiamos SOLO el FreeSurfer desde la etapa 1
COPY --from=freesurfer-builder /opt/freesurfer /opt/freesurfer

# si recon-all no llegó bien, el build falla aquí y lo sabrás
RUN test -x /opt/freesurfer/bin/recon-all && /opt/freesurfer/bin/recon-all --version

WORKDIR /work

RUN rm -f /bin/sh && ln -s /bin/bash /bin/sh

RUN ldconfig

ENV FREESURFER_HOME=/opt/freesurfer \
    SUBJECTS_DIR=/opt/freesurfer/subjects \
    PERL5LIB=/opt/freesurfer/mni/lib/perl5 \
    PATH=/opt/freesurfer/bin:/opt/freesurfer/tktools:/opt/freesurfer/mni/bin:$PATH