# Unsupervised ml
riverdfcsslog =read.csv("riverdfcsslog",header = T)
riverdfcsslog %>% 
  vegdist(method ="bray")%>%
  pam(diss = T,k=2)%>%
  plot(which.plot = 2)