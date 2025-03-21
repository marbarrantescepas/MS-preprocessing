#!/bin/bash

#======================================================================
#              VISUAL QUALITY CHECK DATA
#======================================================================

#@author:tom fuchs, mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated: 21 March 2024, inprogress
#to-do: change usage to make it easier and generaliseable

#---------------------------------------------------------------------

# Check if directory argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Input directory not specified."
    exit 1
fi

# Take parent directory and output dir from launch input
base_dir=$(realpath "$1")

# Change working directory to the base directory
cd "$base_dir" || { echo "Failed to change directory to $base_dir"; exit 1; }
echo "Base directory: $base_dir"

# Initialize a single HTML file for all subjects
all_subjects_html="$base_dir/all_subjects_T1w_qc_images.html"

# Initialize HTML content
echo "<html><head><title>All Subjects Images</title></head><body>" > "$all_subjects_html"

# Iterate through each subdirectory in the base directory
for dir in "$base_dir"/sub-*; do
    if [ -d "$dir" ]; then
        # Change working directory to participant folder
        echo "Checking directory: $dir"
        cd "$dir" || continue
        echo "Current directory: $dir"

        # Get the directory name
        dir_name=$(basename "$dir")
        echo "Directory name: $dir_name" 

        # Create subject directory paths
        subj_dir="$base_dir/$dir_name"
        session_dir00="$subj_dir/ses-T0"
        #session_dir05="$subj_dir/ses-Y05"
        #session_dir10="$subj_dir/ses-Y10"
        echo "Subject directory: $subj_dir"
        echo "Looking for PNG files"

        # Use find to search for .png files in the directory and subdirectories
        png_files=$(find "$subj_dir" -type f -name "*T1w+mask.png")
        echo "Found PNG files: $png_files"

        # Check if any .png files were found
        if [ -n "$png_files" ]; then
            # Print the subject ID above the set of .png files
            echo "<h2>$dir_name</h2>" >> "$all_subjects_html"

            # Iterate through each .png file and add an image tag to the HTML file
            while IFS= read -r png_file; do
                echo "Adding image: $png_file"

                # Use a relative path for the image src
                relative_path=$(realpath --relative-to="$base_dir" "$png_file")

                # Add image path and image tag to the HTML file
                echo "<p> $relative_path </p>" >> "$all_subjects_html"
                echo "<img src=\"$relative_path\" alt=\"$png_file\"><br>" >> "$all_subjects_html"
            done <<< "$png_files"
        fi

        echo "-------------------------"
    fi
done

# Close HTML content
echo "</body></html>" >> "$all_subjects_html"
