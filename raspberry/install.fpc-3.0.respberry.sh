#!/bin/bash

# Author of this script: http://www.getlazarus.org
# This is the universal script to install fpc 3.0.0 minimal

# If you need to fix something and or want to contribute, send your 
# changes to admin at getlazarus dot org with 
# "fpc lazazarus install" in the subject line.

# Prevent this script from running as root 
if [ "$(id -u)" = "0" ]; then
   echo "This script should not be run as root"
   exit 1
fi

# Cross platform expandPath function
function expandPath() {
	if [ `uname`="Darwin" ]; then
		[[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}";
	else
		echo $(readlink -m `$1`)
	fi
}

echo "If Lazarus does not operate correctly, you might be required"
echo "to install these gtk+ dev packages using the sudo command:"
echo
echo "sudo apt-get install libgtk2.0-dev libcairo2-dev libpango1.0-dev \\"
echo "  libgdk-pixbuf2.0-dev libatk1.0-dev libghc-x11-dev"
echo
echo "Press return to continue"
read CHOICE

# Present a description of this script
clear
echo "Raspberry Free Pascal 3.0 with Lazarus install script"
echo "-----------------------------------------------------"
echo "This script will install a lightweight version of"
echo
echo "The Free Pascal Compiler version 3.0"
echo "The Lazarus Development Environment"
echo
echo "After install 242MB of drive space will be used"
echo
echo "This lightweight version is designed specifically"
echo "for the Raspberry Pi running Raspbian OS"
echo
# The default folder
BASE=$HOME/Development/FreePascal

# Ask a series of questions
while true; do
	# Ask for an install location
	echo "Enter an installation folder or press return to"
	echo "accept the default install location"
	echo 
	echo -n "[$BASE]: "
		read CHOICE
	echo

	# Use BASE as the default
	if [ -z "$CHOICE" ]; then
		CHOICE=$BASE
	fi

	# Allow for relative paths
	CHOICE=`eval echo $CHOICE`
	EXPAND=`expandPath "$CHOICE"`

	# Allow install only under your home folder
	if [[ $EXPAND == $HOME* ]]; then
		echo "The install folder will be:"
		echo "$EXPAND"
		echo
	else
		echo "The install folder must be under your personal home folder"
		echo
		continue
	fi

	# Confirm their choice
	echo -n "Continue? (y,n): "
	read CHOICE
	echo 

	case $CHOICE in
		[yY][eE][sS]|[yY]) 
			;;
		*)
			echo "done."
			echo
			exit 1
			;;
	esac

	# If folder already exists ask to remove it
	if [ -d "$EXPAND" ]; then
		echo "Directory already exist"
		echo -n "Remove the entire folder and overwrite? (y,n): "
		read CHOICE
		case $CHOICE in
			[yY][eE][sS]|[yY]) 
				echo
				rm -rf $EXPAND
				;;
			*)
				echo
				echo "done."
				echo
				exit 1
				;;
		esac
	fi

	break
done

# Confirm their choice
echo -n "Create a local application shortcut after install? (y,n): "
read SHORTCUT
echo 

# Create the folder
BASE=$EXPAND
mkdir -p $BASE

# Exit if the folder could not be created
if [ ! -d "$BASE" ]; then
  echo "Could not create directory"
  echo
  echo "done."
  echo
  exit 1;
fi

cd $BASE

# Note we use our bucket instead of sourceforge or svn for the following 
# reason: 
#   It would be unethical to leach other peoples bandwidth and data
#   transfer charges. As such, we rehost the same fpc stable binary, fpc 
#   test sources, and lazarus test sources from sourceforge and free
#   pascal svn servers using our own Amazon S3 bucket.

# Download from our Amazon S3 bucket 
URL=http://cache.getlazarus.org/archives

wget -P "$BASE" $URL/fpc.lazarus.raspberry.tar.gz
tar xvf fpc.lazarus.raspberry.tar.gz
rm "$BASE/fpc.lazarus.raspberry.tar.gz"

# Create the cfg file
rm "$BASE/fpc/bin/fpc.cfg"
"$BASE/fpc/bin/fpcmkcfg" -d "basepath=$BASE/fpc/lib/fpc/\$FPCVERSION" -o "$BASE/fpc/bin/fpc.cfg"

# function replace(folder, files, before, after) 
function replace() {
	BEFORE=$(echo "$3" | sed 's/[\*\.]/\\&/g')
	BEFORE=$(echo "$BEFORE" | sed 's/\//\\\//g')
	AFTER=$(echo "$4" | sed 's/[\*\.]/\\&/g')
	AFTER=$(echo "$AFTER" | sed 's/\//\\\//g')
	find "$1" -name "$2" -exec sed -i "s/$BEFORE/$AFTER/g" {} \;
}

# Replace paths from their original location to the new one
ORIGIN="/home/pi/Development/Base"
replace "$BASE/lazarus/config" "*.xml" "$ORIGIN" "$BASE"
replace "$BASE/lazarus/config" "*.cfg" "$ORIGIN" "$BASE"
replace "$BASE/lazarus" "lazarus.sh" "$ORIGIN" "$BASE"
replace "$BASE/lazarus" "lazarus.desktop" "$ORIGIN" "$BASE"

case $SHORTCUT in
	[yY][eE][sS]|[yY]) 
		cp "$BASE/lazarus/lazarus.desktop" "$HOME/.local/share/applications/"
		;;
	*)
		;;
esac

function hit() {
	if type "curl" > /dev/null; then
		curl -s -o /dev/null "$1"
	elif type "wget" > /dev/null; then
		wget -q -O /dev/null "$1"
	fi	
}

hit "http://www.getlazarus.org/installed/?platform=raspberry"
echo "Your Free Pascal 3.0 with Lazarus now installed"
echo 
