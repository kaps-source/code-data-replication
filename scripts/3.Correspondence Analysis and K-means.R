# ==============================================================================
# Figure 3.Correspondence Analysis and K-means
# ==============================================================================

library(FactoMineR)
library(factoextra)
library(ggplot2)
library(ggrepel)
library(cluster)
library(dplyr)
library(tidyr)
library(tidytext)
library(scales)

#1. Data Loading and Matrix Preparation
datos <- read.csv("data/data_freq_unigrams.csv", encoding = "UTF-8")

datos_palabras <- datos[, 6:ncol(datos)]
datos_palabras <- datos_palabras[, !grepl("^NA\\.$", colnames(datos_palabras))]

# Top-N vocabulary selection
frecuencias <- colSums(datos_palabras)
N <- 50
top_palabras_names <- names(sort(frecuencias, decreasing = TRUE))[1:N]
top_palabras_names <- intersect(top_palabras_names, colnames(datos_palabras))

datos_palabras <- datos_palabras[, top_palabras_names]

# Filter out empty rows
filas_validas <- rowSums(datos_palabras) > 0
datos_palabras <- datos_palabras[filas_validas, ]
datos <- datos[filas_validas, ]

#2. Correspondence Analysis (CA)
ca_result <- CA(datos_palabras, graph = FALSE)

# Inertia Explained
eig <- ca_result$eig
print(eig[1:5, ])

# Scree Plot
fviz_screeplot(ca_result, addlabels = TRUE, ylim = c(0, 50))

# 3. Determination of the Optimal Number of Clusters (Elbow and Silhouette)
coords_use <- as.data.frame(ca_result$row$coord[, 1:2])
colnames(coords_use) <- c("Dim1", "Dim2")

# A) Elbow Method
set.seed(123)
wss <- sapply(1:10, function(k) {
  kmeans(coords_use, centers = k, nstart = 25)$tot.withinss
})

wss_df <- data.frame(k = 1:10, wss = wss)

ggplot(wss_df, aes(x = k, y = wss)) +
  geom_line(color = "steelblue", size = 1) +
  geom_point(color = "steelblue", size = 2.5) +
  labs(title = "Elbow Method for Optimal K",
       x = "Number of Clusters (K)",
       y = "Total Within-Cluster Sum of Squares (WSS)") +
  theme_minimal()
data.frame(k = 1:10, wss = wss)


# B) Average Silhouette Width
set.seed(123)
sil_width <- sapply(2:10, function(k) {
  km <- kmeans(coords_use, centers = k, nstart = 25)
  ss <- silhouette(km$cluster, dist(coords_use))
  mean(ss[, 3])
})

sil_df <- data.frame(k = 2:10, silhouette = sil_width)

ggplot(sil_df, aes(x = k, y = silhouette)) +
  geom_line(color = "darkgreen", size = 1) +
  geom_point(color = "darkgreen", size = 2.5) +
  labs(title = "Average Silhouette Method for Optimal K",
       x = "Number of Clusters (K)",
       y = "Average Silhouette Width") +
  theme_minimal()
data.frame(k = 2:10, silhouette = sil_width)

#4. Final K-Means Clustering and Geometric Reassignment
set.seed(123)
k_clusters <- kmeans(coords_use, centers = 4, nstart = 50)

ca_coord <- coords_use
ca_coord$k_id <- k_clusters$cluster

# Geometric centroids
centroides <- ca_coord %>%
  group_by(k_id) %>%
  summarise(m_Dim1 = mean(Dim1), m_Dim2 = mean(Dim2), .groups = "drop")

# Precise spatial mapping aligned with the Final Figure:
# Cluster 2 (Green): Far left (Dim1 Minimum / maize, sector)
id_verde <- centroides$k_id[which.min(centroides$m_Dim1)]

# Cluster 3 (Blue): Far right (Dim1 Maximum / plant, protection)
id_azul  <- centroides$k_id[which.max(centroides$m_Dim1)]
restantes <- centroides %>% filter(!k_id %in% c(id_verde, id_azul))

# Cluster 4 (Purple): Superior (Dim2 Mayor / gene, technology)
id_morado <- restantes$k_id[which.max(restantes$m_Dim2)]

# Cluster 1 (Red): Lower-Center (Lower Dim2 / local, seed, farmer)
id_rojo   <- restantes$k_id[which.min(restantes$m_Dim2)]

# Factor allocation
ca_coord <- ca_coord %>%
  mutate(
    cluster = case_when(
      k_id == id_rojo   ~ "1", 
      k_id == id_verde  ~ "2", 
      k_id == id_azul   ~ "3", 
      k_id == id_morado ~ "4"  
    ),
    cluster = factor(cluster, levels = c("1", "2", "3", "4"))
  )

datos$cluster <- ca_coord$cluster

# Exact palette of the figure in the item
cluster_colors <- c(
  "1" = "#F8766D", # Rojo
  "2" = "#7CAE00", # Verde
  "3" = "#00BFC4", # Azul
  "4" = "#C77CFF"  # Morado
)


#5. Final Correspondence Analysis Biplot (Figure 3a)

top_palabras_df <- as.data.frame(ca_result$col$coord[, 1:2])
colnames(top_palabras_df) <- c("Dim1", "Dim2")
top_palabras_df$palabra <- rownames(top_palabras_df)
top_palabras_df$contrib <- ca_result$col$contrib[,1] + ca_result$col$contrib[,2]
top_palabras_df <- top_palabras_df[order(-top_palabras_df$contrib), ][1:15, ]

