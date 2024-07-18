#!/bin/bash

# get_owner_and_repo extracts the owner and repo from the GitHub URL
get_owner_and_repo() {
    local url=$1
    local owner_repo=$(echo "$url" | awk -F'github.com/' '{print $2}' | awk -F'.git' '{print $1}')
    echo "$owner_repo"
}

# get_top_contributors gets the top 10 contributors on the given repository
get_top_contributors() {
    local owner_repo=$1
    local num_contributors=$2
    curl -s "https://api.github.com/repos/$owner_repo/contributors?per_page=$num_contributors" | \
    jq -r '.[] | "\(.login)"'
}

# get_user_info returns display name and email for given user
get_user_info() {
    local user=$1
    curl -s -H "Authorization: token $GH_PAT" "https://api.github.com/users/$user" | \
    jq -r '"\(.name // "No name") | \(.email // "Email not public")"'
}

# Check if GH_PAT is set
if [ -z "$GH_PAT" ]; then
    echo "GH_PAT is not set. GH_PAT should be set to GitHub personal access token. Please set it and try again."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it and try again."
    exit 1
fi

# Main script starts here
# If no arguments are provided, show usage
if [ -z "$1" ]; then
    echo "Usage: $0 <github_repo_url>"
    exit 1
fi

# Extract owner and repo from the URL
owner_repo=$(get_owner_and_repo "$1")

# Exract number of contributors and default to 10
num_contributors=${2:-10}

# Output file is optional
output_file=$3

# Create an array to store the formatted lines for the Markdown file
markdown_lines=()

# Add the header for the markdown table
markdown_lines+=("| GitHub Username | Name | Email |")
markdown_lines+=("| --- | --- | --- |")

# Get the top 10 contributors
echo "Top $num_contributors contributors for $owner_repo:"
contributors=$(get_top_contributors "$owner_repo" "$num_contributors")

while IFS= read -r contributor; do
    username=$(echo $contributor | awk '{print $1}')
    user_info=$(get_user_info "$username")
    line="$username | $user_info"

    echo "$line"

    # Add to markdown_lines array if output_file is specified
    if [ -n "$output_file" ]; then
        markdown_lines+=("**$username** | $user_info")
    fi    
done <<< "$contributors"

# Write to the output file if specified
if [ -n "$output_file" ]; then
    for line in "${markdown_lines[@]}"; do
        echo "$line" >> "$output_file"
    done
    echo "Top contributors written to $output_file"
fi