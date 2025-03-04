#!/bin/bash

#Below block for SLURM users. If you are not a SLURM user, remove this block 
#and change below references to SLURM for parallel processing. 
#SBATCH --job-name=postnicms        	#a name for your job
#SBATCH --mem=1G                    	#max memory per node
#SBATCH --partition=luna-cpu-short    	#using luna short queue
#SBATCH --cpus-per-task=4      	      	#max CPU cores per process
#SBATCH --time=00:15:00                	#time limit (DD-HH:MM)
#SBATCH --nice=4000                   	#allow other priority jobs to go first
#SBATCH --qos=anw-cpu                 	#use anw-cpu's
#SBATCH --array=1-XX%YY			        #first-last%parallel subj
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out

#======================================================================
# reorganise output nicms, threshold probability maps 
#======================================================================

#@author: samantha noteboom, mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated; 03 February 2025, works
#to-do: simplify usage 

#Description: 
# Input: folder containing files derived from nicms
# Output: Input files are are reorganized for subsequent steps. Then
# binary T2FLAIR lesion masks are obtained from thresholding and removing clusters 
# that contain less than 5 voxels.  
# Run: It copies old output, thresholds, removes clusters and binarises the lesion mask.

#Requirements:
# 1. Please install FSL, if they are not already in your system.  

# Please modify the following things before running:
# -array: change according the number of participants study
# -projectfolder: change your input folder, where nicms output is stored
# -postnicmsdir: change output folder where to store the data. 
#----------------------------------------------------------------------

#load modules 
module load fsl/6.0.5.1

# Define input directories and create outputdir
curdir=`pwd`
projectfolder=/path/to/your/output/nicms/folder		    #please modify 
postnicmsdir=/path/to/your/output/postnicms/folder		#please modify 
mkdir -p $postnicms

# To use array parallel processing, you create a .txt file with a list of each subject folder.
cd ${projectolder}
ls -d sub-*/ | sed 's:/.*::' > ${curdir}/subjects_post-nicms.txt
subjectid=$(sed "${SLURM_ARRAY_TASK_ID}q;d"  ${curdir}/subjects_post-nicms.txt)
cd ${curdir}

# run postnicms for all sessions of a subject
subject_dir=${projectfolder}/$subjectid
list_ses=($basename -a $(ls -d -1 $(subject_dir/ses-*)))

for ses in ${list_ses[@]}; do

    sessionid=${sessdir##/*/}
    echo "Starting processing $subjectid $sessionid"
    
    indir=${projectfolder}/${subjectid}_${sessionid}/ms112_mweeda_full_nicmslesions
    lesion_old=$indir/ms112_mweeda_full_nicmslesions_prob_1.nii.gz

    outdir=${postnicmsdir}/${subjectid}/${sessionid}
    lesion_new=$outdir/${subjectid}_${sessionid}_ms112_mweeda_full_nicmslesions_prob_1.nii.gz
    
    if [ ! -e $lesion_new ] && [ -e $lesion_old ]; then
        echo "Copying $lesion_old $lesion_new..."
        mkdir -p $outdir
        cp $lesion_old $lesion_new
    fi 

    lesion=$outdir/${subjectid}_${sessionid}_ms112_mweeda_full_nicmslesions_prob_1
    # binarise mask by thresholding for prob 0.4 and removing cluster < 5 voxels. 
    if [ -e $lesion_new ] && [ ! -e ${lesion}_thr04_c5.nii.gz ]; then
        fslmaths ${lesion}.nii.gz -thr 0.4 -bin ${lesion}_thr04.nii.gz #threshold mask 0.4 
        cluster -i ${lesion}_thr04.nii.gz -t 1 -o ${lesion}_thr04_cluster_index --osize=${lesion}_thr04_cluster_size
        fslmaths ${lesion}_thr04_cluster_size -thr 5 -bin ${lesion}_thr04_c5.nii.gz
    fi
done
