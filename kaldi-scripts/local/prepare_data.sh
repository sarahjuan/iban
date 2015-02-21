#!/bin/sh


echo "make text, segments, spk2utt, utt2spk files for $TRAIN_DIR $EXP_DIR"

####build text file########


####build segments file#######

#####build utt2spk file and spk2utt ##########

##Compute MFCC
###first create the file wav.scp in train and test directories

###compute MFCC
pushd /home/samson/Kaldi-System/Iban-Hybrid
steps/make_mfcc.sh --nj 4 data/train data/log  mfcc
steps/compute_cmvn_stats.sh data/train data/log mfcc
steps/make_mfcc.sh --nj 4 data/test data/log  mfcc
steps/compute_cmvn_stats.sh data/test data/log mfcc
popd
#end compute MFCC















