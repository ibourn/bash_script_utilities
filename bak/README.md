# bak.sh

This is a bash script to **backup your project and commit changes**.

---

## Table of Contents

1. [Requirements](#requirements)
2. [Getting Started](#getting-started)
3. [How it works](#how-it-works)
   - [Prerequisites](#prerequisites)
   - [In short](#in-short)
   - [Explanations](#explanations)
4. [Usage](#usage)
   - [Commands](#commands)
   - [Flags](#flags)
   - [Examples](#examples)
5. [Toubleshooting](#troubleshooting)

## Requirements :

[git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

You'll know you did it right if you can run `git --version`.

## Getting Started :

_It will move the script in /usr/local/bin (making it available to all users)
and make it executable ._

With the installer _(bak_install.sh)_ :

1. Clone the repository and navigate to the project directory.
2. Make bak_install.sh executable by running `chmod +x bak_install.sh`.
3. Run the script using `./bak_install.sh`.

**or** 'manually' :

1. Copy bak.sh, then run in your terminal :
2. `sudo mv bak.sh /usr/local/bin/bak`, to make it available for all users.
3. `sudo chmod +x /usr/local/bin/bak`, to make it executable.

optional :

4. `sudo chown root:root /usr/local/bin/bak` to prevent any other user to write to the script.

## How it works :

### Prerequisites :

- The project directory must be a git repository.
- Working directories should contain a .gitignore file (will be created if it does not exist).

### In short :

- Initialize bak in the root project directory with your working subdirectories (if needed)
- Execute commands in a working directory.
- Changes: Use the reset and then the init commands to add or remove working directories.

### Explanations :

The project to backup should be a git repository to allow git commands. Working directories should have .gitignore files to exclude files from the backup, the script will create them otherwise to exclude the BackUp folder and .backup files.

At initialization, bak creates a .backup file in specified working directories and a BackUp directory where you can find your backup files and a log of the actions. .backup files are used to navigate the project and read .gitignore files.

The current directory when using init command is considered as the root of your project and will have, by default, a .backup file. If you have multiple working directories, specify them with the init command (e.g., `bak init frontend backend`).

Several commands are available to backup :

- commit : Add and commit changes and create a backup of the whole project or only the current working directory with the -p flag.
- backup : Create a backup of the project without adding and committing changes.
- copy : Save a copy of specified files or folders of the current directory without commit.

The backup name follows the format: `yyyymmdd-HHMM-name_or_id-index.zip`, where `name_or_id` can be one of the following :

- For the commit command : `<branch>-<commit_hash>`
- For the backup command : a custom name if specified, or the directory name (root directory or current directory with -p flag)
- For the copy command : the items specified, separated by '-'.

If you want to add or remove a working directory use the reset command. It will only delete the .backup files (will not remove the BackUp folder if it exists). And then init again with the desired directory as options.

## Usage

`bak [-flags] [command] [options]`

### Commands:

- `help` : Get information and usage of the script.
- `init [options]` : Initialize the backup system.
  - options : Void (simple project) or working subdirectories to be used.
- `reset` : Reset the backup system.
- `commit "message"` : Add and commit changes, then create a backup (use -p flag to backup only the current directory).
  - message : The commit message is mandatory and copied in the back_logs file.
- `backup [backup_name]` : Create a backup of the project (use -p flag to backup only the current directory).
  - backup_name : Optional, default name is root directory or current directory with -p flag.
- `copy items` : Create a backup of specified files or folders of the **current directory** (no commit).
  - items : Files or folders to backup, at least one.
- `unzip file_name` : Unzip a backup file. A new folder with the name of the file will be created in BackUp.
  - file_name : The file to unzip.

### Flags:

- `-q` : Disable verbose mode.
- `-p` : Backup only the current subdirectory (works only with commit and backup commands).

### Examples:

- `bak init` -> Initialize the backup system for the root directory (only .gitignore of root will be used).
- `bak init front back` -> Initialize the backup system for the root directory and for the front and back subdirectories. Commands can be run in root, front, and back. Files listed in their .gitignore will be excluded from the backups.
- `bak -p commit "myMessage"` -> Add and commit changes and create a backup for the current directory only.
- `bak backup` -> Create a backup of the whole project (no commit).
- `bak copy file1.js file2.txt` -> Create a backup of file1.js file2.txt (no commit).
- `bak unzip myBackup.zip` -> Unzip myBackup.zip.

## Troubleshooting :

- **"I installed it but it doesn't work"** :

  - Reload or open a new terminal for the script to be taken into account.

- **"i'm in a subdirectory and the command doesn't work"** :
  - Be sure you specified the subdirectory whith the init command (a .backup file should be in the subdirectory). bak command works only at the root and in the working directories you specified.
  - Use reset then init commands to add your subdirectory.
- **"the backup don't exclude things specified in .gitignore"** :

  - Only .gitignore of 'working directories' are considered.
  - Use reset then init commands to add your subdirectory.

- **"i can't run 'bak' command"** :
  - If you installed it elsewhere than in /usr/local/bin:
    - make sure to add the folder to PATH
    - **or** add at the end of your . bashrc :
      ```bash
      function bak() {
      /your/Path/To/Bak/bak "$@"
      }
      ```
      then run `source ~/.bashrc` to aplly changes.
  - if you didn't follow the process above ([Getting Started](#getting-started)) but only copy the script in your project, you need to replace in your command 'bak' with './bak.sh'
  - 'bak' commands can only be launched on 2 levels : at the root of the project and in its subfolders that you specify with 'init'

### _Feel free to explore and suggest improvements!_
