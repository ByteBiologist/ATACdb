library(rvest)
library(tibble)

webpage <- read_html("https://bio.liclab.net/ATACdb/search/search_sample_result.php?get_sample_id=1")

tbls <- html_nodes(webpage, "table")

# subset list of table nodes
tbls_ls <- webpage %>% html_nodes("table") %>% .[1] %>% html_table

# Extract the data from the list
data_list <- tbls_ls[[1]]

# Create a tibble with custom column names
tbls_ls <- as_tibble(data_list)
colnames(tbls_ls) <- c("Key", "Value")

# Extracting values for specific attributes
sample_id <- tbls_ls$Value[tbls_ls$Key == "Sample ID:"]
biosample_type <- tbls_ls$Value[tbls_ls$Key == "Biosample type:"]
tissue_type <- tbls_ls$Value[tbls_ls$Key == "Tissue type:"]
biosample_name <- tbls_ls$Value[tbls_ls$Key == "Biosample name:"]
cancer_type <- tbls_ls$Value[tbls_ls$Key == "Cancer type:"]
region_number <- tbls_ls$Value[tbls_ls$Key == "Region number:"]
length <- tbls_ls$Value[tbls_ls$Key == "Length:"]
geo_sra <- tbls_ls$Value[tbls_ls$Key == "GEO/SRA ID:"]

# Create a data frame with the extracted data
sample_data <- data.frame(
  Sample_ID = sample_id,
  Biosample_Type = biosample_type,
  Tissue_Type = tissue_type,
  Biosample_Name = biosample_name,
  Cancer_Type = cancer_type,
  Region_Number = region_number,
  Length = length,
  GEO_SRA = geo_sra
)

# Print the extracted data for Sample 1
print(sample_data)
