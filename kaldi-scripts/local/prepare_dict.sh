#!/bin/bash

mkdir -p data/lang data/local/dict

cat asr_iban/lang/dict/lexicon.txt | sed '1,2d' > data/local/dict/lexicon_words.txt

cp asr_iban/lang/dict/lexicon.txt data/local/dict/.
cp asr_iban/lang/dict/nonsilence_phones.txt data/local/dict/.

touch data/local/dict/extra_questions.txt
touch data/local/dict/optional_silence.txt

echo "SIL" > data/local/dict/optional_silence.txt
echo "SIL" > data/local/dict/silence_phones.txt
echo "<UNK>" > data/lang/oov.txt

echo "Dictionary preparation succeeded"
