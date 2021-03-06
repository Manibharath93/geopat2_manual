library(sf)
library(raster)
library(rasterVis)
library(tidyverse)

## files prep ----------------------------------------------------------------
dir.create("tmp")
file.copy(from = "data/Augusta2011.tif", to = "tmp")
file.copy(from = "data/nlcd_colors.txt", to = "tmp")

setwd("tmp/")

## gpat clustering  prep -----------------------------------------------------
# system("gpat_gridhis -i Augusta2011.tif -o Augusta2011_grid100 -z 100 -f 100")
# system("gpat_segment -i Augusta2011_grid100 -o Augusta2011_seg100.tif -v Augusta2011_seg100.shp --lthreshold=0.1 --uthreshold=0.3")
# system("gpat_polygon -i Augusta2011.tif -e Augusta2011_seg100.tif -o Augusta2011_psign.txt")
# system("gpat_distmtx -i Augusta2011_psign.txt -o Augusta2011_matrix_seg.csv")

## temp solution 1 ----------------------------------------------------------
# system("gpat_gridhis -i Augusta2011.tif -o Augusta2011_grid100 -z 100 -f 100")
# system("gpat_segment -i Augusta2011_grid100 -o Augusta2011_seg100.tif -v Augusta2011_seg100.shp --lthreshold=0.1 --uthreshold=0.3 --size=100")
# system("gpat_polygon -i Augusta2011.tif -e Augusta2011_seg100.tif -o Augusta2011_psign.txt")
# system("gpat_distmtx -i Augusta2011_psign.txt -o Augusta2011_matrix_seg.csv")

## temp solution 2 ----------------------------------------------------------
system("gpat_gridhis -i Augusta2011.tif -o Augusta2011_grid100 -z 100 -f 100")
system("gpat_segment -i Augusta2011_grid100 -o Augusta2011_seg100.tif -v Augusta2011_seg100.gpkg --lthreshold=0.1 --uthreshold=0.3")
system("gdalwarp -tr 30 30 Augusta2011_seg100.tif Augusta2011_seg100_res.tif")
system("gpat_polygon -i Augusta2011.tif -e Augusta2011_seg100_res.tif -o Augusta2011_psign.txt")
system("gpat_distmtx -i Augusta2011_psign.txt -o Augusta2011_matrix_seg.csv")

## r clustering -------------------------------------------------------------
library(sf)
dist_file = read.csv("Augusta2011_matrix_seg.csv")[, -1]
dist_matrix = as.dist(dist_file)

hclust_result = hclust(d = dist_matrix, method = "ward.D2")
plot(hclust_result, label = FALSE)

hclust_cut = cutree(hclust_result, 3)

## return to map
segm = st_read("Augusta2011_seg100.gpkg")
segm$class = (hclust_cut)

plot(segm["class"])

## create a plot
png("../figs/clustering_example_polygon1.png", width = 400, height = 300)
par(mar = c(0, 2, 1, 0))
plot(hclust_result, labels = FALSE, xlab = "", sub = "")
rect.hclust(hclust_result, k = 3, border = "blue")
dev.off()

png("../figs/clustering_example_polygon2.png", width = 400, height = 300)
par(mar = c(0, 0, 1, 0))
plot(segm["class"])
dev.off()

## return to map (better, but more complicated)-------------------------------
# augusta2011 = raster("Augusta2011.tif") %>% 
#         as.factor()
# 
# rat = levels(augusta2011)[[1]]
# rat[["landcoveaugusta2011"]] = rat$ID
# levels(augusta2011) = rat
# 
# lc_colors = readr::read_delim('nlcd_colors.txt', col_names = FALSE, delim = " ") %>% 
#         dplyr::mutate(hex=rgb(X2, X3, X4, , maxColorValue = 255)) %>% 
#         dplyr::filter(X1 %in% rat$ID)
# 
# classes_df = cutree(hclust_result, k = 4) %>% 
#         data.frame(names = names(.), class = .) %>% 
#         dplyr::mutate(segment_id = row_number())
# classes_df
# 
# segm = st_read("Augusta2011_seg100.shp") %>% 
#         left_join(classes_df, by = "segment_id") %>% 
#         group_by(class) %>% 
#         summarise()
# 
# detach(package:ggplot2)
# clustermap = levelplot(augusta2011, col.regions=lc_colors$hex, margin=FALSE,
#                        xlab=NULL, ylab=NULL, colorkey=FALSE, scales=list(draw=FALSE),
#                        main = "Clustering") +
#         layer(sp.polygons(as(segm, "Spatial"), lwd=4, col='black', fill=segm$class, alpha = 0.25))
# 
# clustermap

## clean --------------------------------------------------------------------
setwd("..")
unlink("tmp", recursive = TRUE, force = TRUE)
