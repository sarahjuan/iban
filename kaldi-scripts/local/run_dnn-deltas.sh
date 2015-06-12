#!/bin/bash

# Copyright 2015 Sarah Samson Juan
# Apache 2.0

# This example script trains a DNN on top of delta delta features. 
# Based on Karel's setup for DNN

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)

# Config:
gmmdir=exp/tri2a
stage=-1 # resume training with --stage=N
# End of config.
. utils/parse_options.sh || exit 1;
#

if [ $stage -le 0 ]; then
  # split the data : 90% train 10% cross-validation (held-out)
  dir=data/train
  utils/subset_data_dir_tr_cv.sh $dir ${dir}_tr90 ${dir}_cv10 || exit 1
fi

if [ $stage -le 1 ]; then
  # Pre-train DBN, i.e. a stack of RBMs (small database, smaller DNN)
  dir=exp/dnn4b_pretrain-dbn-deltas
  (tail --pid=$$ -F $dir/log/pretrain_dbn.log 2>/dev/null)& # forward log
  $cuda_cmd $dir/log/pretrain_dbn.log \
    steps/nnet/pretrain_dbn.sh --hid-dim 1024 --rbm-iter 20 data/train $dir || exit 1;
fi

if [ $stage -le 2 ]; then
  # Train the DNN optimizing per-frame cross-entropy.
  dir=exp/dnn4b_pretrain-dbn_dnn-deltas
  ali=${gmmdir}_ali
  feature_transform=exp/dnn4b_pretrain-dbn-deltas/final.feature_transform
  dbn=exp/dnn4b_pretrain-dbn-deltas/6.dbn
  (tail --pid=$$ -F $dir/log/train_nnet.log 2>/dev/null)& # forward log
  # Train
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --feature-transform $feature_transform --dbn $dbn --hid-layers 0 --learn-rate 0.008 \
    data/train_tr90 data/train_cv10 lang $ali $ali $dir || exit 1;
  # Decode (reuse HCLG graph)
  steps/nnet/decode.sh --nj 4 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.1 \
    $gmmdir/graph data/test $dir/decode_test || exit 1;
fi


# Sequence training using sMBR criterion, we do Stochastic-GD 
# with per-utterance updates. We use usually good acwt 0.1
dir=exp/dnn4b_pretrain-dbn_dnn_smbr-deltas
srcdir=exp/dnn4b_pretrain-dbn_dnn-deltas
acwt=0.1

if [ $stage -le 3 ]; then
  # First we generate lattices and alignments:
  steps/nnet/align.sh --nj 4 --cmd "$train_cmd" \
    data/train lang $srcdir ${srcdir}_ali || exit 1;
  steps/nnet/make_denlats.sh --nj 4 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt $acwt \
    data/train lang $srcdir ${srcdir}_denlats || exit 1;
fi

if [ $stage -le 4 ]; then
  # Re-train the DNN by 6 iterations of sMBR 
  steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 6 --acwt $acwt --do-smbr true \
    data/train lang $srcdir ${srcdir}_ali ${srcdir}_denlats $dir || exit 1
  # Decode
  for ITER in 1 2 3 4 5 6; do
    steps/nnet/decode.sh --nj 4 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      $gmmdir/graph data/test $dir/decode_it${ITER} || exit 1
  done 
fi

for x in exp/dnn4b_*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done

echo Success
exit 0

