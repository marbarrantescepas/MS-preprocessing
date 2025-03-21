#======================================================================
#      create screenshots T1w filled and T1w + lesion mask
#======================================================================

#@author: tom fuchs, mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated: March 2025, works

#---------------------------------------------------------------------

import nilearn
from nilearn import plotting, image
import nibabel
import os
import sys
import csv
import matplotlib.pyplot as plt
import matplotlib.image as mpimg

# Function to read subject IDs from CSV file
def read_subject_ids(subject_id_filepath):
    subject_list = []
    with open(subject_id_filepath, 'r') as file:
        reader = csv.reader(file)
        for row in reader:
            subject_list.extend(row)
    return subject_list

#file inputs <func_base_directory> <anat_base_directory> <subject_session_list>
def main():
    if len(sys.argv) != 4:
        print("Usage: python script.py <input_dir> <output_dir> <subject_session_id_list>")
        sys.exit(1)
    
    
    base_dir = sys.argv[1] #set base directory
    output_dir_dir = sys.argv[2] #set output directory 
    subject_id_filepath = sys.argv[3] #set subject list
    
    print(f"The base directory provided is: {base_dir}")
    print(f"The output directory provided is: {output_dir_dir}")
    print(f"The subject session ID list provided is: {subject_id_filepath}")

    # Read subject IDs from CSV file
    subject_session_list = read_subject_ids(subject_id_filepath)
    subjects = []
    sessions = []

    # Loop through the subject_session_list and extract the subject and session
    for item in subject_session_list:
        subject, session = item.split('_')
    
	# Append to the lists
	subject_list.append(subject)
	session_list.append(session)

    #Create output directory 
    print(f"The output images will be stored in: {output_dir_dir}")
    os.system(f"mkdir -p {output_dir_dir}")

    #set color map for overlay
    colors=plt.cm.hot_r
    
    #create empty string for file list. to be used in pdf generation
    files_as_string = ""
    
    for subject_id in subject_list:
        print(f"Starting with subject: {subject_id}")
        #create output dir for subject and each session
        subject_output_dir = output_dir_dir + "/" + subject_id

        for session_id in session_list:
            print(f"Starting with session: {session_id}")
            session_dir = subject_output_dir + "/" + session_id
            os.system(f"mkdir -p {session_dir}")
	
            t1w = base_dir +  "/" + subject_id + "/" + session_id +"/" + subject_id + "_" + session_id + "_T1w.nii.gz"
            t1w_filled = base_dir +  "/" + subject_id + "/" + session_id +"/" + subject_id + "_" + session_id + "_space-t1w_T1w-filled.nii.gz"
            lesion_mask = base_dir +  "/" + subject_id + "/" + session_id +"/" + subject_id + "_" + session_id + "_space-t1w_seg-lst.nii.gz"
        
            print("Paths to files:")
            print(t1w)
            print(t1w_filled)
            print(lesion_mask)
            
            #plot and save t1w filled image
            if os.path.exists(t1w_filled) :

                try:
                    t1w01_raw = nibabel.load(t1w_filled)
                    t1w01_title = subject_id + "_" + session_id + "_T1w_filled.nii.gz"
                    t1w01 = plotting.plot_anat(t1w01_raw, display_mode="mosaic", cut_coords=20, title=t1w01_title)
                    t1w01.savefig(session_dir + "/T1w_filled.png")
                    t1w_plot_location01 = output_dir_dir + "/" + subject_id + "/" + session_id + "/T1w_filled.png"
                    print(t1w_plot_location01)
                except:
                    print("{}: Error reading image".format(t1w_filled))
                    continue
            else:
                print("{}: Missing image".format(t1w_filled))

            #plot and save T1w + lesion mask image
            if os.path.exists(t1w) and os.path.exists(lesion_mask):

                 try:
                     anat00_title = subject_id + session_id + "T1w + lesion mask"
                     anat00 = nibabel.load(t1w)
                     anat_plot00 = plotting.plot_anat(t1w, display_mode="mosaic", cut_coords=20, title = anat00_title)
                     anat_plot00.add_overlay(lesion_mask, cmap=colors, threshold=0, alpha=0.8)
                     anat_plot00.savefig(session_dir + "/T1w+mask.png")
                     anat_plot_location00 = session_dir + "/T1w+mask.png"
                     print(anat_plot_location00)
                   
                 except:
                     print("{}: Error reading t1w image or lesion mask".format(subject_id))
                     continue
            else:
                 print("{}: Missing t1w image or lesion mask".format(subject_id))
     

if __name__ == "__main__":
    main()
