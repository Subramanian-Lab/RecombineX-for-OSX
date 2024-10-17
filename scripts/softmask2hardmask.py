"""
This converts the softmasked sequences in the reference genome to hardmasked sequences by replacing the sequences by "N"
"""

# Importing necessary libraries
from Bio import SeqIO
from Bio.Seq import Seq
import argparse

# Input handling
parser = argparse.ArgumentParser(description="soft masked to hard mapping")

parser.add_argument("--input_file", type=str, help="Soft masked input fasta file", required=True)
parser.add_argument("--output_file", type=str, help="Hard masked output fasta file", required=True)
args = parser.parse_args()

soft_masked_file = args.input_file
hard_masked_file = args.output_file

# Converting soft masked to hard masked
def converting_soft_to_hard(input_handle):
    hard_masked_record = []
    for record in SeqIO.parse(input_handle, "fasta"):
        record.seq = Seq("".join(["N" if letter in ["a", "t", "g", "c", "n"] else letter for letter in record.seq]))
        hard_masked_record.append(record)

    return hard_masked_record

# Running the program
if __name__=="__main__":
    with open(soft_masked_file, "rt") as input_handle:
        hard_masked_record = converting_soft_to_hard(input_handle)

    with open(hard_masked_file, "wt") as output_handle:
        SeqIO.write(hard_masked_record, output_handle, "fasta")
