#!/usr/bin/perl -w
use strict;
use utf8;
use English;
use Encode;
use Getopt::Long;
use Pod::Usage;
use Derbeth::Ortografia;

my $infile = 'in.txt';
my $outfile = 'out.txt';
my $encoding = 'utf8';
my $show_help=0;

GetOptions('r|rzymskie=i' => \$Derbeth::Ortografia::rzymskie_niebezp,
	'k|kropki=i' => \$Derbeth::Ortografia::usun_kropki_z_liczb,
	't|typografia=i' => \$Derbeth::Ortografia::typografia,
	'i|interpunkcja=i' => \$Derbeth::Ortografia::interpunkcja,
	'b|br=i' => \$Derbeth::Ortografia::kasuj_bry,
	'x|ryzykowne=i' => \$Derbeth::Ortografia::ryzykowne,
	'e|encoding=s' => \$encoding,
	'help|h' => \$show_help,
) or pod2usage('-verbose'=>1,'-exitval'=>1);
pod2usage('-verbose'=>2,'-noperldoc'=>1) if ($show_help || $#ARGV > 1);

$infile = $ARGV[0] if ($ARGV[0]);
$outfile = $ARGV[1] if ($ARGV[1]);

open(FIN,$infile) or die "cannot read $infile: $!";
open(FOUT,">$outfile") or die "cannot write to $outfile";

my $NOSORT = 'NOSORT';
my $l_kategorii=0; # liczba kategorii
my $defaultsort=$NOSORT;
my $rozne_sort=0;

my $linia=<FIN>;

my $pocz_kategorii = 0;

while($linia) {
	$linia = decode($encoding, $linia);
	
	if (!$pocz_kategorii && $linia =~ /\[\[(category|kategoria)/i) {
		$pocz_kategorii = 1;
	}
	
	if ($pocz_kategorii) {
		$linia = Derbeth::Ortografia::popraw_kategorie($linia);
	} else {
		$linia = Derbeth::Ortografia::popraw_pisownie($linia);
	}		
} continue {
	$linia = encode($encoding, $linia);
	print FOUT $linia;
	$linia = <FIN>;
}

close FIN;
close FOUT;

=head1 NAME

text.pl - fixes spelling for Polish language

=head1 SYNOPSIS

 text.pl [options] <infile> <outfile>

 You can specify - for infile/outfile - program will read from standard input or write to standard output.

=head1 OPTIONS
   -r --rzymskie <1/0>       enables or disables removing dot from Roman numbers (dangerous, disabled by default)
   -k --kropki <1/0>         changes 1.000 to 1 000
   -t --typografia <1/0>     fixed typography (hyphens etc.)
   -i --interpunkcja <1/0>   fixes interpunction
   -b --br <1/0>             changes double <br/> to two newlines
   -x --ryzykowne <1/0>      some risky changes

   -e --encoding <name>      sets character encoding of input/output files (by default utf8), for example cp1250

   -h --help                 show full help and exit

=head1 AUTHOR

Derbeth

=cut
