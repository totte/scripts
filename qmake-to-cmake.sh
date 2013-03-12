#!/bin/bash
 
###############################################################################
#
#	CMakeLists.txt - Generator
#
###############################################################################
# This script tries to create a basic CMakeLists.txt from an existing *.pro
# qmake-projectfile
###############################################################################
# Parameters: $1 = projectfile
###############################################################################
prof=$(basename $1)
odir=$CWD
cd $(dirname $1)
pro=${prof/\.pr?/}
out=CMakeLists.txt
 
ext=""
for ((i=0; i<${#pro} ; i++)) ; do ext="${ext}#" ; done
rm $out
echo -e "\
################################################$ext\n\
# CMakeLists.txt generated from qmake-project $pro #\n\
################################################$ext\n" >> $out
echo "# ... Project setup ..." >> $out
echo "project($pro)" >> $out
mive=$(cmake --version | sed 's/[a-zA-Z\s-]*//g' | awk '{print $1}')
echo "cmake_minimum_required(VERSION $mive)" >> $out
 
# we've got a qmake project, so I guess we need to link QT
# -> we'll need CMP0003 directive ...
echo -e "if(COMMAND cmake_policy)\n\
\tcmake_policy(SET CMP0003 NEW)\nendif(COMMAND cmake_policy)\n" >> $out
 
# Now let's not care about what really stands in "CONFIG", just use alot...
echo -e "\
# ########## Qt4 setup ##########\n\
FIND_PACKAGE(Qt4 REQUIRED)\n\
INCLUDE(\${QT_USE_FILE})\n\
INCLUDE_DIRECTORIES(\${CMAKE_SOURCE_DIR} \${QT_INCLUDES})\n\
ADD_DEFINITIONS(-DQT_GUI_LIBS -DQT_CORE_LIB)\n" >> $out
 
# finally we could traverse the qmake project file ...
sources=$(egrep "^SOURCES" $prof | sed -e 's/SOURCES//' -e 's/+=//')
headers=$(egrep "^HEADERS" $prof | sed -e 's/HEADERS//' -e 's/+=//')
forms=$(egrep "^FORMS" $prof | sed -e 's/FORMS//' -e 's/+=//')
resources=$(egrep "^RESOURCES" $prof | sed -e 's/RESOURCES//' -e 's/+=//')
transl=$(egrep "^TRANSLATIONS" $prof | sed -e 's/TRANSLATIONS//' -e 's/+=//')
 
echo -e "# Source files\nSET(SRCS\n\t$sources\n)\n" >> $out
echo -e "# Header files\nSET(HDRS\n\t$headers\n)\n" >> $out
if [ -n "$resources" ]
then	echo -e "# Resource files\nSET(RSCS\n\t$resources\n)\n" >> $out
fi
if [ -n "$transl" ]
then	echo -e "# Translation files\nSET(TRANS\n\t$transl\n)\n" >> $out
fi
 
final=""
 
if [ -n "$forms" ]
then	# Forms is not empty - we need the uic-wrapper and a moc wrapper
	echo -e "# UI files\nSET(UIS\n\t$forms\n)\n" >> $out
 
	# if we have forms, we will also need the moc wrapper.  But what are
	# the moc-files?  Just running moc on the Header files and inspecting
	# the output for error-messages should suffice ;)
	mocs=""
	for head in $headers
	do
		moc $head 1> /dev/null 2> __erg__
		erg=$(cat __erg__)
		if [ -z "$erg" ]	# nothing recorded - no error -> do it!
		then	mocs="$mocs $head"
		fi
	done
	if [ -n "$mocs" ]
	then
		echo -e "# Headers to be moc'ed ...\nSET(MOCH\n\t$mocs\n)\n" >> $out
		echo -e "# MOC-wrapper for Metadata stuff\nQT4_WRAP_CPP(MOC \${MOCH})\n" >> $out
		final="$final \${MOC}"
	fi
 
	echo -e "# UIC-wrapper for used forms\nQT4_WRAP_UI(UI_H \${UIS})\n" >> $out
	final="$final \${UI_H}"
fi
 
if [ -n "$transl" ]
then
	echo -e "# add translations ...\nQT4_ADD_TRANSLATION(QM \${TRANS})\n" >> $out
	final="$final \${QM}"
fi
 
if [ -n "$resources" ]
then	# Resources are not empty - so lets add them
	echo -e "# add Resource files ...\nQT4_ADD_RESOURCES(QRC \${RSCS})\n" >> $out
	final="$final \${QRC}"
fi
 
echo -e "# And now - for the final steps ...\n\
ADD_EXECUTABLE($pro \${HDRS} \${SRCS}$final)\n\
TARGET_LINK_LIBRARIES($pro \${QT_LIBRARIES})\n\n# finally the installer\n\
INSTALL(TARGETS $pro DESTINATION bin)" >> $out
 
rm __erg__
cd $odir
