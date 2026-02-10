#!/usr/bin/env bash

QUERY="$*"
PAGE=1
DEPS=(pdftotext jq httpie)
HEADERS=(
	'User-Agent:Mozilla/5.0 (X11; Linux x86_64)'
	'Cookie:justiceGovAgeVerified=true'
)
RED='\e[31m'
YEL='\e[33m'
GRN='\e[32m'
DEF='\e[0m'

trap 'rm -rf /tmp/epstein_file.pdf' EXIT

if [[ -z $QUERY ]]; then
	echo -e "$RED Please provide a valid search term. $DEF"
	exit 1
fi


dependency_check () {
	echo -e "$YEL \nDependency control... $DEF"
	local dep_status=0
	for i in "${DEPS[@]}"; do
		printf "Checking %s -> " "$i"
		if command -v "$i" &>/dev/null; then echo "passed"; ((dep_status++)); else echo "failed"; fi
	done

	if [[ "$dep_status" -ne "${#DEPS[@]}" ]]; then
		echo -e "$RED\nThere are missing packages. Please install them to use grepstein.sh $DEF"
		exit 1
	fi
}

fetch_results () {
	URL="https://www.justice.gov/multimedia-search?keys=$QUERY&page=$PAGE"
	DATA=$(http GET "$URL" "${HEADERS[@]}" | jq)
	TOTAL_RECORDS=$(echo "$DATA" | jq '.hits.total.value')
	mapfile -t PDF_URLS < <(echo "$DATA" | jq -r '.hits.hits[]._source.ORIGIN_FILE_URI' | sed 's/ /%20/g')
	PDF_COUNT=${#PDF_URLS[@]}

	#echo "$DATA"

	echo -e "$GRN \nWe found $TOTAL_RECORDS result(s) for ${QUERY} on all pages. Page $PAGE only shows $PDF_COUNT result(s) $DEF"

	if [[ "$PDF_COUNT" -gt 0 ]]; then
	for i in "${!PDF_URLS[@]}"; do
			echo "$i - ${PDF_URLS[i]}"
		done
	fi
}

ask_usrcmd () {
	if [[ "$PDF_COUNT" -gt 0 ]]; then
		while true; do
			echo -e "$GRN \nPlease select your action $DEF"
			echo "-> Type OPEN to open a file"
			echo "-> Type NEXT to continue to next page"
			echo "-> Type EXIT to exit"
			echo -n "Your command : "
			read -r USRCMD

			USRCMD="${USRCMD,,}"

			case "$USRCMD" in
				open)
					echo -ne "$GRN \nPlease write the index number of the file that you want to open : $DEF"
					read -r INDEX
					if [[ $INDEX -ge 0 && $INDEX -lt $PDF_COUNT ]]; then
						http "${PDF_URLS[INDEX]}" "${HEADERS[@]}" > /tmp/epstein_file.pdf
						pdftotext -layout /tmp/epstein_file.pdf - | less
						rm /tmp/epstein_file.pdf
						fetch_results
					else
						echo -e "$RED \nPlease Provide a valid index number $DEF"
					fi
					;;
				next)
					echo -e "$YEL \nProceding to next page... $DEF"
					((PAGE++))
					fetch_results
					;;
				exit)
					echo -e "$YEL \nExiting... $DEF"
					break
					;;
				*)
					echo -e "$RED \nInvalid command, please enter a valid command. $DEF"
					;;
			esac
		done
	fi
}

dependency_check
fetch_results
ask_usrcmd
