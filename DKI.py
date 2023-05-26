import torch
import numpy as np
import sys, copy, math, time, pdb
import os.path
import random
import pdb
import csv
import argparse
import itertools
from itertools import permutations, product
from sklearn.model_selection import train_test_split
import torch.optim as optim
from torchdiffeq import odeint
import itertools

parser = argparse.ArgumentParser(description='cnode')
# general settings
parser.add_argument('--data-name', default=None, help='data name')
args = parser.parse_args()

dataset = args.data_name

def get_batch(ztrn,ptrn,mb_size):
    s = torch.from_numpy(np.random.choice(np.arange(ptrn.size(dim=0), dtype=np.int64), mb_size, replace=False))
    batch_p = ztrn[s,:]
    batch_q = ptrn[s,:]
    batch_t = t[:batch_time]
    return batch_p.to(device), batch_q.to(device),batch_t.to(device)


def loss_bc(p_i,q_i):
    return torch.sum(torch.abs(p_i-q_i))/torch.sum(torch.abs(p_i+q_i))

def process_data(P):
    Z = P.copy()
    Z[Z>0] = 1
    P = P/P.sum(axis=0)[np.newaxis,:]
    Z = Z/Z.sum(axis=0)[np.newaxis,:]
    
    P = P.astype(np.float32)
    Z = Z.astype(np.float32)

    P = torch.from_numpy(P.T)
    Z = torch.from_numpy(Z.T)
    return P,Z


class ODEFunc(torch.nn.Module):
    def __init__(self):
        super(ODEFunc, self).__init__()
        self.fcc1 = torch.nn.Linear(N, N)
        self.fcc2 = torch.nn.Linear(N, N)

    def forward(self, t, y):
        out = self.fcc1(y)
        out = self.fcc2(out)
        f = torch.matmul(torch.matmul(torch.ones(y.size(dim=1),1),y),torch.transpose(out,0,1))
        return torch.mul(y,out-torch.transpose(f,0,1))


def train_reptile(max_epochs,mb,LR,ztrn,ptrn,ztst,ptst,zval,pval,zall,pall):
    loss_train = []
    loss_val = []
    qtst = np.zeros((ztst.size(dim=0),N))
    qtrn = np.zeros((zall.size(dim=0),N))
    ltst_pred = np.zeros((ztst.size(dim=0),1))
    ltst_ground = np.zeros((ztst.size(dim=0),1))
    
    func = ODEFunc().to(device)
    optimizer = torch.optim.Adam(func.parameters(), lr=LR)

    Loss_opt = 1
    for e in range(max_epochs):
        optimizer.zero_grad()
        batch_p, batch_q, batch_t = get_batch(ztrn,ptrn,mb)
        
        # loss of the traning set
        for i in range(mb):
            p_pred = odeint(func,batch_p[i].unsqueeze(dim=0),batch_t).to(device)
            p_pred = torch.reshape(p_pred[-1,:,:],(1,N))
            if i==0:
                loss = loss_bc(p_pred.unsqueeze(dim=0),batch_q[i].unsqueeze(dim=0))
            else:
                loss = loss + loss_bc(p_pred.unsqueeze(dim=0),batch_q[i].unsqueeze(dim=0))
        loss_train.append(loss.item()/mb)


        # validation set
        for i in range(zval.size(dim=0)):
            p_pred = odeint(func,zval[i].unsqueeze(dim=0),batch_t).to(device)
            p_pred = torch.reshape(p_pred[-1,:,:],(1,N))
            if i==0:
                l_val = loss_bc(p_pred.unsqueeze(dim=0),pval[i].unsqueeze(dim=0))
            else:
                l_val = l_val + loss_bc(p_pred.unsqueeze(dim=0),pval[i].unsqueeze(dim=0))
        loss_val.append(l_val.item()/zval.size(dim=0))
        if l_val.item()/zval.size(dim=0)<=Loss_opt:
            Loss_opt = loss_val[-1]
            best_model = copy.deepcopy(func)
        #print('epoch = ',e, 'loss = ', l_val.item()/mb)

        # update the neural network
        func.zero_grad()
        loss.backward()
        optimizer.step()

        if e == max_epochs-1:
            func = copy.deepcopy(best_model)
            if len(ztst.size())==2:
                for i in range(ztst.size(dim=0)):
                    pred_test = odeint(func, ztst[i].unsqueeze(dim=0), batch_t).to(device)
                    pred_test = pred_test[-1,:,:]
                    pred_test = torch.reshape(pred_test,(1,N))
                    qtst[i,:] = pred_test.detach().numpy()
                for i in range(zall.size(dim=0)):
                    pred_test = odeint(func, zall[i].unsqueeze(dim=0), batch_t).to(device)
                    pred_test = pred_test[-1,:,:]
                    pred_test = torch.reshape(pred_test,(1,N))
                    qtrn[i,:] = pred_test.detach().numpy()
            if len(ztst.size())==1:
                for i in range(ztst.size(dim=0)):
                    pred_test = odeint(func, ztst.unsqueeze(dim=0), batch_t).to(device)
                    pred_test = pred_test[-1,:,:]
                    pred_test = torch.reshape(pred_test,(1,N))
                    qtst = pred_test.detach().numpy()
                for i in range(zall.size(dim=0)):
                    pred_test = odeint(func, zall[i].unsqueeze(dim=0), batch_t).to(device)
                    pred_test = pred_test[-1,:,:]
                    pred_test = torch.reshape(pred_test,(1,N))
                    qtrn[i,:] = pred_test.detach().numpy()

    return loss_train[-5:-1],qtst,qtrn


# hyperparameters
max_epochs = 1000
device = 'cpu'
batch_time = 100
t = torch.arange(0.0, 100.0, 0.01)


# load the dataset
filepath_train = '../data/'+str(dataset)+'/Ptrain.csv'
filepath_test = '../data/'+str(dataset)+'/Ptest.csv' # Replace "Ptest.csv" with "Ztest.csv" for real dataset.

P = np.loadtxt(filepath_train,delimiter=',')
number_of_cols = P.shape[1]
random_indices = np.random.choice(number_of_cols, size=int(0.2*number_of_cols), replace=False)
P_val = P[:,random_indices]
P_train =  P[:,np.setdiff1d(range(0,number_of_cols),random_indices)]
ptrn,ztrn = process_data(P_train)
pval,zval = process_data(P_val)
pall,zall = process_data(P)
M, N = ptrn.shape


P = np.loadtxt(filepath_test,delimiter=',')
ptst,ztst = process_data(P)

# pre training to select the parameter
LR = 0.01
mb = 20

print('dataset:',dataset)
loss_train,qtst,qtrn = train_reptile(max_epochs,mb,LR,ztrn,ptrn,ztst,ptst,zval,pval,zall,pall)


np.savetxt('../results/'+str(dataset)+'/qtst.csv',qtst,delimiter=',')
np.savetxt('../results/'+str(dataset)+'/qtrn.csv',qtrn,delimiter=',')

