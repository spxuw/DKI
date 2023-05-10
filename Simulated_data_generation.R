library("seqtime")

rm(list=ls())

N =100 # number of species
N_sub = 50 # richness
M = 500 # number of samples

# different network connectivity
for (C in c(0.3,0.5,0.7)){
  set.seed(234)
  A = (matrix(rnorm(N*N,mean=0,sd=0.01), N, N))
  set.seed(234)
  Connect = sample(0:1, N^2, prob = c(1-C, C), replace = TRUE)
  A = A * matrix(Connect, N, N)
  set.seed(234)
  boosted = sample(which(A!=0),length(which(A!=0)))
  A[boosted] = A[boosted]*rlnorm(length(boosted), meanlog = 0, sdlog = 1)
  
  diag(A) = -1
  b = runif(N) # growth rate
  
  steady_state_relative = matrix(0,N,M)
  steady_state_absolute = matrix(0,N,M)
  for (i in 1:M){
    set.seed(i)
    collection = sample(1:N,N_sub)
    y_0 = runif(N)
    y_0[setdiff(1:N,collection)] = 0
    x = glv(N = N, A, b = b, y = y_0, tstart = 0, tend = 100, tstep = 0.1, perturb = NULL)
    x[x<0] = 0
    steady_state_relative[,i] = x[,ncol(x)]/sum(x[,ncol(x)])
    steady_state_absolute[,i] = x[,ncol(x)]
  }
  steady_state_relative[steady_state_relative<0] = 0
  steady_state_absolute[steady_state_absolute<0] = 0

  # generate test samples used for keystoneness calculation
  species_id = c()
  sample_id = c()
  absent_composition = c()
  absent_collection = c()
  
  for (j1 in 1:N){
    print(j1)
    for (j2 in 1:M){
      if (steady_state_absolute[j1,j2]>0){
        y_0 = steady_state_absolute[,j2]
        y_0_binary = y_0
        y_0_binary[y_0_binary>0] = 1
        if (sum(y_0_binary)>1){
          y_0[j1] = 0
          x = glv(N = N, A, b = b, y = y_0, tstart = 0, tend = 100, tstep = 0.1, perturb = NULL)
          x[x<0] = 0
          absent_composition = cbind(absent_composition, x[,ncol(x)]/sum(x[,ncol(x)]))
          species_id = c(species_id, j1)
          sample_id = c(sample_id, j2)
          y_0[y_0>0]=1
          absent_collection = cbind(absent_collection, y_0/sum(y_0))
        }
      }
    }
  }
  ifelse(!dir.exists(file.path('../data', paste('gLV_C_v2_',C,sep = ''))), dir.create(file.path('../data', paste('gLV_C_v2_',C,sep = ''))), FALSE)
  write.table(steady_state_relative, file = paste('../data/gLV_C_v2_',C,'/Ptrain.csv',sep = ''), row.names = F, col.names = F, sep=",")
  write.table(species_id, file = paste('../data/gLV_C_v2_',C,'/Species_id.csv',sep = ''), row.names = F, col.names = F, sep=",")
  write.table(sample_id, file = paste('../data/gLV_C_v2_',C,'/Sample_id.csv',sep = ''), row.names = F, col.names = F, sep=",")
  write.table(absent_composition, file = paste('../data/gLV_C_v2_',C,'/Ptest.csv',sep = ''), row.names = F, col.names = F, sep=",")
  write.table(absent_collection, file = paste('../data/gLV_C_v2_',C,'/Ztest.csv',sep = ''), row.names = F, col.names = F, sep=",")
  write.table(A, file = paste('../data/gLV_C_v2_',C,'/A.csv',sep = ''), row.names = F, col.names = F, sep=",")
  write.table(b, file = paste('../data/gLV_C_v2_',C,'/b.csv',sep = ''), row.names = F, col.names = F, sep=",")
}
