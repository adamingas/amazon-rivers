#setwd("~/Thesis")
setwd("~/Documents/Stats/Project/")
library(vegan)
library(ape)
library(dplyr)
data(varespec)
View(varespec)
ncol(varespec)
varespec %>%
  metaMDS(trace = F) %>%
  ordiplot(type = "none")%>%
text("sites") 
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

#Principal Coordinate Analysis
# First step is to calculate a distance matrix. 
# Here we use Bray-Curtis distance metric
dist <- vegdist(varespec,  method = "bray")
PCOA <- pcoa(dist)
barplot(PCOA$values$Relative_eig[1:10])

# Can you also calculate the cumulative explained variance of the first 3 axes?
sum((PCOA$values$Relative_eig/sum(PCOA$values$Relative_eig))[1:3])
# Some distance measures may result in negative eigenvalues. In that case, add a correction:
PCOA <- pcoa(dist, correction = "cailliez")

sum(PCOA$values$Eigenvalues[1:10])/sum(PCOA$values$Eigenvalues)
biplot.pcoa(PCOA)
biplot.pcoa(PCOA, varespec)
plot(PCOA)
#NMDS
# In this part, we define a function NMDS.scree() that automatically 
# performs a NMDS for 1-10 dimensions and plots the nr of dimensions vs the stress
NMDS.scree <- function(x) { #where x is the name of the data frame variable
  plot(rep(1, 10), replicate(10, metaMDS(x, autotransform = F, k = 1)$stress), xlim = c(1, 10),ylim = c(0, 0.40), xlab = "# of Dimensions", ylab = "Stress", main = "NMDS stress plot")
  for (i in 1:11) {
    # repeats so as to check convergence
    points(rep(i ,10),replicate(10, metaMDS(x, autotransform = F, k = i )$stress))
  }
}
plot(rep(1, 10), replicate(10, metaMDS(dist, autotransform = F, k = 1)$stress), xlim = c(1, 10),ylim = c(0, 0.30), xlab = "# of Dimensions", ylab = "Stress", main = "NMDS stress plot")
NMDS.scree(dist)
points(rep(1 ,10),replicate(10, metaMDS(dist, autotransform = F, k = 1 )$stress))

# we`ll set a seed to make the results reproducible
set.seed(2)
NMDS1 <- metaMDS(dist, k = 2, trymax = 100, trace = F)
plot(NMDS1,type="t")

stressplot(NMDS1)

NMDS3 <- metaMDS(varespec, k = 2, trymax = 100, trace = F, autotransform = FALSE, distance="bray")
plot(NMDS3, display = "sites", type = "t")

points(NMDS3, display = "sites", col = "red", cex = 1.25)
text(NMDS3, display ="species")


data(varechem)
View(varechem)
ef <- envfit(NMDS3, varechem, permu = 999)
ef
plot(NMDS3, type = "t", display = "sites")
plot(ef)
