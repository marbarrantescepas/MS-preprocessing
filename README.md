# Structural MRI Preprocessing Pipeline for Multiple Sclerosis
This pipeline is designed for structural MRI preprocessing specifically for studies related to multiple sclerosis (MS) using T1-weighted (T1w) and T2-weighted fluid-attenuated inversion-recovery (FLAIR) images. It includes several preprocessing steps to automatically segment and fill MS lesions, as well as, to perform FreeSurfer preprocessing and quality check (QC) for each step.

## Contents
* [Overview](#overview)
* [Installation](#installation)
* [Usage](#usage)
* [Citation](#citation)
* [Contact](#contact)

## Overview: 
This repository provides scripts to perform anatomical preprocessing using two different lesion segmentation methods (nicMS or LST-AI). 
![plot](https://github.com/marbarrantescepas/MS-preprocessing/blob/main/pipelines.png)

### Using nicMS pipeline: 
1. **Previous to lesion segmentation:** `01_run_preproc-nicms_v2025.01.sh` , `02_run_organize-nicms_v2025.01.sh`<br/>
2. **Lesion segmentation:** `03_lesion-seg_nicms_v2025.01.sh`, `04_postproc-nicms_v2025.01.sh`<br/>
3. **Manual correction:** use `05_run_slicer_v2025.01.sh` to open automatically scans in 3D Slicer.<br/>
3. **Lesion filling:** `06_run_lesion-filling_v2025.01.sh` <br/>
4. **FreeSurfer cross-sectionally:** `07_run_freesurfer-cross_v2025.01.sh` <br/>
5. **Quality Check FreeSurfer:** `08_run_fsqc_v2025.01.sh` <br/>
6. **Manual correction FS:** for further information on FreeSurfer manual edits, check the FreeSurfer webpage. <br/>

### Using LST-AI pipeline: 

Under construction.

## Installation:
`git clone https://github.com/marbarrantescepas/MS-preprocessing.git`

## Usage: 
To submit scripts of the individual steps to the slurm workload manager (sbatch), use: 
`sbatch {script_specific_step}.sh` 
Please make sure to modify all the necessary parameters before running, there are some exceptions: 
`05_run_slicer_v2025.01.sh`, see usage in the script. 

## Citation
Barrantes-Cepas M., Noteboom S., Jelgerhuis J., Fuchs T., Koubiyr I., Schoonheim M.M. (2025). Structural MRI pipeline for Multiple Sclerosis. GitHub. https://github.com/marbarrantescepas/MS-preprocessing<br/>

### Software used: 
- **FSL**: M. Jenkinson, C.F. Beckmann, T.E. Behrens, M.W. Woolrich, S.M. Smith. FSL. NeuroImage, 62:782-90, 2012
- **ANTs**: Isensee F, Schell M, Pflueger I, et al. Automated brain extraction of multisequence MRI using artificial neural networks. Hum Brain Mapp. 2019;40(17):4952-4964. doi:10.1002/hbm.24750 https://github.com/ANTsX/ANTs
- **nicMS**: Valverde S, Salem M, Cabezas M, et al. One-shot domain adaptation in multiple sclerosis lesion segmentation using convolutional neural networks. Neuroimage Clin. 2019;21:101638. doi:10.1016/j.nicl.2018.101638
- **LST-AI**: Wiltgen T, McGinnis J, Schlaeger S, et al. LST-AI: a Deep Learning Ensemble for Accurate MS Lesion Segmentation. Preprint. medRxiv. 2024;2023.11.23.23298966. Published 2024 Mar 11. doi:10.1101/2023.11.23.23298966
- **3D Slicer**: Kikinis R, Pieper SD, Vosburgh K (2014) 3D Slicer: a platform for subject-specific image analysis, visualization, and clinical support. Intraoperative Imaging Image-Guided Therapy, Ferenc A. Jolesz, Editor 3(19):277–289 ISBN: 978-1-4614-7656-6 (Print) 978-1-4614-7657-3 (Online)
- **LST (for filling)**:  Schmidt P, Gaser C, Arsic M, et al. An automated tool for detection of FLAIR-hyperintense white-matter lesions in Multiple Sclerosis. Neuroimage. 2012;59(4):3774-3783. doi:10.1016/j.neuroimage.2011.11.032
- **FreeSurfer**: see FreeSurfer for more information https://surfer.nmr.mgh.harvard.edu/fswiki/recon-all
- **FreeSurfer QC**: Esteban O, Birman D, Schaer M, Koyejo OO, Poldrack RA, Gorgolewski KJ; 2017; MRIQC: Advancing the Automatic Prediction of Image Quality in MRI from Unseen Sites; PLOS ONE 12(9):e0184661; doi:10.1371/journal.pone.0184661.

## Contact
For questions, please email [Mar Barrantes Cepas](mailto:m.barrantescepas@amsterdamumc.nl).
