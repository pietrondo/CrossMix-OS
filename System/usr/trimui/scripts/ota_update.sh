#!/bin/sh
set -u
source /mnt/SDCARD/System/usr/trimui/scripts/update_common.sh

run_bootstrap() {
	url="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/_assets/scripts/ota_bootstrap.sh"
	bootstrap_tmp="/tmp/ota_bootstrap.sh"
	if download_and_verify "$url" "$bootstrap_tmp"; then
		sh "$bootstrap_tmp"
		rm -f "$bootstrap_tmp"
	else
		echo -e "${RED}Failed to verify ota_bootstrap.sh${NC}"
		exit 1
	fi
}

main() {
	check_connection
	sleep 2
	clear
	run_bootstrap
	clear

	echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n" >>"$updatedir/ota_release.log"
	echo -e "${timestamp}\n" >>"$updatedir/ota_release.log"
	/mnt/SDCARD/System/usr/trimui/scripts/update_ota_release.sh | tee -a "$updatedir/ota_release.log"

	# if there is no release to apply, we check if there is hotfix for this version
	if grep -q -E "^(no release|user cancel)$" "/tmp/ota_release_result"; then # "no release", "user cancel", "download failed", "success"
		url="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/_assets/hotfixes/CrossMix-OS_v$Local_CrossMixVersion.sh"

		if /mnt/SDCARD/System/bin/wget -q --spider "$url"; then

			echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n" >>"$updatedir/ota_hotfix.log"
			echo -e "${timestamp}\n" >>"$updatedir/ota_hotfix.log"
			hotfix_tmp="/tmp/ota_hotfix.sh"
			if download_and_verify "$url" "$hotfix_tmp"; then
				sh "$hotfix_tmp" | tee -a "$updatedir/ota_hotfix.log"
				rm -f "$hotfix_tmp"
			else
				echo -e "${RED}Failed to verify hotfix${NC}" | tee -a "$updatedir/ota_hotfix.log"
			fi

		else
			clear
			echo -ne "${PURPLE}Retrieving hotfix information.. ${NC}"
			echo -ne "${GREEN}DONE${NC}\n\n\n"
			echo -e "No hotfix available for CrossMix v$Local_CrossMixVersion.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to exit"
		fi
	fi
	sleep 2
	killall -2 SimpleTerminal

}

main
