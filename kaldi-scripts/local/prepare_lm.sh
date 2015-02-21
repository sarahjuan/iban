#!/bin/sh
# Copyright 2015 Sarah Samson Juan
# To create G.fst from ARPA language model 

if [ -f path.sh ]; then . path.sh; fi

arpa_lm=LM/iban-lm-o3.arpa.tar.gz
[ ! -f $arpa_lm ] && echo No such file $arpa_lm && exit 1


#convert to FST format for Kaldi
gunzip "$arpa_lm" | ./utils/find_arpa_oovs.pl lang/words.txt  > LM/oovs.txt
cat "$arpa_lm" |    \
    grep -v '<s> <s>' | \
    grep -v '</s> <s>' | \
    grep -v '</s> </s>' | \
    arpa2fst - | fstprint | \
    utils/remove_oovs.pl LM/oovs.txt | \
    utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=lang/words.txt \
      --osymbols=lang/words.txt  --keep_isymbols=false --keep_osymbols=false | \
     fstrmepsilon | fstarcsort --sort_type=ilabel > lang/G.fst

utils/validate_lang.pl data/lang || exit 1;

exit 0;
