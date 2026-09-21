# ==============================================================================
# Figure 5 - Clustered Heatmap of Qualitative Codes by Cluster
# ==============================================================================

# 1. Load required libraries
library(dplyr)
library(tidyr)
library(tibble)
library(pheatmap)

# 2. Load dataset
df2 <- read.csv("data/qualitative_coding_matrix.csv", encoding = "UTF-8")

# 3. Rename qualitative code categories
df2$codigo <- c( 
  "collective_property",
  "open_source_property",
  "state_property",
  "collective_state_property",
  "state_private_property",
  "private_property",
  "farmers_economic_benefits",
  "biocultural_conservation",
  "critique_collective_property",
  "critique_state_property",
  "critique_private_property",
  "farmers_rights",
  "negative_effects_biotech",
  "negative_effects_ipr",
  "farmers_limitations",
  "pro_ipr_stance",
  "ipr_exceptions_stance",
  "pro_gmo_stance",
  "gmo_critique",
  "collaboration_networks",
  "conventional_system",
  "traditional_system",
  "sustainability"
)

# 4. Remove previous cluster columns and reshape to long format
base_larga <- df2 %>%
  select(-all_of(c("C1", "C2", "C3", "C4"))) %>%
  mutate(across(-codigo, ~ replace_na(., 0))) %>%
  pivot_longer(
    cols = -codigo,
    names_to = "documento",
    values_to = "freq"
  ) %>%
  mutate(presencia = ifelse(freq > 0, 1, 0))

# 5. Define cluster assignment per document
tabla_clusters <- tibble(
  documento = c("Art22", "Art66", "Art74", "Art85", "Art90",
                "Art6", "Art2", "Art79", "Art60", "Art27",
                "Art48", "Art14", "Art72", "Art33", "Art44",
                "Art23", "Art26", "Art96", "Art18", "Art97"),
  cluster = c("C3", "C4", "C1", "C2", "C3",
              "C4", "C4", "C2", "C3", "C1",
              "C3", "C2", "C1", "C1", "C2",
              "C3", "C4", "C4", "C2", "C1")
)

# 6. Merge cluster assignments and calculate proportions (N=5 per cluster)
resumen_cluster <- base_larga %>%
  left_join(tabla_clusters, by = "documento") %>%
  group_by(cluster, codigo) %>%
  summarise(
    n_docs = sum(presencia),
    .groups = "drop"
  ) %>%
  mutate(
    n_docs = ifelse(is.na(n_docs), 0, n_docs),
    prop = round(n_docs / 5, 2)
  )

# 7. Convert to wide matrix format for pheatmap
matriz_num <- resumen_cluster %>%
  select(cluster, codigo, prop) %>%
  distinct() %>%
  pivot_wider(
    names_from = cluster,
    values_from = prop,
    values_fill = 0
  ) %>%
  mutate(codigo = as.character(codigo)) %>%
  column_to_rownames("codigo") %>%
  as.matrix()

# 8. Generate Figure 5: Clustered Heatmap
figura_5 <- pheatmap(
  matriz_num,
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  color = colorRampPalette(c("#FFFFFF", "#08306B"))(50),
  breaks = seq(0, 1, length.out = 51),
  border_color = "grey90",
  fontsize_row = 9,
  fontsize_col = 11,
  angle_col = 0,
  main = "Figure 5: Proportions of Qualitative Codes Across Document Clusters"
)

# Display the heatmap
print(figura_5)

