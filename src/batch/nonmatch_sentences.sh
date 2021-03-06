#!/bin/bash
#$ -N non_match
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V

echo $HOSTNAME nonmatch_sentence.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check command-line options
if [ $# -ne 1 ]; then
	echo "USAGE: $0 [-v] SCHEME_ID" >&2
	exit 1
fi

# to avoid using LANG, which is used by Perl
LANG_OPTION="en" # for now
SCHEME_ID=$1

TEST_ROOT="$WIKITOPICS/data/sentences/$SCHEME_ID/$LANG_OPTION"

if [ ! -d "$TEST_ROOT" ]; then
	echo "$TEST_ROOT directory not found" >&2
	exit 1
fi

cd $TEST_ROOT
grep '^-1 .*[A-Za-z].*' */*/*.sentences
grep '^0 .*[A-Za-z].*' */*/*.sentences
