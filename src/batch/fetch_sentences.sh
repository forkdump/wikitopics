#!/bin/bash
# Filter non-sentences

if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

SCRIPT="$WIKITOPICS/src/wiki/fetch_sentences.py"
if [ ! -f "$SCRIPT" ]; then
	echo "The $SCRIPT script not found" >&2
	exit 1
fi

if [ "$1" == "--dry-run" ]; then
	DRYRUN=1
	shift
fi
if [ "$1" == "-v" ]; then
	VERBOSE=1
	shift
fi

if [ $# -lt 2 -o $# -gt 3 ]; then
	echo "USAGE: $0 [--dry-run] [-v] LANGUAGE START_DATE [END_DATE]" >&2
	exit 1
fi

# to avoid using LANG, which is used by Perl
LLANG=$1
START_DATE=`date --date "$2" +"%Y-%m-%d"`
if [ $? -ne 0 ]; then
	echo "error using date... fallback to using plain text" >&2
	START_DATE=$2
fi

if [ "$3" == "" ]; then
	END_DATE="$START_DATE"
else
	END_DATE=`date --date "$3" +"%y-%m-%d"`
	if [ $? -ne 0 ]; then
		echo "error using date... fallback to using plain text" >&2
		END_DATE=$3
	fi
fi

TOPIC_DIR="$WIKITOPICS/data/topics"
ARTICLE_DIR="$WIKITOPICS/data/articles"

if [ ! -d "$TOPIC_DIR/$LLANG" ]; then
	echo "input directory not found: $TOPIC_DIR/$LLANG" >&2
	exit 1
fi

for FILE in $TOPIC_DIR/$LLANG/*/*; do
	if [ ! -f "$FILE" ]; then # such a file not found
		continue
	fi
	BASENAME=`basename $FILE | sed -e 's/\.topics$//'`
	echo $BASENAME | grep "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" > /dev/null
	if [ $? -ne 0 ]; then # the directory's name is not a date
		continue
	fi
	if [ "$START_DATE" \> "$BASENAME" -o "$END_DATE" \< "$BASENAME" ]; then # if the date falls out of the range
		continue
	fi

	if [ $VERBOSE ]; then
		echo "$FILE" >&2
	fi

	YEAR="${BASENAME:0:4}"
	OUTPUT_DIR="$ARTICLE_DIR/$LLANG/$YEAR"
	mkdir -p "$OUTPUT_DIR"
	if [ $DRYRUN ]; then
		echo "$SCRIPT -l $LLANG -d $BASENAME -o $OUTPUT_DIR $FILE"
	else
		$SCRIPT -l $LLANG -d $BASENAME -o $OUTPUT_DIR $FILE
	fi
done
