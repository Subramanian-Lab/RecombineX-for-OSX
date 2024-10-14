"""
This code will tidy up the header of the reference genome file and removing descriptions
"""

# Importing necessary packages
import re
import sys
from Bio import SeqIO

# Input and output files
genome_file = sys.argv[1]
tidied_genome_file = sys.argv[2]

# Tidying up the header
def tidying_header(record):
    match = re.search(r'\[(chromosome|location)=([^\]]+)\]', record.description) # Obtaining the chromosome number from the [chromosome=x] or [location=x] line.
    if match:
        chromosome_number = match.group(2)

    record.id = f"chr{chromosome_number}" # Changing the id to chrX
    record.description = ""
    SeqIO.write(record, output_file, "fasta")

with open(genome_file, "r") as input_file, open(tidied_genome_file, "w") as output_file:
    for record in SeqIO.parse(input_file, "fasta"):
        tidying_header(record)
    print(f"Finished tidying up {len(record)} records")