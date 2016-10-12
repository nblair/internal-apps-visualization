#!/usr/bin/env bash
#
# Generate a combined log file for commits to selected projects and download committers' avatars.

# Terminal color codes for pretty-printing
bold='\033[1m'
yellow='\033[0;33m'
red='\033[0;31m'
nc='\033[0m' # no color

# Check for prerequisites and arguments and load configuration
type gource >/dev/null 2>&1 || { printf >&2 "${red}ERROR${nc}: Gource does not appear to be installed.  Aborting."; exit 1; }
type jq >/dev/null 2>&1 || { printf >&2 "${red}ERROR${nc}: jq does not appear to be installed.  Aborting."; exit 1; }
[[ "$#" -eq 1 ]] || { printf >&2 "${red}ERROR${nc}: No input file specified. Aborting."; exit 1; }
source config

# Downloads a selected resource from the GitLab API, taking pagination into account
function gitlab() {
    local endpoint="$1" output_file="$2"
    curl --silent --dump-header workdir/response_headers \
         "$GITLAB_API_URL/$endpoint?per_page=100&private_token=$GITLAB_PRIVATE_TOKEN" > $output_file
    next_page_url="$(get_next_page_url)"
    until [ -z "$next_page_url" ]; do
        curl --silent --dump-header workdir/response_headers $next_page_url >> $output_file
        next_page_url="$(get_next_page_url)"
    done
}

# Navigate pagination via Link headers (https://www.w3.org/wiki/LinkHeader).
# NOTE: This regex is obviously not a robust implementation of RFC 5988, but
# we only need to understand a single deployment of GitLab's dialect.
function get_next_page_url() {
    grep --only-matching --extended-regexp '^Link: .*<(.*)>;[[:space:]]*rel="next".*' workdir/response_headers | \
    sed -E 's/.*<([^ ]+)>;[[:space:]]*rel="next".*/\1/'
}

# Downloads the avatar images specified by each committer's GitLab user profile
function download_avatars() {
    while read name; do
        # Query the user_data JSON for the avatar URL
        local avatar_url="$(jq -r '.[] | select(.name == "'"$name"'") | .avatar_url' workdir/user_data)"
        if [[ -n "$avatar_url" ]]; then
            curl --silent --create-dirs --cookie-jar workdir/cookies --output "workdir/avatars/$name" $avatar_url
            # gource needs a .jpg or .png extension
            file "workdir/avatars/$name" | grep --ignore-case --silent jpeg
            if [[ $? -eq 0 ]]; then
                mv "workdir/avatars/$name" "workdir/avatars/$name.jpg"
            else
                file "workdir/avatars/$name" | grep --ignore-case --silent png
                if [[ $? -eq 0 ]]; then
                    mv "workdir/avatars/$name" "workdir/avatars/$name.png"
                fi
            fi
        else
            printf "${yellow}WARNING${nc}: No avatar URL specified for $name\n"
        fi
    done <workdir/names
}

## Produce combined Git log
printf "${bold}Producing combined Git log${nc}\n"
echo   "======================================"
while IFS='' read -r line || [[ -n "$line" ]]; do
    IFS=', ' read -r -a array <<< "$line"
    git clone git@git.doit.wisc.edu:${array[0]}/${array[1]}.git workdir/${array[1]}
    gource --output-custom-log workdir/${array[1]}.txt workdir/${array[1]}
    # Prepend file paths in log entries with group and project names
    sed "s/\|\//\|\/${array[0]}\/${array[1]}\//" workdir/${array[1]}.txt > workdir/${array[1]}.edited.txt
done < "$1"
cat workdir/*.edited.txt | sort -n > $1.log

## Parse committer names and download user data from GitLab
cut -d '|' -f 2 $1.log | sort | uniq > workdir/names
printf "\n${bold}Downloading user data${nc}..."
gitlab "/users" "workdir/user_data"
echo "done"

## Download user avatars
printf "\n${bold}Downloading user avatars${nc}\n"
download_avatars
echo "done"

printf "\nCombined git log is $1.log, user avatars are in workdir/avatars.\n"
