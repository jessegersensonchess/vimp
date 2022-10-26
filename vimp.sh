#!/bin/bash

#### DESCRIPTION: select, edit and validate a puppet manifest ####
#### USAGE: /usr/bin/vimp.sh [file] ####
#### NOTES: file is optional. Script assumes puppet manifests are in /etc/puppet/manifests ####
#### AUTHOR: Jesse Gersenson

FILEPATH='/etc/puppet/manifests'

if [[ ! -z "$1" || ! "$1" == '' ]]
then
	FILENAME="$1"
else

	#### select a file to edit ####
	files="$(cd "$FILEPATH"; ls -f *.pp)"
	echo ""
	echo "Pick a file to edit:"
	echo ""

	select file in ${files}; do 
		FILENAME="$file";
		break
	done
fi

FILE="${FILEPATH}/${FILENAME}"
TMPFILE="/tmp/${FILENAME}"

function checksum(){
	INPUT="$1"
	#### get checksum of original file ####
	sha256sum "$INPUT" | awk '{print $1}'
}

function doesFileExist(){

	#### check if file exists, other exit ####
	if [[ ! -f "$FILE" ]]
	then
		echo "ERROR: file $FILE does not exist"
		exit
	fi

}


function makeTemporaryFile(){
	#### make a temporary copy ####
	cp "$FILE" "$TMPFILE"
}

function editTemporaryFile(){
	#### edit the temporary file ####
	vim "$TMPFILE"
}

function editAndValidateFile(){
	#### recursive function to edit and validate the manifest. When edited file is valid, copy back to
	#### /etc/puppet/manifests/

	editTemporaryFile
	if [[ $(checksum "$FILE") == $(checksum "$TMPFILE") ]]
	then
		echo ''
		echo 'SUCCESS! Note: checking puppet syntax disabled because no edits were made to the file.'
		echo ''
		exit
	fi

	validate=$(puppet parser validate "$TMPFILE")

	if [[ "$?" -ne 0 ]]
	then
		#### save a backup of the edited file, just in case ####
		cp "$TMPFILE" "${TMPFILE}-$(date +%s)"

		echo "(note: to prevent losing work, if this script has errors, a backup of your edits was saved to /tmp/"
		echo ''
		echo 'OOPS! File includes puppet validation errors'
		echo "type any character to continue editing $TMPFILE"
		read readyToContinue

		editAndValidateFile
		
	else
		echo ''
		echo 'SUCCESS! puppet validation successful'
		echo ''
		cp "$TMPFILE" "$FILE"
		echo "SUCCESSFULLY copied $TMPFILE to $FILE"
		echo ''
	fi

}


doesFileExist
makeTemporaryFile
editAndValidateFile
exit
