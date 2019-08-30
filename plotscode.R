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

taxa <- otudata[,seq(1,8)][,-c(1,2,8)]
taxadf <- data.frame(taxa[-1,],row.names = otudata[-1,1] )
colnames(taxadf) <- taxa[1,]

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
wwfdf$Eastingj = wwfdf$Easting + rnorm(n=164,sd=5e3)
wwfdf$Northingj = wwfdf$Northing+ rnorm(sd=5e3,n=164)
ggplot(wwfdf,aes(x=Eastingj,y=Northingj,shape =Water))+
  geom_point(size=4.1,aes(color = Area_group_name))+
  #scale_color_brewer()+
  #geom_point(color = "Black",size = 1.9)+
  geom_point(size=1.5,aes(shape = Water), color = wwfdf$Water)+
  #aes(color = Water,size = 1.5)+
  #scale_colour_manual(values =c("Black","White"))
  labs(title = "Peruvian Rivers")
ggsave(width = 16,height = 9,dpi=300,filename = "mapofrivers.png")

countdf<- taxadf %>%
          group_by(Class,Order)%>%
          count() %>%
          ungroup()
countdf$nmax <- cumsum(countdf$n)/6.75
countdf$nmin <- c(0,countdf$nmax[-44])

countdf %<>% cumsum(n)
taxadf %>%
  group_by(Order)%>%
  count() -> orderdf

#' x      numeric vector for each slice
#' group  vector identifying the group for each slice
#' labels vector of labels for individual slices
#' col    colors for each group
#' radius radius for inner and outer pie (usually in [0,1])

donuts <- function(x, group = 1, labels = NA, col = NULL, radius = c(.7, 1)) {
  group <- rep_len(group, length(x))
  ug  <- unique(group)
  tbl <- table(group)[order(ug)]
  
  col <- if (is.null(col))
    seq_along(ug) else rep_len(col, length(ug))
  col.main <- Map(rep, col[seq_along(tbl)], tbl)
  col.sub  <- lapply(col.main, function(x) {
    al <- head(seq(0, 1, length.out = length(x) + 2L)[-1L], -1L)
    Vectorize(adjustcolor)(x, alpha.f = al)
  })
  
  plot.new()
  
  par(new = TRUE)
  pie(x, border = NA, radius = radius[2L],
      col = unlist(col.sub), labels = labels)
  
  par(new = TRUE)
  pie(x, border = NA, radius = radius[1L],
      col = unlist(col.main), labels = NA)
}

with(countdf,donuts(n,group=Class,labels = countdf$Order),
     col = c('cyan2','red','orange','green','dodgerblue2'),)
     
ggplot(countdf,aes(x =1)) + 
  geom_bar(aes(fill=Order, y = n),stat= "identity",color = "black") +
  #geom_rect(aes(fill=Class, ymax=nmax, ymin=nmin, xmax=3, xmin=0)) +
# +
  guides(fill = FALSE)+
  theme(aspect.ratio=1) +
  coord_polar(theta="y") 
