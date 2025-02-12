#!/bin/bash

#SBATCH --job-name=org-nicms          #a name for your job
#SBATCH --mem=1G                      #max memory per node
#SBATCH --partition=luna-cpu-short    #using luna queue
#SBATCH --cpus-per-task=4      	      #max CPU cores per process
#SBATCH --time=01:00:00               #time limit (DD-HH:MM)
#SBATCH --nice=4000                   #priority of the job
#SBATCH --qos=anw-cpu                 
#SBATCH --array=1-XX%YY      	      #first-last%parallel subj
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out

#======================================================================
# 	ORGANISE FILES INTO STRUCTURE REQUIRED FOR NICMS
#======================================================================

#@author: samantha noteboom, mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated; 03 February 2025, works
#to-do: simplify usage 

#Description: 
# Input: Brain files otained from previous step
# Output: Folder includying all brain files from previous step
# Run: It copies image files from the previous step to a new folder 
# with a new organization structure
# because nicms needs a different file structure.

#Requirements: None

#Please modify the following things before running:
# -array: change according the number of participants study
# -projectfolder: change your input folder, needs to be pre-nicms
# -archive_nicms: change output folder 
#----------------------------------------------------------------------

projectfolder=/path/to/pre-nicms/folder          #see previous step
archive_nicms=/path/to/org-nicms/folder          #please modify
mkdir -p ${archive_nicms}

# To use array parallel processing, you create a .txt file with a list of each subject folder.
cd ${projectfolder}
ls -d sub-*/ | sed 's:/.*::' > ${curdir}/subjects_org-nicms.txt
subjectid=$(sed "${SLURM_ARRAY_TASK_ID}q;d"  ${curdir}/subjects_org-nicms.txt)
cd ${curdir}

# run organisation for all sessions of a subject
subject_dir=${projectfolder}/$subjectid
list_ses=($basename -a $(ls -d -1 $(subject_dir/ses-*)))

for ses in ${list_ses[@]}; do

	sessionid=${ses##/*/}
	echo "Starting processing $subjectid $sessionid"
 
    if [ -e $ses/${subjectid}_${sessionid}_T1w_N4_brain.nii.gz ]; then
        newdir=${archive_nicms}/${subjectid}_${sessionid}
        mkdir -p $newdir
        echo "cp $ses/*brain.nii.gz $newdir/ "
        cp $ses/*brain.nii.gz $newdir/
    fi 
done
