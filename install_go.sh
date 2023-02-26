#!/bin/bash

# Parameters to script
# -m  - will also install microsoft specific golang settings
# -gv - will install that version of golang

# default values
microsoft=0
goversion="1.17.2"

# parse parameters using getopts
while getopts m:gv: opt; do
    case $opt in
        m) microsoft=1; echo "microsoft flag passed" >&2
        ;;
        gv) # if -gv is passed, install that version of golang
                goversion=$OPTARG
                echo "golang version flag passed: $OPTARG" >&2
        ;;
        \?) echo "Invalid option: -$OPTARG" >&2
        ;;
    esac
    done

# check semver version of golang
if [[ $goversion =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "goversion is a valid semver version : $goversion"
    goversion="go$goversion"
    echo "using version : $goversion"
else
    goversion=$(curl -s https://go.dev/VERSION?m=text)
    echo "goversion is not a valid semver version, using latest version : $goversion"
fi

# Check if Go is already installed
if command -v go &> /dev/null; then
    echo "Go is already installed"
    exit
fi

# install golang of specified version if 
wget https://golang.org/dl/$goversion.linux-amd64.tar.gz

# Extract the archive
tar -C /usr/local -xzf go*.linux-amd64.tar.gz

# Add Go to the system path
echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile.d/go.sh
if [[ $microsoft -eq 1 ]]; then
    echo "export GOPRIVATE=\"github.com/microsoft/*,msazure.visualstudio.com/*,dev.azure.com/*\"" >> /etc/profile.d/go.sh
    echo "export GONOPROXY=\"github.com/microsoft/*,msazure.visualstudio.com/*,dev.azure.com/*\"" >> /etc/profile.d/go.sh
    echo "export GONOSUMDB=\"github.com/microsoft/*,msazure.visualstudio.com/*,dev.azure.com/*\"" >> /etc/profile.d/go.sh
fi

# Reload the system profile
source /etc/profile.d/go.sh

# Verify the installation
go version