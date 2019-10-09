#setwd("~/")
setwd("~/Documents/Stats/Project/amazon-rivers/")

library(vegan)
library(ape)
library(dplyr)
library(ggplot2)
library(magrittr)
library(cluster)
library(metagenomeSeq)
library(caret)
library(MASS)
library(corrplot)
library(mvabund)
library(bartMachine)


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

wwfdf$ID_nosamples <- gsub(pattern = "[a-zA-Z-]","",wwfdf$ID)
wwfdf$ID_nosamples %<>% as.factor
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
###########################
# Correlation of features #
###########################
cormatrix <- cor(otudf,method = "spearman")
highCorIndx <- findCorrelation(cormatrix,cutoff = 0.9)
length( highCorIndx)
otudflowcor <- otudf[,-highCorIndx]
#write.csv(otudflowcor,file = "otudflowcor")
otudflowcor%>%
  {newMRexperiment(t(.))} %>%
  {plotCorr(.,n=300,dendrogram= "none",cexRow = 0.25,
         col=heatmapCols,cexCol = 0.25,trace = "none",norm = FALSE
         ,fun = function(x){cor(x,method = "spearman")})}


#######
# PCA #
#######
PCA <- rda((otudf), scale = FALSE)
barplot(as.vector(PCA$CA$eig)/sum(PCA$CA$eig))
sum(PCA$CA$eig[1:2])/sum(PCA$CA$eig)
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

otupcoa <-otudf %>%
  vegdist(method="bray") %>%
  pcoa()
  
