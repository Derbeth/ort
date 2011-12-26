#!/usr/bin/perl

use strict;

my $TESTDATA_DIR = 'testdata';
my $TEST_TEMP_DIR = '/tmp/ort-test';
my $TEST_NUMBER = 7;

`rm -rf $TEST_TEMP_DIR/`;
`mkdir $TEST_TEMP_DIR`;

for (my $i=0; $i<$TEST_NUMBER; ++$i) {
	my $test_input = "${TESTDATA_DIR}/in${i}.txt";
	my $test_output = "${TEST_TEMP_DIR}/out${i}.txt";
	my $test_expected = "${TESTDATA_DIR}/out${i}.txt";
	`./text.pl $test_input $test_output`;
	my $equal = &compare_files($test_output, $test_expected);
	if (!$equal) {
		print "Test failed.\n";
		`kdiff3 $test_output $test_expected`;
		exit(11);
	}
}
print "$TEST_NUMBER tests succeeded.\n";
exit(0);

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