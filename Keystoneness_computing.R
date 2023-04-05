library(ggplot2)
library(scales)
library(ggpubr)
library(gridExtra)
library(ggExtra)

setwd("/Users/xu-wenwang/Dropbox/Projects/Keystone/code")

## read the data 
species_id = read.table(file = paste('../data/Species_id.csv',sep = ''), header = F, sep=",")
sample_id = read.table(file = paste('../data/Sample_id.csv',sep = ''), header = F, sep=",")
Ptrain = read.table(file = paste('../data/Ptrain.csv',sep = ''), header = F, sep=",")
ptst = read.table(file = paste('../data/Ptest.csv',sep = ''), header = F, sep=",")
GCN_full = read.table(file = paste('../data/GCN.csv',sep = ''), header = F, sep=",")
GCN_full = as.matrix(GCN_full)

## read the prediction of cNODE2
qtst = read.table(file = paste('../results/qtst.csv',sep = ''), header = F, sep=",")
qtrn = read.table(file = paste('../results/qtrn.csv',sep = ''), header = F, sep=",")

## calculate keystoneness
keystone_predicted = c()
keystone_true = c()
function_predicted = c()
function_true = c()
for (i in 1:nrow(qtst)){
  # predicted null composition
  q_i = qtrn[sample_id$V1[i],]
  q_i_null = q_i
  q_i_null[species_id$V1[i]] = 0
  q_i_null = q_i_null/sum(q_i_null)
  
  # true null composition
  p_i = Ptrain[,sample_id$V1[i]]
  p_i_null = p_i
  p_i_null[species_id$V1[i]] = 0
  p_i_null = p_i_null/sum(p_i_null)
  
  # impact to the community
  BC_true=sum(abs(p_i_null-ptst[,i]))/sum(abs(p_i_null+ptst[,i]))
  BC_pred=sum(abs(q_i_null-qtst[i,]))/sum(abs(q_i_null+qtst[i,]))
  
  # structural keystoneness
  keystone_predicted = c(keystone_predicted, BC_pred*as.numeric(1-Ptrain[species_id$V1[i],sample_id$V1[i]]))
  keystone_true = c(keystone_true, BC_true*as.numeric(1-Ptrain[species_id$V1[i],sample_id$V1[i]]))
  
  # functional keystoneness
  f_before_true = as.numeric(p_i_null)%*%as.matrix(GCN_full)
  f_before_pred = as.numeric(q_i_null)%*%as.matrix(GCN_full)
  f_after_true = as.numeric(ptst[,i])%*%as.matrix(GCN_full)
  f_after_pred = as.numeric(qtst[i,])%*%as.matrix(GCN_full)
  f_before_true = f_before_true/sum(f_before_true)
  f_before_pred = f_before_pred/sum(f_before_pred)
  f_after_true = f_after_true/sum(f_after_true)
  f_after_pred = f_after_pred/sum(f_after_pred)
  
  BC_true = sum(abs(f_after_true-f_before_true))/sum(abs(f_after_true+f_before_true))
  BC_pred = sum(abs(f_after_pred-f_before_pred))/sum(abs(f_after_pred+f_before_pred))
  
  function_true = c(function_true, BC_true*(1-as.numeric(Ptrain[species_id$V1[i],sample_id$V1[i]])))
  function_predicted = c(function_predicted, BC_pred*(1-as.numeric(Ptrain[species_id$V1[i],sample_id$V1[i]])))
}
keystoness = data.frame(str_pred=keystone_predicted,func_pred=function_predicted,str_true=keystone_true,func_true=function_true)

# figure
g1 = ggplot(keystoness, aes(x=str_true, y=str_pred)) + 
  geom_hex()+scale_fill_distiller(palette= "Spectral", direction=-1) +
  geom_abline(intercept = 0, slope = 1,color="#d01c8b")+
  scale_x_continuous(limits = c(0, 0.04), breaks = seq(0,0.04,by=0.02))+
  scale_y_continuous(limits = c(0, 0.04), breaks = seq(0,0.04,by=0.02))+
  stat_cor(p.accuracy = 0.001, r.accuracy = 0.01,method = "spearman",size=3,cor.coef.name="rho")+
  xlab(expression(italic(K[s])~'(true)'))+ylab(expression(italic(K[s])~'(prediction)'))+
  theme_bw()+
  theme(
    line = element_line(size = 0.5),
    rect = element_rect(size = 0.5),
    text = element_text(size = 8),
    axis.text.x = element_text(size = 10,color = 'black'),
    axis.text.y = element_text(size = 10,color = 'black'),
    axis.title.x = element_text(size = 10),
    axis.title.y = element_text(size = 10), 
    panel.grid.minor = element_blank(), 
    panel.grid.major.x = element_blank(), 
    panel.grid.major.y = element_blank(),
    legend.title = element_blank(),
    legend.position = 'none',
    legend.box.background = element_rect(size = 0.2), 
    legend.key.size = unit(4, unit = 'mm'),
    legend.text = element_text(size = 8)
  )

