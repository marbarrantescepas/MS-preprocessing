#!/bin/bash

#Below block for SLURM users. If you are not a SLURM user, remove this block 
#and change below references to SLURM for parallel processing. 
#SBATCH --job-name=preproc       	#a name for your job
#SBATCH --mem=6G                    	#max memory per node
#SBATCH --partition=luna-cpu-short    	#using luna short queue
#SBATCH --cpus-per-task=4      	      	#max CPU cores per process
#SBATCH --time=00:15:00                	#time limit (DD-HH:MM)
#SBATCH --nice=4000                   	#allow other priority jobs to go first
#SBATCH --qos=anw-cpu                 	#use anw-cpu's
#SBATCH --array=1-XX%YY			#first-last%parallel subj
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out

#======================================================================
#PREPROCESSING PRIOR TO NICMS (N4, SKULL-STRIPPING, flair to T1 space)
#======================================================================

#@author: samantha noteboom, mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated; 27 January 2025, works
#to-do: simplify usage 

#Description: 
# Input: Folder includying T1w and FLAIR scans in BIDS. 
# Output: T1w and FLAIR scans N4 bias field corrected, brain mask and 
# T1w and FLAIR scans N4 bias field corrected + skull stripped in T1w 
# space. 
# Run: It performs N4 bias field correction in T1w and FLAIR independently, 
# obtains brain mask in T1w sapce, registers FLAIR to T1w space and applies 
# brain mask to FLAIR to obtain a masked FLAIR. 

#Requirements:
# 1. Please install FSL, ANTS, and HD-BET, if they are not already in your
# system. 

# 2. Before use of these scripts, data should be organised in BIDS format, 
# learn more: https://bids.neuroimaging.io/ 

# Please modify the following things before running:
# -array: change according the number of participants in the study (line 12)
# -module load. adapt to your system (line 47)
# -projectfolder: change your input folder, needs to be in BIDS format (line 50)
#----------------------------------------------------------------------

# load modules
module load ANTs/2.4.1             #for registration and N4 bias field

# Define input directories anc create outputdir
curdir=`pwd`
projectfolder=/path/to/your/folder		#please modify 
rawdata=${projectfolder}/rawdata
nicmsdir=${projectfolder}/derivatives/pre-nicms
mkdir -p $nicmsdir

# To use array parallel processing, you create a .txt file with a list of all the subject folders.
cd ${rawdata}
ls -d sub-*/ | sed 's:/.*::' > ${curdir}/subjects_pre-nicms.txt
subjectid=$(sed "${SLURM_ARRAY_TASK_ID}q;d"  ${curdir}/subjects_pre-nicms.txt)
cd ${curdir}

# run preprocessing for all sessions of a subject
subject_dir=${rawdata}/$subjectid
list_ses=($basename -a $(ls -d -1 $(subject_dir/ses-*)))

for ses in ${list_ses[@]}; do
       
	sessionid=${ses##/*/}
	echo "Starting processing $subjectid $sessionid"
	
	# Define directories and input files
	session_dir=${subject_dir}/${sessionid}
	t1=${session_dir}/anat/${subjectid}_${sessionid}_T1w.nii.gz
	flair=${session_dir}/anat/${subjectid}_${sessionid}_FLAIR.nii.gz

 	# Detect if required input files are present
	if [ -e ${t1} ] && [ -e ${flair} ]; then
		outputdir=${nicmsdir}/${subjectid}/${sessionid}
		mkdir -p ${outputdir}
	else
		echo "No t1 and flair available"
	fi
	
	# Define output directories and files
	t1_N4=${outputdir}/${subjectid}_${sessionid}_T1w_N4.nii.gz
	t1_N4_bias=${outputdir}/${subjectid}_${sessionid}_T1w_N4_bias.nii.gz
	flair_N4=${outputdir}/${subjectid}_${sessionid}_FLAIR_N4.nii.gz
	flair_N4_bias=${outputdir}/${subjectid}_${sessionid}_FLAIR_N4_bias.nii.gz
	
	t1_brain=${outputdir}/${subjectid}_${sessionid}_T1w_N4_brain.nii.gz
	flair_t1_prefix=${outputdir}/${subjectid}_${sessionid}_FLAIR_N4_to_T1w_N4_
	flair_t1=${flair_t1_prefix}Warped.nii.gz
	flair_t1_brain=${outputdir}/${subjectid}_${sessionid}_FLAIR_to_T1w_N4_brain.nii.gz
	brain_mask=${outputdir}/${subjectid}_${sessionid}_T1w_N4_brain_mask.nii.gz
	
	#N4 bias field correction and skull stripping
	if [ -e ${outputdir} ]  && [ ! -e ${flair_t1_brain} ]; then
		if [ ! -e ${t1_N4} ]; then 
			echo "Performing N4 biasfield correction..."
			N4BiasFieldCorrection -d 3 -v 1 -s 4 -b [ 180 ] -c [ 50x50x50x50, 0.0 ] \
			-i $t1 -o [ ${t1_N4}, ${t1_N4_bias} ]
	
			N4BiasFieldCorrection -d 3 -v 1 -s 4 -b [ 180 ] -c [ 50x50x50x50, 0.0 ] \
			-i $flair -o [ ${flair_N4}, ${flair_N4_bias} ]
		fi 
	
		## Run HD-BET to obtain brain + brain mask 
		if [ ! -e ${t1_brain} ]; then 
			echo "Performing hd-bet..."
			/opt/aumc-containers/singularity/hd-bet/hd-bet_v20220401.sif -i ${t1_N4} -o ${t1_brain} -s 1 -device cpu -mode fast -tta 0
		fi 
	
		## Register FLAIR to T1 and apply to brain_mask
		if [ ! -e ${flair_t1_brain} ]; then 
  
			antsRegistrationSyN.sh -d 3 -f ${t1_N4} -m ${flair_N4} -o ${flair_t1_prefix} -t a
			fslmaths ${flair_t1} -mas ${brain_mask} ${flair_t1_brain}
		
		fi
	fi
done;

#----------------------------------------------------------------------
# References
#----------------------------------------------------------------------
#M. Jenkinson, C.F. Beckmann, T.E. Behrens, M.W. Woolrich, S.M. Smith. FSL. NeuroImage, 62:782-90, 2012
#Isensee F, Schell M, Pflueger I, et al. Automated brain extraction of multisequence MRI using artificial neural networks. Hum Brain Mapp. 2019;40(17):4952-4964. doi:10.1002/hbm.24750
#https://github.com/ANTsX/ANTs
