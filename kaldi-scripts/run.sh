#!/bin/sh

# initialization PATH
. ./path.sh  || die "path.sh expected";
# initialization commands
. ./cmd.sh

# download iban to build ASR
if [ ! -d "asr_iban" ]; then
  #available from github
  svn co https://github.com/sarahjuan/trunk/asr_iban || exit 1;
fi

[ ! -L "steps" ] && ln -s ../../wsj/s5/steps

[ ! -L "utils" ] && ln -s ../../wsj/s5/utils

[ ! -L "conf" ] && ln -s ../../wsj/s5/conf

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
