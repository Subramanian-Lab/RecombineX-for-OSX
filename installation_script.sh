#!/bin/zsh

########################### NOT FOR RUNNING ################################

# Installing miniforge

curl -fsSLo Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-$(uname -m).sh"

bash Miniforge3.sh -b -p "${HOME}/conda"

mamba create -n recombinex_venv pandas biopython

# Installing sratools
wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-mac64.tar.gz


