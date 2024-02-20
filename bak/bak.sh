#!/bin/bash

# Author: ibourn

VERBOSE=true                    # true or false
ONLY_CURRENT_DIRECTORY=false    # true or false
MODE="BACKUP"                   # "BACKUP" or "COPY"

# Function to throw an error message and exit the script
error() {
    echo "Error: $1" && exit 1
}

# Function to print a message and log it in the bak_logs.txt file
print_and_log() {
    local message="$1"          # message to print and log
    local parent_directory="$2" # used when .backup does not exist (init and reset commands)

    if [ "$VERBOSE" = true ]; then
        echo "$message"
    fi
    if [ -e .backup ]; then
        parent_directory=$(cat .backup)
    fi
    echo "$message" >> "$parent_directory/BackUp/bak_logs.txt"
}

# Function to initialize files (.backup and .gitignore) 
initialize_files() {
    local directory="$1"
    # Check if .backup does not exist, create it, and add the parent directory to it
    if [ ! -e .backup ]; then
        if [ -n "$directory" ]; then
            echo ".." > .backup
        else
            echo "." > .backup
        fi
        print_and_log "Creating .backup file in $directory."
    fi
    # Check if .gitignore does not exist, create it, and add exclusions to it
    if [ ! -e .gitignore ]; then
        touch .gitignore && print_and_log "Creating .gitignore file in $directory." 
    fi
    if ! grep -q "# backup" .gitignore; then
        print_and_log "Adding entries to .gitignore." 
        echo "# backup" >> .gitignore
        echo -e ".backup\nBackUp/" >> .gitignore
        echo -e "node_modules" >> .gitignore 
    fi
}

# Function to initialize the backup system
initialize_bak() {
    local options="$1"
    # Check if the target directory is a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        error "Folder $target_directory is not in a Git repository. No git No commit. Please initialize Git before continuing."
    fi
    # Check if the BackUp directory exists, create it if it doesn't
    if [ ! -d "BackUp" ]; then
        mkdir -p BackUp && touch BackUp/bak_logs.txt
        print_and_log "Created BackUp directory and bak_logs.txt file." .
    fi
    initialize_files    

    if [ -n "$options" ]; then 
        # If options are provided, consider them as subdirectories and create .backup files
        for folder in $options; do 
            if [ "$folder" != "init" ]; then
                cd "$folder" && initialize_files "$folder"
                cd ..
            fi
        done
    fi
    print_and_log "Backup initialized successfully."
}

confirm() {
    read -p "$1" answer
    case $answer in
        [Yy]* ) return 0;;
        [Nn]* ) return 1;;
        * ) echo "Please answer yes or no."; return 1;;
    esac
}

# Function to confirm the project directory and the subdirectories to backup
confirm_project_directory() {
    local options="$1"
    local confirm_message="Confirm that you are in the root project directory"
    # Check if the provided directories exist
    if [ -n "$options" ]; then
        for folder in $options; do
            if [ ! -d "$folder" ]; then
                error "Directory '$folder' does not exist." 
            fi
        done
        confirm_message="$confirm_message and that your working directories are : \"$options\" "
    fi
    confirm "$confirm_message ? (y/n): "
}

# Function to reset the backup system (remove .backup files)
confirm_and_reset() {
    confirm "Are you sure you want to reset the backup system (it will only remove the .backup files) ? (y/n): " answer
    # move to the root directory
    cd $(cat .backup)
    if [ -e .backup ]; then
        rm .backup && print_and_log "Backup system reset for $(pwd)." .
    fi
    # loop through subdirectories
    for subdirectory in */; do
        if [ -e "$subdirectory/.backup" ]; then
            print_and_log "Backup system reset for $subdirectory." .
            rm "$subdirectory/.backup"
        fi
    done
}

# Function to add and commit changes. Returns the commit id
commit() {
    git add .
    if [ "$VERBOSE" = true ]; then
        git add . && git commit -m "$1"                     # print the output of the command
    else
        git add . && git commit -m "$1" > /dev/null 2>&1    # suppress the output of the command
    fi
    # return branch name and commit hash 
    echo "$(git rev-parse --abbrev-ref HEAD)-$(git rev-parse HEAD)"
}

