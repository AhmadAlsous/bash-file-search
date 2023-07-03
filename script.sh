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
    if [ ! -d "$1" ]; then
	echo "Error: Invalid directory path: $1"
	echo "Please enter a valid directory path (e.g., /home)."
	exit 2
    fi
}

validate_extension(){
    if ! [[ "$1" =~ ^\.[A-Za-z0-9]+$  ]]; then
	echo "Error: Invalid file extension: $1"
	echo "Please enter a valid file extension (e.g., .txt)."
	exit 3
    fi
}

path=""
extension=""

while [ $# -gt 0 ]; do
	case "$1" in
		-p | --path)
			validate_path "$2"
			path=$2
			shift; shift
			;;
		-e | --extension)
			validate_extension "$2"
			extension=$2
			shift; shift
			;;
		-h | --help)
			print_help
			exit 0
			;;
		*)
			echo "Error: Invalid option: $1"
			print_help
			exit 1
			;;
	esac
done

if test -z "$path"; then
	read -p "What directory do you want to search? " path
fi
validate_path "$path"

if test -z "$extension"; then
	read -p "What extension do you want to search for? " extension
fi
validate_extension "$extension"

extension=${extension,,} # convert extension to lowercase
output=$(find "$path" -name "*$extension" -type f -printf "%u %s bytes %M %TY-%Tm-%Td %TH:%TM:%.2TS %p\n" | sort -k1,1 -k2n)

if test -z "$output"; then
	echo "No files were found in directory $path with extension $extension."
	exit 0
fi

echo "$output" >file_analysis.txt
echo "The report has been saved to file_analysis.txt"
