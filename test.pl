#!/usr/bin/perl

use strict;

use Getopt::Long;
use Time::HiRes;

my $interactive=1; # run kdiff3
my $continue=0;

GetOptions(
	'i|interactive!'=> \$interactive,
	'c|continue!' => \$continue,
) or die;

my $TESTDATA_DIR = 'testdata';
my $TEST_TEMP_DIR = '/tmp/ort-test';

`rm -rf $TEST_TEMP_DIR/`;
`mkdir $TEST_TEMP_DIR`;

my $start_time=Time::HiRes::time;
my $successful=0;
my $failed=0;
for (my $i=$ARGV[0] || 0 ; ; ++$i) {
	my $test_input = "$TESTDATA_DIR/in${i}.txt";
	my $test_output = "$TEST_TEMP_DIR/out${i}.txt";
	my $test_expected = "$TESTDATA_DIR/out${i}.txt";
	my $test_params = "$TESTDATA_DIR/param${i}.txt";
	last unless(-e $test_input && -e $test_expected);
	my $params = read_params($test_params);

	print '.';
	system("./text.pl $params $test_input $test_output") == 0 or die "Died on test $i";
	my $equal = &compare_files($test_output, $test_expected);
	if (!$equal) {
		print "Test no. $i failed.\n";
		my $diff_program = $interactive && `which kdiff3` ? 'kdiff3' : 'diff --unified=2';
		system("$diff_program $test_output $test_expected");
		exit(11) unless $continue;
		++$failed;
	} else {
		++$successful;
	}
}
print "\n$successful tests succeeded";
if ($failed) {
	print " $failed failed";
}
printf(" in %.2f ms\n", Time::HiRes::time - $start_time);
exit($failed ? 11 : 0);

# returns true if files are identical, otherwise false.
# when files are not identical, prints diff to standard output.
sub compare_files {
	my ($file1,$file2) = @_;
	my $result = `diff $file1 $file2`;
	if ($result eq '') {
		return 1;
	} else {
		#print $result;
		return 0;
	}
}

sub read_params {
	my ($file) = @_;
	my $params = '';
	if (-e $file) {
		open(PARFILE, $file) or die "cannot read $file";
		$params = <PARFILE>;
		chomp $params;
		close(PARFILE);
	}
	return $params;
}
