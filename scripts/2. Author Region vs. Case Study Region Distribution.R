# ==============================================================================
# Figure 2 - Author Region vs. Case Study Region Distribution
# ==============================================================================

# 1. Load required libraries
library(ggplot2)
library(dplyr)
library(forcats)

# 2. Load original dataset
datos <- read.csv("data/data_freq_unigrams.csv", encoding = "UTF-8")

# 3. Data cleaning and standardization of regional names
datos_geo <- datos %>%
  mutate(
    # Recoding Author Region
    Geopol_c_a = case_when(
      Geopol_c_a == "Western European and other States" ~ "Western Europe",
      Geopol_c_a == "Asia-Pacific States"               ~ "Asia-Pacific",
      Geopol_c_a == "African States"                    ~ "Africa",
      Geopol_c_a == "Latin American and Caribbean States" ~ "LAC",
      Geopol_c_a == "Eastern European States"           ~ "E. Europe",
      TRUE ~ as.character(Geopol_c_a)
    ),
    
    # Recoding Case Study Region
    C_study_geo = case_when(
      grepl("/", C_study_geo)                            ~ "Mixed",
      tolower(C_study_geo) == "global"                   ~ "Global",
      C_study_geo == "Western European and other States" ~ "Western Europe",
      C_study_geo == "Asia-Pacific States"               ~ "Asia-Pacific",
      C_study_geo == "African States"                    ~ "Africa",
      C_study_geo == "Latin American and Caribbean States" ~ "LAC",
      C_study_geo == "Eastern European States"           ~ "E. Europe",
      TRUE ~ as.character(C_study_geo)
    )
  )

# 4. Grouping and proportion calculations for labels
df_bar <- datos_geo %>%
  group_by(Geopol_c_a, C_study_geo) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(Geopol_c_a) %>%
  mutate(
    prop = n / sum(n),
    # Generate label with percentage if it accounts for more than 5% of the total bar
    label = ifelse(prop > 0.05, paste0(round(prop * 100), "%"), "")
  ) %>%
  ungroup() %>%
  filter(!is.na(Geopol_c_a) & !is.na(C_study_geo))

# 5. Factor formatting and stacking order
df_bar_mod <- df_bar %>%
  mutate(
    # Normalize names for consistency
    Geopol_c_a  = recode(as.character(Geopol_c_a), "W. Europe & Others" = "Western Europe"),
    C_study_geo = recode(as.character(C_study_geo), "W. Europe & Others" = "Western Europe"),
    
    # Order X-axis bars from highest to lowest total number of publications
    Geopol_c_a  = fct_infreq(Geopol_c_a),
    
    # Define exact stacking hierarchy in bars (from top to bottom)
    C_study_geo = factor(C_study_geo, levels = c(
      "Global",         # 1st top (Haze gray)
      "Mixed",          # 2nd top (Pastel salmon)
      "Africa",         # Localized regions
      "Asia-Pacific",
      "E. Europe",
      "LAC",
      "Western Europe"  # Bar base
    ))
  ) %>%
  arrange(desc(C_study_geo))

# 6. Definition of the map/region color palette
mapa_colors_updated <- c(
  "Western Europe" = "#A85751",
  "E. Europe"      = "#473C8B",
  "LAC"            = "#7E9F59",
  "Africa"         = "#8B4789",
  "Asia-Pacific"   = "#CDbe70",
  "Global"         = "#9DC4C9",
  "Mixed"          = "#F3A993"
)

# 7. Figure 2 generation (ggplot2)
figura_2 <- ggplot(df_bar_mod, 
                   aes(x = Geopol_c_a, 
                       y = n, 
                       fill = C_study_geo)) +
  
  geom_bar(stat = "identity") + 
  
  geom_text(aes(label = label),
            position = position_stack(vjust = 0.5), 
            size = 3.6,
            color = "#222222") + 
  
  scale_fill_manual(values = mapa_colors_updated) + 
  
  labs(
    x = "Author region",
    y = "Number of publications",
    fill = "Case study region"
  ) +
  
  theme_minimal() +
  theme(
    axis.text.x  = element_text(angle = 45, hjust = 1, size = 12),
    axis.text.y  = element_text(size = 12),
    axis.title   = element_text(size = 14),
    legend.title = element_text(size = 13),
    legend.text  = element_text(size = 11)
  )

# Display figure in console
print(figura_2)

