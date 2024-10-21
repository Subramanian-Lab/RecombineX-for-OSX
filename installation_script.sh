#!/bin/zsh

########################### NOT FOR RUNNING ################################

# Installing miniforge

curl -fsSLo Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-$(uname -m).sh"

bash Miniforge3.sh -b -p "${HOME}/conda"

mamba create -n recombinex_venv pandas biopython

# Installing sratools
wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-mac64.tar.gz

# For installing bwa in mac
cd bwa/
sed -i -e 's/<emmintrin.h>/"sse2neon.h"/' ksw.c
wget https://gitlab.com/arm-hpc/packages/uploads/ca862a40906a0012de90ef7b3a98e49d/sse2neon.h
make clean all

This solves the gcc error in mac

