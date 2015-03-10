#!/bin/bash

# Copyright 2012-2014  Brno University of Technology (Author: Karel Vesely)
# Apache 2.0

# This example script trains a DNN on top of fMLLR features. 
# The training is done in 3 stages,
#
# 1) RBM pre-training:
#    in this unsupervised stage we train stack of RBMs, 
#    a good starting point for frame cross-entropy trainig.
# 2) frame cross-entropy training:
#    the objective is to classify frames to correct pdfs.
# 3) sequence-training optimizing sMBR: 
#    the objective is to emphasize state-sequences with better 
#    frame accuracy w.r.t. reference alignment.

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

#. ./path.sh ## Source the tools/utils (import the queue.pl)

# Config:
gmmdir=exp/tri3b
data_fmllr=data-fmllr-tri3b
stage=4 # resume training with --stage=N
# End of config.
. utils/parse_options.sh || exit 1;
#

if [ $stage -le 0 ]; then
  # Store fMLLR features, so we can train on them easily,
  # test
  dir=$data_fmllr/test
  steps/nnet/make_fmllr_feats.sh --nj 4 --cmd "$train_cmd" \
     --transform-dir $gmmdir/decode_test \
     $dir data/test $gmmdir $dir/log $dir/data || exit 1
  # train
  dir=$data_fmllr/train
  steps/nnet/make_fmllr_feats.sh --nj 4 --cmd "$train_cmd" \
     --transform-dir ${gmmdir}_ali \
     $dir data/train $gmmdir $dir/log $dir/data || exit 1
  # split the data : 90% train 10% cross-validation (held-out)
  utils/subset_data_dir_tr_cv.sh $dir ${dir}_tr90 ${dir}_cv10 || exit 1
fi

if [ $stage -le 1 ]; then
  # Pre-train DBN, i.e. a stack of RBMs (small database, smaller DNN)
  dir=exp/dnn4b_pretrain-dbn
  (tail --pid=$$ -F $dir/log/pretrain_dbn.log 2>/dev/null)& # forward log
  $cuda_cmd $dir/log/pretrain_dbn.log \
    steps/nnet/pretrain_dbn.sh --hid-dim 1024 --rbm-iter 20 $data_fmllr/train $dir || exit 1;
fi

if [ $stage -le 2 ]; then
  # Train the DNN optimizing per-frame cross-entropy.
  dir=exp/dnn4b_pretrain-dbn_dnn
  ali=${gmmdir}_ali
  feature_transform=exp/dnn4b_pretrain-dbn/final.feature_transform
  dbn=exp/dnn4b_pretrain-dbn/6.dbn
  (tail --pid=$$ -F $dir/log/train_nnet.log 2>/dev/null)& # forward log
  # Train
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --feature-transform $feature_transform --dbn $dbn --hid-layers 0 --learn-rate 0.008 \
    $data_fmllr/train_tr90 $data_fmllr/train_cv10 lang $ali $ali $dir || exit 1;
  # Decode (reuse HCLG graph)
  steps/nnet/decode.sh --nj 4 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.1 \
    $gmmdir/graph $data_fmllr/test $dir/decode_test || exit 1;
  #steps/nnet/decode.sh --nj 4 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.1 \
  #  $gmmdir/graph_ug $data_fmllr/test $dir/decode_ug || exit 1;
fi


# Sequence training using sMBR criterion, we do Stochastic-GD 
# with per-utterance updates. We use usually good acwt 0.1
dir=exp/dnn4b_pretrain-dbn_dnn_smbr
srcdir=exp/dnn4b_pretrain-dbn_dnn
acwt=0.1

if [ $stage -le 3 ]; then
  # First we generate lattices and alignments:
  steps/nnet/align.sh --nj 4 --cmd "$train_cmd" \
    $data_fmllr/train lang $srcdir ${srcdir}_ali || exit 1;
  steps/nnet/make_denlats.sh --nj 4 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt $acwt \
    $data_fmllr/train lang $srcdir ${srcdir}_denlats || exit 1;
fi

if [ $stage -le 4 ]; then
  # Re-train the DNN by 6 iterations of sMBR 
  steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 6 --acwt $acwt --do-smbr true \
    $data_fmllr/train lang $srcdir ${srcdir}_ali ${srcdir}_denlats $dir || exit 1
  # Decode
  for ITER in 1 2 3 4 5 6; do
    steps/nnet/decode.sh --nj 4 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      $gmmdir/graph $data_fmllr/test $dir/decode_it${ITER} || exit 1
    #steps/nnet/decode.sh --nj 4 --cmd "$decode_cmd" --config conf/decode_dnn.config \
    #  --nnet $dir/${ITER}.nnet --acwt $acwt \
    #  $gmmdir/graph_ug $data_fmllr/test $dir/decode_ug_it${ITER} || exit 1
  done 
fi

echo Success
exit 0

# Getting results [see RESULTS file]
# for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done

# Showing how model conversion to nnet2 works; note, we use the expanded variable
# names here so be careful in case the script changes.
# steps/nnet2/convert_nnet1_to_nnet2.sh exp/dnn4b_pretrain-dbn_dnn exp/dnn4b_nnet2
# cp exp/tri3b/splice_opts exp/tri3b/cmvn_opts exp/tri3b/final.mat exp/dnn4b_nnet2/
# 
#  steps/nnet2/decode.sh --nj 4 --cmd "$decode_cmd" --transform-dir exp/tri3b/decode_test \
#    --config conf/decode.config exp/tri3b/graph data/test exp/dnn4b_nnet2/decode_test

# decoding results are essentially the same (any small difference is probably because
# decode.config != decode_dnn.config).
# %WER 1.58 [ 198 / 12533, 22 ins, 45 del, 131 sub ] exp/dnn4b_nnet2/decode/wer_3
# %WER 1.59 [ 199 / 12533, 23 ins, 45 del, 131 sub ] exp/dnn4b_pretrain-dbn_dnn/decode/wer_3
