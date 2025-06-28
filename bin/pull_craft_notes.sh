#!/usr/bin/env bash

# Check if ASK_MY_NOTES_HOME is set
if [ -z "$ASK_MY_NOTES_HOME" ]; then
    echo "Error: ASK_MY_NOTES_HOME environment variable is not set"
    exit 1
fi

ASK_MY_NOTES_MD_DIR="$ASK_MY_NOTES_HOME/craft_notes_md"

# Function to process textbundles
process_textbundles() {
    local source_dir="$1"
    local target_dir="$2"
    local processed_count=0
    
    # Normalize source_dir by removing trailing slash if present
    source_dir="${source_dir%/}"

    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"

    # Find all text.markdown files in TextBundle directories
    while IFS= read -r markdown_file; do
        # Get the directory containing the markdown file
        bundle_dir=$(dirname "$markdown_file")
        
        # Get the relative path from source directory
        rel_path="${bundle_dir#$source_dir/}"
        
        # Remove .textbundle extension if present
        if [[ "$rel_path" == *".textbundle" ]]; then
            rel_path="${rel_path%.textbundle}"
        fi
        
        # Replace path separators with dashes
        new_filename=$(echo "$rel_path" | tr '/' '-')
        
        # Clean up filename (remove invalid characters)
        new_filename=$(echo "$new_filename" | sed 's/[^a-zA-Z0-9_]]*/_/g')
        
        # Remove dynamic export path prefix (handles any export date)
        new_filename=$(echo "$new_filename" | sed 's/_Users_mremy_Dropbox_martin_backups_Craft_Notes_Exports_Export_[0-9]*_TextBundle_//g')
        
        # Remove Martin's Space prefix pattern
        new_filename=$(echo "$new_filename" | sed 's/Martin___s_Space_//g')
        
        # Remove leading and trailing spaces and add .md extension
        new_filename=$(echo "$new_filename" | sed 's/^ *//g' | sed 's/ *$//g')
        new_filename="$new_filename.md"
        
        # Source and destination file paths
        target_file="$target_dir/$new_filename"
        
        # Copy the content
        if cp "$markdown_file" "$target_file"; then
            ((processed_count++))
            echo "Processed: $rel_path → $new_filename"
        else
            echo "Error processing $markdown_file"
        fi
    done < <(find "$source_dir" -name "text.markdown")
    
    echo "$processed_count"
}

# Main conversion function
convert() {
    local source_dir="$1"
    local target_dir="$ASK_MY_NOTES_MD_DIR"
    
    # Check if target directory exists
    if [ ! -d "$target_dir" ]; then
        echo "Target directory $target_dir does not exist. Please create it before running this script."
        return 1
    fi
    
    # Check if source directory exists
    if [ ! -d "$source_dir" ]; then
        echo "Source directory $source_dir does not exist. Please create it before running this script."
        return 1
    fi
    
    # Delete all contents of target_dir before processing
    echo "Warning: Before copying the latest Craft export, I'm going to delete everything in [$target_dir]"
    read -p "Is that ok? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "Deleting contents of target directory..."
        rm -rf "$target_dir"/*
    else
        echo "OK, never mind."
        return 0
    fi
    
    echo "Starting TextBundle conversion from $source_dir to $target_dir"
    count=$(process_textbundles "$source_dir" "$target_dir")
    echo "Conversion complete. Processed $count TextBundle files."
}

# Check if source directory is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <craft_textbundle_export_dir>"
    echo "Example: $0 ~/Dropbox/backups/Craft_Notes_Exports/Export_20250319_TextBundle"
    exit 1
fi

# Call the conversion function with the provided source directory
convert "$1"
