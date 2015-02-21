#!/bin/sh
# Copyright 2015 Sarah Samson Juan
#
# To prepare data into Kaldi format

if [ -f path.sh ]; then . path.sh; fi


srcdir=data


echo "Prepare text, spk2utt, utt2spk files for $TRAIN_DIR $EXP_DIR"

for x in train test; do
  mkdir -p data/$x
  cp $srcdir/${x}_wav.scp data/$x/wav.scp || exit 1;
  cp $srcdir/${x}_text data/$x/text || exit 1;
  cp $srcdir/$x.spk2utt data/$x/spk2utt || exit 1;
  cp $srcdir/$x.utt2spk data/$x/utt2spk || exit 1;
done

echo "Prepare pronunciation dictionary"

[ ! -f lang/dict/lexicon.txt ||  lang/dict/nonsilence_phones.txt] && echo lang/dict has no lexicons! && exit 1;

touch lang/dict/extra_questions.txt
# remove the lexiconp.txt file if exist, else it won't be updated
rm lang/dict/lexiconp.txt
echo "SIL" >  lang/dict/optional_silence.txt
echo "<UNK>" > lang/oov.txt
echo "SIL" >> lang/dict/silence_phones.txt

# check if data is OK!
utils/prepare_lang.sh lang/dict/ "<UNK>" lang/tmp/ lang/
