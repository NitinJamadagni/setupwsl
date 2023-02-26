#!/bin/bash


# This script will install the following:
# - bashrc
# - gitconfig
# - golang
# - basic tools for building and testing
#       - sudo apt-get install build-essential
#       - sudo apt-get install mingw-w64
# - az cli

# parameters to script
# -m - install for microsoft
# -g - install golang
#    - if -m is passed, will also install microsoft specific golang settings
#    - if -gv is passed, will install that version of golang
# -t - install basic tools for building and testing
# -az - install azure cli
# -h - print help text

# default values
microsoft=0
golang=0
goversion="1.17.2"
tools=0
az=0
help=0


# parse parameters using getopts
while getopts m:g:gv:t:az:h; opt; do
    case $opt in
        m) microsoft=1; echo "microsoft flag passed" >&2
        ;;
        g) golang=1; echo "golang flag passed" >&2
        ;;
        gv) # if -gv is passed, install that version of golang
                goversion=$OPTARG
                golang=1
                echo "golang version flag passed: $OPTARG" >&2
        ;;
        h) help=1; echo "help flag passed" >&2
        ;;
        t) tools=1; echo "tools flag passed" >&2
        ;;
        az) az=1; echo "az flag passed" >&2
        ;;
        \?) echo "Invalid option: -$OPTARG" >&2
        ;;
    esac
    done




function install_basic_tools() {
        echo "installing basic tools"
        sudo apt-get install build-essential
        sudo apt-get install mingw-w64
}

function print_help() {
        echo "parameters to script"
        echo "-m - install for microsoft"
        echo "-g - install golang"
        echo "   - if -m is passed, will also install microsoft specific golang settings"
        echo "   - if -gv is passed, will install that version of golang"
        echo "-t - install basic tools for building and testing"
        echo "-az - install azure cli"
        echo "-h - print help text"
}

# print help text
if [[ $help -eq 1 ]]; then
        print_help
        exit 0
fi

# make sure script is run as root
if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root!"
fi

function install_bashrc_other_users() {
        # install the custom .bashrc (default)
        # install .bashrc to all users (root and non-root)
        getent passwd | while IFS=: read -r name password uid gid gecos home shell; do
            # if user is 
                # - not system user
                # - home directory exists
                # - starts with /home/* or /root
            if [ -d "$home" ] && [ "$(stat -c %u "$home")" = "$uid" ] && [[ $home == /home/* || $home == /root ]]; then
                echo "Installing bashrc to $home"
                BASHRC=$home/.bashrc
                if [[ -f "$BASHRC" ]]; then
                        echo "backing up existing bashrc..."
                        mv $BASHRC $home/.bashrc_bkp
                fi
                cp ./.bashrc $BASHRC
                source $BASHRC
            fi
        done
}

function main() {
        # install the custom .bashrc (default)
        # install .bashrc to all users (root and non-root)
        install_bashrc_other_users
        BASHRC=$HOME/.bashrc
        source $BASHRC

        # install the custom .gitconfig (--microsoft flag)
        GITCONFIG=$HOME/.gitconfig
        if [[ $microsoft -eq 1 ]]; then
                echo "microsoft flag passed for gitconfig"
                if [[ -f "$GITCONFIG" ]]; then
                        echo "backing up existing gitconfig"
                        mv $GITCONFIG $HOME/.gitconfig_bkp
                fi
                cp ./.gitconfig $GITCONFIG
        fi

        # install golang (--go flag)
        if [[ $golang -eq 1 ]]; then
                echo "installing golang...."
                chmod +x install_go.sh
                # create arguments to pass to install_go.sh
                arguments=""
                if [[ $microsoft -eq 1 ]]; then
                        arguments="$arguments --microsoft"
                fi
                if [[ $goversion != "" ]]; then
                        arguments="$arguments --version $goversion"
                fi

                # install golang, pass microsoft flag if it was passed to this script
                ./install_go.sh $arguments
        fi

        # install basic tools (--tools flag)
        if [[ $tools -eq 1 ]]; then
                install_basic_tools
        fi
        
        # install azure cli (--az flag)
        if [[ $az -eq 1 ]]; then
                echo "installing azure cli..."
                curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        fi
}

main $@

