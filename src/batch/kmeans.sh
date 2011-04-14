#$ -N kmeans
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
echo kmeans.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "the WIKITOPICS environment variable not set" >&2
	exit 1
fi
if [ "$MALLET" == "" ]; then
	echo "set the MALLET environment variable" >&2
	exit 1
fi

# check command-line options
if [ $# -lt 1 -o $# -gt 3 ]; then
	echo "Usage: $0 LANG [START_DATE [END_DATE]]" >&2
	exit 1
fi

LANG_OPTION=$1
if [ "$2" != "" ]; then
	START_DATE=`date --date "$2" +"%Y-%m-%d"`
	if [ $? -ne 0 ]; then
		echo "error using date... fallback to using plain text" >&2
		START_DATE=$2
	fi

	if [ "$3" == "" ]; then
		END_DATE="$START_DATE"
	else
		END_DATE=`date --date "$3" +"%Y-%m-%d"`
		if [ $? -ne 0 ]; then
			echo "error using date... fallback to using plain text" >&2
			END_DATE=$3
		fi
	fi
else
# if DATE is omitted, process all articles
	START_DATE="0000-00-00"
	END_DATE="9999-99-99"
fi

INPUT_ROOT="$WIKITOPICS/data/articles/$LANG_OPTION"
OUTPUT_ROOT="$WIKITOPICS/data/clusters/kmeans/$LANG_OPTION"
for DIR in $INPUT_ROOT/*/*; do
	if [ ! -d "$DIR" ]; then # such directory not found
		continue
	fi
	DATE=`basename $DIR`
	echo $DATE | grep "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" > /dev/null
	if [ $? -ne 0 ]; then # the directory's name is not a date
		continue
	fi
	if [ "$START_DATE" \> "$DATE" -o "$END_DATE" \< "$DATE" ]; then # if the date falls out of the range
		continue
	fi

	YEAR=${DATE:0:4}
	OUTPUT_FILE="$OUTPUT_ROOT/$YEAR/$DATE.clusters"
	echo "Input: $DIR" >&2
	echo "Output: $OUTPUT_FILE" >&2
	mkdir -p `dirname $OUTPUT_FILE`
	java -cp $WIKITOPICS/src/cluster/kmeans/ClusterFiles:$MALLET/class:$MALLET/lib/mallet-deps.jar -Xmx2g ClusterFiles --k 50 --input $DIR > "$OUTPUT_FILE"
done