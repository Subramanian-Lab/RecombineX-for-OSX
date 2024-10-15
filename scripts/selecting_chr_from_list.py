"""
This code selects or excludes the fasta sequences from a predetermined file and output in a custom order
"""

# Importing necessary packages
from Bio import SeqIO
import argparse
import global_functions as gf

# Handling input and output files and parameters

parser = argparse.ArgumentParser(description="selecting or excluding fasta sequences")

parser.add_argument('--input_fasta', type=str, help='Tidied fasta file')
parser.add_argument('--list', type=str, help='Chromosome list')
parser.add_argument('--output_fasta', type=str, help='Output fasta file')
parser.add_argument('--selection_mode', type=str, help='Selection mode ("select" or "exclude". Default = "select")')
parser.add_argument('--ranking_order', type=str, help='Ranking order ("from_fasta" or "from_list")')

args = parser.parse_args()

# Input, output and parameters from commandline input
tidied_fasta_file = args.input_fasta
chromosome_file = args.list
filtered_output_file = args.output_fasta
selection_mode = args.selection_mode
ranking_order = args.ranking_order

# Checking file existence
gf.testing_file_existence(tidied_fasta_file)
gf.testing_file_existence(chromosome_file)

# Creating chromosome lists from fasta file and list
with open(chromosome_file, "r") as chr_list_file:
    chromosome_list = [chromosome_id.strip() for chromosome_id in chr_list_file] # Contains chromosome ids from list

record_id_list = [record.id for record in SeqIO.parse(tidied_fasta_file, "fasta")] # Contain chromosome id from fasta

# Selecting from the list
def selecting_from_list(tidy_file_path: str, chromosome_list: list, selection_mode = "select"):
    filtered_records = []
    for record in SeqIO.parse(tidy_file_path, "fasta"):
        if selection_mode == "select":
            if record.id in chromosome_list:
                filtered_records.append(record)
        elif selection_mode == "exclude":
            if record.id not in chromosome_list:
                filtered_records.append(record)
    
    return filtered_records

# Sorting according to fasta or list
def sorting_from_file(sorting_order: list, filtered_records: list):
    sorted_records = []
    for order in sorting_order:
        for record in filtered_records:
            if order == record.id:
                sorted_records.append(record)

    return sorted_records

if __name__=="__main__":
    # Filtering according to the list
    filtered_records = selecting_from_list(tidied_fasta_file, chromosome_list, selection_mode)
    
    # Sorting the filtered records
    if ranking_order == "by_fasta":
        sorted_records = sorting_from_file(record_id_list, filtered_records)
    elif ranking_order == "by_list":
        sorted_records = sorting_from_file(chromosome_list, filtered_records)

# Writing to the output file
SeqIO.write(sorted_records, filtered_output_file, "fasta")