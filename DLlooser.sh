#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Display banner
echo -e "${RED}"
echo "▗▄▄▄  █ ▗▖  ▄▄▄   ▄▄▄   ▄▄▄ ▗▞▀▚▖ ▄▄▄ "
echo "▐▌  █ █ ▐▌ █   █ █   █ ▀▄▄  ▐▛▀▀▘█    "
echo "▐▌  █ █ ▐▌ ▀▄▄▄▀ ▀▄▄▄▀ ▄▄▄▀ ▝▚▄▄▖█    "
echo "▐▙▄▄▀ █ ▐▙▄▄▖                         "
echo "      █▄▄▄▄▄▄▖                        "
echo "                           By GabriWar"
echo -e "${NC}"

# Function to search for SteamLibrary folder
search_steam_library() {
	local drive=$1
	find "$drive" -type d -name "SteamLibrary" 2>/dev/null
}

# Get a list of mounted drives
drives=$(lsblk -o MOUNTPOINT -nr | grep -v '^$')

# Initialize an array to store SteamLibrary paths
steam_libraries=()

# Search for SteamLibrary folder on each drive
for drive in $drives; do
	result=$(search_steam_library "$drive")
	if [ -n "$result" ]; then
		steam_libraries+=("$result")
		echo -e "${GREEN}SteamLibrary found at: $result${NC}"
	fi
done

# Print all found SteamLibrary paths
echo -e "${GREEN}All found SteamLibrary paths:${NC}"
for library in "${steam_libraries[@]}"; do
	echo "$library"
done

# Initialize an array to store game paths
game_paths=()

# Find game names inside the common folder of each SteamLibrary
echo -e "${GREEN}Game names found in common folders:${NC}"
for library in "${steam_libraries[@]}"; do
	common_folder="$library/steamapps/common"
	if [ -d "$common_folder" ]; then
		echo "Games in $common_folder:"
		for game in "$common_folder"/*; do
			if [ -d "$game" ]; then
				game_paths+=("$game")
				echo "  $(basename "$game")"
			fi
		done
	else
		echo -e "${RED}No common folder found in $library${NC}"
	fi
done

# Print all found game paths
echo -e "${GREEN}All found game paths:${NC}"
for path in "${game_paths[@]}"; do
	echo "$path"
done

# Initialize arrays to store DLL paths
steam_api_dll_paths=()
steam_api64_dll_paths=()

# Search for steam_api.dll and steam_api64.dll in game paths
echo -e "${GREEN}Searching for steam_api.dll and steam_api64.dll in game paths:${NC}"
for path in "${game_paths[@]}"; do
	steam_api_dll=$(find "$path" -name "steam_api.dll" 2>/dev/null)
	steam_api64_dll=$(find "$path" -name "steam_api64.dll" 2>/dev/null)

	if [ -n "$steam_api_dll" ]; then
		steam_api_dll_paths+=("$steam_api_dll")
		echo "Found steam_api.dll at: $steam_api_dll"
	fi

	if [ -n "$steam_api64_dll" ]; then
		steam_api64_dll_paths+=("$steam_api64_dll")
		echo "Found steam_api64.dll at: $steam_api64_dll"
	fi
done

# Print all found DLL paths
echo -e "${GREEN}All found steam_api.dll paths:${NC}"
for dll in "${steam_api_dll_paths[@]}"; do
	echo "$dll"
done

echo -e "${GREEN}All found steam_api64.dll paths:${NC}"
for dll in "${steam_api64_dll_paths[@]}"; do
	echo "$dll"
done

# Function to check DLLs
check_dll() {
	local dll_path=$1
	local dll_name=$(basename "$dll_path")
	local script_dll_path="./$dll_name"

	if [ -f "$script_dll_path" ]; then
		local original_shasum=$(sha1sum "$dll_path" | awk '{print $1}')
		local script_shasum=$(sha1sum "$script_dll_path" | awk '{print $1}')

		if [ "$original_shasum" != "$script_shasum" ]; then
			return 1
		else
			return 0
		fi
	else
		return 2
	fi
}

# Function to check and replace DLLs
check_and_replace_dll() {
	local dll_path=$1
	local dll_name=$(basename "$dll_path")
	local script_dll_path="./$dll_name"

	if [ -f "$script_dll_path" ]; then
		local original_shasum=$(sha1sum "$dll_path" | awk '{print $1}')
		local script_shasum=$(sha1sum "$script_dll_path" | awk '{print $1}')

		if [ "$original_shasum" != "$script_shasum" ]; then
			echo -e "${RED}SHA-1 checksum mismatch for $dll_name${NC}"
			read -p "Do you want to rename the original and replace it with the one from the script path? (y/n): " choice
			if [ "$choice" == "y" ]; then
				mv "$dll_path" "${dll_path%.dll}_o.dll"
				cp "$script_dll_path" "$dll_path"
				echo -e "${GREEN}Replaced $dll_name with the one from the script path${NC}"
			fi
		else
			echo -e "${GREEN}SHA-1 checksum matches for $dll_name${NC}"
		fi
	else
		echo -e "${RED}DLL $dll_name not found in the script path${NC}"
	fi
}

# Simple menu to select games
echo -e "${GREEN}Select a game to check and replace DLLs:${NC}"
PS3="Please enter your choice: "
select game_path in "${game_paths[@]}"; do
	if [ -n "$game_path" ]; then
		echo -e "${GREEN}Selected game: $(basename "$game_path")${NC}"

		# Check and replace steam_api.dll
		steam_api_dll=$(find "$game_path" -name "steam_api.dll" 2>/dev/null)
		if [ -n "$steam_api_dll" ]; then
			check_dll "$steam_api_dll"
			dll_status=$?
			if [ $dll_status -eq 1 ]; then
				echo -e "${RED}steam_api.dll does not match${NC}"
				check_and_replace_dll "$steam_api_dll"
			elif [ $dll_status -eq 0 ]; then
				echo -e "${GREEN}steam_api.dll matches${NC}"
			else
				echo -e "${RED}steam_api.dll not found in the script path${NC}"
			fi
		else
			echo -e "${RED}steam_api.dll not found in $game_path${NC}"
		fi

		# Check and replace steam_api64.dll
		steam_api64_dll=$(find "$game_path" -name "steam_api64.dll" 2>/dev/null)
		if [ -n "$steam_api64_dll" ]; then
			check_dll "$steam_api64_dll"
			dll_status=$?
			if [ $dll_status -eq 1 ]; then
				echo -e "${RED}steam_api64.dll does not match${NC}"
				check_and_replace_dll "$steam_api64_dll"
			elif [ $dll_status -eq 0 ]; then
				echo -e "${GREEN}steam_api64.dll matches${NC}"
			else
				echo -e "${RED}steam_api64.dll not found in the script path${NC}"
			fi
		else
			echo -e "${RED}steam_api64.dll not found in $game_path${NC}"
		fi

		break
	else
		echo -e "${RED}Invalid selection. Please try again.${NC}"
	fi
done
