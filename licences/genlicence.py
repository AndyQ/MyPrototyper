#!/usr/bin/python

import os
import re
from subprocess import call

def createRootPlistFile():
    rootPlistF.write( "<?xml version=""1.0"" encoding=""UTF-8""?>\n" )
    rootPlistF.write( "<!DOCTYPE plist PUBLIC ""-//Apple//DTD PLIST 1.0//EN"" ""http://www.apple.com/DTDs/PropertyList-1.0.dtd"">\n" )
    rootPlistF.write( "<plist version=""1.0"">\n" )
    rootPlistF.write( "    <dict>\n" )
    rootPlistF.write( "        <key>PreferenceSpecifiers</key>\n" )
    rootPlistF.write( "        <array>\n" )
    rootPlistF.write( "                <dict>\n" )
    rootPlistF.write( "                    <key>Type</key>\n" )
    rootPlistF.write( "                    <string>PSChildPaneSpecifier</string>\n" )
    rootPlistF.write( "                    <key>FooterText</key>\n" )
    rootPlistF.write( "                    <string>Credits</string>\n" )
    rootPlistF.write( "                    <key>File</key>\n" )
    rootPlistF.write( "                    <string>Credits</string>\n" )
    rootPlistF.write( "                </dict>\n" )
    rootPlistF.write( "       </array>\n" )
    rootPlistF.write( "       <key>StringsTable</key>\n" )
    rootPlistF.write( "       <string>Root</string>\n" )
    rootPlistF.write( "   </dict>\n" )
    rootPlistF.write( "</plist>\n" )


def createPlist( file, itemName ):
    strings = "../Settings.bundle/en.lproj/" + itemName + ".strings"
    plist = "../Settings.bundle/" + itemName + ".plist"

    stringsF = open( strings, "w" )
    plistF = open( plist, "w" )

    plistF.write( "<?xml version=""1.0"" encoding=""UTF-8""?>\n" )
    plistF.write( "<!DOCTYPE plist PUBLIC ""-//Apple//DTD PLIST 1.0//EN"" ""http://www.apple.com/DTDs/PropertyList-1.0.dtd"">\n" )
    plistF.write( "<plist version=""1.0"">\n" )
    plistF.write( "    <dict>\n" )
    plistF.write( "        <key>StringsTable</key>\n" )
    plistF.write( "        <string>" + itemName + "</string>\n" )
    plistF.write( "        <key>PreferenceSpecifiers</key>\n" )
    plistF.write( "        <array>\n" )

    value = open( file ).read()

    value = value.replace( "\r", "")
    value = value.replace( "\n", "\r")
    value = value.replace( "\"", "'")
    value = re.sub( r'[ \t]+\r', "\r", value)

    value = itemName + "\r\r" + value
    count = 1
    lines = value.split( "\r\r")
    keynum = itemName
    for line in lines:
        plistF.write( "            <dict>\n" )
        plistF.write( "                <key>Type</key>\n" )
        plistF.write( "                <string>PSGroupSpecifier</string>\n" )
        plistF.write( "                <key>FooterText</key>\n" )
        plistF.write( "                <string>" + keynum + "</string>\n" )
        plistF.write( "            </dict>\n")
        
        stringsF.write( "\"" + keynum + "\" = \"" + line + "\";\n" )
        count += 1
        keynum = key + str( count )


    plistF.write( "       </array>\n" )
    plistF.write( "   </dict>\n" )
    plistF.write( "</plist>\n" )


def createCreditsFile( creditsF ):
    creditsF.write( "<?xml version=""1.0"" encoding=""UTF-8""?>\n" )
    creditsF.write( "<!DOCTYPE plist PUBLIC ""-//Apple//DTD PLIST 1.0//EN"" ""http://www.apple.com/DTDs/PropertyList-1.0.dtd"">\n" )
    creditsF.write( "<plist version=""1.0"">\n" )
    creditsF.write( "    <dict>\n" )
    creditsF.write( "        <key>PreferenceSpecifiers</key>\n" )
    creditsF.write( "        <array>\n" )

def addItemToCredits( creditsF, itemName ):
    creditsF.write( "                <dict>\n" )
    creditsF.write( "                    <key>Type</key>\n" )
    creditsF.write( "                    <string>PSChildPaneSpecifier</string>\n" )
    creditsF.write( "                    <key>Title</key>\n" )
    creditsF.write( "                    <string>" + itemName + "</string>\n" )
    creditsF.write( "                    <key>File</key>\n" )
    creditsF.write( "                    <string>" + itemName + "</string>\n" )
    creditsF.write( "                </dict>\n" )

def finishCreditsFile( creditsF ):
    creditsF.write( "       </array>\n" )
    creditsF.write( "       <key>StringsTable</key>\n" )
    creditsF.write( "       <string>Credits</string>\n" )
    creditsF.write( "   </dict>\n" )
    creditsF.write( "</plist>\n" )

def alreadySetup(file, search):
    if os.path.exists(file) == False:
        return 1

    fo=open(file,"r")
    query = fo.readlines()
    query=[ i.rstrip() for i in query ]
    if any(search in s for s in query):
	return 0
    return 1

creditsStrings = "../Settings.bundle/en.lproj/Credits.strings"
creditsPlist = "../Settings.bundle/Credits.plist"
rootPlist = "../Settings.bundle/Root.plist"

creditsStringsF = open( creditsStrings, "w" )
creditsPlistF = open( creditsPlist, "w" )

# Only write out the Root plist file IF we haven't added credits to it already
output = alreadySetup( rootPlist, "Credits" )
if output == 1:
    rootPlistF = open( rootPlist, "r" )
    lines = rootPlistF.readlines()
    rootPlistF.close();
    print "Credits not yet setup - adding " + rootPlist

    rootPlistF = open( rootPlist, "w" )
    for line in lines:
        if line.find( "</array>" ) != -1:
            rootPlistF.write( "                <dict>\n" )
            rootPlistF.write( "                    <key>Type</key>\n" )
            rootPlistF.write( "                    <string>PSChildPaneSpecifier</string>\n" )
            rootPlistF.write( "                    <key>Title</key>\n" )
            rootPlistF.write( "                    <string>Credits</string>\n" )
            rootPlistF.write( "                    <key>File</key>\n" )
            rootPlistF.write( "                    <string>Credits</string>\n" )
            rootPlistF.write( "                </dict>\n" )

        rootPlistF.write( line )

# remove old plist files and string files from Settings bundle (we will create them again
#TODO!

createCreditsFile( creditsPlistF )

arrays = []
arrays.append( "." )
d = os.path.dirname( "../BAFramework/BAFramework.bundle/licences" )
if os.path.exists( d ):
    print( "Adding BAFramework licences..." )
    arrays.append( "../BAFramework/BAFramework.bundle/licences" )

for path in arrays:
    for filen in os.listdir(path):
        if filen.endswith( ".licence" ): 
            fullPath = path + "/" + filen
            key = filen.replace( ".licence", "")

            print "Adding licence file " + fullPath
            createPlist( fullPath, key )
            addItemToCredits( creditsPlistF, key )

finishCreditsFile( creditsPlistF )