ggplot(ca_coord, aes(x = Dim1, y = Dim2, color = cluster)) +
  geom_point(size = 2.8, alpha = 0.8) +
  geom_segment(data = top_palabras_df,
               aes(x = 0, y = 0, xend = Dim1, yend = Dim2),
               inherit.aes = FALSE,
               arrow = arrow(length = unit(0.2, "cm")),
               color = "black", alpha = 0.7) +
  geom_text_repel(data = top_palabras_df,
                  aes(x = Dim1, y = Dim2, label = palabra),
                  inherit.aes = FALSE,
                  size = 3, color = "black") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey70") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey70") +
  scale_color_manual(values = cluster_colors) +
  theme_minimal() +
  labs(
    title = "Correspondence Analysis Biplot with Keyword Vectors",
    x = paste0("Dim1 (", round(ca_result$eig[1,2], 1), "%)"),
    y = paste0("Dim2 (", round(ca_result$eig[2,2], 1), "%)"),
    color = "Cluster"
  )

#6. Representative Words by Cluster
datos_palabras_cluster <- datos_palabras %>%
  mutate(cluster = datos$cluster)

# Average frequency of occurrence
mean_words_cluster <- datos_palabras_cluster %>%
  group_by(cluster) %>%
  summarise(across(where(is.numeric), mean, na.rm = TRUE))

tabla_larga <- mean_words_cluster %>%
  pivot_longer(-cluster, names_to = "palabra", values_to = "promedio")

# Relative specificity by cluster
palabras_especificas <- tabla_larga %>%
  group_by(palabra) %>%
  mutate(porcentaje_relativo = (promedio / sum(promedio, na.rm = TRUE)) * 100) %>%
  ungroup()

palabras_top_especificas <- palabras_especificas %>%
  group_by(cluster) %>%
  slice_max(order_by = porcentaje_relativo, n = 10, with_ties = FALSE) %>%
  arrange(cluster, desc(porcentaje_relativo))

palabras_exclusivas <- palabras_top_especificas %>%
  mutate(palabra = as.character(palabra)) %>%
  mutate(palabra = gsub("___.*", "", palabra)) %>%
  group_by(palabra) %>%
  slice_max(order_by = porcentaje_relativo, n = 1, with_ties = FALSE) %>%
  ungroup()

palabras_grafico <- palabras_exclusivas %>%
  group_by(cluster) %>%
  slice_max(order_by = porcentaje_relativo, n = 10) %>% 
  mutate(
    porcentaje_final = (porcentaje_relativo / max(palabras_top_especificas$porcentaje_relativo)) * 100
  ) %>%
  ungroup() %>%
  mutate(cluster = as.factor(cluster),
         palabra = reorder_within(palabra, porcentaje_final, cluster))

# Bar chart corresponding to Figure b
ggplot(palabras_grafico, 
       aes(x = palabra, y = porcentaje_final, fill = cluster)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ cluster, scales = "free_y") + 
  coord_flip() +
  scale_x_reordered() +
  scale_y_continuous(labels = unit_format(unit = "%")) + 
  scale_fill_manual(values = cluster_colors) +
  labs(
    title = "Representative words by Cluster",
    subtitle = "Relative specificity of keywords across clusters",
    x = NULL,
    y = "Relative inter-cluster frequency"
  ) +
  theme_minimal(base_size = 13) +
  theme(strip.text = element_text(face = "bold"))


#write.csv(datos, "data_processed_clusters.csv", row.names = FALSE)


# 5. Selection of Representative Articles by Cluster Centroid

# Function to extract representative articles closest to centroid
get_representative_articles_ca <- function(datos_df, ca_obj, n_per_cluster = 5) {
  
  # Extract CA coordinates
  coords_ca <- as.data.frame(ca_obj$row$coord)
  coords_ca$ID <- seq_len(nrow(coords_ca))
  
  # Join coordinates with dataset and cluster assignments
  datos_unidos <- datos_df %>%
    mutate(ID = row_number()) %>%
    left_join(coords_ca, by = "ID")
  
  # Identify dimension columns
  dim_cols <- grep("^Dim", names(datos_unidos), value = TRUE)
  
  # Calculate actual cluster centroids
  centroides <- datos_unidos %>%
    group_by(cluster) %>%
    summarise(across(all_of(dim_cols), mean), .groups = "drop")
  
  # Calculate Euclidean distance from each document to its centroid
  datos_con_distancia <- datos_unidos %>%
    rowwise() %>%
    mutate(distancia = {
      c_vals <- centroides[centroides$cluster == cluster, dim_cols]
      sqrt(sum((unlist(across(all_of(dim_cols))) - as.numeric(c_vals))^2))
    }) %>%
    ungroup()
  
  # Select n articles with shortest Euclidean distance
  representatives <- datos_con_distancia %>%
    group_by(cluster) %>%
    slice_min(order_by = distancia, n = n_per_cluster, with_ties = FALSE) %>%
    ungroup()
  
  return(representatives)
}

# Execute selection (5 representative articles x 4 clusters = 20 articles)
representative_articles_20 <- get_representative_articles_ca(datos, ca_result, n_per_cluster = 5)

View(representative_articles_20)

