# Author:   madur@psb.ugent.be
# Updated:  2025-30-01
# Description:
#   Reads the master position file (.txt) produced by TipTracker (Wangenheim et al. 2017) to produce several graphs (root position, growth and growth rates).

# Preset ------------------------------------------------------------------
library(ggplot2)
library(readr)
library(dplyr)

read_tt_position_file <- function (file_name) {
  df <- read.delim(file_name, 
                     sep = '\t',
                     header = FALSE)
  df <- df[, c(2,4,6,8,10,12)]
  colnames(df) = c("t", "dt", "n", "position", "dx", "dy")
  
  return(df)
}

# User defined variables --------------------------------------------------
setwd("/PATH")       # Working directory
pxpum = 1            # Calibration, pixels per micrometer
file_name = "DATE_.txt"   # Single master position file produced by TipTracker

# Analysis ----------------------------------------------------------------
data <- read_tt_position_file(file_name) # Read 

data <- data %>%
  mutate(position = as.factor(position)) %>%
  group_by(position) %>%
    mutate(
      dx_um = dx / pxpum,
      dy_um = dy / pxpum,
      growth_um = sqrt( (dx - lag(dx, 1))**2 + (dy - lag(dy, 1))**2) / 1.6028, # Simple Euclidian distance measure
      growth_rate_um_min = (growth_um / (t - lag(t, 1))) * 60,
      total_growth_um = cumsum(replace_na(growth_um, 0))
    )

# Summary of root trajectories during acquisition (as registered by TipTracker)
ggplot(data, aes(x = dx_um, y = dy_um, group = position)) +
  geom_path(aes(color = position)) +
  scale_color_discrete(name = 'Position') +
  theme_bw() +
  xlab('X (μm)') + 
  ylab('Y (μm)')

# Growth curves
ggplot(data, aes(x = t / 60**2, y = total_growth_um)) +
  geom_line(aes(color = position)) +
  scale_color_discrete(name = 'Position') +
  theme_bw() +
  xlab("Hours") +
  ylab('Total growth (μm)')

# Growth rates, step size depends on image acquisition interval
ggplot(data, aes(x = t / 60**2, y = growth_rate_um_min)) +
  geom_step(aes(color = position)) +
  scale_color_discrete(name = 'Position') +
  theme_bw() +
  xlab("Hours") +
  ylab('Growth rate (μm/min)')

# Combined graph showing growth rates along the trajectory for each position
ggplot(data, aes(x = dx_um, y = dy_um, group = position)) +
  geom_path(aes(color = growth_rate_um_min), size = 1) +
  facet_wrap(~position) +
  scale_color_viridis_b(name = "Growth rate (μm/min)") +
  theme_bw() +
  xlab('X (μm)') + 
  ylab('Y (μm)')

# For reference: A root tip of a 4–5 day-old Arabidopsis seedling grows approximately 50–300 µm per hour (Wangenheim et al. 2017).
