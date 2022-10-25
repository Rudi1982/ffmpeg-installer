#!/usr/bin/bash

#############################################
##                                         ##
## Install-Script for nwjs-ffmpeg-prebuild ##
##          written by Rudi1982            ##
##                 2022                    ##
##                                         ##
#############################################

if (( $EUID != 0 )); then
    echo "Bitte starte das Script als root oder mit dem sudo Kommando neu!"
    exit 1
fi

# Lese die Paketlisten neu im Silent-Mode ein
echo "Prüfe auf Updates..."
sudo apt -qq update

# Prüfe, ob die benötigten Pakete vorhanden sind, falls nicht werden sie installiert
declare -a packages=(
			"wget"
			"curl"
			"unzip"
			"jq"
)
for pkg in "${packages[@]}"; do
	if dpkg-query -s $pkg 2>/dev/null | grep -q installed; then
    	echo "$pkg ist installiert"
    else
    	echo "Installiere $pkg..."
    	sudo apt-get -qy install $pkg 2>/dev/null
    fi
done

# Löschen der Konsole
clear

# Benötigte Pfade im Script:
OPERA_PATH=/usr/lib/x86_64-linux-gnu/opera
TMP_DIR=/tmp
TMP_WORKING_DIR=/tmp/github.com/nwjs-ffmpeg-prebuilt/

# Benötigte Dateien:
FILE=libffmpeg.so
OPERA_CUR_VER_FILE=opera_ver.txt
LIBFFMPEG_CUR_VER_FILE=libffmpeg_ver.txt
OPERA_INST_VER=$(apt-cache policy opera-stable | grep Installiert | awk '{ print $2 }')

if [ -f $OPERA_PATH/$OPERA_CUR_VER_FILE ]
then OPERA_CUR_VER=$(cat $OPERA_PATH/$OPERA_CUR_VER_FILE)
else OPERA_CUR_VER=0
fi

if [ -f $OPERA_PATH/$LIBFFMPEG_CUR_VER_FILE ]
then LIBFFMPEG_CURR_VER=$(cat $OPERA_PATH/$LIBFFMPEG_CUR_VER_FILE)
else LIBFFMPEG_CURR_VER=0
fi

# Variante 1 zum Auslesen der aktuellen Version auf github.com
VERSION=$(wget -o - --max-redirect=0 https://github.com/nwjs-ffmpeg-prebuilt/nwjs-ffmpeg-prebuilt/releases/latest | 
sed -n '/^Platz/ s#^.*/tag/\([^ ]*\).*$#\1#p')

# Variante 2 zum Auslesen der aktuellen Version auf github.com
#VERSION="$(curl -Hv "Accept: application/vnd.github+json" https://api.github.com/repos/nwjs-ffmpeg-prebuilt/nwjs-ffmpeg-prebuilt/releases 2> /dev/null | jq '.[0].tag_name')"

if [ "$VERSION" != "$LIBFFMPEG_CURR_VER" ] && [ "$OPERA_INST_VER" != "$OPERA_CUR_VER" ]
then
	echo "Update notwendig"
	FILENAME=$VERSION-linux-x64.zip
	URL=https://github.com/nwjs-ffmpeg-prebuilt/nwjs-ffmpeg-prebuilt/releases/download/$VERSION/$FILENAME

	echo "Download der der neuen libffmpeg"...
	wget -q "$URL" -r -P "$TMP_DIR"

	echo "Entpacke die neue libffmpeg..."
	unzip -qe $TMP_WORKING_DIR/nwjs-ffmpeg-prebuilt/releases/download/$VERSION/$FILENAME -d $TMP_WORKING_DIR

	# Prüfe, ob es schon ein Backup-File der libffmpeg gibt und falls ja, lösche sie
	if test -f "/usr/lib/x86_64-linux-gnu/opera/$FILE.bak"; then
		rm -f $OPERA_PATH/$FILE.bak
	fi

	# Erstelle von der aktuellen Datei ein Backup (.bak) und verschiebe die Neue an den Zielort
	mv $OPERA_PATH/$FILE $OPERA_PATH/$FILE.bak
	mv $TMP_WORKING_DIR/$FILE $OPERA_PATH/$FILE

	# Erstelle libffmpeg_ver.txt und opera_ver.txt neu mit der neuen Versionsnummer
	echo $VERSION > $OPERA_PATH/$LIBFFMPEG_CUR_VER_FILE
	echo $OPERA_INST_VER > $OPERA_PATH/$OPERA_CUR_VER_FILE

	rm -rf $TMP_WORKING_DIR
	
	# Checke, ob Opera läuft und beende ggf.
	if [ "$(pidof opera)" ]
	then
		echo "Opera muss neu gestartet werden, um die Änderungen zu übernehmen."
		echo "Opera wird in 20sek automatisch beendet..."
		sleep 20
		killall opera
	fi
else
	echo "Nichts zu tun! Beende das Script..."	
fi
exit 
