setwd("~/Thesis")
library(vegan)
library(ape)
library(dplyr)

wwf =read.table(file = "WWF_Samples.txt",header =TRUE,sep = "\t",stringsAsFactors = FALSE)
data = read.table(file = "WWF_Peru_for_BenCalderhead.csv",sep = ",",stringsAsFactors = FALSE)
otutable<- t(data)[-seq(1,8),]
colnames(otutable) <- c("ID",t(data)[1,-1])

otudf <- as.data.frame(x=otutable,stringsAsFactors=FALSE)
#otudf$ID <- as.character(otudf$ID)
otudf[,-1]<- sapply(otudf[,-1], as.numeric)
wwfd <- as.data.frame(x=wwf)
otum<- merge(otudf,wwfd[c("ID","Area_group_name")],by.x = "ID",by.y ="ID")
# otu <- as.data.frame(x=data[-1,], row.names = data[-1,1])
exclude <-names(otum) %in% c("Area_group_name","ID")
otum[!exclude]  %>%
  metaMDS(trace = F) %>%
  ordiplot(type = "none") %>%
  text("sites") 
nrows(wwf)
#164
sum(wwf[,6]=="White")
#143
wwf[,2] =wwf[,2] -mean(wwf[,2])
wwf[,3] =wwf[,3] -mean(wwf[,3])
plot(wwf[,c(2,3)],col = wwf[,5])
legend(x="topleft",legend = levels(wwf[,5])[1:10],pch=1,col=seq(1,10))
legend(x="top",legend = levels(wwf[,5])[11:17],pch=1,col=seq(11,17))
identify(x=wwf[,2], y=wwf[,3], labels=wwf[,5]) # identify points 
