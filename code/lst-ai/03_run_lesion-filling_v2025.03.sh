#!/bin/bash

#Below block for SLURM users. If you are not a SLURM user, remove this block 
#and change below references to SLURM for parallel processing.

#SBATCH --job-name=lesionfilling    # a convenient name for your job
#SBATCH --mem=10G                   # max memory per node
#SBATCH --partition=luna-short      # using luna short queue 
#SBATCH --cpus-per-task=8           # max CPU cores per process
#SBATCH --time=00-8:00:00           # time limit (DD-HH:MM)
#SBATCH --nice=2000                 # allow other priority jobs
#SBATCH --qos=anw                   # use anw-cpu's
#SBATCH --array=1-XX%YY             #first-last%parallel subj
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out

#======================================================================
# LESION FILLING USING LST
#======================================================================
#@author: samantha noteboom, mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated; 03 february 2025, works
#to-do: simplify usage 

#Description: 
# Input: Binary lesion mask (corrected) and T1w image. 
# Output: T1w with lesion filled. 
# Run: It needs to run lesion segmentation LST-LGA to obtain intermediate
# files in order to perform the lesion filling on T1w image. 

#Requirements:
# 1. Please install lst, https://www.applied-statistics.de/lst.html, if 
# not already install in your system.

# Please modify the following things before running:
# -array: change according the number of participants study (line 12)
# -projectfolder: change your input folder, needs to be in BIDS format (line 44)
#----------------------------------------------------------------------

# Load modules
module load matlab
module load matlab-toolbox/spm12/r7771
ml ANTs/2.5.1

# Define input directories and create outputdir
curdir=`pwd`
projectfolder=/path/to/project/folder #please modify before running
lst_ai=${projectfolder}/derivatives/lst_ai
filling=${Projectfolder}/derivatives/filling
mkdir -p $filling

# for parallel preprocessing create txt file for each subject
cd ${lst_ai}
ls -d sub-*/ | sed 's:/.*::' > ${curdir}/subjects-lesion-filling.txt
subjectid=$(sed "${SLURM_ARRAY_TASK_ID}q;d" ${curdir}/subjects-lesion-filling.txt)
cd ${curdir}

# loop over session folders in subject folder
subject_dir=${lst_ai}/$subjectid
list_ses=($basename $(ls -d -1 ${subject_dir}/ses-*))

