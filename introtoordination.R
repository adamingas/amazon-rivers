setwd("~/Thesis")
library(vegan)
library(ape)
library(dplyr)
data(varespec)
View(varespec)
varespec %>%
  metaMDS(trace = F) %>%
  ordiplot(type = "none")

PCA <- rda(varespec, scale = FALSE)
# Use scale = TRUE if your variables are on different scales (e.g. for abiotic variables).
# Here, all species are measured on the same scale 
# So use scale = FALSE

# Now plot a bar plot of relative eigenvalues. This is the percentage variance explained by each axis
barplot(as.vector(PCA$CA$eig)/sum(PCA$CA$eig)) 
# How much of the variance in our dataset is explained by the first principal component?

# Calculate the percent of variance explained by first two axes
sum((as.vector(PCA$CA$eig)/sum(PCA$CA$eig))[1:2]) # 79%, this is ok.
# Also try to do it for the first three axes

# Now, we`ll plot our results with the plot function
plot(PCA)
plot(PCA, display = "sites", type = "points")
plot(PCA, display = "species", type = "text")
