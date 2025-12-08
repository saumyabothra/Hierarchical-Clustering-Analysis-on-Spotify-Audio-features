# Spotify Musical Eras Clustering (Hierarchical + Silhouette + Heatmaps)

This project groups years into “musical eras” using hierarchical clustering on Spotify audio features from `data_by_year.csv`.

## The pipeline:

- Cleans and scales yearly Spotify audio features
- Runs hierarchical clustering with Ward’s method
- Uses silhouette analysis to choose the number of clusters
- Summarises each cluster with a feature heatmap
- Shows how clusters distribute across decades

The idea is to see if audio features alone can recover intuitive eras in popular music over time.

## Dataset

The dataset `data_by_year` is a year-level summary of Spotify tracks:

- One row per year (e.g. 1921–2020)
- Columns include:
  - `year`, `mode`, `key`
  - Audio features: `acousticness`, `danceability`, `energy`, `instrumentalness`,
    `liveness`, `speechiness`, `valence`
  - Other numeric fields: `duration_ms`, `loudness`, `tempo`, `popularity`


## Getting Started

All steps can be executed by running the R script that contains the code.

## This script:
1. Loads data_by_year.csv
2. Splits metadata (year, mode, key) from numeric features
3. Performs necessary data transformations
4. Computes an Euclidean distance matrix
5. Runs hierarchical clustering
6. Builds:
  - A dendrogram of years
  - A heatmap of z-scored cluster means
  - A decade-by-cluster bar chart

## Customizing the Analysis
To play with different ideas, you can:
1. Change the number of clusters:
  - Edit k <- 3 and re-run to try k = 2, 4, etc.
2. Adjust preprocessing:
  - Include key and mode (after encoding) or remove less useful features
3. Try different transforms on skewed variables
4. Swap distance or linkage:
  - Use dist(..., method = "manhattan")
  - Try hclust(..., method = "average" or "complete")

## License
This project is released under the MIT License.
