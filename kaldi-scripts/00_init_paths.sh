#!/bin/sh


DATA_DIR=/home/samson/Kaldi-System/Iban-Hybrid/data
WORK_DIR=/home/samson/Kaldi-System/Iban-Hybrid
KALDI_DIR=/home/samson/Kaldi-System/kaldi-trunk   ##download and install kaldi-trunk from KALDI website
LEXICON=iban0413.dic
EXP_DIR="test"
TRAIN_DIR="train"

PATH=$PATH:./:$KALDI_DIR/src/bin:$KALDI_DIR/src/gmmbin:$KALDI_DIR/src/latbin:$KALDI_DIR/src/featbin:$KALDI_DIR/tools/openfst-1.3.2/bin:$KALDI_DIR/src/fstbin:$WORK_DIR/utils:$WORK_DIR/steps:$KALDI_DIR/src/sgmmbin/:$KALDI_DIR/src/fgmmbin:$KALDI_DIR/src/sgmm2bin:/home/Toolkits/Kaldi/kaldi-trunk/src/nnet-cpubin/:

export PATH
export LC_ALL=C

cd $WORK_DIR


