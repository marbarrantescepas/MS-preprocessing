#!/bin/bash

#SBATCH --job-name=freesurfer     		#a convenient name for your job
#SBATCH --mem=8G                     	#max memory per node --> around 3 GB for this task
#SBATCH --partition=luna-cpu-long   	#using luna short queue
#SBATCH --cpus-per-task=8             	#max CPU cores per process
#SBATCH --time=18:00:00                	#time limit (DD-HH:MM)
#SBATCH --nice=4000                   	#allow other priority jobs to go first
#SBATCH --qos=anw-cpu                 	#use anw-cpu's
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out
#SBATCH --array=1-20%20

# Load modules
module load FreeSurfer/7.3.2-centos8_x86_64

# Define paths to data 
curdir=`pwd`
#dir=/home/anw/snoteboom/my-scratch/programs-bids
dir=/data/anw/anw-gold/KNW/m.barrace/programs/programs-bids
bidsdir=${dir}/rawdata

der=/home/anw/mbarrantescepas/my-scratch/prograMS/freesurfer_round4
nicdir=${der}/derivatives/nicms
fsdir=${der}/derivatives/freesurfer

# To use array parallel processing, you create a .txt file with a list of each subject folder.
cd ${nicdir}
ls -d sub-*/ | sed 's:/.*::' > ${curdir}/subjects-fs4_${sess}.txt
subjid=$(sed "${SLURM_ARRAY_TASK_ID}q;d" ${curdir}/subjects-fs4_${sess}.txt)
cd ${curdir}

# Run lesion filling for all sessions
subdir=${nicdir}/${subjid}
for sessdir in ${subdir}/*; do
	echo $sessdir
	sess=${sessdir##/*/}
	echo $sess

	t1_filled=${nicdir}/$subjid/$sess/anat/${subjid}_${sess}_T1w_filled.nii.gz
	t1_bids=${bidsdir}/${subjid}/${sess}/anat/${subjid}_${sess}_T1w.nii.gz
	SUBJECTS_DIR=${fsdir}/${subjid}
#	mkdir -p ${SUBJECTS_DIR}
	echo $SUBJECTS_DIR

	if [ -e $t1_filled ]; then
		t1=${t1_filled}
	else 
		t1=${t1_bids}
	fi 

	if [ ! -e ${SUBJECTS_DIR}/$sess ] && [ -e ${t1} ]; then
		echo "Start running recon-all ${SUBJECTS_DIR}/${sess}"
		echo $sess
		#		recon-all -subjid ${sess} -i ${t1} -all
	fi

done 