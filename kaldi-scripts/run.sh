#!/bin/sh
# This script builds data and run training and testing for Iban ASR. Download the database from github. wav files are in data/wav, language model in LM/*.arpa.tar.gz and lexicons in lang/dict.
 
# initialization PATH
. ./path.sh  || die "path.sh expected";
# initialization commands
. ./cmd.sh

# download iban to build ASR
if [ ! -d "asr_iban" ]; then
  #available from github
  svn co https://github.com/sarahjuan/iban || exit 1;
fi

[ ! -L "steps" ] && ln -s ../../wsj/s5/steps

[ ! -L "utils" ] && ln -s ../../wsj/s5/utils

[ ! -L "conf" ] && ln -s ../../wsj/s5/conf


#Now make MFCC
for x in $TRAIN $TEST; do
  steps/make_mfcc.sh --nj 4 data/$x data/log  mfcc
  steps/compute_cmvn_stats.sh data/$x data/log mfcc
done

wait;


#Monophone
04_train_mono.sh
#Triphone
04a_train_triphone.sh
# + LDA + MLLT
04b_train_MLLT_LDA.sh
# + SAT_FMLLR
04c_train_SAT_FMLLR.sh
# + SGMM
04e_train_sgmm.sh

