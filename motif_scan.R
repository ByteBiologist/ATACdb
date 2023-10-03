# Define the URL of the motifs BED file
motif_url <- "https://bio.liclab.net/ATACdb/download/packages/Motif_scan_package.txt"

# Extract the filename from the URL
motif_filename <- basename(motif_url)

# Define the directory path for the motif files
motif_dir <- "motif/"

# Ensure that the directory exists; create it if it doesn't
dir.create(motif_dir, showWarnings = FALSE, recursive = TRUE)

# Check if the raw motifs BED file already exists in the motif directory
if (!file.exists(file.path(motif_dir, motif_filename))) {
  # Download the motifs BED file from the URL and save it to the motif directory if it doesn't exist
  download.file(motif_url, destfile = file.path(motif_dir, motif_filename))

  # Check if the file has been downloaded successfully
  if (file.exists(file.path(motif_dir, motif_filename))) {
    cat("Raw motifs BED file downloaded successfully.\n")
  } else {
    cat("Failed to download the raw motifs BED file.\n")
  }
} else {
  cat("Raw motifs BED file already exists in the motif directory.\n")
}

# Read the motifs BED file into a data frame
motif_data <- read.table(file.path(motif_dir, motif_filename), header = TRUE, sep = "\t")

# Rearrange the columns as specified
# Create a new data frame with the desired column order
rearranged_motif_data <- motif_data[, c("motif_sacn_chr", "motif_sacn_start", "motif_sacn_end", "motif_sacn_tf_name", "motif_sacn_motif_id", "motif_sacn_strand", "motif_sacn_pvalue", "motif_sacn_qvalue", "motif_sacn_sequence")]

# Define the output filename for the rearranged motifs BED file
output_filename <- file.path(motif_dir, "Motif_scan_package_rearranged.bed")

# Write the modified data frame to a new BED file in the motif directory
write.table(rearranged_motif_data, file = output_filename, sep = "\t", quote = FALSE, row.names = FALSE)

cat("Rearranged motifs BED file saved as", output_filename, "\n")
