#####.#####.#####.#####.#####.#####.#####.#####.#####.#####.#####.#####.
## Validation of UAV height analysis from DEM
## (RGB photogammetry based Digital Elevation Models)
## HS
## Last updated: 4 November, 2025
#####.#####.#####.#####.#####.#####.#####.#####.#####.#####.#####.#####.
## Library imports
library(readxl)
library(readr)
library(stringr)
library(ggplot2)
library(dplyr)

# Read in tables
# Plantcv derived traits
sv_df <- read_csv("./Documents/Projects/teff/wider-bounds/DEM-validation/tef-height-output-nov4.json-single-value-traits.csv")
# Manual/Grount Truth data
gt_df <- read_xlsx("./Documents/Projects/teff/wider-bounds/DEM-validation/Teff Satnd and Plant Height data for Dhiraj[97] (1).xlsx", skip = 0) 

# Rename columns in gt data
gt_df$plot_ids <- as.character(gt_df$plot_ids)
sv_df$plot_ids <- as.character(sv_df$sample)

# Format date information 
sv_df$date <- str_split_i(sv_df$id, "_", i=1)

# Merge ground truth with pcv output height data
merge_df <- left_join(sv_df, gt_df, by=c("plot_ids"))

# Filter on date closest to Ground Truth measurements 
df_subset <- merge_df[merge_df$date == "2023-07-12",]


################################
## Plot correlation of traits ##
################################
## Calculate linear regression between manual and pcv data
ml = lm(df_subset$`Average Stand Height` ~ df_subset$plant_height_default) 
## Plot the correlation
ggplot(data = df_subset ) +
  geom_jitter(mapping = aes(x = `Average Stand Height`, y = plant_height_default)) +       
  labs(y = "Plot height (plantcv: 12 July UAV flight)",
       x = "Avg stand height (manual: 13 July, 2023)",
       subtitle = paste(c("R^2 = "), summary(ml)$r.squared ),
       title = "Tef plot height")  ## Embed r^2 into plot as subtitle
## Summary of linear model 
summary(ml) 

#####.#####.#####.#####.#####.#####.#####.#####.#####.#####.#####.#####.
