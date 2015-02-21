#!/bin/sh
#To prepare the lang/ materials
. 00_init_paths.sh 

touch lang/dict/extra_questions.txt

# remove the lexiconp.txt file if exist, else it won't be updated
rm lang/dict/lexiconp.txt

# create lexicon.txt (if doesn't exist in the lang/) from an existing pronunciation dictionary $LEXICON
#+ add silence entries into the lexicon + add <UNK> with a "garbage" phone

#lexicon.txt and nonsilence_phones.txt are available

echo "SIL" >  lang/dict/optional_silence.txt
echo "<UNK>" > lang/oov.txt
echo "SIL" >> lang/dict/silence_phones.txt

# check if everything's ok
utils/prepare_lang.sh lang/dict/ "<UNK>" lang/tmp/ lang/
