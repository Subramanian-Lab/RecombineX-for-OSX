"""
Relabelling chromosome names in the gff file
"""

# Importing necessary packages
import argparse

# Input handling
parser = argparse.ArgumentParser(description="Relabelling chromosome names")
parser.add_argument("--input_file", type=str, help="Input GFF file")
parser.add_argument("--tag", type=str, help="Prefix")
parser.add_argument("--output_file", type=str, help="Output GFF file")

args = parser.parse_args()

input_gff_file = args.input_file
output_gff_file = args.output_file
tag = args.tag

# Running the program
with open(input_gff_file, "rt") as input_handle, open(output_gff_file, "wt") as output_handle:
    for line in input_handle:
        fields = line.split()
        fields[0] = f"{tag}_{fields[0]}"
        output_handle.write("\t".join(fields))