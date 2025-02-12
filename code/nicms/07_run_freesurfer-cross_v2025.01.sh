#!/bin/bash

#SBATCH --job-name=FS-cross     	#a convenient name for your job
#SBATCH --mem=8G                     	#max memory per node 
#SBATCH --partition=luna-cpu-long   	#using luna short queue
#SBATCH --cpus-per-task=8             	#max CPU cores per process
#SBATCH --time=18:00:00                	#time limit (DD-HH:MM)
#SBATCH --nice=4000                   	#allow other priority jobs to go first
#SBATCH --qos=anw-cpu                 	#use anw-cpu's
#SBATCH --array=1-XX%YY			 #first-last%parallel subj
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out

#======================================================================
#  FREESURFER CROSS-SECTIONAL
#======================================================================
#@author: samantha noteboom, mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated; 03 february 2025, works
#to-do: simplify usage, add hd-bet mask as input, finish slides

#Description: 
# Input: T1w filled 
# Output: FreeSurfer files.
# Run: 

#Requirements:
# 1. Please install FreeSurfer if not already install in your system.

# Please modify the following things before running:
# -array: change according the number of participants study
# -projectfolder: change your input folder, needs to be in BIDS format 
#----------------------------------------------------------------------

# load modules
module load FreeSurfer/7.3.2-centos8_x86_64

# Define paths to data 
curdir=`pwd`
projectfolder=/path/to/project/folder
rawdata=${projectfolder}/rawdata
nicmsdir=${projectfolder}/derivatives/nicms
fsdir=${projectfolder}/derivatives/freesurfer

# To use array parallel processing, create a .txt file with a list of each subject folder.
cd ${nicmsdir}
ls -d sub-*/ | sed 's:/.*::' > ${curdir}/subjects-freesurfer.txt
subjectid=$(sed "${SLURM_ARRAY_TASK_ID}q;d" ${curdir}/subjects-freesurfer.txt)
cd ${curdir}

# run preprocessing for all sessions of a subject
subject_dir=${nicmsdir}/$subjectid
list_ses=($basename -a $(ls -d -1 $(subject_dir/ses-*)))

for ses in ${list_ses[@]}; do

	sessionid=${ses##/*/}
        session_dir=${subject_dir}/${sessionid}
	echo "Starting processing $subjectid $sessionid"

	t1_filled=${nicdir}/$subjectid/$sessionid/${subjectid}_${sessionid}_T1w_filled.nii.gz
	t1_raw=${rawdata}/${subjectid}/${sessionid}/${subjectid}_${sessionid}_T1w.nii.gz
 
	SUBJECTS_DIR=${fsdir}/${subjectid}
	mkdir -p ${SUBJECTS_DIR}
	echo $SUBJECTS_DIR
 
	if [ -e $t1_filled ]; then
		t1=${t1_filled}
	else 
		t1=${t1_raw}
	fi 

	if [ ! -e ${SUBJECTS_DIR}/$sessionid ] && [ -e ${t1} ]; then
		echo "Start running recon-all ${SUBJECTS_DIR}/${sessionid}"
		recon-all -subjid ${sess} -i ${t1} -all
	fi

done 
