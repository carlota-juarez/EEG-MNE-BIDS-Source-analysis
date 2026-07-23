FROM debian:bookworm-slim AS freesurfer-builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tar \
    gzip \
    bash \
    perl \
    tcsh \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
    https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.4.1/freesurfer-linux-ubuntu22_amd64-7.4.1.tar.gz \
    | tar -xz -C /opt

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

ENV FREESURFER_HOME=/opt/freesurfer
ENV SUBJECTS_DIR=/opt/freesurfer/subjects
ENV PERL5LIB=/opt/freesurfer/mni/lib/perl5
ENV PATH=/opt/freesurfer/bin:/opt/freesurfer/mni/bin:$PATH

RUN test -x /opt/freesurfer/bin/recon-all
RUN test -f /opt/freesurfer/mni/lib/perl5/MNI/Startup.pm

RUN bash -c "source /opt/freesurfer/SetUpFreeSurfer.sh && recon-all --version"



FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    QT_QPA_PLATFORM=offscreen \
    MPLBACKEND=Agg \
    PYVISTA_OFF_SCREEN=true \
    LIBGL_ALWAYS_SOFTWARE=1 \
    MNE_BROWSER_BACKEND=matplotlib \
    MNE_3D_BACKEND=pyvistaqt \
    MNE_3D_OPTION_ANTIALIAS=false \
    OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    NUMEXPR_NUM_THREADS=1 \
    VECLIB_MAXIMUM_THREADS=1 \
    FREESURFER_HOME=/opt/freesurfer \
    SUBJECTS_DIR=/opt/freesurfer/subjects \
    PERL5LIB=/opt/freesurfer/mni/lib/perl5 \
    PATH=/opt/freesurfer/bin:/opt/freesurfer/mni/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    bash \
    perl \
    tcsh \
    bc \
    tar \
    gzip \
    unzip \
    xvfb \
    libgomp1 \
    libgsl-dev \
    libgl1 \
    libglib2.0-0 \
    libgl1-mesa-dri \
    libosmesa6 \
    libegl1 \
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
    libxml-parser-perl \
 && rm -rf /var/lib/apt/lists/*

COPY --from=freesurfer-builder /opt/freesurfer /opt/freesurfer

RUN mkdir -p /opt/freesurfer/license

RUN ls -la /opt/freesurfer

RUN test -x /opt/freesurfer/bin/recon-all
RUN test -f /opt/freesurfer/mni/lib/perl5/MNI/Startup.pm
RUN test -f /opt/freesurfer/SetUpFreeSurfer.sh

RUN bash -c "source /opt/freesurfer/SetUpFreeSurfer.sh && recon-all --version"

RUN pip install --no-cache-dir \
    "numpy<2" \
    scipy \
    matplotlib \
    scikit-learn \
    PyQt5 \
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
 && pip install --no-cache-dir \
        --extra-index-url https://wheels.vtk.org \
        vtk-osmesa \
 && find /usr/local/lib/python3.11 \
        -type d \
        -name "__pycache__" \
        -exec rm -rf {} + \
 && find /usr/local/lib/python3.11 \
        -type d \
        \( -name "tests" -o -name "test" \) \
        -exec rm -rf {} + \
 && rm -rf /root/.cache /tmp/*

WORKDIR /work

RUN rm -f /bin/sh && ln -s /bin/bash /bin/sh

RUN ldconfig
