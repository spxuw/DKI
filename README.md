# Quest for keystone species in microbial communities 
We have tested this code for Python 3.8.13 and R 4.1.2.

## This repository contains:
(1) A synthetic dataset to test the Data-driven Keystone species Identification (DKI) framework.

(2) Python code to predict the species composition using species assemblage (cNODE2) and R code to compute keystoneness.

(3) Predicted species composition after removing each present species in each sample.

## How the use the DKI framework.
(1) Run "DKI.py" to predict species compostion using species assemblage.

(2) Run "Keystoness_computing.R" to compute the keystoneness.

# Data type for DKI.
(1) Ptrain.csv: matrix of taxanomic profile of size N*M, where N is the number of taxa and M is the sample size (without header).

|           | sample 1 | sample 2 | sample 3 | sample 4 |
|-----------|----------|----------|----------|----------|
| species 1 | 0.45     | 0.35     | 0.86     | 0.77     |
| species 2 | 0.51     | 0        | 0        | 0        |
| species 3 | 0        | 0.25     | 0        | 0        |
| species 4 | 0        | 0        | 0.07     | 0        |
| species 5 | 0        | 0        | 0        | 0.17     |
| species 6 | 0.04     | 0.4      | 0.07     | 0.06     |
