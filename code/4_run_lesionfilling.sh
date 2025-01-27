#!/bin/bash
#SBATCH --job-name=lesionfilling    # a convenient name for your job
#SBATCH --mem=10G                   # max memory per node
#SBATCH --partition=luna-cpu-short  # using luna short queue 
#SBATCH --cpus-per-task=2           # max CPU cores per process
#SBATCH --time=00-1:00:00           # time limit (DD-HH:MM)
#SBATCH --nice=2000                 # allow other priority jobs to go first (note, this is different from the linux nice command below)
#SBATCH --qos=anw-cpu               # use anw-cpu's
#SBATCH --array=1-100%15   
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out

# Load modules
module load FreeSurfer/7.3.2-centos8_x86_64
module load niftyseg/20230322
module load matlab/R2022b
module load matlab-toolbox/spm12/r7771
module load fsl/6.0.6.5

# Define input directories anc create outputdir
curdir=`pwd`
#dir=/home/anw/snoteboom/my-scratch/programs-bids
#dir=/data/anw/anw-gold/KNW/m.barrace/programs/presgene_2021_bids_nicms_completedec2023/
dir=/data/anw/anw-gold/KNW/m.barrace/programs/programs-bids
bidsdir=${dir}/rawdata
#nicdir=/home/anw/mbarrantescepas/my-scratch/prograMS/lesionfilling_round3/segmentation_round2_batch2
nicdir=/data/anw/anw-gold/KNW/m.barrace/programs/programs-bids/derivatives/nicms
#nicdir=${dir}/derivatives/nicms

# To use array parallel processing, you create a .txt file with a list of each subject folder.
cd ${nicdir}
ls -d sub-*/ | sed 's:/.*::' >subjects-round4.txt
subjid=$(sed "${SLURM_ARRAY_TASK_ID}q;d" subjects-round4.txt)
cd ${curdir}

subjid=sub-PAPR089 # test 1 subject for debugging

# Run lesion filling for all sessions
subdir=${nicdir}/${subjid}
for sessdir in ${subdir}/*; do
        echo $sessdir
        sess=${sessdir##/*/}

        # Define filenames
        t1=${bidsdir}/${subjid}/${sess}/anat/${subjid}_${sess}_T1w.nii.gz
        flair=${bidsdir}/${subjid}/${sess}/anat/${subjid}_${sess}_FLAIR.nii.gz
        t1_filled_lst=${sessdir}/anat/${subjid}_${sess}_T1w_filled.nii.gz

        lesion_nicms=${sessdir}/anat/${subjid}_${sess}_ms112_mweeda_full_nicmslesions_prob_1_thr04_c5.nii.gz
        lesion_qc=${sessdir}/anat/${subjid}_${sess}_ms112_mweeda_full_nicmslesions_prob_1_thr04_c5_qc.nii.gz
        lesion_qc2=${sessdir}/anat/${subjid}_${sess}_ms112_mweeda_full_nicmslesions_prob_1_thr04_c5_qc2.nii.gz
        lesion_qc3=${sessdir}/anat/${subjid}_${sess}_ms112_mweeda_full_nicmslesions_prob_1_thr04_c5_qc3.nii.gz
        lesion_mask=${sessdir}/anat/${subjid}_${sess}_lesion.nii.gz

        # Create soft link to nicms or qc lesion mask
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

            ln -sr ${lesion} ${lesion_mask}
        fi


        # Run LST lesion filling
        if [ ! -e ${t1_filled_lst} ] && [ -e ${lesion_mask} ]; then  
             echo "Preparing LST lesion filling..."
            
            # Copy files
            cp ${t1} ${sessdir}/anat/${subjid}_${sess}_T1w.nii.gz
            if [ ! -e ${flair} ]; then
                cp ${t1} ${sessdir}/anat/${subjid}_${sess}_FLAIR.nii.gz
            else
                cp ${flair} ${sessdir}/anat/${subjid}_${sess}_FLAIR.nii.gz
            fi
            cp ${lesion_mask} ${sessdir}/anat/${subjid}_${sess}_lesion_lst.nii.gz

            # Define .nii file names
            t1_lst=${sessdir}/anat/${subjid}_${sess}_T1w.nii
            flair_lst=${sessdir}/anat/${subjid}_${sess}_FLAIR.nii
            lesion_mask_lst=${sessdir}/anat/${subjid}_${sess}_lesion_lst.nii
            if [ ! -e ${lesion_mask_lst} ]; then
                gunzip ${sessdir}/anat/${subjid}_${sess}_T1w.nii.gz
                gunzip ${sessdir}/anat/${subjid}_${sess}_FLAIR.nii.gz
                gunzip ${sessdir}/anat/${subjid}_${sess}_lesion_lst.nii.gz
            fi

            ples_flair=${sessdir}/anat/ples_lga_0.3_rm${subjid}_${sess}_FLAIR.nii

            # Run LGA (otherwise LST lesfill crashes)
            if [ ! -e ${ples_flair}.gz ] || [ ! -e ${t1_filled_lst} ]; then
                logname=${sessdir}/anat/${subjid}_${sess}_lst_lga
                matlab -nodisplay –nojvm -nosplash -logfile "${logname}.log"  \
                -r "addpath('/opt/aumc-apps/matlab/toolbox/spm12_r7771/toolbox/LST'); ps_LST_lga('${t1_lst}', '${flair_lst}' ); exit"  <  /dev/null 1> ${logname}.stdout 2> ${logname}.stderr
                gzip ${ples_flair}
                mv ${lesion_mask_lst} ${ples_flair}
            fi

            # # Fill lesions
            if [ ! -e ${t1_filled_lst} ] && [ -e ${ples_flair}.gz ]; then
                echo "Fill lesions..."           
                logname=${sessdir}/anat/${subjid}_${sess}_lst_lga_filling
                matlab -nodisplay –nojvm -nosplash -logfile "${logname}.log"  \
                -r "addpath('/opt/aumc-apps/matlab/toolbox/spm12_r7771/toolbox/LST'); ps_LST_lesfill( '${t1_lst}','${ples_flair}',false,false ); exit"  <  /dev/null 1> ${logname}.stdout 2> ${logname}.stderr
                gzip ${sessdir}/anat/${subjid}_${sess}_T1w_filled_lga_0.3_rm${subjid}_${sess}_FLAIR.nii
                mv ${sessdir}/anat/${subjid}_${sess}_T1w_filled_lga_0.3_rm${subjid}_${sess}_FLAIR.nii.gz ${t1_filled_lst}
                rm -r ${sessdir}/anat/LST_lga_0.3_rm${subjid}_${sess}_FLAIR
                rm ${sessdir}/anat/*.nii ${sessdir}/anat/*.log ${sessdir}/anat/*.stderr ${sessdir}/anat/*.stdout ${sessdir}/anat/*.html
            fi
        fi 
done;


