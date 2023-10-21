# Load the necessary libraries (if not already installed)
# install.packages("data.table")
# install.packages("dplyr")

library(data.table)
library(dplyr)

# Set the input and output directory paths
chromatin_directory <- "Accessible_chromatin_files/test"
motif_directory <- "motif"
output_directory <- "mapping"

# Create the output directory if it doesn't exist
if (!dir.exists(output_directory)) {
  dir.create(output_directory)
}

# List all files in the chromatin input directory
chromatin_files <- list.files(path = chromatin_directory, full.names = TRUE)

# Set the pattern to match motif files
motif_pattern <- "^Motif_scan_package_rearranged_chr[0-9]+\\.bed$"

# List all files in the motif input directory that match the pattern
chromosome_motif_files <- list.files(path = motif_directory, full.names = TRUE, pattern = motif_pattern)

#print(chromosome_motif_files)

# Function to process a single chromatin file with a specific motif file
process_chromatin_file <- function(chromatin_file, motif_file) {
  # Extract the file name without the path
  chromatin_file_name <- basename(chromatin_file)
  
  # Load the accessible chromatin regions data
  chromatin_data <- fread(chromatin_file, header = TRUE, sep = "\t")
  
  # Load the motif data for the current chromosome
  motif_data <- fread(motif_file, header = TRUE, sep = "\t")
  
  # Initialize lists to store mapping results
  region_ids <- character(0)
  motif_ids <- character(0)
  tf_names <- character(0)
  pvalues <- numeric(0)
  qvalues <- numeric(0)
  
  # Iterate through each chromatin region
  for (i in 1:nrow(chromatin_data)) {
    chrom <- chromatin_data[i, "chr"]
    start <- chromatin_data[i, "start"]
    end <- chromatin_data[i, "end"]
    
    # Find motifs that overlap with the chromatin region
    overlapping_motifs <- motif_data %>%
      filter(
        motif_sacn_chr == chrom,
        motif_sacn_start >= start,
        motif_sacn_end <= end
      )
    
    # Check if any motifs were found
    if (nrow(overlapping_motifs) > 0) {
      # Extract relevant information and store it in lists
      region_ids <- c(region_ids, rep(chromatin_data[i, "region_ID"], nrow(overlapping_motifs)))
      motif_ids <- c(motif_ids, overlapping_motifs$motif_sacn_motif_id)
      tf_names <- c(tf_names, overlapping_motifs$motif_sacn_tf_name)
      pvalues <- c(pvalues, overlapping_motifs$motif_sacn_pvalue)
      qvalues <- c(qvalues, overlapping_motifs$motif_sacn_qvalue)
    }
  }
  
  # Combine the extracted information into a data frame
  mapping_df <- data.frame(
    Accessible_Chromatin_Region = region_ids,
    Motif_ID = motif_ids,
    TF_Name = tf_names,
    PValue = pvalues,
    QValue = qvalues
  )
  
  # Create the output file name (based on the chromatin input file name)
  output_file <- file.path(output_directory, paste0("Mapping_results_", chromatin_file_name))
  
  # Save the mapping results to the output file
  write.csv(mapping_df, file = output_file, row.names = FALSE)
}

# Process each chromatin file with its corresponding motif file
for (chromatin_file in chromatin_files) {
  # Iterate through all chromosome-specific motif files
  for (chromosome_motif_file in chromosome_motif_files) {
    process_chromatin_file(chromatin_file, chromosome_motif_file)
  }
}

# Optionally, you can do further analysis or processing with the collected results.
# For example, you can combine results from multiple files or generate summary statistics.

# Print a message to indicate that the mapping is complete
cat("Mapping complete. Results are saved in the 'mapping' directory.\n")
