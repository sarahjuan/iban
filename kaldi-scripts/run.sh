#!/bin/sh

. 00_init_paths.sh

#EXPERIMENTS

#Monophone
./04_train_mono.sh
#Triphone
./04a_train_triphone.sh
# + LDA + MLLT
./04b_train_MLLT_LDA.sh
# + SAT_FMLLR
./04c_train_SAT_FMLLR.sh
# + SGMM
./04e_train_sgmm.sh
