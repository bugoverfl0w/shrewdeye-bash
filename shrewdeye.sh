#!/bin/bash

# Function to install figlet if required
install_figlet() {
    if ! command -v figlet &> /dev/null; then
        echo "Figlet is not installed. Installing..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y figlet
        elif command -v yum &> /dev/null; then
            sudo yum install -y figlet
        else
            echo "Error: Unsupported package manager. Please install figlet manually."
            exit 1
        fi
    fi
}

# Function to display the banner using figlet
display_banner() {
    if command -v figlet &> /dev/null; then
        echo "$(figlet -f slant 'Shrewdeye' | sed 's/^/ /')"
        echo -e "\e[1;32mTess approved! \U1F480 \e[0m\n"
        echo "Credit: Shrewdeye Tool - https://shrewdeye.app/"
        echo "--------------------------------------------------------"
    else
        install_figlet
        display_banner  # Call display_banner again after installation
    fi
}

process_domain() {
    timestamp=$(date +"%Y%m%d%H%M%S")  # Get current date and time in the format YYYYMMDDHHMMSS
    failed_domains_count=0

    api_url="https://shrewdeye.app/domains/${domain}.txt"
    response=$(curl -s "$api_url")

    if [ $? -eq 0 ]; then
        output_file="${domain}_${timestamp}_output.txt"
        [ -n "$2" ] && output_file=$2
        echo "$response" > "$output_file"
        echo "Data for $domain saved to $output_file"
    else
        echo "Error: Unable to fetch data for $domain from the API. Please check the domain name and try again."
        failed_domains_count=$((failed_domains_count + 1))
        failed_domains_output="${domain}_failed_${timestamp}.txt"
        echo "$domain" >> "$failed_domains_output"
    fi

    if [ "$failed_domains_count" -gt 1 ]; then
        echo "Multiple domains failed. List of failed domains saved to ${failed_domains_output}"
    fi
}

show_help() {
    echo "Usage: shrewdeye.sh [OPTIONS]"
    echo "Options:"
    echo "  -d, --domain    Specify a single domain to process"
    echo "  -o, --output    Specify a file for writing output, this is optional option"
    echo "  -l, --list      Specify a list of domain1,domain2 ..."
    echo "  -f, --file      Specify a text file containing a list of domains to process"
    echo "  -h, --help      Show this help message and exit"
    echo "  - Notes: You can run all options together"
    exit 0
}

# Main Script
display_banner
output=""
domain_list=""
file_path=""
domain_name=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -o|--output)
            output="$2"
            shift 2
            ;;
        -d|--domain)
            domain_name="$2"
            shift 2
            ;;
        -l|--list)
            domain_list="$2" 
            shift 2
            ;;
        -f|--file)
            file_path="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Error: Invalid option: $key. Use -h for help."
            exit 1
            ;;
    esac
done

set -- "${POSITIONAL[@]}"

if [ -n "$domain_name" ]; then
    process_domain "$domain_name" "$output"
fi

if [ -n "$domain_list" ]; then
    # Use a while loop to iterate over space-separated domains
    for domain in $(echo $domain_list | tr "," "\n"); do
        # Check if the argument starts with '-' (indicating a new option)
        if [[ $domain == -* ]]; then
            break
        fi
        echo $domain
        process_domain "$domain" "${output}_$domain"
    done
fi

if [ -f "$file_path" ]; then
    # Read domains from the file and process each one
    while IFS= read -r domain || [ -n "$domain" ]; do
        process_domain "$domain" "$output"
    done < "$file_path"
fi

echo "Thanks for using shrewdeye-bash"
