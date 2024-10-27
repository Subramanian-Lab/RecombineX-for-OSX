#!/bin/zsh

########################### NOT FOR RUNNING ################################

## Installing miniforge

curl -fsSLo Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-$(uname -m).sh"

bash Miniforge3.sh -b -p "${HOME}/conda"

# Sourcing mamba
source conda/etc/profile.d/conda.sh
source conda/etc/profile.d/mamba.sh

# Creating venv
mamba create -n recombinex_venv pandas biopython

# Installing samtools
Download the tar file
tar xvjf samtools-${SAMTOOLS_VERSION}.tar.bz2
 cd $samtools_dir
 C_INCLUDE_PATH=""
 ./configure --without-curses;
 make -j $MAKE_JOBS
 cd htslib-${SAMTOOLS_VERSION}
 #autoheader
 #autoconf
 ./configure
 make -j $MAKE_JOBS
 cd $build_dir
 rm samtools-${SAMTOOLS_VERSION}.tar.bz2
 note_installed $samtools_dir

## Installing blast+
Download from this site ( version 2.2.31)
http://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/

## Installing UCSC utilities
from link: http://hgdownload.soe.ucsc.edu/admin/exe

fasplit, fastotwobit, twobitinfo

## Installing sratools
wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-mac64.tar.gz

## Installing Trimmomatic
http://www.usadellab.org/cms/index.php?page=trimmomatic (version 0.39)

## Installing java 8
brew install --cask adoptopenjdk8

## For installing bwa in mac
cd bwa/
sed -i -e 's/<emmintrin.h>/"sse2neon.h"/' ksw.c
wget https://gitlab.com/arm-hpc/packages/uploads/ca862a40906a0012de90ef7b3a98e49d/sse2neon.h
make clean all

This solves the gcc error in mac

# gcc error for FREEC
https://cmichel.io/fixing-cpp-compilation-bugs-for-the-mac-os-catalina-upgrade/


