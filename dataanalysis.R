#setwd("~/")
setwd("~/Documents/Stats/Project/amazon-rivers/")

library(vegan)
library(ape)
library(dplyr)
library(ggplot2)
library(magrittr)
library(cluster)
library(metagenomeSeq)

wwf =read.table(file = "WWF_Samples.txt",header =TRUE,sep = "\t",stringsAsFactors = FALSE)
otudata = read.table(file = "WWF_Peru_for_BenCalderhead.csv",sep = ",",stringsAsFactors = FALSE)
otutable<- t(otudata)[-seq(1,8),]
colnames(otutable) <- c("ID",t(otudata)[1,-1])

otudf <- as.data.frame(x=otutable[,-1],stringsAsFactors=FALSE,row.names = otutable[,1])
#otudf$ID <- as.character(otudf$ID)
otudf[,]<- sapply(otudf[,], as.numeric)
otumatrix <-as.matrix( t(otudf))
wwfdf <- as.data.frame(x=wwf)
wwfdf$Area_group %<>% as.numeric %>% as.factor
wwfdf[,"Area_group_name"] <- sapply(wwfdf[,"Area_group_name"],as.factor)
wwfdf$Water %<>% as.factor

#write.csv(wwfdf,file="wwfdf")
#write.csv(otudf,file = "otudf")
plotfun <- function(data,axis1,axis2){
  mergeddata  <-merge(data,wwfdf[,c("ID","Area_group","Area_group_name","Water")],by.x=0,by.y="ID")
 return( ggplot(mergeddata,aes_string(axis1,axis2,shape = "Water"),size = 2) 
  #geom_point(aes(color=Water),size=2)
  + geom_point(aes(fill = Area_group_name),size=3)
  + geom_point(aes(color = Area_group_name),size=2)
  +scale_colour_brewer(palette = "Accent")    
  )}
#######
# PCA #
#######
PCA <- rda(otudf, scale = FALSE)
barplot(as.vector(PCA$CA$eig)/sum(PCA$CA$eig))
sum(PCA$CA$eig[1:4])/sum(PCA$CA$eig)
# 45% 2D
# 60% 3D
# 70% 4D
plotfun(PCA$CA$u,"PC1","PC2")+labs(title = "Sites PCA",
                                   y ="PCA axis 2",x = "PCA axis 1")
ggsave(filename = "pcaotu12.png",dpi=600)
biplot(PCA, choices = c(1,2), type = c("text", "points"), xlim = c(-5,10)) # biplot of axis 1 vs 2

################################
# Principal coordinate analysis#
################################
otudist <- vegdist(otudf,method="jaccard")
otupcoa <-pcoa(otudist)
plotfun(otupcoa$vectors,"Axis.1","Axis.3") +labs(title = "Sites PCOA",
y ="PCOA axis 2",x = "PCOA axis 1")

plot(otupcoa$values$Relative_eig[1:10])
biplot.pcoa(otupcoa)
plot(otupcoa$vectors[,5],otupcoa$vectors[,1])

pcoam   <- merge(otupcoa$vectors[,1:2],wwfdf[,c("ID","Area_group","Area_group_name")],by.x=0,by.y="ID")
ppcoa   <- ggplot(pcoam,aes_string("Axis.1","Axis.2"))
ppcoa + geom_point(color = "black",size=2)+ geom_point(aes(color = Area_group_name),size=1.5) +labs(title = "Sites NMDS",
        y ="PCOA axis 2",x = "PCOA axis 1") +scale_colour_brewer(palette = "Accent")  

ggsave(filename = "pcoaotu12.png",dpi =600)
plotfun(otupcoa$vectors[,1:3],"Axis.1","Axis.3") +labs(title = "Sites PCOA",
                                                       y ="PCOA axis 3",x = "PCOA axis 1")

###################################################################
# Applying NMDS and plotting it using area name for color plotting#
###################################################################
NMDS.scree <- function(x) { #where x is the name of the data frame variable
  plot(rep(1, 10), replicate(10, metaMDS(x,distance="bray", autotransform = F, k = 1)$stress),
       xlim = c(1, 10),ylim = c(0, 0.50), xlab = "# of Dimensions", ylab = "Stress", main = "NMDS stress plot")
  for (i in 1:10) {
    points(rep(i + 1,10),replicate(10, metaMDS(x,distance="bray", autotransform = F, k = i + 1)$stress))
  }
}

autonmds <- function(data,pbool){
  nmds1 <-metaMDS(data,distance = "bray",trace = F,autotransform = F,k=2,trymax = 100)
  if (pbool ==TRUE) {
  # Plot if true
  plot(    plotfun(nmds1$points,"MDS1","MDS2")+
    labs(title = "Sites NMDS",
       y ="NMDS axis 2",x = "NMDS axis 1"))
    stressplot(nmds1)}

  return(nmds1)
}
NMDS.scree(otudf)
# 2 dimensions has a stress betd ween 0.1 and 0.2, 3D has a little bit higher than 0.1
# and 4D around 0.1
set.seed(11235)
nmds1 <-metaMDS(otudf,distance = "bray",trace = F,
                autotransform = F,k=2,trymax = 1000)

