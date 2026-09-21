# ==============================================================================
# Figure 4: Cluster Proportions and Geopolitical Distribution
# ==============================================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(rstatix)
library(patchwork)

# 1. Load processed dataset using relative path from repository data folder
datos <- read.csv("data/data_processed_clusters.csv", encoding = "UTF-8")

# Ensure factor levels for cluster ordering
datos$cluster <- factor(datos$cluster, levels = c("1", "2", "3", "4"))

# Define cluster color palette
cluster_colors <- c(
  "1" = "#F8766D",
  "2" = "#7CAE00",
  "3" = "#00BFC4",
  "4" = "#C77CFF"
) 

# 2. Recode Geopolitical Variables
datos <- datos %>%
  mutate(
    # Author's geopolitical region
    Geopol_c_a = case_when(
      Geopol_c_a == "Western European and other States" ~ "Western Europe",
      Geopol_c_a == "Asia-Pacific States"              ~ "Asia-Pacific",
      Geopol_c_a == "African States"                   ~ "Africa",
      Geopol_c_a == "Latin American and Caribbean States" ~ "LAC",
      Geopol_c_a == "Eastern European States"          ~ "E. Europe",
      TRUE ~ as.character(Geopol_c_a)
    ),
    
    # Case study region
    C_study_geo = case_when(
      grepl("/", C_study_geo)                          ~ "Mixed",
      tolower(C_study_geo) == "global"                 ~ "Global",
      C_study_geo == "Western European and other States" ~ "Western Europe",
      C_study_geo == "Asia-Pacific States"              ~ "Asia-Pacific",
      C_study_geo == "African States"                   ~ "Africa",
      C_study_geo == "Latin American and Caribbean States" ~ "LAC",
      C_study_geo == "Eastern European States"          ~ "E. Europe",
      TRUE ~ as.character(C_study_geo)
    )
  ) 

# 3.Figure 4a. Percentage of Articles per Cluster

panel_a_data <- datos %>%
  count(cluster) %>%
  mutate(
    percentage = n / sum(n) * 100,
    label = paste0(round(percentage, 1), "%"),
    # Statistical significance grouping letters
    letra = case_when(
      cluster %in% c(1, 3) ~ "a",
      cluster %in% c(2, 4) ~ "b"
    ),
    cluster = factor(cluster, levels = c(1, 2, 3, 4))
  )

fig_4a <- ggplot(panel_a_data, aes(x = cluster, y = percentage, fill = cluster)) +
  geom_bar(stat = "identity", width = 0.6) +
  geom_text(aes(label = label), vjust = -0.3, size = 4) +
  geom_text(aes(label = letra), vjust = -1.5, size = 5, fontface = "bold") +
  scale_fill_manual(values = cluster_colors) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "a) Percentage of articles per cluster",
    x = "Thematic Cluster",
    y = "Percentage (%)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(fig_4a)

#Statistical test for Cluster Proportions (Pairwise Proportion Test)
cat("\n--- PAIRWISE PROPORTION TEST BETWEEN CLUSTERS ---\n")
prop_test_res <- pairwise.prop.test(
  x = table(datos$cluster),
  n = rep(sum(table(datos$cluster)), 4),
  p.adjust.method = "bonferroni"
)
print(prop_test_res)


#4. Figure 4b.Distribution of Clusters by Region
# Filter out non-territorialized categories ("Global" and "Mixed")
datos_filtrados <- datos %>%
  filter(!C_study_geo %in% c("Global", "Mixed"))

# Author region counts
df_author <- datos_filtrados %>%
  group_by(Type = "Author region", Region = Geopol_c_a, cluster) %>%
  summarise(n = n(), .groups = "drop")

# Case study region counts
df_case <- datos_filtrados %>%
  group_by(Type = "Case study region", Region = C_study_geo, cluster) %>%
  summarise(n = n(), .groups = "drop")

# Combine datasets
df_plot <- bind_rows(df_author, df_case)

# Set factor levels for structured visualization
orden_regiones <- c("Asia-Pacific", "Western Europe", "Africa", "LAC", "E. Europe")

df_plot <- df_plot %>%
  mutate(
    Region = factor(Region, levels = orden_regiones),
    cluster = factor(cluster, levels = c(1, 2, 3, 4))
  )

fig_4b <- ggplot(df_plot, aes(x = Region, y = n, fill = cluster)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = cluster_colors) +
  facet_wrap(~ Type) +
  labs(
    title = "b) Distribution of clusters across regions",
    x = "Geopolitical Region",
    y = "Number of articles",
    fill = "Cluster"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

print(fig_4b) 


#5. Statistical Association Tests (Chi-Square & Cramér's V)
# Filtered dataset preparation
datos_limpios <- datos %>% 
  filter(!C_study_geo %in% c("Global", "Mixed")) %>% 
  mutate(
    Geopol_c_a = droplevels(factor(Geopol_c_a)),
    C_study_geo = droplevels(factor(C_study_geo))
  )

# --- AUTHOR REGION ANALYSIS ---
cat("\n=========================================\n")
cat("          AUTHOR REGION CONTEXT          \n")
cat("=========================================\n")

tabla_author <- table(datos_limpios$Geopol_c_a, datos_limpios$cluster)

cat("\nPercentages by Region (Author):\n")
print(round(prop.table(tabla_author, margin = 1) * 100, 1))

set.seed(123)
chi_author <- chisq.test(tabla_author, simulate.p.value = TRUE, B = 10000)
print(chi_author)

cat("\nStandardized Residuals (Author):\n")
print(round(chi_author$residuals, 2))

cat("\nCramér's V (Author):\n")
print(cramer_v(tabla_author))


# --- CASE STUDY REGION ANALYSIS ---
cat("\n=========================================\n")
cat("        CASE STUDY REGION CONTEXT        \n")
cat("=========================================\n")

tabla_case <- table(datos_limpios$C_study_geo, datos_limpios$cluster)

cat("\nPercentages by Region (Case Study):\n")
print(round(prop.table(tabla_case, margin = 1) * 100, 1))

set.seed(123)
chi_case <- chisq.test(tabla_case, simulate.p.value = TRUE, B = 10000)
print(chi_case)

cat("\nStandardized Residuals (Case Study):\n")
print(round(chi_case$residuals, 2))

cat("\nCramér's V (Case Study):\n")
print(cramer_v(tabla_case))
