#!/usr/bin/python

import subprocess
import os

# Define base directory path
base_dir = "/mnt/ebs/jackal/FILER2/FILER2-production/ATACdb/"

# Define liftover path and chain file relative to the base directory
liftover_path = os.path.join(base_dir, "Liftover/liftOver")
chain_file = os.path.join(base_dir, "Liftover/hg19ToHg38.over.chain.gz")

# Relative paths for input file and destination directory
input_file_rel = "motif_scan/Motif_scan_package_rearranged.bed"
destination_dir_rel = "hg38/liftover_Motifs"

# Function to filter BED file
def filter_bed_file(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for idx, line in enumerate(infile):
            if idx == 0:
                continue

            fields = line.strip().split('\t')
            start_position = fields[1]

            try:
                int(start_position)
            except ValueError:
                continue

            outfile.write(line)

# Function to perform liftover
def liftover_bed(input_file, destination_dir):
    base_name = os.path.basename(input_file).split('.')[0]
    output_file = os.path.join(destination_dir, "Motif_scan_hg38_lifted.bed")
    filtered_input_file = os.path.join(destination_dir, f"filtered_{base_name}.bed")
    filter_bed_file(input_file, filtered_input_file)
    unlifted_path = os.path.join(destination_dir, "unlifted.bed")

    cmd = [
        liftover_path,
        "-bedPlus=6",
        filtered_input_file,
        chain_file,
        output_file,
        unlifted_path
    ]

    try:
        subprocess.run(cmd, check=True)
        print("Liftover completed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error during liftover: {e}")
        raise

    return output_file

# Function to get reference sequence
def get_reference(sequenceID):
    fa = "hg38.fa"
    output = subprocess.check_output(["samtools", "faidx", fa, sequenceID]).decode("utf-8")
    lines = output.split('\n')
    ref_sequence = ''.join(lines[1:])
    return ref_sequence.upper()

# Function to get reverse complement sequence
def get_reverse_complement(sequence):
    complement = {'a': 't', 'c': 'g', 'g': 'c', 't': 'a'}
    reverse_complement = ''
    sequence = sequence.lower()
    for base in reversed(sequence):
        if base in complement:
            reverse_complement += complement[base]
        else:
            reverse_complement += base
    return reverse_complement.upper()

# Main function to liftover and process sequences
def process_sequences(input_file, destination_dir):
    lifted_output_file = liftover_bed(input_file, destination_dir)

    # Write the lifted sequences to a new file
    lifted_output_with_sequences = os.path.join(destination_dir, "Motif_scan_hg38_lifted_with_sequences.bed")
    mismatched_sequences_file = os.path.join(destination_dir, "mismatched_sequences.bed")
    with open(lifted_output_file, 'r') as lifted_file, \
         open(lifted_output_with_sequences, 'w') as output, \
         open(mismatched_sequences_file, 'w') as mismatched_output:
        # Write header line from input file
        with open(input_file, 'r') as input_header:
            header_line = input_header.readline().strip()
            output.write(header_line + '\thg38_reference\n')
            mismatched_output.write(header_line + '\thg38_reference\n')

        for line in lifted_file:
            fields = line.strip().split('\t')
            chr = fields[0]
            start = fields[1]
            end = fields[2]
            strand = fields[5]
            start_position = int(start) + 1
            sequenceID = f"{chr}:{start_position}-{end}"

            if strand == '+':
                hg38_sequence = get_reference(sequenceID)
            elif strand == '-':
                ref_sequence = get_reference(sequenceID)
                hg38_sequence = get_reverse_complement(ref_sequence).upper()
            else:
                print("Invalid strand information.")
                continue

            # Append the hg38_sequence at the end of each line
            line_with_hg38_sequence = line.strip() + '\t' + hg38_sequence + '\n'
            output.write(line_with_hg38_sequence)

            # Check if hg19 and hg38 sequences match
            hg19_sequence = fields[9]
            if hg19_sequence != hg38_sequence:
                mismatched_line = line.strip() + '\t' + hg38_sequence + '\n'
                mismatched_output.write(mismatched_line)


# Construct full paths for input file and destination directory
input_file = os.path.join(base_dir, input_file_rel)
destination_dir = os.path.join(base_dir, destination_dir_rel)

# Call the main function
process_sequences(input_file, destination_dir)
