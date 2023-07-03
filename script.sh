#!/bin/bash

print_help() {
	echo "Usage:"
	echo "  $0 [-p|--path <directory>] [-e|--extension <extension>] [-h|--help]"
	echo "Description:"
	echo "  Search for all files with the specified extension in the given directory and its subdirectories."
	echo "  File information includes: owner, size, permissions, last modified timestamp, and full path."
	echo "  Files are grouped by owner and sorted by size."
	echo "  The report is saved into file_analysis.txt."
	echo "Options:"
	echo "  -p, --path       Specify the directory path to search"
	echo "  -e, --extension  Specify the file extension to search for"
	echo "  -h, --help       Display help message"
}

validate_path(){
	path=$1
	while [ ! -d "$path" ]; do
		echo "Error: Invalid directory path: $path"
		read -p "Please enter a valid directory path (e.g., /home) " path
	done
}

validate_extension(){
	extension=$1
	while ! [[ "$extension" =~ ^\.[A-Za-z0-9]+$ ]]; do
		echo "Error: Invalid file extension: $1"
		read -p "Please enter a valid file extension (e.g., .txt) " extension
	done
}

while [ $# -gt 0 ]; do
	case "$1" in
		-p | --path | -e | --extension)
			if [ -z "$2" ] || [ "${2:0:1}" = "-" ]; then
				echo "Missing argument for option $1"
		    	shift
			elif [ "$1" = "-p" ] || [ "$1" = "--path" ]; then
				validate_path "$2"
				shift; shift
			elif [ "$1" = "-e" ] || [ "$1" = "--extension" ]; then
				validate_extension "$2"
				shift; shift
			fi
			;;
		-h | --help)
			print_help
			exit 0
			;;
		*)
			echo "Error: Invalid option: $1"
			echo "Usage: $0 [-p|--path <directory>] [-e|--extension <extension>] [-h|--help]"
			exit 1
			;;
	esac
done

if test -z "$path"; then
	read -p "What directory do you want to search? " path
	validate_path "$path"
fi

if test -z "$extension"; then
	read -p "What extension do you want to search for? " extension
	validate_extension "$extension"
fi

extension=${extension,,} # convert extension to lowercase
echo "Searching for all files with extension $extension in directory $path"
output=$(find "$path" -name "*$extension" -type f -printf "%u %s bytes %M %TY-%Tm-%Td %TH:%TM:%.2TS %p\n" | sort -k1,1 -k2,2n)

if test -z "$output"; then
	echo "No files were found in directory $path with extension $extension."
	exit 0
fi

declare -A owner_size=()
while IFS=" " read -r owner size _; do
    owner_size[$owner]=$((owner_size[$owner] + size))
done <<< "$output"

sorted_output=$(for owner in "${!owner_size[@]}"; do
    				echo "$owner ${owner_size[$owner]}"
				done | sort -k2,2nr)

output=$(while read -r owner _; do
    		grep "^$owner" <<< "$output"
			echo 
		done <<< "$sorted_output")

echo "$output" > file_analysis.txt
echo "The report has been saved to file_analysis.txt"