#write.csv(x = nmds1$points[,],file = "nmds20dim")
nmdsm <-merge(nmds1$points,wwfdf[,c("ID","Area_group","Area_group_name","Water")],by.x=0,by.y="ID")
plotfun(nmds1$points,"MDS1","MDS2") +labs(title = "Sites NMDS",
                                          y ="NMDS axis 2",x = "NMDS axis 1")
#ggsave(filename = "nmdsotu12.png",dpi=600)

# plotting using ggplot
p <- ggplot(nmdsm,aes(MDS1,MDS2))
p + geom_point(color = "black",size=2)+ geom_point(aes(color = Area_group_name),size=1.5) +labs(title = "Sites NMDS",
 y ="NMDS axis 2",x = "NMDS axis 1") +scale_colour_brewer(palette = "Accent")  
  
stressplot(nmds1)
# good stress plot
# Species nmds is not very informative
otudf %>%
  metaMDS(k=2,trace = F,distance = "bray",autotransform = F,trymax = F) %>%
  ordiplot( display = "species",cex=1,type="t") 
# Environmental variables fitting

waternmds <- envfit(nmds1 ~ Water,wwfdf)
locnmds <- envfit(nmds1~ Easting,wwfdf)
northnmds <- envfit(nmds1~ Northing
                    ,wwfdf)
plot(nmds1,display = "sites")
plot(northnmds)
legend("topleft",legend = c("Northing","Easting"),fill = c("red","green"))
with(wwfdf,ordisurf(nmds1,Easting,add=TRUE,col = "green"))
with(wwfdf,ordisurf(nmds1,Northing,add=TRUE,col = "red"))
#######
# CCA #
#######

ccaotudf <- cca(otudf ~ Water,wwfdf)
plot(ccaotudf)


#multi dimensional KMeans with bray curtis distance metric


#####################
# Kmeans clustering #
#####################

otudist.pam <- pam(x=otudist,diss = TRUE,k=2)
summary(otudist.pam)
otudf %>% 
  vegdist(method ="bray")%>%
  pam(diss = T,k=2)%>%
  plot(which.plot = 2)

# plots 1 clustplot and 2 silhouette
# clustplot is 2d representation of the observations
# usinf pca or mds and observations are clustered using
# ellipses
plot(otudist.pam,which.plots = 2,labels=2,lines =1)
# Not very informative
###########################
# Alpha diversity metrics #
###########################

specnumber(otudf)
wwfdf$shannon <- diversity(otudf,index = "shannon")
wwfdf$simpson <- diversity(otudf,index = "simpson")

alphaplot <- ggplot(data = wwfdf,aes(x = Easting,y = simpson))
alphaplot + geom_point(aes(shape = Water,col = Area_group_name))

summary(rowSums(otudf))



# large disparity in the total number of reads
low_rowsums<- which(rowSums(otudf)<10000)
# there are 7 samples that contain less than 10000 reads, we can
# exclude them to see how clustering, and ordination change
exclude <-  !( rownames(otudf) %in% names(which(rowSums(otudf)<10000)))
otudf.min <- otudf[exclude,]
# Running nmds again with 2D
autonmds(otudf.min,pbool=TRUE)
ggsave(filename = "nmdsotumin12.png",dpi=600)
autonmds(otudf,pbool=TRUE)
# Slight difference between the two data sets
# Trying Kmeans to see if there is a difference
    
otudf.min.bray <-  vegdist(x = otudf.min,method ="bray")
otupam.bray <- pam(x = otudf.min.bray,diss = T,k=2)
plot(otupam.bray,which.plot = 1)

#############
# Normalising #
#############
rrarefy(otudf.min)

# Normalisation using CSS abd metaseq package
MRotu <-newMRexperiment(otumatrix)
MRotucss <-cumNorm(MRotu,p = cumNormStat(MRotu))
otudf.css <- t(MRcounts(MRotucss,norm = TRUE))
# Trying out NMDS
autonmds(otudf.css,TRUE)
# Diferent results, much better separation of water colour
#PCoA
otudist.css <- vegdist(otudf.css,method="bray")
otupcoa.css <-pcoa(otudist.css)
plotfun(otupcoa.css$vectors,"Axis.1","Axis.3") +labs(title = "Sites PCOA",
  y ="PCOA axis 2",x = "PCOA axis 1")
########################
# Meta Data exploration#
########################
nrows(wwf)
#164
sum(wwf[,6]=="White")
#143
wwf[,2] =wwf[,2] -mean(wwf[,2])
wwf[,3] =wwf[,3] -mean(wwf[,3])
plot(wwfdf[,c(2,3)],col = wwfdf$Area_group)
legend(x="topleft",legend = levels(wwfdf$Area_group_name),pch=1,col=levels(wwfdf$Area_group))
identify(x=wwf[,2], y=wwf[,3], labels=wwf[,5]) # identify points 

# Euclidean distnce
# Example including distances
site_distance <-vegdist(distinct(wwfdf[,c("Easting","Northing")]),method = "euclidean")
site_distance.pcoa <- pcoa(D =site_distance)
site_distance %>%
  metaMDS(k=2,autotransform = F) %>%
  ordiplot(choices = c(1,2))
  stressplot()
ggsave(filename = "nmdsdistance.png",dpi =600)