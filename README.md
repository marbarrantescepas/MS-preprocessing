# Structural MRI Preprocessing Pipeline for Multiple Sclerosis
This pipeline is designed for structural MRI preprocessing specifically for studies related to Multiple Sclerosis (MS). It includes several preprocessing steps to automatically segment and fill MS lesions, as well as, to perform FreeSurfer preprocessing and quality check (QC) for each step.

## Contents
* [Overview](#overview)
* [How to use](#how-to-use)
* [Additional instructions](#additional-instructions)
* [Initialization](#initialization)
* [Example usage](#example-usage)

## Overview: 
This repository provides scripts to perform anatomical preprocessing using 2 different lesion segmentation methods (nicMS or LST-AI). 
![plot](https://github.com/marbarrantescepas/MS-preprocessing/blob/main/pipelines.png)

### Using nicMS: 
1. **Previous to lesion segmentation:** `01_run_preproc-nicms_v2025.01.sh` , `02_run_organize-nicms_v2025.01.sh`<br/>
2. **Lesion segmentation:** `03_lesion-seg_nicms_v2025.01.sh`, `04_postproc-nicms_v2025.01.sh`
3. **Quality control lesion segmentation:** `05_run_slicer_v2025.01.sh`
4. **Lesion filling:** `06_run_lesion-filling_v2025.01.sh`
6. **FreeSurfer cross-sectionally:** `07_run_freesurfer-cross_v2025.01.sh`
7. **Quality Check FreeSurfer:** `08_run_fsqc_v2025.01.sh`

### Using LST-AI: 

## Installation:
   
## Example Usage: 
To submit scripts of the individual steps to the slurm workload manager (sbatch), use: 
`sbatch {script_specific_step}.sh` 
Please make sure to modify all the necessary parameters before running, there are some exceptions: 
`05_run_slicer_v2025.01.sh`, see usage in the script. 

## Citation
Barrantes-Cepas M., Noteboom S., Jelgerhuis J., Fuchs T., Koubiyr I., Schoonheim M.M. (2025). Structural MRI pipeline for Multiple Sclerosis. GitHub. https://github.com/marbarrantescepas/MS-preprocessing<br/>

### Please don't forget to cite: 

## Contact
For questions, please email [Mar Barrantes Cepas](mailto:m.barrantescepas@amsterdamumc.nl).
