#!/usr/bin/env perl

use Env qw(HOME);

$DELETE=0;
if ($ARGV[0] eq "--delete") {
	shift @ARGV;
	print "delete log files without an error...\n";
	$DELETE=1;
}

$DIR="$HOME/log/grid";
unless (-d $DIR) {
	die "$0 INPUT_DIR" unless (-d $ARGV[0]);
	$DIR = $ARGV[0];
} elsif (-d $ARGV[0]) {
	$DIR = $ARGV[0];
}

@FILES = glob("$DIR/proc_daily.* $DIR/get_daily.*");
print "DATE      \tTIME\n";

$first_error = 1;
foreach $FILENAME (@FILES) {
	if (!$first_error) {
		# There have been an error or more in the previous file.
		print STDERR "\n";
	}

	open FILE, $FILENAME;
	$first_time = 1;
	$first_error = 1;
	while (<FILE>) {
		if (/get_daily_stats.sh ([-0-9]+)/) {
			$date = $1;
			if ($date =~ /^[0-9]+$/) {
				$date = substr($date, 0, 4) . "-" . substr($date, 4, 2) . "-" . substr($date, 6, 2);
			}
			$line = $.;
		} elsif ($first_time && /real\s+([0-9]+)m([0-9]+)\.([0-9]+)s/) {
			$min = $1;
			$second = $2;
			$hour = $min/60;
			$min %= 60;
			printf "$date\t%02d:%02d:%02d\n", $hour, $min, $second;
			$first_time = 0;
		} else {
			unless (/process_daily_stats.sh *[0-9]+/ || # header
				/[A-Za-z]+ [A-Za-z]+ [0-9]+ [:0-9]+ [A-Z]+ [0-9]+/ || # date and time
				/(real|user|sys)\s+[0-9]+m[0-9]+\.[0-9]+s/ || # elapsed time
				/^\S+ \S+\s+\d+ \d\d:\d\d:\d\d EDT 20\d\d$/ || # timestamp
				/^\.+$/ || # progress bar
				/^$/ || # empty line
				/Your job [0-9]+ \([^)]+\) has been submitted/ || # qsub result
				/processing finished./)
			{
				if ($first_error) {
					print STDERR "Log file name: $FILENAME\n";
					$first_error = 0;
				}
				print STDERR;
			}
		}
	}
	close FILE;
}
