#!/bin/bash

#Below block for SLURM users. If you are not a SLURM user, remove this block 
#and change below references to SLURM for parallel processing. 

#SBATCH --job-name=fs-cross     	#a convenient name for your job
#SBATCH --mem=8G                     	#max memory per node 
#SBATCH --partition=luna-cpu-long   	#using luna short queue
#SBATCH --cpus-per-task=8             	#max CPU cores per process
#SBATCH --time=18:00:00                	#time limit (DD-HH:MM)
#SBATCH --nice=4000                   	#allow other priority jobs to go first
#SBATCH --qos=anw-cpu                 	#use anw-cpu's
#SBATCH --array=1-XX%YY			#first-last%parallel subj
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out

#======================================================================
#  FREESURFER CROSS-SECTIONAL
#======================================================================
#@author: mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated; 21 March 2025, works

#Description: 
# Input: T1w filled 
# Output: FreeSurfer files.
# Run: make sure to run inside scripts folder

#Requirements:
# 1. Please install FreeSurfer if not already install in your system.

# Please modify the following things before running:
# -array: change according the number of participants study (line 12)
# -projectfolder: change your input folder, needs to be in BIDS format (line 41)
#----------------------------------------------------------------------

# load modules
module load FreeSurfer/7.3.2-centos8_x86_64

# Define paths to data 
curdir=`pwd`
projectfolder=/path/to/your/project 				#please modify 
lstdir=${projectfolder}/derivatives/lst_ai
filling=${projectfolder}/derivatives/filling
fsdir=${projectfolder}/derivatives2/freesurfer

# for parallel preprocessing, create txt file with subjects
cd ${filling}
ls -d sub-*/ | sed 's:/.*::' > ${curdir}/subjects-freesurfer.txt
subjectid=$(sed "${SLURM_ARRAY_TASK_ID}q;d" ${curdir}/subjects-freesurfer.txt)
cd ${curdir}

# loop over all the sessions inside a subject folder
subject_dir=${filling}/$subjectid
list_ses=($(for ses_dir in $subject_dir/ses-*; do basename "$ses_dir"; done))

for ses in ${list_ses[@]}; do

	sessionid=${ses##/*/}
        session_dir=${subject_dir}/${sessionid}
	echo "Starting processing $subjectid $sessionid"

	#define input and output files
	t1_filled=${filling}/$subjectid/$sessionid/${subjectid}_${sessionid}_space-t1w_T1w-filled.nii.gz
	t1_raw=${lstdir}/${subjectid}/${sessionid}/tmp/sub-X_ses-Y_space-t1w_T1w.nii.gz
        brain_mask=${lstdir}/${subjectid}/${sessionid}/tmp/sub-X_ses-Y_space-t1w_brainmask.nii.gz 
 
	SUBJECTS_DIR=${fsdir}/${subjectid}
	mkdir -p ${SUBJECTS_DIR}
	echo $SUBJECTS_DIR

	#if exists t1 filled use t1 filled, otherwise use raw t1 
	if [ -e $t1_filled ]; then
		t1=${t1_filled}
	else 
		t1=${t1_raw}
	fi 

	if [ ! -e ${SUBJECTS_DIR}/$sessionid ] && [ -e ${t1} ]; then
		echo "Start running recon-all ${SUBJECTS_DIR}/${sessionid}"
		recon-all -subjid ${ses} -i ${t1} -xmask ${brain_mask} -all
	fi

done 
#----------------------------------------------------------------------
# References 
#----------------------------------------------------------------------
#[1] Collins, DL, Neelin, P., Peters, TM, and Evans, AC. (1994) Automatic 3D Inter-Subject Registration of MR Volumetric Data in Standardized Talairach Space, Journal of Computer Assisted Tomography, 18(2) p192-205, 1994 PMID: 8126267; UI: 94172121
#[2] Cortical Surface-Based Analysis I: Segmentation and Surface Reconstruction Dale, A.M., Fischl, Bruce, Sereno, M.I., (1999). Cortical Surface-Based Analysis I: Segmentation and Surface Reconstruction. NeuroImage 9(2):179-194
#[3] Fischl, B.R., Sereno, M.I.,Dale, A. M. (1999) Cortical Surface-Based Analysis II: Inflation, Flattening, and Surface-Based Coordinate System. NeuroImage, 9, 195-207.
#[4] Fischl, Bruce, Sereno, M.I., Tootell, R.B.H., and Dale, A.M., (1999). High-resolution inter-subject averaging and a coordinate system for the cortical surface. Human Brain Mapping, 8(4): 272-284
#[5] Fischl, Bruce, and Dale, A.M., (2000). Measuring the Thickness of the Human Cerebral Cortex from Magnetic Resonance Images. Proceedings of the National Academy of Sciences, 97:11044-11049.
#[6] Fischl, Bruce, Liu, Arthur, and Dale, A.M., (2001). Automated Manifold Surgery: Constructing Geometrically Accurate and Topologically Correct Models of the Human Cerebral Cortex. IEEE Transactions on Medical Imaging, 20(1):70-80
#[7] Non-Uniform Intensity Correction. http://www.bic.mni.mcgill.ca/software/N3/node6.html
#[8] Fischl B, Salat DH, Busa E, Albert M, Dieterich M, Haselgrove C, van der Kouwe A, Killiany R, Kennedy D, Klaveness S, Montillo A, Makris N, Rosen B, Dale AM. Whole brain segmentation: automated labeling of neuroanatomical structures in the human brain. Neuron. 2002 Jan 31;33(3):341-55.
#[9] Bruce Fischl, Andre van der Kouwe, Christophe Destrieux, Eric Halgren, Florent Segonne, David H. Salat, Evelina Busa, Larry J. Seidman, Jill Goldstein, David Kennedy, Verne Caviness, Nikos Makris, Bruce Rosen, and Anders M. Dale. Automatically Parcellating the Human Cerebral Cortex. Cerebral Cortex January 2004; 14:11-22.
