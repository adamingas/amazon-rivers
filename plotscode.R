setwd("~/Documents/Stats/Project/amazon-rivers/")

library(vegan)
library(ape)
library(dplyr)
library(ggplot2)
library(magrittr)
library(cluster)
library(metagenomeSeq)
library(splitstackshape)
library(caret)
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

cormatrix <- cor(otudf,method = "pearson")
highCorIndx <- findCorrelation(cormatrix,cutoff = 0.7)
otudflowcor <- otudf[,-highCorIndx]
sum(abs(cormatrix[upper.tri(cormatrix)]) ==1)

# Stratified into train and test
trainIndx <- createDataPartition(wwfdf$Area_group,times =2,p = 0.7)
wwfdf$train <- rep(0,nrow(wwfdf))
wwfdf$train[-trainIndx$Resample2] <- 1
wwfdf$train %<>% as.factor

gg <-ggplot(wwfdf,aes(Easting,Northing),size = 3) 
gg + geom_point(aes(colour = Area_group_name))
#geom_point(aes(color=Water),size=2)
gg+ 
geom_jitter(aes(fill = train),size =4,width = 2e4,shape = 21,alpha=0.6) +
  scale_fill_manual(values=c("green", "red"),labels=c("Train","Test"))+
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        legend.title = element_blank(),
        panel.background = element_rect(fill = "transparent",colour = NA)
        #,plot.background = element_rect(fill = "transparent",colour = NA)
        )+
  labs(title = "Stratified Sampling")
ggsave(filename = "stratsamp2.png",dpi = 600,bg ="transparent")  
gg+ geom_jitter(aes(fill = Area_group),size = 4 , width = 2e4,shape=21)+
  theme(panel.grid.major = element_blank(), 
           panel.grid.minor = element_blank(),
           legend.title = element_blank(),
           panel.background = element_rect(fill = "transparent",colour = NA))+ 
  scale_fill_manual(values=c("green","red","green","green","green","green","green"),
                    breaks=c("2","1"),labels = c("Test","Train"))+
  labs(title = "Group Sampling")
ggsave(filename = "groupsamp2.png",dpi=600)
scale_colour_brewer(palette = "Accent")  
hist(colSums(otudf))

read.table(file="HumanGutI_COGcountsRaw.txt")
