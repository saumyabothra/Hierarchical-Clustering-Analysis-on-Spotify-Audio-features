# Hierarchical clustering on the `data_by_year.csv` dataset with
# cluster summary heatmap and decade distribution
rm(list = ls())

if (!require(tidyverse)) install.packages("tidyverse", dependencies = TRUE)
if (!require(cluster)) install.packages("cluster", dependencies = TRUE)

library(tidyverse)
library(cluster)

# 1. Import and inspect the data ---------------------------------------------
data <- read.csv("~/Desktop/Seminar Data Science/data_by_year.csv", stringsAsFactors = FALSE)

str(data)
summary(data)
# Check for missing values
sapply(data, function(x) sum(is.na(x)))

# 2. Prepare the features -----------------------------------------------------
# Separate out the non‑numeric (categorical) fields (year, mode, key) for later use.
metadata <- data %>% select(year, mode, key)

features <- data %>%
  select(-year, -mode, -key) %>%
  # Log‑transform speechiness to dampen the influence of extreme values
  mutate(speechiness = log1p(speechiness))

# Standardise all features to mean 0 and sd 1
features_scaled <- scale(features)
summary(as.data.frame(features_scaled))

# 3. Compute distance matrix and perform clustering --------------------------
# Compute Euclidean distances and perform Ward's hierarchical clustering
dist_matrix <- dist(features_scaled, method = "euclidean")
hclust_ward <- hclust(dist_matrix, method = "ward.D2")

# Plot the dendrogram for visual inspection.  Label leaves with the
# year for easy interpretation.
plot(hclust_ward, labels = metadata$year,
     main = "Dendrogram of data_by_year (Ward linkage)",
     xlab = "Year", sub = "", cex = 0.6)

# 4. Evaluate cluster quality (optional) ---------------------------------------
# Compute average silhouette widths for k = 2:10.  Higher values
# indicate better separation.  Although the maximum silhouette width
# may occur at k = 2, domain knowledge may suggest using k = 3
# clusters.  Use this output for exploratory purposes.
sil_results <- data.frame(k = integer(), avg_silhouette = numeric())
for (k in 2:10) {
  cluster_assignments <- cutree(hclust_ward, k = k)
  sil <- silhouette(cluster_assignments, dist_matrix)
  sil_results <- rbind(sil_results, data.frame(k = k, avg_silhouette = mean(sil[, 3])))
}

print(sil_results)

# Plot the average silhouette width for k = 2..10
plot(sil_results$k, sil_results$avg_silhouette, type = "b", pch = 16,
     xlab = "Number of clusters (k)",
     ylab = "Average silhouette width",
     main = "Silhouette Analysis (Ward linkage)")
grid()

# 4. Choose the number of clusters -------------------------------------------
# We select k = 3 clusters based on domain knowledge about distinct
# historical eras.
k <- 3
cluster_assignments <- cutree(hclust_ward, k = k)

# Add the cluster labels back to the metadata and the original data
data$cluster <- factor(cluster_assignments)

# 5. Summarise clusters and create heatmap -----------------------------------
# Compute mean of each numeric feature within each cluster using the
# original (unscaled, non‑logged) data.  We include duration_ms,
# loudness, tempo, popularity, etc.
cluster_means <- data %>%
  group_by(cluster) %>%
  summarise(acousticness   = mean(acousticness),
            danceability   = mean(danceability),
            duration_ms    = mean(duration_ms),
            energy         = mean(energy),
            instrumentalness = mean(instrumentalness),
            liveness       = mean(liveness),
            loudness       = mean(loudness),
            speechiness    = mean(speechiness),
            tempo          = mean(tempo),
            valence        = mean(valence),
            popularity     = mean(popularity))

# Convert the cluster means to z‑scores column‑wise so that each
# feature can be compared across clusters on a common scale.  We
# select the numeric columns (excluding the cluster label) and
# apply scale().
scaled_means <- as.data.frame(scale(select(cluster_means, -cluster)))
cluster_means_z <- bind_cols(cluster = cluster_means$cluster, scaled_means)

# Reshape to long format for the heatmap
cluster_means_long <- cluster_means_z %>%
  pivot_longer(-cluster, names_to = "feature", values_to = "zscore")

# Plot the heatmap using ggplot2.  Warm colours represent high
# relative means, cool colours represent low means.
heatmap_plot <- ggplot(cluster_means_long,
                       aes(x = feature, y = cluster, fill = zscore)) +
  geom_tile() +
  scale_fill_gradient2(low = "navy", mid = "white", high = "firebrick",
                       midpoint = 0, name = "Z‑score") +
  labs(x = "Audio feature", y = "Cluster",
       title = "Heatmap of z‑scored mean features by cluster") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(heatmap_plot)

# 6. Tabulate years by decade and cluster -------------------------------------
# Create a decade column by flooring the year to the nearest decade
data$decade <- floor(data$year / 10) * 10

# Count the number of years in each decade for each cluster
decade_counts <- data %>%
  group_by(decade, cluster) %>%
  summarise(n_years = n(), .groups = "drop")

# Plot the distribution of years by decade and cluster
decade_plot <- ggplot(decade_counts,
                      aes(x = factor(decade), y = n_years, fill = cluster)) +
  geom_col(position = "dodge") +
  labs(x = "Decade", y = "Number of years", fill = "Cluster",
       title = "Distribution of years by decade and cluster") +
  theme_minimal()

print(decade_plot)

# End of script