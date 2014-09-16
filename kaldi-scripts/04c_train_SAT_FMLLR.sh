#!/bin/sh
# decoding stage will present two results ; decode_test_si and decode_test in tri3b folder. decode_test_si gives results with SAT and decode_test gives results with SAT and fMLLR applied 

. ./00_init_paths.sh  || die "00_init_paths.sh expected";



steps/align_si.sh  --nj 4 --use-graphs true data/train lang exp/tri2b exp/tri2b_ali
steps/train_sat.sh 4200 40000 data/train lang exp/tri2b_ali exp/tri3b 
utils/mkgraph.sh lang  exp/tri3b exp/tri3b/graph
steps/decode_fmllr.sh --nj 4  exp/tri3b/graph  data/test exp/tri3b/decode_test

steps/align_fmllr.sh --nj 4 data/train lang exp/tri3b exp/tri3b_ali


