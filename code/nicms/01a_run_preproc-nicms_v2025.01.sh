#!/bin/bash

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
#to-do: finish description, change folder structure + name, simplify usage 

#Description: 
# Input:
# Output: 
# Run: 

#Requirements:

#Please modify the following things before running:

#----------------------------------------------------------------------

# Load modules
module load ANTs/2.4.1                  #for registration and N4 bias field

# Define input directories anc create outputdir
curdir=`pwd`
dir=/path/to/your/folder
bidsdir=${dir}/bids_approved
outputdir=${dir}/nicms
mkdir -p outputdir

# To use array parallel processing, you create a .txt file with a list of each subject folder.
cd ${bidsdir}
ls -d sub-*/ | sed 's:/.*::' >subjects.txt
subjid=$(sed "${SLURM_ARRAY_TASK_ID}q;d" subjects.txt)
cd ${curdir}

#subjid=$1 # test 1 subject for debugging

# Run lesion filling for all sessions
subdir=${bidsdir}/$subjid

for sessdir in ${subdir}/*; do
        echo $sessdir
        sess=${sessdir##/*/}

		# Define directories and input files
		bidsdir=${sessdir}/anat
		t1=${bidsdir}/${subjid}_${sess}_T1w.nii.gz
		flair=${bidsdir}/${subjid}_${sess}_FLAIR.nii.gz

		# Define output directories and files
		workdir=${outputdir}/$subjid/$sess/preproc_nicms
		t1_N4=${workdir}/${subjid}_${sess}_T1w_N4.nii.gz
		t1_N4_bias=${workdir}/${subjid}_${sess}_T1w_N4_bias.nii.gz
		flair_N4=${workdir}/${subjid}_${sess}_FLAIR_N4.nii.gz
		flair_N4_bias=${workdir}/${subjid}_${sess}_FLAIR_N4_bias.nii.gz
		t1_brain=${workdir}/${subjid}_${sess}_T1w_N4_brain.nii.gz
		flair_t1_prefix=${workdir}/${subjid}_${sess}_FLAIR_N4_to_T1w_N4_
		flair_t1=${flair_t1_prefix}Warped.nii.gz
		flair_t1_brain=${workdir}/${subjid}_${sess}_FLAIR_to_T1w_N4_brain.nii.gz
		brain_mask=${workdir}/${subjid}_${sess}_T1w_N4_brain_mask.nii.gz

		if [ -e ${t1} ] && [ -e ${flair} ]; then
			mkdir -p ${workdir}
		else
			echo "No t1 and flair available"
		fi

		# Preproc for NICMS: N$ bias field correction and skull stripping
		if [ -e ${workdir} ]  && [ ! -e ${flair_t1_brain} ]; then

			## Run N4 bias field correction
			if [ ! -e ${t1_N4} ]; then 
				echo "Performing N4 biasfield correction..."
				N4BiasFieldCorrection -d 3 -v 1 -s 4 -b [ 180 ] -c [ 50x50x50x50, 0.0 ] \
  				-i $t1 -o [ ${t1_N4}, ${t1_N4_bias} ]

				N4BiasFieldCorrection -d 3 -v 1 -s 4 -b [ 180 ] -c [ 50x50x50x50, 0.0 ] \
  				-i $flair -o [ ${flair_N4}, ${flair_N4_bias} ]

			fi 


			## Run HD-BET to obtain WST brain + WST brain mask 
			if [ ! -e ${t1_brain} ]; then 
				echo "Performing hd-bet..."
				/opt/aumc-containers/singularity/hd-bet/hd-bet_v20220401.sif -i ${t1_N4} -o ${t1_brain} -s 1 -device cpu -mode fast -tta 0
			fi 

			## Register FLAIR to T1 and apply to brain_mask
			if [ ! -e ${flair_t1_brain} ]; then 

				# Register FLAIR to T1
				antsRegistrationSyN.sh -d 3 -f ${t1_N4} \
				-m ${flair_N4} -o ${flair_t1_prefix} -t a

				# Mask flair
				fslmaths ${flair_t1} -mas ${brain_mask} ${flair_t1_brain}
			
			fi
		fi
done;