for ses in ${list_ses[@]}; do

	sessionid=${ses##/*/}
        session_dir=${subject_dir}/${sessionid}
	echo "Starting processing $subjectid $sessionid"

	# define input files from lst ai 
	dir=${lst_ai}/${subjectid}/${sessionid}/tmp

	t1=${dir}/sub-X_ses-Y_space-t1w_T1w.nii.gz
	flair_flair=${dir}/sub-X_ses-Y_space-flair_FLAIR.nii.gz
	lesion_flair=${dir}/sub-X_ses-Y_space-flair_seg-lst.nii.gz

	lstdir=${filling}/${subjectid}/$sessionid
	mkdir -p $lstdir

	flair_t1w=${dir}/${subjectid}_${sessionid}_space-t1w_FLAIR_
	lesion_t1w=${dir}/${subjectid}_${sessionid}_space-t1w_seg-lst.nii.gz
	wrap_flair_t1w=${flair_t1w}1Warp.nii.gz
	mat_flair_t1w=${flair_t1w}0GenericAffine.mat

	# register lesion mask in flair space to t1 space
	if [ -e $t1 ] && [ -e $flair_flair ] && [ -e $lesion_flair ]; then 
		if [ ! -e $lesion_t1w ]; then 

			#first, register flair image to t1 space
			echo "Lesion in T1w space doesn't exist: $lesion_t1w" 
      			antsRegistrationSyN.sh -d 3 -f ${t1} -m ${flair_flair} -o ${flair_t1w} -t s

			# apply registration to lesion mask
		 	antsApplyTransforms -d 3 -i ${lesion_flair} -r ${t1} \
		 	-o ${lesion_t1w} -n nearestNeighbor -t ${wrap_flair_t1w} -t ${mat_flair_t1w} --verbose
 		
		else echo "Lesion mask in t1w space exist: OK!"
		fi 

	else echo "Registration failed: Missing input data!"

	fi 

	#define files necessary for lesion filling
	t1_lst=${lstdir}/${subjectid}_${sessionid}_space-t1w_T1w.nii
	flair_lst=${lstdir}/${subjectid}_${sessionid}_space-t1w_FLAIR.nii
	lesion_mask_lst=${lstdir}/${subjectid}_${sessionid}_space-t1w_seg-lst_lst.nii
	t1_filled_lst=${lstdir}/${subjectid}_${sessionid}_space-t1w_T1w-filled.nii.gz

	if [ -e $t1 ] && [ -e "${flair_t1w}Warped.nii.gz" ] && [ -e $lesion_t1w ]; then 

		#lst requires files unzipped, their recommendation is to copy files to new folder		
		echo "creating and copying file new directory"
		mkdir -p $lstdir
		cp $t1 "${t1_lst}.gz"
		cp "${flair_t1w}Warped.nii.gz" "${flair_lst}.gz"
		cp $lesion_t1w "${lesion_mask_lst}.gz"
		
		echo "decompressing data output dir"
		gunzip ${t1_lst}.gz
		gunzip ${flair_lst}.gz
		gunzip ${lesion_mask_lst}.gz

	else echo "missing input data"
	fi 

	
	# Run LST lesion filling
	if [ ! -e ${t1_filled_lst} ] && [ -e ${lesion_mask_lst} ]; then  

	    echo "Preparing LST lesion filling..."    
	    ples_flair=${lstdir}/ples_lga_0.3_rm${subjectid}_${sessionid}_space-t1w_FLAIR.nii
			

	    # Run LGA (otherwise LST lesfill crashes)
	    if [ ! -e ${ples_flair}.gz ] || [ ! -e ${t1_filled_lst} ]; then
		logname=${lstdir}/log_lst_lga
		matlab -nodisplay –nojvm -nosplash -logfile "${logname}.log"  \
		-r "addpath('/opt/aumc-apps/matlab/toolbox/spm12_r7771/toolbox/LST'); ps_LST_lga('${t1_lst}', '${flair_lst}' ); exit"  <  /dev/null 1> ${logname}.stdout 2> ${logname}.stderr
		gzip ${ples_flair}
		mv ${lesion_mask_lst} ${ples_flair}
	    fi

	    # # Fill lesions
	    if [ ! -e ${t1_filled_lst} ] && [ -e ${ples_flair}.gz ]; then
		echo "Fill lesions..."          
		logname=${lstdir}/lst_lga_filling
		matlab -nodisplay –nojvm -nosplash -logfile "${logname}.log"  \
		-r "addpath('/opt/aumc-apps/matlab/toolbox/spm12_r7771/toolbox/LST'); ps_LST_lesfill( '${t1_lst}','${ples_flair}',false,false ); exit"  <  /dev/null 1> ${logname}.stdout 2> ${logname}.stderr
		gzip ${lstdir}/${subjectid}_${sessionid}_space-t1w_T1w_filled_lga_0.3_rm${subjectid}_${sessionid}_space-t1w_FLAIR.nii
		mv ${lstdir}/${subjectid}_${sessionid}_space-t1w_T1w_filled_lga_0.3_rm${subjectid}_${sessionid}_space-t1w_FLAIR.nii.gz ${t1_filled_lst}
		rm -r ${lstdir}/LST_lga_0.3_rm${subjectid}_${sessionid}_space-t1w_FLAIR
		rm ${lstdir}/*.log ${lstdir}/*.stderr ${lstdir}/*.stdout ${lstdir}/*.html

fi; fi; done
