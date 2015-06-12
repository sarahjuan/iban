#!/bin/bash
# To create G.fst from ARPA language model
. ./path.sh || die "path.sh expected";

cd data
#convert to FST format for Kaldi
cat local/iban-lm-o3.arpa | ../utils/find_arpa_oovs.pl lang/words.txt  > lang/oovs.txt
cat local/iban-lm-o3.arpa |    \
    grep -v '<s> <s>' | \
    grep -v '</s> <s>' | \
    grep -v '</s> </s>' | \
    arpa2fst - | fstprint | \
    ../utils/remove_oovs.pl lang/oovs.txt | \
    ../utils/eps2disambig.pl | ../utils/s2eps.pl | fstcompile --isymbols=lang/words.txt \
      --osymbols=lang/words.txt  --keep_isymbols=false --keep_osymbols=false | \
     fstrmepsilon | fstarcsort --sort_type=ilabel > lang/G.fst

exit 0;
