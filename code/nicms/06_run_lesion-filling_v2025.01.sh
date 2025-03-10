#!/bin/bash

#Below block for SLURM users. If you are not a SLURM user, remove this block 
#and change below references to SLURM for parallel processing. 
#SBATCH --job-name=lesionfilling    # a convenient name for your job
#SBATCH --mem=10G                   # max memory per node
#SBATCH --partition=luna-cpu-short  # using luna short queue 
#SBATCH --cpus-per-task=2           # max CPU cores per process
#SBATCH --time=00-1:00:00           # time limit (DD-HH:MM)
#SBATCH --nice=2000                 # allow other priority jobs 
#SBATCH --qos=anw-cpu               # use anw-cpu's
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

# load modules
module load matlab/R2022b
module load matlab-toolbox/spm12/r7771

# Define input directories and create outputdir
curdir=`pwd` 		#pressumes you are in the script directory
projectfolder=/path/to/project/folder
rawdata=${projectfolder}/rawdata
nicmsdir=${projectfolder}/derivatives/nicms

# To use array parallel processing, you create a .txt file with a list of each subject folder.
cd ${nicmsdir}
ls -d sub-*/ | sed 's:/.*::' > ${curdir}/subjects-les-filling.txt
subjectid=$(sed "${SLURM_ARRAY_TASK_ID}q;d" ${curdir}/subjects-les-filling.txt)
cd ${curdir}

# run preprocessing for all sessions of a subject
subject_dir=${nicmsdir}/$subjectid
list_ses=($basename -a $(ls -d -1 $(subject_dir/ses-*)))

