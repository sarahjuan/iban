#!/bin/sh

#Use NIST-sclite to evaluate decoding results. You must have sctk-2.4.0 installed.

#Prepare REF file for sclite. Refer 'trn' format from nist website 

echo "make reference text" 
cd data/test
#iban_test.transcription was in this format : <s> sentence </s> (SPK_ID)
cat iban_test.transcription | sed 's/<s> //g' | sed 's/ <\/s>//g' > iban_test.ref
cd ../

#hyp files
cd exp
echo "make hypotheses for MONO, TRI and TRI+DELTA+DELTA TRI+DELTA+DELTA+MLTT+LDA" 
for type in mono tri1 tri2a tri2b
do 
    cd $type/decode_test/scoring

    for i in 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
    do 
        cat $i.tra | utils/int2sym.pl -f 2- ../../graph/words.txt > tmp_$type-$i
        cat tmp_$type-$i | sed 's/ib*.*\_[0-9][0-9][0-9] //g' > tmp_$type-line-$i
        cat tmp_$type-$i | sed 's/ [a-z]*.*//' > tmp_$type-ids-$i
        paste tmp_$type-line-$i tmp_$type-ids-$i > tmp_$type-$i_hyp
        cat tmp_$type-$i_hyp | sed 's/\t/(/g' | sed 's/$/\)/g' | sed 's/ibm_/ibm/g' | sed 's/ibf_/ibf/g' > results_$type-$i.hyp  #in scoring folder
    done
    rm tmp_*
    echo "$type hyp done"
    cd ../../../
done    

echo "make hypotheses for SAT+fMLLR"
#decode_test_si is first PASS
#decode_test is SAT+fMLLR applied

cd tri3b
for type in decode_test.si decode_test
do
    cd $type/scoring
    for i in 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
    do
        #######important
        cat $i.tra | utils/int2sym.pl -f 2- ../../graph/words.txt > tmp_$type-$i
        cat tmp_$type-$i | sed 's/ib*.*\_[0-9][0-9][0-9] //g' > tmp_$type-line-$i
        cat tmp_$type-$i | sed 's/ [a-z]*.*//' > tmp_$type-ids-$i
        paste tmp_$type-line-$i tmp_$type-ids-$i > tmp_$type-$i_hyp
        cat tmp_$type-$i_hyp | sed 's/\t/(/g' | sed 's/$/\)/g' | sed 's/ibm_/ibm/g' | sed 's/ibf_/ibf/g' > results_$type-$i.hyp  #in scoring folder   
    done
    rm tmp_*
    echo "$type hyp done"
    cd ../../
done

cd ../

echo "run sclite"

#run sclite for evaluation

for type in mono tri1 tri2a tri2b
do 
    cd $type/decode_test/scoring
    mkdir sclite_results
    for i in 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
    do
        mv results_$type-$i.hyp sclite_results/
        $KALDI_DIR/tools/sctk-2.4.0/src/sclite/sclite -r data/test/iban_test.ref -h sclite_results/results_$type-$i.hyp -i spu_id -o all
    done
    cd ../../../
done

#tri3b; SAT and SAT+MLLR
cd tri3b
for type in decode_test.si decode_test
do
    cd $type/scoring
    mkdir sclite_results
    for i in 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
    do
        mv results_$type-$i.hyp sclite_results/
        $KALDI_DIR/tools/sctk-2.4.0/src/sclite/sclite -r $WORK_DIR/data/test/iban_test.ref -h sclite_results/results_$type-$i.hyp -i spu_id -o all
    done
    cd $WORK_DIR/exp/tri3b
done

cd $WORK_DIR

echo "You can check outputs in scoring/sclite_results"
#compile sys results 

echo "Compile .sys results"

#MONO, TRI and TRI+DELTA+DELTA TRI+DELTA+DELTA+MLTT+LDA#
for type in mono tri1 tri2a tri2b
do
    cat exp/$type/decode_test/scoring/sclite_results/results_$type-*.hyp.sys > exp/$type/decode_test/scoring/sclite_results/results_$type-all.hyp.sys
done


#tri3b; SAT and SAT+MLLR
for type in decode_test.si decode_test
do 
    cat exp/tri3b/$type/scoring/sclite_results/results_$type-*.hyp.sys > exp/tri3b/$type/scoring/sclite_results/results_$type-all.hyp.sys
done

