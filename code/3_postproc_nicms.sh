#!/bin/bash

module load fsl/6.0.5.1

#Input folder
archive=/home/anw/snoteboom/my-scratch/appsms/nicms
archive_nicms=/home/anw/snoteboom/my-scratch/appsms_nicms_N4_output
prefix=sub-AMS

# Organize lesion data to folders
for dir in ${archive}/${prefix}*; do
    subjectid=${dir##/*/}
    echo "${subjectid}"
    for sessdir in ${dir}/*; do
        sess=${sessdir##/*/}
        echo ${sess}
        mkdir -p $sessdir/nicms
        newdir=${archive_nicms}/${subjectid}_${sess}/ms112_mweeda_full_nicmslesions
        lesion_old=$newdir/ms112_mweeda_full_nicmslesions_prob_1.nii.gz
        lesion_new=$sessdir/nicms/${subjectid}_${sess}_ms112_mweeda_full_nicmslesions_prob_1.nii.gz
        echo $newdir
        if [ ! -e $lesion_new ] && [ -e $lesion_old ]; then
            echo "$sessdir"
            echo "cp $lesion_old $lesion_new"
            cp $lesion_old $lesion_new
        fi 

        lesion=$sessdir/nicms/${subjectid}_${sess}_ms112_mweeda_full_nicmslesions_prob_1

        if [ -e $lesion_new ] && [ ! -e ${lesion}_thr04_c5.nii.gz ]; then
            # Threshold mask 0.4 
            fslmaths ${lesion}.nii.gz -thr 0.4 -bin ${lesion}_thr04.nii.gz

            # Threshold clusters mask on 5 voxels
            cluster -i ${lesion}_thr04.nii.gz -t 1 -o ${lesion}_thr04_cluster_index --osize=${lesion}_thr04_cluster_size
            fslmaths ${lesion}_thr04_cluster_size -thr 5 -bin ${lesion}_thr04_c5.nii.gz
        fi
    done;
done;