for ses in ${list_ses[@]}; do

	sessionid=${ses##/*/}
        session_dir=${subject_dir}/${sessionid}
	echo "Starting processing $subjectid $sessionid"
 
        # Define input and output filenames
        raw_sub_ses_dir=${rawdata}/${subjectid}/${sessionid}
        t1=${raw_sub_ses_dir}/anat/${subjectid}_${sessionid}_T1w.nii.gz
        flair==${raw_sub_ses_dir}/anat/${subjectid}_${sessionid}_FLAIR.nii.gz
        t1_filled_lst=${raw_sub_ses_dir}/anat/${subjectid}_${sessionid}_T1w_filled.nii.gz

        lesion_prefix=${session_dir}/anat/${subjectid}_${sessionid}_ms112_mweeda_full_nicmslesions_prob_1_thr04_c5 #naming convention specific to our center
        lesion_nicms=${lesion_prefix}.nii.gz
        lesion_qc=${lesion_prefix}_qc.nii.gz
        lesion_qc2=${lesion_prefix}_qc2.nii.gz    #only needed if multiple quality check outputs
        lesion_qc3=${lesion_prefix}_qc3.nii.gz    #only needed if multiple quality check outputs
        lesion_mask=${session_dir}/${subjectid}_${sessionid}_lesion-mask.nii.gz

        # Create soft link to nicms raw lesion mask or most recent qc lesion mask
        if [ ! -e ${lesion_mask} ]; then
            if [ -e ${lesion_qc3} ]; then
                lesion=${lesion_qc3}
                echo "use QC mask 3"
            elif [ -e ${lesion_qc2} ]; then
                lesion=${lesion_qc2}
                echo "use QC mask 2"
            elif [ -e ${lesion_qc} ]; then
                lesion=${lesion_qc}
                echo "use QC mask"
            elif [ -e ${lesion_nicms} ]; then
                lesion=${lesion_nicms}
                echo "use nicms mask"
            else
                echo "no lesion mask available, exit"
                exit 0
            fi
            ln -sr ${lesion} ${lesion_mask} # create symbolic link
        fi
        
        # Run LST lesion filling
        if [ ! -e ${t1_filled_lst} ] && [ -e ${lesion_mask} ]; then  
            
            echo "Preparing LST lesion filling..."
            cp ${t1} ${session_dir}/anat/${subjectid}_${sessionid}_T1w.nii.gz
            
            if [ ! -e ${flair} ]; then
	    	#use t1 as flair if flair doesnt exist
                cp ${t1} ${session_dir}/${subjectid}_${sessionid}_FLAIR.nii.gz
            else
                cp ${flair} ${session_dir}/${subjectid}_${sessionid}_FLAIR.nii.gz
            fi
            cp ${lesion_mask} ${session_id}/${subjectid}_${sessionid}_lesion_lst.nii.gz

            # Define .nii file names
            t1_lst=${session_dir}/${subjectid}_${sessionid}_T1w.nii
            flair_lst=${session_dir}/${subjectid}_${sessionid}_FLAIR.nii
            lesion_mask_lst=${session_dir}/${subjectid}_${sessionid}_lesion_lst.nii
        
            if [ ! -e ${lesion_mask_lst} ]; then
                gunzip ${session_dir}/${subjectid}_${sessionid}_T1w.nii.gz
                gunzip ${session_dir}/${subjectid}_${sessionid}_FLAIR.nii.gz
                gunzip ${session_dir}/${subjectid}_${sessionid}_lesion_lst.nii.gz
            fi

	    #define output file LGA (lesion segmentation algorithm)
            ples_flair=${session_dir}/ples_lga_0.3_rm${subjid}_${sess}_FLAIR.nii

            # Run LGA (otherwise LST lesion filling crashes, though lesion mask is replaced)
            if [ ! -e ${ples_flair}.gz ] || [ ! -e ${t1_filled_lst} ]; then
                logname=${session_dir}/${subjectid}_${sessionid}_lst_lga
                matlab -nodisplay –nojvm -nosplash -logfile "${logname}.log"  \
                -r "addpath('/opt/aumc-apps/matlab/toolbox/spm12_r7771/toolbox/LST'); ps_LST_lga('${t1_lst}', '${flair_lst}' ); exit"  <  /dev/null 1> ${logname}.stdout 2> ${logname}.stderr
                gzip ${ples_flair}
                mv ${lesion_mask_lst} ${ples_flair} #replacing lst lesion mask for nicms lesion mask
            fi
            
            # Filling lesions... 
            if [ ! -e ${t1_filled_lst} ] && [ -e ${ples_flair}.gz ]; then
                echo "Fill lesions..."           
                logname=${session_dir}/${subjectid}_${sessionid}_lst_lga_filling
                matlab -nodisplay –nojvm -nosplash -logfile "${logname}.log"  \
                -r "addpath('/opt/aumc-apps/matlab/toolbox/spm12_r7771/toolbox/LST'); ps_LST_lesfill( '${t1_lst}','${ples_flair}',false,false ); exit"  <  /dev/null 1> ${logname}.stdout 2> ${logname}.stderr
                gzip ${session_dir}/${subjectid}_${sessionid}_T1w_filled_lga_0.3_rm${subjectid}_${sessionid}_FLAIR.nii
                mv ${session_dir}/anat/${subjectid}_${sessionid}_T1w_filled_lga_0.3_rm${subjectid}_${sessionid}_FLAIR.nii.gz ${t1_filled_lst}
                #removing intermediate files
		rm -r ${session_dir}/anat/LST_lga_0.3_rm${subjectid}_${sessionid}_FLAIR
                rm ${session_dir}/anat/*.nii ${session_dir}/anat/*.log ${session_dir}/anat/*.stderr ${session_dir}/anat/*.stdout ${session_dir}/anat/*.html
            fi
        fi 
done;

#----------------------------------------------------------------------
# References
#----------------------------------------------------------------------
# Schmidt P, Gaser C, Arsic M, et al. An automated tool for detection of FLAIR-hyperintense white-matter lesions in Multiple Sclerosis. Neuroimage. 2012;59(4):3774-3783. doi:10.1016/j.neuroimage.2011.11.032