# Function to get the next available index for the backup folder
# if file does not exist return empty string else return the '-index'
get_next_index() {
    local backup_dir="$1"
    local index=1
    if [ -e "${backup_dir}.zip" ]; then
        while [[ -e "${backup_dir}-${index}.zip" ]]; do
            ((index++))
        done
        index="-$index"
    else
        index=""
    fi
    echo "$index"
}

# Function to create a backup 
# backup & ONLY_CURRENT_DIRECTORY = true : backup only the current directory
# backup & ONLY_CURRENT_DIRECTORY = false : backup all the project
# backup <options> & MODE = COPY : backup only the options in the current directory
# params : none (backup command), commit_id (commit command) or options (copy command)
backup() {
    local backUp_id="$1"
    local backup_dir="./BackUp"
    # If backup all the project move to the root directory else adjust the backup directory
    if [ $ONLY_CURRENT_DIRECTORY = false ]; then
        cd "$(cat .backup)"
    else
        backup_dir="$(cat .backup)/BackUp"
    fi
    mkdir -p "$backup_dir"

    local target_dir=$(pwd)
    # "COPY" : backup_id is the list of the options (files or folders to backup)
    if [ "$MODE" = "COPY" ]; then
        # replace dots by spaces, replace spaces by dashes, remove trailing dashes
        backUp_id=$(printf "%s " "$@" | sed 's/\./ /g' | tr -s ' ' '-' | sed 's/\-\+$//')
    # check if backup_id exists else extract folder name from target_dir
    elif [ -z "$backUp_id" ]; then
        backUp_id=$(basename "$target_dir")
    fi

    # Create a new folder to work : BackUp/date-backup_id-index
    local current_date=$(date +'%Y%m%d-%H%M')
    local backup_folder="${backup_dir}/${current_date}-${backUp_id}"
    local index=$(get_next_index "$backup_folder")
 
    local backup_name="${current_date}-${backUp_id}${index}"
    backup_folder="${backup_folder}${index}"
    mkdir -p "$backup_folder"

    # Copy files and directories to the backup folder
    while IFS= read -r item; do
        local item_name="$(basename "$item")"
        # Check if we are in COPY mode and if the item is not in options
        if [ "$MODE" = "COPY" ] && ! [[ $options =~ $item_name ]]; then
            continue  # Skip to the next iteration of the loop
        fi
        # Check if the item is listed in the .gitignore
        if ! grep -Eq "^($item_name|${item_name}/)" .gitignore; then
            # If it's a file, copy it to the backup folder
            if [ -f "$item" ]; then
                cp -r "$item" "$backup_folder"
            # If it's a directory and it contains a .backup file, copy and exclude files listed in .gitignore
            elif [ -d "$item" ] && [ -e "$item/.backup" ]; then
                rsync -a --exclude-from="$item/.gitignore" "$item/" "$backup_folder/${item#./}"
            # If it's a directory and it doesn't contain a .backup file
            elif [ -d "$item" ]; then
                cp -r "$item" "$backup_folder"
            fi
        fi
    done < <(find . -mindepth 1 -maxdepth 1)

    cd "$(cat .backup)/BackUp"
    zip -rq "$backup_name.zip" "$backup_name"
    rm -rf "$backup_name"
    cd - > /dev/null
    print_and_log "Back up done: $backup_name.zip"
}

# Function to unzip a backup file
unzip_backup() {
    local zip_file="$1"
    cd "$(cat .backup)/BackUp"
    # Check if the zip file exists and is a zip file
    if [ ! -e "$zip_file" ] || ! [[ "$zip_file" =~ \.zip$ ]]; then
        error "The file does not exist or is not a zip file."
    
    fi
    # unzip the file in a folder with the same name
    local folder_name=$(basename "$zip_file" .zip)
    mkdir -p "$folder_name" && unzip -q "$zip_file" 
    cd - > /dev/null
    print_and_log "Unzip done: $zip_file"
}

