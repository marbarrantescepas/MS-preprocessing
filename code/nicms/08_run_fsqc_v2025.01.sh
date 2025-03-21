#!/bin/bash

#Below block for SLURM users. If you are not a SLURM user, remove this block 
#and change below references to SLURM for parallel processing. 
#SBATCH --job-name=fsqc                 #a name for your job
#SBATCH --mem=4G                        #max memory per node 
#SBATCH --partition=luna-cpu-short      #using luna queue
#SBATCH --cpus-per-task=4               #max CPU cores per process
#SBATCH --time=04:00:00                 #time limit (DD-HH:MM)
#SBATCH --nice=4000                     #priority jobs 
#SBATCH --qos=anw-cpu                   
#SBATCH --output=slurm_logs/slurm-%x.%j_%A_%a.out  #store log files
#SBATCH --array=1-XX%YY                #first-last%parallel subj

#======================================================================
#              VISUAL QUALITY CHECK FREESURFER DATA
#======================================================================

#@author: mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated: 12 Febuary 2024, works
#todo: change fsqc locally to luna-server

#Description
# Input: Folder includying subjects folders with FreeSurfer output
# Output: Folder with CSV, screenshoots, HTML, and log files
# Run: Captures different screenshots from the brain + surface 
# segmentation from FreeSurfer and combines them into a HTML file. 
# It also provides a CSV file with some parameters and log file.
# See more information in https://github.com/Deep-MI/fsqc

# Requirements: 
# Please install the fsqc tool https://github.com/Deep-MI/fsqc
# If not already install in your system. 

#Please change the following things:
# - array: change according the number of participants study (line 12)
# - dir & output folder: change your input and output folders (line 44 & 45)
# - change path to fsqc tool if using different system (line 61)
#---------------------------------------------------------------------

# Define paths to data
curdir=`pwd`
dir=/path/to/freesurfer           #please modify
output=/path/to/freesurfer_qc     #please modify

# To use array parallel processing, you create a .txt file with a list of each subject folder.
cd ${dir}
ls -d sub-*/ | sed 's:/.*::' > ${curdir}/subjects-fsqc_${sess}.txt
subjid=$(sed "${SLURM_ARRAY_TASK_ID}q;d" ${curdir}/subjects-fsqc_${sess}.txt)
cd ${curdir}

# Run lesion filling for all sessions
subject_dir=${dir}/${subjid}
for sessdir in ${subject_dir}/*; do

    echo $sessdir
    sess=${sessdir##/*/}

    if [ ! -d ${output}/${subjid} ]; then 
          /opt/aumc-containers/singularity/fsqc/fsqc-v2.1.1.sif --subjects_dir ${subject_dir} --output_dir ${output}/${subjid} \
        --screenshots_overlay none --screenshots-html --screenshots_layout 15 3 \
        --screenshots_views  x=-65 y=-65 z=-40 x=-60 y=-60 z=-35 x=-50 y=-50 z=-30 x=-40 y=-40 z=-40 x=-30 y=-30 z=-25 x=-20 y=-20 z=-20 \
        x=-10 y=-10 z=-10 x=0 y=0 z=0 x=10 y=10 z=10 x=20 y=20 z=20 x=30 y=30 z=30 x=40 y=40 z=35 x=50 y=50 z=40 x=50 y=50 z=45 x=60 y=60 z=50
    fi 
done

#---------------------------------------------------------------------
# References
#---------------------------------------------------------------------

#Esteban O, Birman D, Schaer M, Koyejo OO, Poldrack RA, Gorgolewski KJ; 2017; MRIQC: Advancing the Automatic Prediction of Image Quality in MRI from Unseen Sites; PLOS ONE 12(9):e0184661; doi:10.1371/journal.pone.0184661.
#Wachinger C, Golland P, Kremen W, Fischl B, Reuter M; 2015; BrainPrint: a Discriminative Characterization of Brain Morphology; Neuroimage: 109, 232-248; doi:10.1016/j.neuroimage.2015.01.032.
#Reuter M, Wolter FE, Shenton M, Niethammer M; 2009; Laplace-Beltrami Eigenvalues and Topological Features of Eigenfunctions for Statistical Shape Analysis; Computer-Aided Design: 41, 739-755; doi:10.1016/j.cad.2009.02.007.
#Potvin O, Mouiha A, Dieumegarde L, Duchesne S, & Alzheimer's Disease Neuroimaging Initiative; 2016; Normative data for subcortical regional volumes over the lifetime of the adult human brain; Neuroimage: 137, 9-20; doi.org/10.1016/j.neuroimage.2016.05.016
