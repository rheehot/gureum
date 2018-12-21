#!/bin/bash

if [ ! $CONFIGURATION ]; then
	CONFIGURATION='Release'
fi
SCRIPT_DIR=`dirname "${BASH_SOURCE[0]}"`
. "${SCRIPT_DIR}/ready.sh" || exit $?

sudo installer -pkg ~/Downloads"/$PACKAGE_NAME.pkg" -target '/' && sudo killall Gureum
