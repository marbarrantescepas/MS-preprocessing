#!/bin/bash

#@author: samantha noteboom, mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated; 27 January 2025, works
#to-do: finish description, change folder structure + name, simplify usage 

#Description: 
# Input:
# Output: 
# Run: 

#Requirements:

#Please modify the following things before running:

#----------------------------------------------------------------------
#Input folder
archive=/home/anw/snoteboom/my-scratch/appsms/nicms
archive_nicms=/home/anw/snoteboom/my-scratch/appsms/appsms_david_N4
mkdir -p ${archive_nicms}

for dir in ${archive}/${prefix}*; do
    subjectid=${dir##/*/}
    echo "${subjectid}"
    for sessdir in ${dir}/*; do
        sess=${sessdir##/*/}
        echo ${sess}
        newdir=${archive_nicms}/${subjectid}_${sess}
        echo $newdir
        if [ -e $sessdir/preproc_nicms/${subjectid}_${sess}_T1w_N4_brain.nii.gz ]; then
            mkdir -p $newdir
            echo "$sessdir"
            echo "cp $sessdir/preproc_nicms/*brain.nii.gz $newdir/ "
            cp $sessdir/preproc_nicms/*brain.nii.gz $newdir/
        fi 
    done;
done;


