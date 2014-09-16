#!/bin/sh

. ./00_init_paths.sh  || die "00_init_paths.sh expected";



# triphones

steps/align_si.sh --boost-silence 1.25 --nj 4  data/train lang exp/mono exp/mono_ali
steps/train_deltas.sh --boost-silence 1.25  4200 40000 data/train lang exp/mono_ali exp/tri1
utils/mkgraph.sh lang  exp/tri1 exp/tri1/graph
steps/decode.sh --nj 4  exp/tri1/graph  data/test exp/tri1/decode_test

# triphones + delta delta

steps/align_si.sh  --nj 4  data/train lang exp/tri1 exp/tri1_ali
steps/train_deltas.sh  4200 40000 data/train lang exp/tri1_ali exp/tri2a
utils/mkgraph.sh lang/  exp/tri2a exp/tri2a/graph
steps/decode.sh --nj 4  exp/tri2a/graph  data/test exp/tri2a/decode_test

