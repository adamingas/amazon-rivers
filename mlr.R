setwd("~/Documents/Stats/Project/amazon-rivers/")
library(kohonen)
library(dplyr)
library(magrittr)
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


#######
# SOM #
#######
trainindex = sample(nrow(otudf),130)
Xtrain = matrix(as.numeric(unlist(otudf[trainindex,])),ncol = 675)
Xtest = matrix(as.numeric(unlist(otudf[-trainindex,])),ncol = 675)
ytrain = wwfdf$Water[trainindex]
ytest = wwfdf$Water[-trainindex]
som.full <-xyf(X=Xtrain,Y=(ytrain), grid = somgrid(5,5, "hexagonal"))
plot(som.full)

som.prediction <- predict(som.full,newdata = Xtest,whatmap = 1)

table(ytest,som.prediction$predictions[[2]])