help() {
    echo "bak is a utility script to backup your project and commit changes."
    echo ""
    echo "First:  initialize bak in the root project directory with, as options, your working subdirectories (ex : front back, or \"\")"
    echo "        working directories are considered those containing a .gitignore file to be abble to filter files to backup."
    echo "Next:   commands should be run in a working directory (the root of the project or a subdirectory given as init options)."
    echo "Change: if you want to add/remove a working directory use the reset command and then the init command with the desired options."
    echo ""
    echo "Usage: bak [-flags] [command] [options]"
    echo ""
    echo "Commands:"
    echo "  init [options]       Initialize the backup system."
    echo "      options          subdirectories to backup (it allows to filter working directories for mono repos..)."
    echo "      no options       simple project with a .gitignore at the root."
    echo "  reset                Reset the backup system (will not remove the BackUp folder if it exists)."
    echo "  commit \"message\"     Add and commit changes, then create a backup. (see flag -p to filter backup)"
    echo "  backup               Create a backup of the project (see flag -p to backup only the current subdirectoy)."
    echo "  copy [options]       Create a backup of a file(s) or folder(s) of the current directory (no commit)."
    echo "      options          file(s) or folder(s) to backup."
    echo "  unzip file_name      Unzip a backup file."
    echo "Flags:"
    echo "  -q                   Disable verbose mode."
    echo "  -p                   Backup only the current subdirectory (works only with commit command)."
    echo ""
    echo "Examples:"
    echo "  bak init                    ->  Initialize the backup system for the root directory (only .gitignore of root will be used)."
    echo "  bak init front back         ->  Initialize the backup system for the root directory and for the front and back subdirectories."
    echo "  bak reset                   ->  Reset the backup system."
    echo "  bak -p commit \"myMessage\" ->  Commit changes and create a backup for the current directory only (without -p = for all the project)."
    echo "  bak backup                  ->  Create a backup of the project (-p = only the current directory)."    
    echo "  bak copy file1.js file2.txt ->  Create a backup of file1.js file2.txt (no commit)."
    echo "  bak unzip myBackup.zip      ->  Unzip a backup file."
    echo ""
    echo "Prerequisites:"
    echo "  The project directory must be a git repository."
    echo "  Working directories should contain a .gitignore file (will create it if it does not exist)"
 }

# Manage flags
while getopts "qp" opt; do
    case $opt in
        q) VERBOSE=false ;;
        p) ONLY_CURRENT_DIRECTORY=true ;;
        \?) echo "Invalid option. Type 'bak help' for more information." ; exit 1 ;;
    esac
done
shift $((OPTIND -1))

# Manage Commands
if [ "$1" = "help" ]; then
    help
elif [ "$1" = "init" ]; then
    if [ -e .backup ]; then
        error ".backup file(s) already exists."
    fi
    options="${@:2}"
    confirm_project_directory "$options" || exit 1
    initialize_bak "$options"
else
    # Check if the .backup file exists (so the project is initialized)
    if [ -e .backup ]; then
        if [ "$1" = "commit" ]; then
            # Git commit and capture the output of commit function into an array
            mapfile -t output_array < <(commit "$2")
            last_index=$(( ${#output_array[@]} - 1 ))
            commit_id="${output_array[$last_index]}"

            unset 'output_array[$last_index]'
            commit_message="${output_array[*]}"         
            print_and_log "Commit done: $commit_message, commit id: $commit_id"

            backup "$commit_id"
        elif [ "$1" = "backup" ]; then
            backup "$2"
        elif [ "$1" = "unzip" ]; then
            unzip_backup "$2"
        elif [ "$1" = "copy" ]; then
            options="${@:2}"
            if [ -z "$options" ]; then
                error "Please provide at least one file or folder name to backup."
            fi
            MODE="COPY"
            ONLY_CURRENT_DIRECTORY=true
            backup "$options"
        elif [ "$1" = "reset" ]; then
            confirm_and_reset
        else
            error "Invalid command. Please run 'bak help'"
        fi
    else
        error ".backup file does not exist. Please run 'bak init' or 'bak help'."
    fi
fi
# End of the script
# do before : chmod +x file_name.sh




