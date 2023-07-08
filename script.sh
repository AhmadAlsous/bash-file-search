#!/bin/bash

print_help() {
	echo "Usage:"
	echo "  $0 [-p|--path <directory>] [-e|--extension <extensions>] [-h|--help]"
	echo "Description:"
	echo "  Search for all files with the specified extensions in the given directory and its subdirectories."
	echo "  File information includes: owner, size, permissions, last modified timestamp, and full path."
	echo "  Files are grouped by owner and sorted by size."
	echo "  The report is saved into file_analysis.txt."
	echo "Options:"
	echo "  -p, --path       Specify the directory path to search"
	echo "  -e, --extension  Specify the file extensions to search for"
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
	if ! [[ "$extension" =~ ^\.[A-Za-z0-9]+$ ]]; then
		echo "Error: Invalid file extension: $1"
		return 1
	fi
	return 0
}

while [ $# -gt 0 ]; do
	case "$1" in
		-p | --path | -e | --extension)
			if [ -z "$2" ] || [[ "$2" == -* ]]; then
				echo "Missing argument for option $1"
		    	shift
			elif [ "$1" = "-p" ] || [ "$1" = "--path" ]; then
				validate_path "$2"
				shift 2
			elif [ "$1" = "-e" ] || [ "$1" = "--extension" ]; then
				shift
				extensions=()
				while [[ "$1" != -* ]] && [ $# -gt 0 ]; do
					validate_extension $1
					if [ $? -eq 0 ]; then
						extensions+=("$1")
					fi
					shift
				done
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

if [ -z "$path" ]; then
	read -p "What directory do you want to search? " path
	validate_path "$path"
fi

while [ -z "$extensions" ]; do
	read -p "What extensions do you want to search for? " exts
	IFS=' ' read -ra user_extensions <<< "$exts"
	for extension in "${user_extensions[@]}"; do
		validate_extension "$extension"
		if [ $? -eq 0 ]; then
			extensions+=("$extension")
		fi
	done
done

regex_pattern=""
for ext in "${extensions[@]}"; do
  if [ -n "$regex_pattern" ]; then
    regex_pattern+="\|"
  fi
  regex_pattern+="$ext"
done

echo "Searching for all files with extension ${extensions[@]} in directory $path"
output=$(find "$path" -regex ".*\($regex_pattern\)$" -type f -printf "%u %s bytes %M %AF %Ar %p\n" | sort -k2,2n)

if [ -z "$output" ]; then
	echo "No files were found in directory $path with extension $extension."
	exit 0
fi

declare -A owner_size=()
while read owner size _; do
    owner_size[$owner]=$((owner_size[$owner] + size))
done <<< "$output"

sorted_output=$(for owner in "${!owner_size[@]}"; do
    				echo "$owner ${owner_size[$owner]}"
				done | sort -k2,2nr)

output=$(while read owner _; do
    		grep "^$owner" <<< "$output"
			echo
		done <<< "$sorted_output")

echo "$output" > file_analysis.txt
echo "The report has been saved to file_analysis.txt"
