"""
This code will tidy up the header of the reference genome file and removing descriptions
"""

# Importing necessary packages
import re
import sys
from Bio import SeqIO
import argparse

# Managing input and output fasta files
parser = argparse.ArgumentParser(description="Tidying SGD fasta file")
parser.add_argument('--input_fasta', type=str, help="Input fasta file")
parser.add_argument('--output_fasta', type=str, help="Input fasta file")
args = parser.parse_args()

fasta_file = args.input_fasta
tidied_fasta_file = args.output_fasta

# Tidying up the header
def tidying_header(record):
    match = re.search(r'\[(chromosome|location)=([^\]]+)\]', record.description) # Obtaining the chromosome number from the [chromosome=x] or [location=x] line.
    if match:
        chromosome_number = match.group(2)

    record.id = f"chr{chromosome_number}" # Changing the id to chrX
    record.description = ""
    SeqIO.write(record, output_file, "fasta")

with open(fasta_file, "r") as input_file, open(tidied_fasta_file, "w") as output_file:
    for record in SeqIO.parse(input_file, "fasta"):
        tidying_header(record)
    print(f"Finished tidying up {len(record)} records")