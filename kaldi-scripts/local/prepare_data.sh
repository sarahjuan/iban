#!/bin/bash
if [[ $1 && $2 ]]; then
	
	local=`pwd`/local
		
	mkdir -p data data/local data/$1 data/$2

	echo "Preparing train and test data"

	rm -rf data/mfcc data/log
	
	cd asr_iban/data
	
	echo "Copy spk2utt, utt2spk, wav.scp, text for $1 $2"

    for x in train test; do
        mkdir -p $x
        cp $x/${x}_wav.scp ../../data/$x/wav.scp || exit 1;
        cp $x/${x}_text ../../data/$x/text || exit 1;
        cp $x/${x}_spk2utt ../../data/$x/spk2utt || exit 1;
        cp $x/${x}_utt2spk ../../data/$x/utt2spk || exit 1;
    done
	
	pushd ../../data/local
        echo "Find language model"
	if [ ! -f  "iban-lm-o3.arpa" ]; then
		cd ../../asr_iban/LM
		tar -zxvf iban-lm-o3.arpa.tar.gz -C ../../data/local/
	fi
	popd		
	
	echo "Data preparation completed."
	
	cd ../..
else
        echo "ERROR: Preparing train and test data failed !"
        echo "You must have forgotten to precise train test directories"
        echo "Usage: local/prepare_data.sh train test"
fi
