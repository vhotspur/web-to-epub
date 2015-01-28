#!/bin/sh

#
# Copyright (c) 2015 Vojtech Horky
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# - Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# - The name of the author may not be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

RESOURCE_DIR=`dirname "$0"`

read_config_value() {
	if [ -e "$HOME/.web-to-epub.conf" ]; then
		cat "$HOME/.web-to-epub.conf" | \
			sed -n 's#^'"$1"'=\(.*\)#\1#p' | \
			tail -n 1
	else
		echo ""
	fi
}

if ! echo "$RESOURCE_DIR" | grep -q '^/'; then
	RESOURCE_DIR="`pwd`/$RESOURCE_DIR"
fi

escape_filename() {
	recode -f utf8..flat \
		| tr -dc 'a-zA-Z 0-9-_' \
		| tr ' _' '--' \
		| sed 's#--*#-#g'
}

echo1() {
	echo "[web-to-epub]:" "$@"
}

echo2() {
	echo "[web-to-epub]: -" "$@"
}


download_and_convert() {
	echo2 "Current directory is `pwd`."
	
	echo1 "Downloading $1..."
	wget -p -q -k -nd "$1"
	
	filename=`basename "$1"`
	if echo "$1" | grep -q '/$'; then
		filename=index.html
	fi
	if echo "$filename" | grep -q '^[?]'; then
		filename="index.html$filename"
	fi
	
	server=`echo "$1" | sed 's#^\(\(.*://\)\?\)\([^/]*\).*$#\3#'`
	
	processor=""
	case $server in
		*.abclinuxu.cz) processor="abclinuxu.xsl" ;;
		*.perceptualedge.com) processor="perceptualedge.xsl" ;;
		*.prahaneznama.cz) processor="prahaneznama.xsl" ;;
		*) ;;
	esac
	
	if [ -n "$processor" ]; then
		echo1 "Stripping extra content from the page..."
		echo2 "Using processor $processor (server $server) on $filename."
		xsltproc --html "$RESOURCE_DIR/engines/$processor" "$filename" 2>/dev/null >BOOK.html
	else
		cp "$filename" BOOK.html
	fi
	
	checksum=`md5sum BOOK.html | cut -f 1 '-d '`
	
	title=`xsltproc --html "$RESOURCE_DIR/gettitle.xsl" BOOK.html`
	echo2 "Page title is $title."
	(
		echo "<dc:title>$title</dc:title>"
		echo "<dc:creator>$server</dc:creator>"
	) >META.xml
	
	echo "$title" >TITLE.txt
	
	pandoc -f html+yaml_metadata_block -t epub -o BOOK.epub META.xml BOOK.html
}

TARGET_DIR=`read_config_value output-directory`

KEEP_TEMP_FILES=false

MY_OPTS="-o d:k -l output-directory:,keep-temporary-files"
getopt -Q $MY_OPTS -- "$@" || exit 2
eval set -- `getopt -q $MY_OPTS -- "$@"`

while ! [ "$1" = "--" ]; do
	case "$1" in
		-d|--output-directory)
			TARGET_DIR="$2"
			shift
			;;
		-k|keep-temporary-files)
			KEEP_TEMP_FILES=true
			;;
		*)
			exit 1
			;;
	esac
	shift
done
shift

if [ -z "$TARGET_DIR" ]; then
	TARGET_DIR=`pwd`
fi

if ! [ -d "$TARGET_DIR" ]; then
	echo "Target directory $TARGET_DIR does not exist."
	exit 1
fi

if [ $# -eq 0 ]; then
	echo "Usage: $0 [url [url [...]]]"
	exit 0
fi

for url in "$@"; do
	temp_dir=`mktemp -d`
	(
		cd "$temp_dir"
		download_and_convert "$url"
	)
	BOOK_MD5=`md5sum "$temp_dir/BOOK.epub" | cut -f 1 '-d ' | cut -c 1-8`
	FINAL_FILENAME=`cat "$temp_dir/TITLE.txt" | escape_filename`
	FINAL_FILENAME="$TARGET_DIR/$FINAL_FILENAME-$BOOK_MD5.epub"
	
	if [ -e "$FINAL_FILENAME" ]; then
		echo "Refusing to overwrite $FINAL_FILENAME"
		echo "Keeping data in $temp_dir/book.epub"
	else
		echo1 "Stored $url to $FINAL_FILENAME"
		cp "$temp_dir/BOOK.epub" "$FINAL_FILENAME"
		if ! $KEEP_TEMP_FILES; then
			rm -rf "$temp_dir"
		fi
	fi
done
