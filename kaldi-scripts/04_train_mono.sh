#!/bin/sh
 
. ./00_init_paths.sh  || die "00_init_paths.sh expected";
  
# mono_phones ---> 


steps/train_mono.sh  --nj 4 data/train lang/ exp/mono
utils/mkgraph.sh --mono lang/ exp/mono exp/mono/graph
steps/decode.sh --nj 4  exp/mono/graph  data/test exp/mono/decode_test

