#!/bin/sh
. ./00_init_paths.sh


#We use a LM with %PPL=158 
#To create G.fst from ARPA language model 


#convert to FST format for Kaldi
cat ./LM/Oct2013/iban-lm-o3.arpa | ./utils/find_arpa_oovs.pl lang/words.txt  > LM/oovs.txt
cat ./LM/Oct2013/iban-lm-o3.arpa |    \
    grep -v '<s> <s>' | \
    grep -v '</s> <s>' | \
    grep -v '</s> </s>' | \
    $KALDI_DIR/src/bin/arpa2fst - | $KALDI_DIR/tools/openfst-1.3.2/bin/fstprint | \
    utils/remove_oovs.pl LM/oovs.txt | \
    utils/eps2disambig.pl | utils/s2eps.pl | $KALDI_DIR/tools/openfst-1.3.2/bin/fstcompile --isymbols=lang/words.txt \
      --osymbols=lang/words.txt  --keep_isymbols=false --keep_osymbols=false | \
     $KALDI_DIR/tools/openfst-1.3.2/bin/fstrmepsilon > ./LM/G.fst

