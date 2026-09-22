# Replication Code and Data Repository for PGRFA Review Manuscript

This repository contains the data and R execution scripts required to replicate the quantitative text analysis, Correspondence Analysis (CA), k-means clustering, geopolitical tests, and qualitative heatmap visualization presented in the manuscript.

To preserve the double-blind peer-review process, all personal identifiers and absolute file paths have been removed.

---

## Repository Structure

```text
.
├── data/
│   ├── data_freq_unigrams.csv           # Document-term matrix (unigrams) for CA & Clustering
│   ├── data_processed_clusters.csv       # Article dataset with assigned cluster variables
│   ├── qualitative_coding_matrix.csv     # Qualitative coding presence/absence matrix (n=20)
│   └── Qualitative_Analysis_PGRFA.atlasti # Complete ATLAS.ti project bundle (quotations & codes)
├── scripts/
│   ├── 2. Author Region vs. Case Study Region Distribution.R
│   ├── 3.Correspondence Analysis and K-means.R
│   ├── 4. Cluster Proportions and Geopolitical Distribution.R
│   └── 5.Clustered Heatmap of Qualitative Codes by Cluster.R
├── .gitignore
├── LICENSE
└── README.md
```

---

## Requirements

### R Packages

The analysis requires the following R libraries:

```R
install.packages(c(
  "ggplot2", "dplyr", "forcats", "tidyr", "tibble",
  "FactoMineR", "factoextra", "ggrepel", "cluster",
  "tidytext", "scales", "rstatix", "patchwork", "pheatmap"
))
```
## Qualitative Analysis Software
* **ATLAS.ti (v22/v23/v24/v25):** Recommended to access the full qualitative analysis, including the complete code hierarchy, coded quotations, and thematic memos (`data/Qualitative_Analysis_PGRFA.atlasti`).
* **Open Access Alternative:** Non-ATLAS.ti users can inspect the reduced presence/absence matrix used to compute the heatmap directly via `data/qualitative_coding_matrix.csv`.
---

## Execution Workflow

All scripts are configured to run using relative paths assuming the root folder of this repository as the working directory.

1. **Geopolitical Mapping (Figure 2)**
   * **Script:** `scripts/2. Author Region vs. Case Study Region Distribution.R`
   * **Input:** `data/data_freq_unigrams.csv`
   * **Description:** Standardizes regional categories (Author Region vs. Case Study Region) and generates the stacked bar chart for Figure 2.

2. **Correspondence Analysis & K-Means Clustering (Figure 3)**
   * **Script:** `scripts/3.Correspondence Analysis and K-means.R`
   * **Input:** `data/data_freq_unigrams.csv`
   * **Description:** Performs Correspondence Analysis (CA), determines optimal k via Elbow and Silhouette methods, executes k-means (k=4), generates the CA Biplot (Figure 3a), specificity charts (Figure 3b), and identifies the 20 focal articles closest to cluster centroids.
   * *Note:* The text preprocessing pipeline (Python script for raw text lemmatization) will be made available upon final publication; the preprocessed document-term matrix is provided directly in `data/data_freq_unigrams.csv`.

3. **Cluster Proportions & Geopolitical Distribution (Figure 4)**
   * **Script:** `scripts/4. Cluster Proportions and Geopolitical Distribution.R`
   * **Input:** `data/data_processed_clusters.csv`
   * **Description:** Computes cluster proportions, executes pairwise proportion tests with Bonferroni corrections, and evaluates regional-thematic independence via Chi-square tests (Monte Carlo simulations) and Cramér's V.

4. **Clustered Heatmap of Qualitative Codes (Figure 5)**
   * **Script:** `scripts/5.Clustered Heatmap of Qualitative Codes by Cluster.R`
   * **Input:** `data/qualitative_coding_matrix.csv`
   * **Description:** Aggregates qualitative code presence/absence proportions across the 20 focal articles and generates the hierarchical clustered heatmap (Figure 5).
