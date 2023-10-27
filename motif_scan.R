# Define the URL of the motifs BED file
motif_url <- "https://bio.liclab.net/ATACdb/download/packages/Motif_scan_package.txt"

# Extract the filename from the URL
motif_filename <- basename(motif_url)

# Define the directory path
motif_dir <- "motif_scan/"
jaspar_dir <- "JASPAR/"

# Create a log file for capturing download errors
log_file_path <- file.path(jaspar_dir, "download_log.txt")

# Ensure that the directory exists; create it if it doesn't
dir.create(motif_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(jaspar_dir, showWarnings = FALSE, recursive = TRUE)

# Function to download MEME file and log errors
download_meme_file <- function(motif_id, meme_url, meme_dest) {
  # Check if MEME file already exists; skip download if it does
  if (file.exists(meme_dest)) {
    cat("MEME file for", motif_id, "already exists. Skipping download.\n")
    return()
  }

  tryCatch({
    download.file(meme_url, destfile = meme_dest, method = "auto")
    cat("MEME file for", motif_id, "downloaded successfully.\n")
  }, error = function(e) {
    cat("Failed to download MEME file for", motif_id, ". Error:", e$message, "\n")
    cat(paste("Failed to download MEME file for", motif_id, ". Error:", e$message, "\n"), file = log_file_path, append = TRUE)
  })
}

# Function to download PFM file and log errors
download_pfm_file <- function(motif_id, pfm_url, pfm_dest) {
  # Check if PFM file already exists; skip download if it does
  if (file.exists(pfm_dest)) {
    cat("PFM file for", motif_id, "already exists. Skipping download.\n")
    return()
  }

  tryCatch({
    download.file(pfm_url, destfile = pfm_dest, method = "auto")
    cat("PFM file for", motif_id, "downloaded successfully.\n")
  }, error = function(e) {
    cat("Failed to download PFM file for", motif_id, ". Error:", e$message, "\n")
    cat(paste("Failed to download PFM file for", motif_id, ". Error:", e$message, "\n"), file = log_file_path, append = TRUE)
  })
}

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

# Get unique motif IDs from column 1
unique_motif_ids <- unique(motif_data$motif_sacn_motif_id)

# Loop through unique motif IDs and download the corresponding files
for (motif_id in unique_motif_ids) {
  # Define the base URL
  base_url <- "https://jaspar.genereg.net/api/v1/matrix/"

  # Define the URLs for MEME and PFM files
  meme_url <- paste0(base_url, motif_id, ".meme")
  pfm_url <- paste0(base_url, motif_id, ".pfm")

  # Define the file paths for MEME and PFM files
  meme_dest <- file.path(jaspar_dir, paste0(motif_id, ".meme"))
  pfm_dest <- file.path(jaspar_dir, paste0(motif_id, ".pfm"))

  # Download MEME and PFM files
  download_meme_file(motif_id, meme_url, meme_dest)
  download_pfm_file(motif_id, pfm_url, pfm_dest)
}

# Calculate score based on -log10(qvalue)
motif_data$score <- as.integer(-10 * log10(motif_data$motif_sacn_qvalue))

# Create a new data frame with the desired column order
rearranged_motif_data <- motif_data[, c("motif_sacn_chr", "motif_sacn_start", "motif_sacn_end", "motif_sacn_tf_name", "score", "motif_sacn_strand", "motif_sacn_motif_id", "motif_sacn_pvalue", "motif_sacn_qvalue", "motif_sacn_sequence")]

# Modify the column names in the data frame
colnames(rearranged_motif_data) <- c("#chrom", "start", "end", "name", "score", "strand", "motif_id", "pValue", "qValue", "binding_sequence")

# Define the output filename for the rearranged motifs BED file
output_filename <- file.path(motif_dir, "Motif_scan_package_rearranged.bed")

# Write the modified data frame to a new BED file in the motif directory
write.table(rearranged_motif_data, file = output_filename, sep = "\t", quote = FALSE, row.names = FALSE)

cat("Rearranged motifs BED file saved as", output_filename, "\n")
