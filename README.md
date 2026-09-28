# Replication Code and Data Repository for PGRFA Review Manuscript

This repository contains the full data preprocessing pipeline, quantitative text analysis, Correspondence Analysis (CA), k-means clustering, geopolitical tests, and qualitative heatmap visualization presented in the manuscript.

---

## Repository Structure

```text
.
├── data/
│   ├── data_freq_unigrams.csv                 # Document-term matrix (unigrams) for CA & Clustering
│   ├── data_processed_clusters.csv             # Article dataset with assigned cluster variables
│   ├── qualitative_coding_matrix.csv           # Qualitative coding presence/absence matrix (n=20)
│   ├── qualitative_codebook_and_quotations.pdf # Qualitative Coding Report (codes & original quotations)
│   └── Qualitative_Analysis_PGRFA.atlasti       # Complete ATLAS.ti project bundle
├── scripts/
│   ├── 1. Text Preprocessing and Lemmatization.py
│   ├── 2. Author Region vs. Case Study Region Distribution.R
│   ├── 3.Correspondence Analysis and K-means.R
│   ├── 4. Cluster Proportions and Geopolitical Distribution.R
│   └── 5.Clustered Heatmap of Qualitative Codes by Cluster.R
├── .gitignore
├── LICENSE
└── README.md
```
#Note on raw text data: Raw full-text files (.txt) for the 107 articles are omitted from this public repository to respect publisher copyright restrictions. However, all transformed, preprocessed, and analytical datasets required to fully reproduce the study are provided in the data/ directory.
---

## Requirements
#Python Environment (Text Preprocessing)
-Python 3.8+
-Required Libraries: `pandas, nltk, xlsxwriter`
-NLTK Resources: `stopwords, words, wordnet`(automatically downloaded upon script execution if missing).

# R Packages
-R 4.0+
-The analysis requires the following R libraries:

```R
install.packages(c(
  "ggplot2", "dplyr", "forcats", "tidyr", "tibble",
  "FactoMineR", "factoextra", "ggrepel", "cluster",
  "tidytext", "scales", "rstatix", "patchwork", "pheatmap"
))
```
## Qualitative Analysis Access Options
* **ATLAS.ti Project Bundle (`data/Qualitative_Analysis_PGRFA.atlasti`):** Recommended to access the full interactive qualitative analysis, including the complete code hierarchy and coded quotations (requires ATLAS.ti v9+).
* **Qualitative Coding Report (`data/qualitative_codebook_and_quotations.doc`):** A standalone document for reviewers without an ATLAS.ti license. It includes all coding categories and original text quotations to provide direct access to qualitative evidence
---

## Execution Workflow

All scripts are configured to execute using relative paths from the root directory of this repository.

1. Text Preprocessing & Lemmatization (Corpus Preparation)
  * **Script**: `scripts/1. Text Preprocessing and Lemmatization.py`
  * **Input**: `Raw .txt` files for the 107 analyzed articles.
* Note on Raw Text Availability: Due to publisher copyright restrictions, the raw full-text files (`seeds/raw/`) are excluded from this repository. The preprocessed document-term matrix derived from this step is provided directly in `data/data_freq_unigrams.csv` for full replication of all downstream workflows. Full raw text files are available from the corresponding author upon reasonable request.
  * **Output**: Cleaned/lemmatized text files (`seeds/*_limpio.txt`) and top term frequencies Excel workbook (`all_text_analysis_top100.xlsx`).
  * **Data Pipeline Connection**: The unigramas sheet generated in all_text_analysis_top100.xlsx corresponds directly to data/data_freq_unigrams.csv (saved as CSV for direct integration into the R quantitative workflow).
  * **Description**: Lowercases text, strips punctuation/digits, tokenizes via NLTK, removes English stopwords and non-dictionary terms, applies WordNet lemmatization, and extracts top unigram/bigram frequency matrices across all 107 articles.

2. **Geopolitical Mapping (Figure 2)**
   * **Script:** `scripts/2. Author Region vs. Case Study Region Distribution.R`
   * **Input:** `data/data_freq_unigrams.csv`
   * **Description:** Standardizes regional categories (Author Region vs. Case Study Region) and generates the stacked bar chart for Figure 2.

3. **Correspondence Analysis & K-Means Clustering (Figure 3)**
   * **Script:** `scripts/3.Correspondence Analysis and K-means.R`
   * **Input:** `data/data_freq_unigrams.csv`
   * **Description:** Performs Correspondence Analysis (CA), determines optimal k via Elbow and Silhouette methods, executes k-means (k=4), generates the CA Biplot (Figure 3a), specificity charts (Figure 3b), and identifies the 20 focal articles closest to cluster centroids.
   * *Note:* The text preprocessing pipeline (Python script for raw text lemmatization) will be made available upon final publication; the preprocessed document-term matrix is provided directly in `data/data_freq_unigrams.csv`.

4. **Cluster Proportions & Geopolitical Distribution (Figure 4)**
   * **Script:** `scripts/4. Cluster Proportions and Geopolitical Distribution.R`
   * **Input:** `data/data_processed_clusters.csv`
   * **Description:** Computes cluster proportions, executes pairwise proportion tests with Bonferroni corrections, and evaluates regional-thematic independence via Chi-square tests (Monte Carlo simulations) and Cramér's V.

5. **Clustered Heatmap of Qualitative Codes (Figure 5)**
   * **Script:** `scripts/5.Clustered Heatmap of Qualitative Codes by Cluster.R`
   * **Input:** `data/qualitative_coding_matrix.csv`
   * **Description:** Aggregates qualitative code presence/absence proportions across the 20 focal articles and generates the hierarchical clustered heatmap (Figure 5). The full underlying qualitative evidence base (raw text quotations, code definitions, and categories) can be inspected directly in the provided PDF report or ATLAS.ti project bundle.