plotfun(otupcoa$vectors,"Axis.1","Axis.2") +labs(title = "Sites PCOA",
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
# Creating PCoA using Bray-Curtis distance to save it as a csv and use it 
# as features in classification
(otudflowcor) %>%
  vegdist(method = "bray")%>%
  {pcoa(.,correction = "lingoes")} %>%#-> pcoaOtu
 { plotfun(.$vectors,"Axis.1","Axis.2") +labs(title = "Sites PCoA Euclidean",
 y ="PCOA axis 2",x = "PCOA axis 1")}
ggsave(filename = "pcoa12eucotu.png",dpi = 600)
write.csv(x=pcoaOtu$vectors,file="pcoaOtu")
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
nmds1 <-metaMDS(otudf,distance = "euclidean",trace = F,
                autotransform = F,k=2,trymax = 1000)

#write.csv(x = nmds1$points[,],file = "nmds20dim")
nmdsm <-merge(nmds1$points,wwfdf[,c("ID","Area_group","Area_group_name","Water")],by.x=0,by.y="ID")
plotfun(nmds1$points,"MDS1","MDS2") +labs(title = "Sites NMDS",
                                          y ="NMDS axis 2",x = "NMDS axis 1")
ggsave(filename = "nmdsotu12euc.png",dpi=600)

# plotting using ggplot
p <- ggplot(nmdsm,aes(MDS1,MDS2))
p + geom_point(color = "black",size=2)+ geom_point(aes(color = Area_group_name),size=1.5) +labs(title = "Sites NMDS",
 y ="NMDS axis 2",x = "NMDS axis 1") +scale_colour_brewer(palette = "Accent")  
  
stressplot(nmds1)
# good stress plot
# Species nmds is not very informative
otudflowcor %>%
  metaMDS(k=2,trace = F,distance = "bray",autotransform = F,trymax = F) %>%
  ordiplot( display = "species",cex=1,type="t") 
# Environmental variables fitting

waternmds <- envfit(nmds1 ~ Water,wwfdf)
locnmds <- envfit(nmds1~ Easting,wwfdf)
northnmds <- envfit(nmds1~ Northing,wwfdf)
#extract environmental data from ordisurf
extract.xyz <- function(obj) {
  xy <- expand.grid(x = obj$grid$x, y = obj$grid$y)
  xyz <- cbind(xy, c(obj$grid$z))
  names(xyz) <- c("x", "y", "z")
  return(xyz)
}

ordnorth <- with (wwfdf,ordisurf(nmds1,Northing,plot = FALSE))
ordeast <- with (wwfdf,ordisurf(nmds1,Easting,plot = FALSE))
contoursnorth <- extract.xyz(ordnorth)
contourseast <- extract.xyz(ordeast)

ggplot(data = contoursnorth, aes(x, y, z = z)) + stat_contour(aes(colour = ..level..)) +
  ggplot(data = contourseast, aes(x, y, z = z)) + stat_contour(aes(colour = ..level..)) 

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
#######
# MIN #
######
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
############################
# Testing for significance #
############################
# getting normalised counts

otudf.min %>%
  cssnormalisation()%>%
  as.data.frame()%>%
  {.$alpha <-diversity(.,index = "invsimpson")}%>%
  {merge(.,wwfdf[,c("ID","Water")],by.x=0,by.y="ID") }-> alphaotu
{wilcox.test(x ~ Water,data =alphaotu)}
ggplot(alphaotu,aes(x = Water,fill=Water,y=x))+
  geom_boxplot()

##Checking permutations
perm <-how(plots =Plots(strata = wwfdf$ID_nosamples), within = Within(type = "series", mirror = TRUE))
rval <- rep(NA,2000)
rval[1] <- wilcox.test(x ~ Water,data =alphaotu)$stat
set.seed(11235)
for (i in 2:2000) {
  indx <- shuffle(alphaotu,control = perm)
  rvalrand <- wilcox.test(x ~ Water[indx],data =alphaotu)$stat
  rval[i] <- rvalrand
}
print(pval <- sum(rval >= rval[1]) / (2000))
###############
# Normalising #
###############
rrarefy(otudf.min)

# Normalisation using CSS abd metaseq package
cssnormalisation <- function(dataframe,log=FALSE){
  # Normalises dataframe
  MRObject <-newMRexperiment(t(dataframe))
  MRObject.css<-cumNorm(MRObject, p = cumNormStat(MRObject))
  dataframe.css <- t(MRcounts(MRObject.css,norm = TRUE,log = log))
  return(dataframe.css)
}

MRotu <-newMRexperiment(otumatrix)
MRotucss <-cumNorm(MRotu,p = cumNormStat(MRotu))
otudf.css <- t(MRcounts(MRotucss,norm = TRUE))

otudf.css1 <- cssnormalisation(otudf[1:140,],log=TRUE)
otudf.css2 <- cssnormalisation(otudf,log=TRUE)[1:140,]
hist(rowSums(otudf.css))
(otudf) %>%
  cssnormalisation()%>%
  {autonmds(.,FALSE)}%>%
  {plotfun(data = .$points,"MDS1","MDS2") +labs(title = "Sites NMDS_MIN_CSS",
  y ="NMDS axis 2",x = "NMDS axis 1")}
ggsave(dpi=600,filename = "nmds12otumincss.png")

t(otudf) %>%
  newMRexperiment() %>%
  cumNorm(.,p = cumNormStat(.))%>%
  MRcounts(norm = TRUE)%>%
  t %>%
  vegdist(method="bray") %>%
  pcoa()%>%
  {plotfun(data = .$vectors,"Axis.1","Axis.2") +labs(title = "Sites PCOA_MIN_CSS Bray",
   y ="PCOA axis 2",x = "PCOA axis 1")}
ggsave(dpi=600,filename = "pcoa12otumincss.png")

#only fishes otudf
fishindex =taxadf["Class"] == "Actinopterygii"
fishdf = otudf[,fishindex]
notzerosmples =rowSums( fishdf) != 0
fishdf.css = cssnormalisation(fishdf[notzerosmples,])
fishdf.css.log =cssnormalisation(fishdf[notzerosmples,],log=TRUE)
write.csv(fishdf[notzerosmples,],file = "fishdf")
write.csv(wwfdf[notzerosmples,],file="wwfdffish")
write.csv(fishdf.css,file= "fishdfcss")
write.csv(fishdf.css.log,file= "fishdfcsslog")
# Trying out NMDS
autonmds(otudf.css,TRUE)

# Diferent results, much better separation of water colour
#PCoA
otupcoa.css<- otudf.css %>%
  vegdist(method="bray") %>%
  pcoa 
otupcoa.css <-pcoa(otudist.css)
plotfun(otupcoa.css$vectors,"Axis.1","Axis.3") +labs(title = "Sites PCOA",
  y ="PCOA axis 2",x = "PCOA axis 1")

otudf %>% cssnormalisation(log=TRUE)%>%
  vegdist(method = "bray")%>%
  {pcoa(.)$vectors} %>%#-> pcoaCss %>%
  {plotfun(.,"Axis.1","Axis.2") +labs(title = "Sites PCOA",
                                                        y ="PCOA axis 2",x = "PCOA axis 1")
  }


otudf.min.css %>%
  vegdist(method = "bray")%>%
  {pcoa(.)$vectors} -> pcoaMinCss
nmds20Css <-metaMDS(otudf.css,distance = "bray",trace = T,
        autotransform = F,k=20,trymax = 1000)
nmds20MinCss <-metaMDS(otudf.min.css,distance = "bray",trace = T,
                    autotransform = F,k=20,trymax = 100)

# Minimum wwfdf 
write.csv(wwfdf[exclude,],file="wwfdfmin")
write.csv(x = otudf.css,file = "otudfCss")
write.csv(x = otudf.min.css,file = "otudfMinCss")
write.csv(x = pcoaCss,file = "pcoaCss")
write.csv(x = pcoaMinCss,file = "pcoaMinCss")
write.csv(x = nmds20Css$points,file = "nmds20Css")
write.csv(x = nmds20MinCss$points,file = "nmds20MinCss")
# css with log normalisation
otudf %>% cssnormalisation(log=TRUE) -> otudf.css.log
write.csv(x = otudf.css.log,file = "otudfCssLog")

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
### MRobject creation and exploration
# Creating taxonomic dataframes
taxa <- otudata[,seq(1,8)][,-c(1,2,8)]
taxadf <- data.frame(taxa[-1,],row.names = otudata[-1,1] )
colnames(taxadf) <- taxa[1,]
fishotus =rownames(taxadf[(taxadf["Class"] == "Actinopterygii"),])
taxonomicData <- AnnotatedDataFrame(taxadf)
rownames(wwfdf) <- wwfdf$ID
metaData <- AnnotatedDataFrame(wwfdf)
# Crating an MR object
MRdata<- newMRexperiment(t(otudf),featureData = taxonomicData,phenoData = metaData)
MRdatanorm<- cumNorm(MRdata,p=cumNormStat(MRdata))
otudf
# Aggreagating by taxonomy
MRClass <- aggregateByTaxonomy(obj = MRdata,lvl = "Class")
heatmapCols = colorRampPalette(brewer.pal(9, "RdBu"))(50)
heatmapColColors = brewer.pal(12, "Set3")[as.integer(wwfdf$Water)]
plotMRheatmap(obj = MRdata,n = 100,norm = TRUE,cexRow = 0.25,
              col=heatmapCols,cexCol = 0.25,trace = "none",
              ColSideColors = heatmapColColors)

plotCorr(MRdata,n=200,dendrogram= "none",cexRow = 0.25,
         col=heatmapCols,cexCol = 0.25,trace = "none")

plotOrd(MRdata, tran = TRUE, usePCA = FALSE, useDist = TRUE,
        bg = wwfdf$Water, pch = 21,norm = TRUE)
rownames(wwfdf) <- wwfdf$ID

#Differential abundance testing
# Filtering
MRdata<- filterData(MRdata,present = 20,depth =1)
# Normalising
MRdata <- cumNorm(MRdata,p = 0.5)

mod <- model.matrix(~1 + Water, data = pData(MRdata))
fittedModel<- fitFeatureModel(MRdata,mod = mod)

# Creating a histogram of total sample reads
df <- data.frame(Water = wwfdf$Water, size = rowSums(otudf.css))
ggplot(df, aes(x =size,color =Water )) +
  geom_histogram(fill ="white",position = "dodge",bins = 20) +
  labs(title = "Histogram of total sample counts CSS")
ggsave(filename = "histogramofcountdatacss.png",dpi =300)
#############
# PERMANOVA #
#############
perm <-how(plots =Plots(strata = wwfdf$ID_nosamples), within = Within(type = "series", mirror = TRUE))
shuffle(wwfdf,control = perm)
rval <- rep(NA,2000)
rval[1] <- adonis(formula = otudf ~ wwfdf$Water,permutations = 1,
        method="bray",data = otudf)$aov.tab[1,4]
set.seed(11235)
for (i in 2:2000) {
  indx <- shuffle(wwfdf)#,control = perm)
  rvalrand <- adonis(formula = otudf ~ wwfdf$Water[indx],permutations = 1,
                method="bray",data = otudf)$aov.tab[1,4]
  rval[i] <- rvalrand
}
print(pval <- sum(rval >= rval[1]) / (2000))
# P vaue is 0.025 which means it's significant
hist(rval)
rval[1]


par(mfrow=c(1,1))
plot(meta11<-metaMDS(otudf,k = 2,distance = "bray"),type="n",
     main="same beta-disp\nsame location")
points(meta11,select=which(wwfdf$Water =="White"),col="red")
points(meta11,select=which(wwfdf$Water =="Black"),col="blue")
ordispider(meta11,group=wwfdf$Water)

#
# LDA #
#######
#Removing correlated features 
cormatrix <- cor(otudf,method = "spearman")
highCorIndx <- findCorrelation(cormatrix,cutoff = 0.8)
otudflowcor <- otudf[,-highCorIndx]
write.csv(otudflowcor,file = "otudfLow")

otudfpcoa <-pcoa(vegdist(otudf.css))
dataforlda <- cbind(as.matrix(otudflowcor),as.numeric(wwfdf$Water)-1)
colnames( dataforlda)[length(dataforlda)]<- "Water"
dataforlda %<>% data.frame()
f <- paste("Water", "~", paste(names(dataforlda)[-length(dataforlda)], collapse=" + "))
dldatest<-lda(x= otudflowcor,grouping = wwfdf$Water,CV=TRUE)
ldacalss <-lda(x = otudfpcoa$vectors,grouping = wwfdf$Water,CV=TRUE)$class
mean(ldacalss == wwfdf$Water)

#####
# MVABUND #
######

######
# BART #
########
# train test stratified split
trainIndx <- createDataPartition(wwfdf$Area_group,times =7,p = 0.8)
for (i in trainIndx){
  bartmodel = bartMachine(X=otudf[i,],y=wwfdf$Water[i],verbose = F)
  predbart <-bart_predict_for_test_data(bartmodel,otudf[-i,],wwfdf$Water[-i])
  print(mean(predbart$y_hat ==wwfdf$Water[-i]))
}

bm<- bartMachine(X = otudf,y=wwfdf$Water)
bart_predict_for_test_data(bm,otudf,wwfdf$Water)$y_hat ==wwfdf$Water

## Bayesian adiit
#A review of tree baed bayesn methods 
# BART bayesian additive random trees
#WAIC
#widly applicable aic