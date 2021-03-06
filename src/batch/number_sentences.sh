#!/bin/bash
#$ -N num_sent
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V

echo $HOSTNAME number_sentences.sh $* >&2

if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check command-line options
if [ "$1" == "-v" ]; then
	VERBOSE=1
	shift
fi

if [ $# -lt 2 ]; then
	echo "USAGE: $0 [-v] LANGUAGE DATA_SET [START_DATE [END_DATE]]" >&2
	exit 1
fi

# to avoid using LANG, which is used by Perl
LANG_OPTION=$1
DATA_SET=$2
SCRIPT="$WIKITOPICS/src/sent_eval/number_sents.py"
if [ ! -f "$SCRIPT" ]; then
	echo "$SCRIPT not found" >&2
	exit 1
fi

if [ "$3" != "" ]; then
	START_DATE=`date --date "$3" +"%Y-%m-%d"`
	if [ $? -ne 0 ]; then
		echo "error using the date command... fallback to using plain text" >&2
		START_DATE=$3
	fi

	if [ "$4" == "" ]; then
		END_DATE="$START_DATE"
	else
		END_DATE=`date --date "$4" +"%Y-%m-%d"`
		if [ $? -ne 0 ]; then
			echo "error using the date command... fallback to using plain text" >&2
			END_DATE=$4
		fi
	fi
else
# if DATE is omitted, process all articles
	START_DATE="0000-00-00"
	END_DATE="9999-99-99"
fi

INPUT_ROOT="$WIKITOPICS/data/backup/sent/old/$DATA_SET"
SOURCE_ROOT="$WIKITOPICS/data/serif/input/$LANG_OPTION"
OUTPUT_ROOT="$WIKITOPICS/data/sentences/$DATA_SET/$LANG_OPTION"

if [ ! -d "$INPUT_ROOT" ]; then
	echo "input directory not found: $INPUT_ROOT" >&2
	exit 1
fi

for INPUT_DIR in $INPUT_ROOT/*; do
	if [ ! -d "$INPUT_DIR" ]; then # such directory not found
		continue
	fi
	BASE_DIR=`basename $INPUT_DIR`
	echo $BASE_DIR | grep "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" > /dev/null
	if [ $? -ne 0 ]; then # the directory's name is not a date
		continue
	fi
	if [ "$START_DATE" \> "$BASE_DIR" -o "$END_DATE" \< "$BASE_DIR" ]; then # if the date falls out of the range
		continue
	fi

	YEAR=${BASE_DIR:0:4}
	SOURCE_DIR="$SOURCE_ROOT/$YEAR/$BASE_DIR"
	OUTPUT_DIR="$OUTPUT_ROOT/$YEAR/$BASE_DIR"
	if [ $VERBOSE ]; then
		echo "`basename $SCRIPT` $INPUT_DIR $SOURCE_DIR $OUTPUT_DIR" >&2
	fi
	mkdir -p $OUTPUT_DIR
	# here BASE_DIR is the date
	$SCRIPT $INPUT_DIR $SOURCE_DIR $OUTPUT_DIR
done
