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

validate_directory(){
	directory=$1
	while [ ! -d "$directory" ]; do
		echo "Error: Invalid directory path: $directory"
		read -p "Please enter a valid directory path (e.g., /home) " directory
	done
}

validate_extension(){
	extension=$1
	if ! [[ "$extension" =~ ^\.[A-Za-z0-9]+$ ]]; then
		echo "Error: Invalid file extension: $extension"
		return 1
	fi
	return 0
}

validate_filter_option(){
    if ! [[ "$1" =~ $2 ]]; then
        echo "Error: Invalid file $3: $1"
        return 2
    fi
    local -n filter=$4
	filter="$1"
    return 0
}

size="-1000G"
time_minute="+0"
time_day="-999999"
permission="000"

while [ $# -gt 0 ]; do
	case "$1" in
		-d | --directory | -e | --extension | -p | --permission)
			if [ -z "$2" ] || [[ "$2" == -* ]]; then
				echo "Error: Missing argument for option $1"
		    	shift
			elif [ "$1" = "-d" ] || [ "$1" = "--directory" ]; then
				validate_directory "$2"
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
			elif [ "$1" = "-p" ] || [ "$1" = "--path" ]; then
				validate_filter_option $2 "^([0-7]{3}|(([ugoa]=[rwx],)*[uoga]=[rwx]))$" "permission" "permission"
				shift 2
			fi
			;;
		-s | --size | -tm | --timeminute | -td | --timeday)
			if [ -z "$2" ]; then
				echo "Error: Missing argument for option $1"
                shift
			elif [ "$1" = "-s" ] || [ "$1" = "--size" ]; then
				validate_filter_option $2 "^[+-]?[0-9]+[bcwkMG]$" "size" "size"
				shift 2
			elif [ "$1" = "-tm" ] || [ "$1" = "--timeminute" ]; then
				validate_filter_option $2 "^[+-]?[0-9]+$" "last modified time" "time_minute"
				shift 2
			elif [ "$1" = "-td" ] || [ "$1" = "--timeday" ]; then
				validate_filter_option $2 "^[+-]?[0-9]+$" "last modified time" "time_day"
            	shift 2
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

if [ -z "$directory" ]; then
	read -p "What directory do you want to search? " directory
	validate_directory "$directory"
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

echo "Searching for files with extension ${extensions[@]} in directory $directory"
output=$(find "$directory" -regex ".*\($regex_pattern\)$" -type f -size "$size" -mmin "$time_minute" -mtime "$time_day" -perm "-$permission" -printf "%u %s bytes %M %AF %Ar %p\n" | sort -k2,2n)

if [ -z "$output" ]; then
	echo "No files were found in directory $directory with extension ${extensions[@]}."
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
