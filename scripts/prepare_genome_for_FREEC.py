"""
This code prepares the genome for FREEC analysis
"""

# Importing necessary packages
from Bio import SeqIO
import argparse
import os

# Input handling
parser = argparse.ArgumentParser(description="Genome preparation for FREEC analysis")
parser.add_argument("--input_file", type=str, help="Input genome fasta file", required=True)
parser.add_argument("--prefix", type=str, help="Prefix for FREEC genome", required=True)
parser.add_argument("--excluded_list", type=str, help="List of excluded sequences")

args = parser.parse_args()

input_fasta = args.input_file
excluded_chr_list_file = args.excluded_list
prefix = args.prefix

freec_chr_directory = f"{prefix}_FREEC_chr"
output_fasta = f"{prefix}.FREEC.fa"
dict_file = f"{prefix}.FREEC_chr.dict"

# Converting Chromosome ID to integers and storing a dictionary for reference
def converting_chr_id_to_int(dict_handle, output_handle, record, index):
    # Writing to dictionary
    dict_handle.write("\t".join(["original_to_FREEC", str(record.id), "chr" + str(index), "\n"]))
    dict_handle.write("\t".join(["FREEC_to_original", "chr" + str(index), str(record.id), "\n"]))

    # Writing the renamed records into a fasta file
    record.id = "chr" + str(index)
    record.description = ""

    # Writing individual chromosome sequences into seperate files
    single_chr_path = os.path.join(freec_chr_directory, str(record.id) + ".fa")
    with open(single_chr_path, "wt") as chr_out:
        SeqIO.write(record, chr_out, "fasta")

    return record

# Creating an exluding chromosome list
def getting_excluding_chr_list(excluded_list_handle):
    excluded_chr_list = []
    for line in excluded_list_handle:
        excluded_chr_list.append(line.strip())

    return excluded_chr_list

# Running the code
if __name__=="__main__":
    # Creating the directory to store individual chromosome sequence
    os.makedirs(freec_chr_directory, exist_ok=True)
    
    # Obtaining exluding chromosome list
    if excluded_chr_list_file != "":
        with open(excluded_chr_list_file, "rt") as chr_list:
            excluded_chr_list = getting_excluding_chr_list(chr_list)
    else:
        excluded_chr_list = []

    # Converting the chromosome headers to int
    with open(input_fasta, "rt") as input_handle, open(output_fasta, "wt") as output_handle, open(dict_file, "wt") as output_dict:
        chr_num = 1
        new_records = []
        for record in SeqIO.parse(input_handle, "fasta"):
            if record.id in excluded_chr_list:
                continue
            else:
                modified_record = converting_chr_id_to_int(output_dict, output_handle, record, chr_num)
                new_records.append(modified_record)
                chr_num += 1
        
        SeqIO.write(new_records, output_handle, "fasta")