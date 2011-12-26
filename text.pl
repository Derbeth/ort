#!/usr/bin/perl -w
use strict;
use utf8;
use English;
use Encode;
use Getopt::Long;
use Derbeth::Ortografia;

my $infile = 'in.txt';
my $outfile = 'out.txt';

$infile = $ARGV[0] if ($ARGV[0]);
$outfile = $ARGV[1] if ($ARGV[1]);

open(FIN,$infile);
open(FOUT,">$outfile");

my $NOSORT = 'NOSORT';
my $l_kategorii=0; # liczba kategorii
my $defaultsort=$NOSORT;
my $rozne_sort=0;

my $linia=<FIN>;

GetOptions('r|rzymskie=i' => \$Derbeth::Ortografia::rzymskie_niebezp,
	'k|kropki=i' => \$Derbeth::Ortografia::usun_kropki_z_liczb,
	't|typografia=i' => \$Derbeth::Ortografia::typografia,
	'i|interpunkcja=i' => \$Derbeth::Ortografia::interpunkcja,
	'b|br=i' => \$Derbeth::Ortografia::kasuj_bry,
);

my $pocz_kategorii = 0;

while($linia) {
	$linia = decode_utf8($linia);
	
	if (!$pocz_kategorii && $linia =~ /\[\[(category|kategoria)/i) {
		$pocz_kategorii = 1;
	}
	
	if ($pocz_kategorii) {
		$linia = Derbeth::Ortografia::popraw_kategorie($linia);
	} else {
		$linia = Derbeth::Ortografia::popraw_pisownie($linia);
	}		
} continue {
	$linia = encode_utf8($linia);
	print FOUT $linia;
	$linia = <FIN>;
}

close FIN;
close FOUT;
