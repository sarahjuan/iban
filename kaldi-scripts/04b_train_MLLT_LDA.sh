#!/bin/sh

. ./00_init_paths.sh  || die "00_init_paths.sh expected";
# LDA+MLLT

steps/align_si.sh  --nj 4  data/train lang exp/tri2a exp/tri2a_ali
steps/train_lda_mllt.sh   --splice-opts "--left-context=3 --right-context=3"   4200 40000 data/train lang  exp/tri2a_ali exp/tri2b
utils/mkgraph.sh lang  exp/tri2b exp/tri2b/graph
steps/decode.sh --nj 4  exp/tri2b/graph  data/test exp/tri2b/decode_test

