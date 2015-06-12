#!/bin/sh

# Copyright 2015 Sarah Samson Juan
# Apache 2.0

# This script prepares data and train/decode ASR. 
# Download the Iban corpus from github. wav files are in data/wav, language model in LM/*.arpa.tar.gz and lexicon in lang/dict.
 
# initialization PATH
. ./path.sh  || die "path.sh expected";
# initialization commands
. ./cmd.sh

# download iban to build ASR
if [ ! -d "asr_iban" ]; then
 #available from github
 svn co https://github.com/sarahjuan/iban/trunk/ asr_iban || exit 1;
fi

[ ! -L "steps" ] && ln -s ../../wsj/s5/steps

[ ! -L "utils" ] && ln -s ../../wsj/s5/utils

[ ! -L "conf" ] && ln -s ../../wsj/s5/conf

# Data preparation
local/prepare_data.sh train test
local/prepare_dict.sh
##utils/prepare_lang.sh --position-dependent-phones false data/local/dict "<SIL>" data/local/lang data/lang
local/prepare_lm.sh
utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

# Feature extraction
for x in train test; do
 steps/make_mfcc.sh --nj 4 data/$x exp/make_mfcc/$x mfcc
 steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
done

### Monophone
# Training
steps/train_mono.sh  --nj 4 data/train data/lang exp/mono
# Graph compilation  
utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph
# Decoding
steps/decode.sh --nj 4  exp/mono/graph  data/test exp/mono/decode_test
echo -e "Mono training done.\n"


### Triphone 
# Training
steps/align_si.sh --boost-silence 1.25 --nj 4  data/train data/lang exp/mono exp/mono_ali
steps/train_deltas.sh --boost-silence 1.25  4200 40000  data/train data/lang exp/mono_ali exp/tri1
# Graph compilation
utils/mkgraph.sh data/lang  exp/tri1 exp/tri1/graph
# Decoding
steps/decode.sh --nj 4  exp/tri1/graph  data/test exp/tri1/decode_test

## Triphones + delta delta
# Training
steps/align_si.sh  --nj 4  data/train data/lang exp/tri1 exp/tri1_ali
steps/train_deltas.sh  4200 40000 data/train data/lang exp/tri1_ali exp/tri2a
# Graph compilation
utils/mkgraph.sh data/lang  exp/tri2a exp/tri2a/graph
# Decoding
steps/decode.sh --nj 4  exp/tri2a/graph  data/test exp/tri2a/decode_test
echo -e "Triphone training done.\n" 

### Triphone + LDA and MLLT
# Training
steps/align_si.sh  --nj 4  data/train data/lang exp/tri2a exp/tri2a_ali
steps/train_lda_mllt.sh   --splice-opts "--left-context=3 --right-context=3"   4200 40000 data/train data/lang  exp/tri2a_ali exp/tri2b
# Graph compilation
utils/mkgraph.sh data/lang  exp/tri2b exp/tri2b/graph
# Decoding
steps/decode.sh --nj 4  exp/tri2b/graph  data/test exp/tri2b/decode_test
echo -e "LDA+MLLT training done.\n"

### Triphone + LDA and MLLT + SAT and FMLLR
# Training
steps/align_si.sh  --nj 4 --use-graphs true data/train data/lang exp/tri2b exp/tri2b_ali
steps/train_sat.sh 4200 40000 data/train data/lang exp/tri2b_ali exp/tri3b
# Graph compilation
utils/mkgraph.sh data/lang  exp/tri3b exp/tri3b/graph
# Decoding
steps/decode_fmllr.sh --nj 4  exp/tri3b/graph  data/test exp/tri3b/decode_test
# 
steps/align_fmllr.sh --nj 4 data/train data/lang exp/tri3b exp/tri3b_ali
echo -e "SAT+FMLLR training done.\n"

### Triphone + LDA and MLLT + SAT and FMLLR + SGMM
## SGMM
# Training
steps/train_ubm.sh  600 data/train data/lang exp/tri3b_ali exp/ubm5b2 || exit 1;
steps/train_sgmm2.sh  4200 12000 data/train data/lang exp/tri3b_ali exp/ubm5b2/final.ubm exp/sgmm2_5b2 || exit 1;
# Graph compilation
utils/mkgraph.sh data/lang exp/sgmm2_5b2 exp/sgmm2_5b2/graph
# Decoding
steps/decode_sgmm2.sh --nj 4  --transform-dir exp/tri3b/decode_test exp/sgmm2_5b2/graph data/test exp/sgmm2_5b2/decode_test
echo -e "SGMM training done.\n"

## Triphones + delta delta + DNN
local/run_dnn-deltas.sh

## Triphone + LDA and MLLT + SAT and FMLLR + DNN 
local/run_dnn.sh
echo -e "DNN training done.\n"

#score
for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
