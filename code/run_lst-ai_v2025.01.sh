#!/bin/bash

#SBATCH --job-name=lst-ai             #a name for your job
#SBATCH --mem=12G                     #max memory per node
#SBATCH --partition=luna-cpu-short    #using luna queue
#SBATCH --cpus-per-task=4      	      #max CPU cores per process
#SBATCH --time=01:00:00               #time limit (DD-HH:MM)
#SBATCH --nice=4000                   #priority of the job
#SBATCH --qos=anw-cpu                 
#SBATCH --array=1-3%3       	      #first-last%parallel subj
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out

#======================================================================
# 	AUTOMATIC LESION SEGMENTATION USING LST-AI
#======================================================================

#@author: mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated; 17 January 2025, works
#to-do: simplify usage 

#Description: 
# Input: Folder includying T1w and FLAIR scans in BIDS, if your study
# only includes T1w or FLAIR, we recommend to check old LST algortihms 
# (https://www.applied-statistics.de/lst.html)
# Output: lesion segmentation probablity map, binary mask and annotated  
# masks, as well as, other intermediate files. See more information:
# https://github.com/CompImg/LST-AI
# Run: It performs lesion segmentation from FLAIR and T1w scans.

#Requirements:
# 1. Please install lst-ai https://github.com/CompImg/LST-AI, if not
# already install in your server. 

# 2. Data should be organised in BIDS format, learn more: 
# https://bids.neuroimaging.io/ 

#Please modify the following things before running:
# -array: change according the number of participants study
# -dir: change your input folder, needs to be in BIDS format 

#----------------------------------------------------------------------

# load modules
module load greedy
source /opt/aumc/share/venvs/LST_AI-1.1.0/bin/activate

# Define paths to data
curdir=`pwd`
projectfolder=/path/to/your/folder 	#please modify
rawdata=${projectfolder}/rawdata
derivatives=${projectfolder}/derivatives 

# to use parallel processing, create a .txt file with a list of subject folder.
cd ${rawdata}
ls -d sub-*/ | sed 's:/.*::' >${curdir}/subjects_lst-ai.txt
subjectid=$(sed "${SLURM_ARRAY_TASK_ID}q;d" ${curdir}/subjects_lst-ai.txt)
cd ${curdir}

# run lesion segmentation for all session of a subject
subject_dir=${rawdata}/$subjectid
list_ses=($(basename -a $(ls -d -1 ${subject_dir}/ses-*)))

for ses in ${list_ses[@]};do

    sessionid=${ses##/*/}                                 #e.g. ses-00
    echo "Starting processing $subjectid $sessionid"
    
    session_dir=${subject_dir}/${sessionid}
    t1=${session_dir}/anat/${subjectid}_${sessionid}_T1w.nii.gz
    flair=${session_dir}/anat/${subjectid}_${sessionid}_FLAIR.nii.gz

    outdir=$derivatives/lst_ai/$subjectid/$sessionid
    tmpdir=$outdir/tmp

    mkdir -p $outdir
    mkdir -p $tmpdir

    # run lst-ai if T1w and flair exist, and output files aren't there
    if [ -e $t1 ] && [ -e $flair ]; then 
        if [ ! -e $outdir/lesion_stats.csv ]; then 

	   echo "Starting lst $subjectid $sessionid"
           lst --t1 $t1 --flair $flair --output $outdir --temp $tmpdir --device cpu --probability_map

	else 
	    echo "$subjectid, $sessionid already done!"
        fi 
    else 
      echo "$t1 or $flair doesn't exist, please check data structure"
    fi
done

#----------------------------------------------------------------------
# References
#----------------------------------------------------------------------

#Wiltgen, T., McGinnis, J., Schlaeger, S., Kofler, F., Voon, C., Berthele, A., Bischl, D., Grundl, L., Will, N., Metz, M., Schinz, D., Sepp, D., Prucker, P., Schmitz-Koep, B., Zimmer, C., Menze, B., Rueckert, D., Hemmer, B., Kirschke, J., Mühlau, M., … Wiestler, B. (2024). LST-AI: a Deep Learning Ensemble for Accurate MS Lesion Segmentation. medRxiv : the preprint server for health sciences, 2023.11.23.23298966. https://doi.org/10.1101/2023.11.23.23298966

#Yushkevich, P.A., Pluta, J., Wang, H., Wisse, L.E.M., Das, S. and Wolk, D. (2016), IC-P-174: Fast Automatic Segmentation of Hippocampal Subfields and Medial Temporal Lobe Subregions In 3 Tesla and 7 Tesla T2-Weighted MRI. Alzheimer's & Dementia, 12: P126-P127. https://doi.org/10.1016/j.jalz.2016.06.205 

#Isensee, F., Schell, M., Pflueger, I., Brugnara, G., Bonekamp, D., Neuberger, U., Wick, A., Schlemmer, H. P., Heiland, S., Wick, W., Bendszus, M., Maier-Hein, K. H., & Kickingereder, P. (2019). Automated brain extraction of multisequence MRI using artificial neural networks. Human brain mapping, 40(17), 4952–4964. https://doi.org/10.1002/hbm.2475

