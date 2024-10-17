"""
This code converts letter to upper case or lower case
"""

# Importing necessary libraries
import gzip
from Bio import SeqIO
import argparse
import sys

# Input handling
parser = argparse.ArgumentParser("Switch letter cases.")
parser.add_argument("--input_fasta", type=str, help="Input fasta file", required=True)
parser.add_argument("--output_fasta", type=str, help="Output case switched fasta file", required=True)
parser.add_argument("--case", type=str, choices=["upper", "lower"], help="<upper> or <lower> case", required=True)

args = parser.parse_args()

input_fasta_file = args.input_fasta
output_fasta_file = args.output_fasta
case = args.case

# Reading through the records and switching cases
def switching_case(input_handle, letter_case):
    switched_records = []
    for record in SeqIO.parse(input_handle, "fasta"):
        if letter_case == "upper":
            record.seq = record.seq.upper()
            switched_records.append(record)
        elif letter_case == "lower":
            record.seq = record.seq.lower()
            switched_records.append(record)

    return switched_records

# Running the program
if __name__=="__main__":
    # Processing unzipped and zipped inputs
    if input_fasta_file.endswith(".gz"):
        with gzip.open(input_fasta_file, "rt") as input_handle:
            switched_records = switching_case(input_handle, case)
    else:
        with open(input_fasta_file, "r") as input_handle:
            switched_records = switching_case(input_handle, case)
    
    with gzip.open(output_fasta_file, "wt") as output_handle:
        SeqIO.write(switched_records, output_handle, "fasta")
