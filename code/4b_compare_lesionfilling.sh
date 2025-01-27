#!/bin/bash
#SBATCH --job-name=lesionfilling    # a convenient name for your job
#SBATCH --mem=6G               # max memory per node
#SBATCH --partition=luna-cpu-short # using luna short queue 
#SBATCH --cpus-per-task=2      # max CPU cores per process
#SBATCH --time=00-1:00:00         # time limit (DD-HH:MM)
#SBATCH --nice=2000            # allow other priority jobs to go first (note, this is different from the linux nice command below)
#SBATCH --qos=anw-cpu           # use anw-cpu's
#SBATCH --array=1-1%1   
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out

# Load modules
module load FreeSurfer/7.3.2-centos8_x86_64
module load niftyseg/20230322
module load matlab/R2022b
module load matlab-toolbox/spm12/r7771
module load fsl/6.0.6.5

# Define input directories anc create outputdir
curdir=`pwd`
dir=/home/anw/snoteboom/my-scratch/programs_test
bidsdir=${dir}/rawdata
nicdir=${dir}/derivatives/nicms

# To use array parallel processing, you create a .txt file with a list of each subject folder.
cd ${nicdir}
ls -d */ | sed 's:/.*::' >subjects.txt
subjid=$(sed "${SLURM_ARRAY_TASK_ID}q;d" subjects.txt)
cd ${curdir}

subjid=$1 # test 1 subject for debugging

# Run lesion filling for all sessions
subdir=${nicdir}/${subjid}
for sessdir in ${subdir}/*; do
        echo $sessdir
        sess=${sessdir##/*/}

        # Define filenames
        t1=${bidsdir}/${subjid}/${sess}/anat/${subjid}_${sess}_T1w.nii.gz
        flair=${bidsdir}/${subjid}/${sess}/anat/${subjid}_${sess}_FLAIR.nii.gz
        t1_filled=${sessdir}/anat/${subjid}_${sess}_T1w_filled.nii.gz
        t1_brain=${sessdir}/anat/${subjid}_${sess}_T1w_brain.nii.gz
        t1_filled_slf=${sessdir}/anat/${subjid}_${sess}_T1w_filled_slf.nii.gz
        t1_filled_fsl=${sessdir}/anat/${subjid}_${sess}_T1w_filled_fsl.nii.gz
        t1_filled_lst=${sessdir}/anat/${subjid}_${sess}_T1w_filled_lst.nii.gz

        lesion_mask=${sessdir}/anat/${subjid}_${sess}_lesion.nii.gz
        brain_mask=${sessdir}/anat/${subjid}_${sess}_T1w_brain_mask.nii.gz

        # Run SLF
        if [ ! -e ${t1_filled_slf} ] && [ -e ${lesion_mask} ]; then 
            if [ ! -e ${t1_brain} ]; then
                echo "Performing hd-bet..."
                /opt/aumc-containers/singularity/hd-bet/hd-bet_v20220401.sif -i ${t1} -o ${t1_brain} -s 1 -device cpu -mode fast -tta 0
            fi
            echo "Performing SLF..."
            matlab -nodisplay -nosplash -nodesktop -r "cd('/data/anw/anw-gold/AMDA/apps');lesionfilling('${t1}', '${t1_filled_slf}', '${lesion_mask}', '${brain_mask}');exit;"
        fi

        # Run lesionfilling NiftySeg
        if [ ! -e ${t1_filled} ] && [ -e ${lesion_mask} ]; then  
            echo "Performing NiftySeg lesion filling..."
            seg_FillLesions -i ${t1} -l ${lesion_mask} -o ${t1_filled}
        fi

        # # Run fsl lesion filling
        # if [ ! -e ${t1_filled_fsl} ] && [ -e ${lesion_mask} ]; then  
        #     echo "Performing FSL lesion filling..."
        #     wm_mask=${sessdir}/anat/${subjid}_${sess}_fast_seg_2.nii.gz

        #     # Brain extraction T1
        #     if [ ! -e ${t1_brain} ]; then
        #          echo "Performing hd-bet..."
        #         /opt/aumc-containers/singularity/hd-bet/hd-bet_v20220401.sif -i ${t1} -o ${t1_brain} -s 1 -device cpu -mode fast -tta 0
        #     fi 

        #     # Segment skull-stripped brain
        #     if [ ! -e ${wm_mask} ]; then
        #         fast -g -t 1 -n 3 -o ${sessdir}/anat/${subjid}_${sess}_fast $t1_brain
        #         lesion_filling -i $t1 -l ${lesion_mask} -w $wm_mask -o ${t1_filled_fsl}
        #     fi

        # fi


        # Run LST lesion filling
        if [ ! -e ${t1_filled_lst} ] && [ -e ${lesion_mask} ]; then  
             echo "Preparing LST lesion filling..."
            
            # Copy files
            cp ${t1} ${sessdir}/anat/${subjid}_${sess}_T1w.nii.gz
            cp ${flair} ${sessdir}/anat/${subjid}_${sess}_FLAIR.nii.gz
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
            if [ ! -e ${ples_flair}.gz ]; then
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
                rm ${sessdir}/anat/*.nii ${sessdir}/anat/*.log ${sessdir}/anat/*.stderr 
            fi
        fi 
done;



# Lesion filling reference
# F. Prados, M. J. Cardoso, B. Kanber, O. Ciccarelli, R. Kapoor, C. A. M. Gandini Wheeler-Kingshott, S. Ourselin.
# A multi-time-point modality-agnostic patch-based method for lesion filling in multiple sclerosis.
# Neuroimage 139, 376-384 (2016)