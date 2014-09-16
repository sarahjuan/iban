#!/bin/sh
#To prepare the lang/ materials
. 00_init_paths.sh 

touch lang/dict/extra_questions.txt

# remove the lexiconp.txt file if exist, else it won't be updated
rm lang/dict/lexiconp.txt

# create lexicon.txt (if doesn't exist in the lang/) from an existing pronunciation dictionary $LEXICON
cat $WORK_DIR/$LEXICON > lang/dict/lexicon.txt
#+ add silence entries into the lexicon + add <UNK> with a "garbage" phone

echo "SIL" >  lang/dict/optional_silence.txt
echo "<UNK>" > lang/oov.txt
echo "SIL" >> lang/dict/silence_phones.txt
cp $WORK_DIR/$PHONES  nonsilence_phones.txt #speech phones

utils/prepare_lang.sh lang/dict/ "<UNK>" lang/tmp/ lang/
