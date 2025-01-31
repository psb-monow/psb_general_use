
# Author:   madur@psb.ugent.be
# Updated:  2025-30-01
# Description:
#   Reads a position file (.csv) created by the ZEN tracker (Zeiss) to produce several graphs (root position and growth). 

# Preset ------------------------------------------------------------------
# load required libraries
library(ggplot2)
library(plotly)
library(lubridate)
library(dplyr)
library(gridExtra)
library(tidyr)

# User defined variables --------------------------------------------------
setwd("/PATH")       # Working directory
voxel_size = c(1, 1, 1) # Voxel size, micron^3
file_name = "_.csv"   

# Analysis ----------------------------------------------------------------
# read the file
data <- read.csv(file = file_name,
                 col.names = c("date","time", "x_abs", "y_abs", "z_abs", "path"),
                 colClasses = c("character", "character", "numeric", "numeric", "numeric", "character"),
                 skip = 1) # first row can be skipped

reference_point <- data[1,c(3,4,5)] # fix the first point as the reference point (0,0,0)

# add calculated fields
data <-
  data %>%
  mutate(datetime = as_datetime(
            paste(date, time),
            format = "%y%m%d %H:%M:%S"), # parse the date
         dt = as.numeric(datetime - lag(datetime, 1)), # time difference
         total_time = cumsum(replace_na(dt, 0)), # total time since the first acquisition
         # calculate position relative to the reference point
         x_rel = x_abs - reference_point$x_abs,
         y_rel = y_abs - reference_point$y_abs,
         z_rel = z_abs - reference_point$z_abs,
         # scale the measurements
         x_rel_um = x_rel * voxel_size[1],
         y_rel_um = y_rel * voxel_size[2],
         z_rel_um = z_rel * voxel_size[3],
         # total growth (distance between sequential points), euclidean distance
         growth = sqrt(
           (x_rel_um - lag(x_rel_um, 1))**2 +
           (y_rel_um - lag(y_rel_um, 1))**2 +
           (z_rel_um - lag(z_rel_um, 1))**2
         ),
         total_growth = cumsum(replace_na(growth, 0)) # cumulative distance
  )

# plot total growth over time
ggplot(data, aes(x = total_time / 60, y = total_growth)) +
  geom_line() +
  theme_bw() +
  xlab('Hours') +
  ylab('Total growth (μm)')
  
# actual growth rates
ggplot(data, aes(x = total_time, y = growth)) +
  geom_line() +
  theme_bw() +
  xlab('Minutes') +
  ylab('Growth (μm)')

# growth profile
ggplot(data, aes(x = total_time)) +
  geom_line(aes(y = x_rel_um, color = 'X')) +
  geom_line(aes(y = y_rel_um, color = 'Y')) +
  geom_line(aes(y = z_rel_um, color = 'Z')) +
  scale_color_discrete(name = "Axis") +
  theme_bw() +
  xlab('X (μm)') + 
  ylab('Y (μm)')

# visualize growth in 3D
plot_ly(data, x = ~x_rel_um, y = ~y_rel_um, z = ~z_rel_um, mode = 'lines', line = list(width = 6))
