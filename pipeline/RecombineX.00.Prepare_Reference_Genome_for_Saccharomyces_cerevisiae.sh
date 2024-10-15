#!/bin/zsh

# Setting pipefail
set -e -o pipefail

# load environment variables for RecombineX
source ./../../env.sh

#################### set project-specific variables ##########################

debug="no" # Whether to keep intermediate files for debuging. Use "yes" if prefer to keep intermediate files, otherwise use "no". Default = "no".

#############################################################################

# process the pipeline
echo "retrieve sample reference genome data ..."

# Obtaining the reference genome
wget -c https://downloads.yeastgenome.org/sequence/S288C_reference/genome_releases/S288C_reference_genome_R64-2-1_20150113.tgz

# Unzipping
tar -xvzf S288C_reference_genome_R64-2-1_20150113.tgz

# Extracting genome.fa and feature.gff files
cp ./S288C_reference_genome_R64-2-1_20150113/S288C_reference_sequence_R64-2-1_20150113.fsa  SGDref.genome.raw.fa
cp ./S288C_reference_genome_R64-2-1_20150113/saccharomyces_cerevisiae_R64-2-1_20150113.gff SGDref.all_feature.gff

# Tidying reference genome
python $RECOMBINEX_HOME/scripts/tidying_SGD_reference_genome.py --input_fasta SGDref.genome.raw.fa --output_fasta SGDref.genome.tidy.fa

# Selecting fasta from list
python $RECOMBINEX_HOME/scripts/selecting_chr_from_list.py --input_fasta SGDref.genome.tidy.fa --list $RECOMBINEX_HOME/data/Saccharomyces_cerevisiae.chr_list.txt --output_fasta SGDref.genome.fa --selection_mode select --ranking_order by_fasta

# Zipping genome file
gzip SGDref.genome.fa

# Selecting features from gff file
python $RECOMBINEX_HOME/scripts/filtering_gff_by_feature.py --input_fasta SGDref.all_feature.gff --output_fasta SGDref.centromere.gff --feature centromere --mode keep

if [[ $debug = "no" ]]
then
    echo ""
    echo "removing intermediate files and directories ..."

    rm -rf S288C_reference_genome_R64-2-1_20150113*
    rm SGDref.genome.raw.fa
    rm SGDref.genome.tidy.fa
    rm SGDref.all_feature.gff
fi

############################
# checking bash exit status
if [[ $? -eq 0 ]]
then
    echo ""
    echo "RecombineX message: This bash script has been successfully processed! :)"
    echo ""
    echo ""
    exit 0
fi
############################

