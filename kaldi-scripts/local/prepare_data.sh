#!/bin/sh
# Copyright 2015 Sarah Samson Juan
# 

if [ -f path.sh ]; then . path.sh; fi

echo "make text, spk2utt, utt2spk files for $TRAIN_DIR $EXP_DIR"

srcdir=data
lexicon=lang/dict/lexicon.txt

echo "make text, spk2utt, utt2spk files for $TRAIN_DIR $EXP_DIR"

for x in train test; do
  mkdir -p data/$x
  cp $srcdir/${x}_wav.scp data/$x/wav.scp || exit 1;
  cp $srcdir/${x}_text data/$x/text || exit 1;
  cp $srcdir/$x.spk2utt data/$x/spk2utt || exit 1;
  cp $srcdir/$x.utt2spk data/$x/utt2spk || exit 1;
done
