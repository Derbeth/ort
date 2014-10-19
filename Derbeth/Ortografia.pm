# MIT License
#
# Copyright (c) 2007-2012 Derbeth
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

package Derbeth::Ortografia;

require Exporter;

use strict;
use utf8;
use English;

our @ISA = qw/Exporter/;
our $VERSION = 0.6.11;
my @EXPORT = ('popraw_pisownie');

our $rzymskie_niebezp = 0; # pozwala na niebezpieczne zamiany
our $usun_kropki_z_liczb = 1; # niebezpieczne: zamienia 1.000 na 1 000
our $typografia = 1;
our $interpunkcja = 1;
our $kasuj_bry = 1;
our $ryzykowne = 1; # rozne nieco ryzykowne poprawki

# eg. safe_replace("(\w)'(\w)", "$1-$2"
sub safe_replace {
	my ($match,$replace,$linia) = @_;
	die unless $linia;	
	my ($done, $todo) = ('', $linia);
	while ($todo =~ /$match/) {
		my ($before,$capture,$after) = ($`,$&,$');
		my $true_replace = eval("$1 --> ");
		print STDERR ">> $true_replace\n";
		if ($before !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) { 
			$capture =~ s/$match/$replace/ or die;
		}
		$done .= $before.$capture;
		$todo = $after;
	}
	return  $done.$todo;
}

sub popraw_apostrofy {
	my $linia = shift;
	my @czesci = split /(<math>.*?<\/math>)/i, $linia;
	for (my $i=0; $i<=$#czesci; ++$i) {	
		if ($czesci[$i] !~ /<math>/i) {
			$czesci[$i] = popraw_apostrofy1($czesci[$i]);
			$czesci[$i] = popraw_apostrofy2($czesci[$i]);
			$czesci[$i] = popraw_apostrofy3($czesci[$i]);
		}
	}
	return join '', @czesci;
}

sub popraw_apostrofy1 {
	my $linia = shift;
	if ($linia =~ /((?:b|c|d|f|g|h|j|k|l|m|n|p|r|s|t|v|x|w|z|ey|ay|oy|uy|o|ee|i)]?]?)(?:'|’|`|-|–|—)(ach|iem|em|ów|owych|owym|owy|owego|owej|owe|owskimi|owskich|owskiego|owskie|owski|owcy|owca|owców|owie|owi|ową|ami|ie|ego|go|emu|ą|ę|a|i|e|y|mu|m|u)\b/) {
		my ($m1,$m2,$match,$before, $after) = ($1,$2,$MATCH,$PREMATCH,$POSTMATCH);
		if (($ryzykowne || $after !~ /^-/) && # Jay'a-Z
		$PREMATCH !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i &&
		"$PREMATCH$m1" !~ /(Barthes|Georges|Gilles|Jacques|Yves)$/) {
			$match = "${m1}${m2}";
		}
		$after = popraw_apostrofy1($after);
		$linia = $before.$match.$after;
	}
	return $linia;
}

# Laurie'mu -> Lauriemu
sub popraw_apostrofy2 {
	my $linia = shift;
	if ($linia =~ /((ie)]?]?)(?:'|’|`|-|–|—)(go|mu|m)\b(?!-)/) {
		my ($m1,$m3,$match,$before, $after) = ($1,$3,$MATCH,$PREMATCH,$POSTMATCH);
		if ($PREMATCH !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) {
			$match = "${m1}${m3}";
		}
		$after = popraw_apostrofy2($after);
		$linia = $before.$match.$after;
	}
	return $linia;
}

# Selby'ch -> Selbych
sub popraw_apostrofy3 {
	my $linia = shift;
	if ($linia =~ /([y])(?:'|’|`|-|–|—)(ch)\b(?!-)/) {
		my ($m1,$m2,$match,$before, $after) = ($1,$2,$MATCH,$PREMATCH,$POSTMATCH);
		if ($PREMATCH !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) {
			$match = "${m1}${m2}";
		}
		$after = popraw_apostrofy3($after);
		$linia = $before.$match.$after;
	}
	return $linia;
}

sub popraw_skrotowce {
	my $linia = shift;
	if ($linia =~ /([a-zA-ZłśżŁŚŻ][A-ZŁŚŻ])(\]\])?('|’|`|- | -|–|—)?(ach|ami|zie|ów|ka|etu|ecie|ocie|otu|owych|owym|owy|owi|owa|owe|ką|kę|(?:(?:ow)?(?:skie|skich|skim|ski|ską))|iem|em|om|ie|i|a|e|ę|u|y)\b(?![a-zćłńóśźż])/) {
		my ($m1,$m2,$m3,$m4,$match,$before, $after) = ($1,$2,$3,$4,$MATCH,$PREMATCH,$POSTMATCH);
		$m2 ||= '';
		if (($ryzykowne || $m3)
		&& $PREMATCH !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i && $match !~ /kPa|kDa|\bI[a-z]\b/) {
			$match = "$m1$m2-$m4"; # LOTu -> LOT-u
		}
		$after = popraw_skrotowce($after);
		$linia = $before.$match.$after;
	}
	return $linia;
}

sub popraw_porzadkowe {
	my $linia = shift;
	if ($linia =~ /<math>/i) {
		return $linia;
	}
	
	if ($linia =~ /(\d|\b[XIV]+\b)(\]\])?( ?- ?|'|–|—)?(stym|tym|dmym|mym|wszym|szym|ym|stymi|tymi|ymi|stych|tych|sty|ty|stą|tą|ą|sta|ta|stej|dmej|mej|tej|ej|wszego|szego|wszej|szej|stego|tego|dmego|mego|ste|te|dme|ciego|ciej|cim|cie|cia|cią|ci|gim|im|giego|giej|gie|gi|go|ga|iej|iego|wsza|sza|wsze|sze|wszych|szych|dmych|mych|ych|dmy|my|dma|ma|dmą|mą|wszy|szy|me|e|ego|go|y|ą)\b/) {
		my ($m1,$m2,$m3,$match,$before,$after) = ($1,$2,$3,$MATCH,$PREMATCH,$POSTMATCH);
		if (($ryzykowne || $m3)
		&& $PREMATCH !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) {
			if ($m1 =~ /\d+/) {
				$match = "$m1."; # 10-te -> 10.
			} else {
				$match = "$m1"; # VI-tym -> IV
			}
		}
		$after = popraw_porzadkowe($after);
		$linia = $before.$match.$after;
	}
	return $linia;
}

sub popraw_em {
	my $linia = shift;
	if ($linia =~ /(b|c|d|f|g|h|j|k|l|m|n|p|r|s|t|v|x|w|z)e(\]\])?('|’|`|-|–|—)m\b/) {
		my ($m1,$m2,$m3,$match,$before,$after) = ($1,$2,$3,$MATCH,$PREMATCH,$POSTMATCH);
		$m2 ||= '';
		if ($PREMATCH !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) {
			$match = "${m1}e${m2}${m3}em"; # Steve'm -> Steve'em
		}
		$after = popraw_em($after);
		$linia = $before.$match.$after;
	}
	return $linia;
}

sub popraw_liczebniki1 {
	my $linia = shift;
	if ($linia =~ /<math>/i) {
		return $linia;
	}
	
	if ($linia =~ /(\d|\b[XIV]+\b)( ?- ?|[–—])?(nasto|cio|ro|sto|to|mio|o) /) {
		my ($m1,$match,$before,$after) = ($1,$MATCH,$PREMATCH,$POSTMATCH);
		if ($PREMATCH !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) {
			$match = "$1-"; # 5-cio osobowy -> 5-osobowy, XIX-sto wieczny -> XIX-wieczny
		}
		$after = popraw_liczebniki1($after);
		$linia = $before.$match.$after;	
	}
	return $linia;
}

sub popraw_liczebniki2 {
	my $linia = shift;
	if ($linia =~ /<math>/i) {
		return $linia;
	}
	
	if ($linia =~ /(\d|\b[XIV]+\b)( ?- ?|[–—])?(miu|toma|cioma|ciu|wu|stu|rech|ech|tu|óch|ch|u)\b/) {
		my ($m1,$m2,$match,$before,$after) = ($1,$2,$MATCH,$PREMATCH,$POSTMATCH);
		if (($ryzykowne || $2)
		&& $PREMATCH !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) {
			$match = "$1"; # 12-tu -> 12
		}
		$after = popraw_liczebniki2($after);
		$linia = $before.$match.$after;	
	}
	return $linia;
}

sub popraw_liczebniki {
	my $linia = shift;
	$linia = popraw_liczebniki2 ( popraw_liczebniki1($linia) );
	return $linia;
}

sub interpunkcja {
	my $linia = shift;
	# brak odstępu po przecinku
	$linia =~ s/,(podczas (któr(ych|ej|ego)|gdy|kiedy)|jako że|mimo że|taki jak)\b/, $1/g;
	$linia =~ s/,((z|bez|od|do|po|dla) (któr(ymi|ym|ej|ego|ych|ym|ą)))\b/, $1/g;
	$linia =~ s/ ?,(kiedy|że|któr(ego|ej|ych|ym|y|ą|e)|mimo|chociaż|a|od)\b/, $1/g;

	if ($ryzykowne) {
		my ($done, $todo) = ('', $linia); # coś.Niecoś -> coś. Niecoś
		while ($todo =~ /([a-ząćęłńóśżź\]])\.([A-ZĄĆĘŁŃÓŚŻŹ])/) {
			my ($before,$match,$after,$m1,$m2) = ($`,$&,$',$1,$2);
			if ($before !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) { 
				$match = "$1. $2";
			}
			$done .= $before.$match;
			$todo = $after;
		}
		$linia = $done.$todo;
	}
	
	#$linia = safe_replace("([a-ząćęłńóśżź])\.([A-ZĄĆĘŁŃÓŚŻŹ])", "$1. $2", $linia);
	# norm
	$linia =~ s/\b((?:J|j)ako|(?:m|M)imo), (iż|że)\b/$1 $2/g;
	$linia =~ s/\b(O|o)d, któr(ego|ej|ych)\b/$1d któr$2/g;
	$linia =~ s/\bz, któr(ymi|ym|ą)\b/z któr$1/g;
	$linia =~ s/\b(bez|od|do|po|dla), (któr(ej|ego|ych|ym))\b/$1 $2/g;
	$linia =~ s/, (niż)\b/ $1/g;
	$linia =~ s/\b([pP]odczas), (któr(ych|ej|ego)|gdy|kiedy)\b/$1 $2/g;
	$linia =~ s/\btaki, jak\b/taki jak/g;
	$linia =~ s/\b([Pp]onadto), (?!że)/$1 /g;
	$linia =~ s/([^;>,\-–—]) (podczas (któr(ych|ej|ego)|gdy|kiedy)|jako że|mimo że|taki jak)\b/$1, $2/g;
	$linia =~ s/([^;>,\-–—]) ((z|bez|od|do|po|dla) (któr(ymi|ym|ej|ego|ych|ym|ą)))\b/$1, $2/g;
	# odwracanie
	$linia =~ s/\bco, do któr(ych|ego|ej)\b/co do któr$1/g;
	$linia =~ s/\b(zgodnie|wraz), z któr(ymi|ym|ą)\b/$1 z któr$2/g;	
	$linia =~ s/\bi, (po|od|z) któr(ych|ym|ego|ej)\b/i $1 któr$2/g;
	$linia =~ s/\bi, (mimo że)\b/i $1/g;
	return $linia;
}

sub typografia {
	my $linia = shift;
	# 24 - 25 -> 24-25
	my ($done, $todo) = ('', $linia);
	while ($todo =~ /(\d(?:\]\])?) (?:-|–|—|&[mn]dash;) ?((?:\[\[)?\d)/) {
		my ($before,$match,$after,$m1,$m2) = ($`,$&,$',$1,$2);
		if ($before !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) { 
			$match = "$m1–$m2";
		}
		$done .= $before.$match;
		$todo = $after;
	}
	$linia = $done.$todo;
	
	# [[1]]-[[2]] -> [[1]]półpauza[[2]]
	($done, $todo) = ('', $linia);
	while ($todo =~ /(^|[ (])((?:\[\[)?\d+(?:\]\])?)-((?:\[\[)?\d+(?:\]\])?)([ )&;,]|$)/) {
		my ($before,$match,$after,$m1,$m2,$m3,$m4) = ($`,$&,$',$1,$2,$3,$4);
		if ($before !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]+$|^==!i && $before !~ /kod_poczt|^\[\[[^[\]|]+$/ && $before !~ /ISBN *$/) { # TODO FIX
			$match = "$1$2–$3$4";
		}
		$done .= $before.$match;
		$todo = $after;
	}
	$linia = $done.$todo;
	
	# a - b -> a półpauza b
	($done, $todo) = ('', $linia);
	while ($todo =~ / - /) {
		my ($before,$match,$after) = ($`,$&,$');
		if ($before !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) { 
			$match = " – ";
		}
		$done .= $before.$match;
		$todo = $after;
	}
	$linia = $done.$todo;
	
	return $linia;
}


sub popraw_pisownie {
	my $linia = shift;
	#$linia =~ s/, to/ to/g; # Usuwanie tekstów w stylu "Komputer, to maszyna licząca".

	$linia =~ s/ \]\] /]] /g; # usuwanie spacji przed koncem linku
	$linia =~ s/ \[\[ / \[\[/g; # usuwanie spacji na początku linkus
	$linia =~ s/\bnr\.(\d)/nr $1/g; # nr.10 -> nr 10
	$linia =~ s/\b(wg|nr|Wg|Nr|mgr|mjr|ppłk|płk)\./$1/g;
	$linia =~ s!\b(W|w)\/w\b!$1w.!g; # w/w -> ww.
	$linia =~ s/\b(j|J)\/w\b/$1w./g; # j/w -> jw.
	$linia =~ s/\b(j|J)\.w\./$1w./g;
	$linia =~ s!\b(W|w)\/g\b!$1g!g;  # w/g -> wg
	$linia =~ s!\bd\/s\b!ds.!g;  # w/g -> wg
	$linia =~ s/\bdr\.\b/dr/g; # dr. -> dr, może działać źle
	
	# poprawa pisowni liczb: 10-te -> 10.
	$linia = popraw_porzadkowe($linia);
	
	if ($rzymskie_niebezp) {
		my ($done, $todo) = ('', $linia);  # nie ma kropki po rzymskich licz. porz. XX. -> XX <- niebezpieczne
		while ($todo =~ /\b([XIV]+)\./) {
			my ($before, $match, $after, $m1) = ($`,$&,$',$1);
			if ($m1 !~ /^(I|V)$/) {
				$match = "$m1";
			}
			$done .= $before.$match;
			$todo = $after;
		}
		$linia = $done.$todo;
   }
   $linia =~ s/(\b[XIV]+)\. (wiek|wieczn|stuleci)/$1 $2/g; # XX. wieku -> XX wieku
   $linia =~ s/((w|W)ieku?) (\b[XIV]+)\./$1 $3/g; # wiek XX. -> wiek XX 
   $linia =~ s/(\b[XIV]+)( |- | -| - |[–—])(wieczn)/$1-$3/g; # XX wieczny -> XX-wieczny

	$linia =~ s/(godzin(a|ie|ą)) (\d+)\.(?!\d)/$1 $3/g; # o godzinie 10. -> o godzinie 10
	$linia =~ s/(\d)\. (stycznia|lutego|marca|kwietnia|maja|czerwca|lipca|sierpnia|września|października|listopada|grudnia)/$1 $2/gi; # 1. stycznia -> 1 stycznia
	
	if ($usun_kropki_z_liczb) { # 1.000 -> 1 000; 13,000,000 -> 13 000 000
		$linia =~ s/([ (])(\d{1,3})[.,]000([ )])/$1$2 000$3/g;
		$linia =~ s/([ (])(\d{1,3})([,.])(\d\d0)\3(000)([ )])/$1$2 $4 $5$6/g;
	}
	
	# wstawia QQQ jako znak, że to trzeba zweryfikować ręcznie
	$linia =~ s/(\d)( ?- ?|[–—])?(set)\b/$1-$3QQQ/g; # ostrzeżenie przed 400-set itp.
	$linia =~ s/(\d)( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ke|ce|ek))\b/$1-$3QQQ/g; # ostrzeżenie przed zapisem 12-tka (http://poradnia.pwn.pl/lista.php?id=7010)
	$linia = popraw_liczebniki($linia);
	$linia =~ s/\b1(?:-|–|—)wszo /pierwszo/g;

	my $JEDNOSTKI = '((?:mega|kilo|deka|centy)?(?:bajtow|gramow|hercow|metrow)|barwn|biegow|bitow|bramkow|calow|cylindrow|cyfrow|częściow|dekadow|dniow|dolarow|dzieln|dzienn|etapow|fazow|funtow|godzinn|groszow|gwiazdkow|hektarow|kanałow|kątn|klasow|klawiszow|kołow|kondygnacyjn|konn|krotn|lec|letn|lufow|masztow|miejscow|miesięczn|miliardow|milionow|minutow|nabojow|nawow|odcinkow|osobow|palczast|pasmow|piętrow|pinow|płytow|procentow|procesorow|przęsłow|punktow|ramienn|rdzeniow|roczn|rurow|sekundow|setow|silnikow|spadow|stopniow|strunow|strzałow|suwow|ścienn|taktow|tomow|tonow|tygodniow|tysięczn|wartościow|watow|wieczn|woltow|wymiarow|zaworow|zębow)(ia|ie|iu|ią|iej|ych|ymi|ym|ego|emu|ej|[aeyią])|lat(ek|kami|ka|kiem|ki|ku|ków)';
	my $LICZEBNIKI = '';
	$linia =~ s/(\d)(?: | - |[-–—] | [-–—]|\. |–|—)($JEDNOSTKI)\b/$1-$2/og; # 32 bitowy -> 32-bitowy
	$linia =~ s/\b([jJ]edno|[dD]wu|[tT]rój|[tT]rzy|[cC]ztero|[pP]ięcio|[sS]ześcio|[sS]iedmio|[oO]śmio|[dD]ziewięcio|[dD]ziesięcio|[dD]wunasto|[pP]iętnasto|[sS]zesnasto|[dD]wudziesto|[pP]ółtora|[tT]rzydziesto|[sS]tu|[wW]ielo)(?: | - |[-–—] | [-–—]|\. |–|—|-)($JEDNOSTKI)\b/$1$2/og; # sześcio tonowy -> sześciotonowy
	$linia =~ s/\b([dD]wu|[cC]ztero|[pP]ięcio|[sS]ześcio|[sS]iedmio|[oO]śmio|[dD]ziewięcio|[dD]ziesięcio|[dD]wunasto|[pP]iętnasto|[sS]zesnasto|[dD]wudziesto|[tT]rzydziesto) i pół ($JEDNOSTKI)/$1ipół$2/og; # http://so.pwn.pl/zasady.php?id=629465
	$linia =~ s/\b([dD]wu|[cC]ztero|[pP]ięcio|[sS]ześcio|[sS]iedmio|[oO]śmio|[dD]ziewięcio|[dD]ziesięcio|[dD]wunasto|[pP]iętnasto|[sS]zesnasto|[dD]wudziesto|[tT]rzydziesto)((?:, | ))/$1-$2/og;
	$linia =~ s/\b([dD]wu|[cC]ztero|[pP]ięcio|[sS]ześcio|[sS]iedmio|[oO]śmio|[dD]ziewięcio|[dD]ziesięcio|[dD]wunasto|[pP]iętnasto|[sS]zesnasto|[dD]wudziesto|[tT]rzydziesto)-(lub)/$1- $2/og; # trzy-lub czterokołowy

	$linia =~ s/(lat(ach|a)?) '(\d\d)/$1 $3./g; # lat '80 -> lat 80.
	$linia =~ s/ '(\d\d)\.(?!\d)/ $1./g; # lat '80. -> lat 80  # '
	$linia =~ s/\b([XIV]{2,})w\./$1 w./g; # XXw. -> XX w.
	
	$linia =~ s/keQQQ/kęQQQ/g;
	
	$linia =~ s/10( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/dziesiąt$4/g;
	$linia =~ s/11( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/jedenast$4/g;
	$linia =~ s/12( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/dwunast$4/g;
	$linia =~ s/13( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/trzynast$4/g;
	$linia =~ s/14( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/czternast$4/g;
	$linia =~ s/15( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/piętnast$4/g;
	$linia =~ s/16( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/szesnast$4/g;
	$linia =~ s/17( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/siedemnast$4/g;
	$linia =~ s/18( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/osiemnast$4/g;
	$linia =~ s/19( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/dziewiętnast$4/g;
	$linia =~ s/20( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/dwudziest$4/g;
	$linia =~ s/30( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/trzydziest$4/g;
	$linia =~ s/40( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/czterdziest$4/g;
	$linia =~ s/50( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/pięćdziesiąt$4/g;
	$linia =~ s/60( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/sześćdziesiąt$4/g;
	$linia =~ s/70( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/siedemdziesiąt$4/g;
	$linia =~ s/80( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/osiemdziesiąt$4/g;
	$linia =~ s/90( ?- ?|[–—])?((st|t|)(kom|kach|kami|ka|ki|kę|ką|ce|ek))QQQ\b/dziewięćdziesiąt$4/g;
	
	if ($ryzykowne) {
		my ($done, $todo) = ('', $linia);  # 4.. -> 4. ale nie 4...
		while ($todo =~ /(\d)\.\.(?!\.)/) {
			my ($before, $match, $after, $m1) = ($`,$&,$',$1);
			if ($before  !~ m!http://\S+$|(Grafika|Image|Plik|File):[^\|]*$!i) {
				$match = "$1.";
			}
			$done .= $before.$match;
			$todo = $after;
		}
		$linia = $done.$todo;
	}
	
	$linia =~ s/\b(d|D)j\b/DJ/g; # Dj -> DJ
	#$linia =~ s/([A-Z]|Ł|Ż)('|’|`)(ską|ski|ką|kę|[uaeyoiąęćó])/$1$3/g; # ' # DJ'a -> DJa, w następnej linii się poprawi porządnie
	
	# poprawa odmiany skrótowców: LOTu -> LOT-u
	$linia = popraw_skrotowce($linia);
	
	$linia =~ s/Ż-e\b/Że/g; # popr. po poprzednim
	#$linia =~ s/(Ł)-/$1/g; # usunięcie Łyżwiński -> Ł-yżwiński
	$linia =~ s/\bhP-a\b/hPa/g;
	if ($linia =~ /\b([A-Z]+)T(\]\])?[-–—]ie\b/ ) { # LOT-ie -> Locie
		my $subst = lc($1) . "cie";
		$subst = ucfirst($subst);
		if ( $2 eq ']]' ) { $subst = "$1T|$subst]]"; }
		$linia =~ s/\b([A-Z]+)T(\]\])?[-–—]ie\b/$subst/g;
	}
	if ($linia =~ /\b([A-Z]+)X(\]\])?[-–—]ie\b/ ) { # UNIX-ie -> Uniksie
		my $subst = lc($1) . "ksie";
		$subst = ucfirst($subst);
		if ( $2 eq ']]' ) { $subst = "$1X|$subst]]"; }
		$linia =~ s/\b([A-Z]+)X(\]\])?-ie\b/$subst/g;
	}
	
	# apostrofy
	$linia =~ s/\B(oy|ey)('|’|`|-|–|—)e?go\b/$1’a/g;
	
	$linia = popraw_apostrofy($linia);
	$linia =~ s/(Luk|Mik|[rR]emak|Spik)e('|’|`|-|–|—)(em|m)\b/$1iem/g; # Mike'm -> Mikiem
	$linia =~ s/\[\[\s*(Luk|Mik|[rR]emak|Spik)e\s*\]\]('|’|`|-|–|—)(em|m)\b/[[$1e|$1iem]]/g; # [[remake]]'m -> [[remake|remakiem]]
	$linia =~ s/(Luk|Mik|[rR]emak|Spik)e('|’|`|-|–|—)(i)\b/$1i/g;   # remake'i -> remaki
	$linia =~ s/\[\[\s*(Luk|Mik|[rR]emak|Spik)e\s*\]\]('|’|`|-|–|—)(i)\b/[[$1e|$1i]]/g; # [[remake]]'i -> [[remake|remaki]]
	$linia =~ s/\b(Metall|Galact)ici\b/$1iki/g; # Metallici -> Metalliki
	$linia =~ s/\B(ell)i(?:'|’|`|-)?(ego|emu)\b/$1$2/g; # Botticelliemu -> Botticellemu http://so.pwn.pl/zasady.php?id=629632
	$linia =~ s/\[\[([^\]|]+ell)i\]\](?:'|’|`|-)?(ego|emu)\b/[[$1i|$1$2]]/g; # [[Sandro Botticelli]]ego

	$linia =~ s/ieego\b/iego$1/g; # Laurieego -> Lauriego
	$linia =~ s/(Mar|Eri)ciem\b/$1kiem/g; # Marciem, Markem -> Markiem, Ericiem -> Erikiem
	$linia =~ s/\bMarkem\b/Markiem/g;
	$linia =~ s/a('|’|`)([ąęy])\b/$2/g; # Laura'y -> Laury
	$linia =~ s/(oe)((?:\]\])?)('|’|`|-)(go|m)\b/$1$2$4/g; # Joe'go -> Joego
	$linia =~ s/\Be('|’|`)go\b/ego/g; # Mecke'go -> Meckego
	$linia =~ s/y('|’|`|-|–|—)iego\b/y’ego/g; # Percy'iego -> Percy'ego
	$linia =~ s/y((?:\]\])?)('|’|`|-)m\b/y$1m/g; # Tony'm -> Tonym '
	$linia = popraw_em($linia);
	$linia =~ s/`/’/g; # zmiana apostrofu
	if ($ryzykowne) {
		$linia =~ s/\Bt'cie/cie/g; # Kurt'cie -> Kurcie
		$linia =~ s/xie\b/ksie/g; # Foxie -> Foksie
		$linia =~ s/\[\[([^\]]+)x\]\]ie\b/[[$1x|$1ksie]]/g; # [[box]]ie -> [[box|boksie]] "
	}
	$linia =~ s/(Burke|Duke|George|Luke|Mike|Pete|Shayne|Spike|Steve)((?:\]\])?)(a|owi)\b/$1$2’$3/g;
	$linia =~ s/(Boyl|Doyl|Joyc|Lawrenc|Wayn)e?((?:\]\])?)(a|owi)\b/$1e$2’$3/g;
	$linia =~ s/(Boyl|Doyl|Joyc|Lawrenc|Wayn)e?((?:\]\])?)(em|m)\b/$1e$2’em/g;
	$linia =~ s/(Barr|Dann|Gar|Gretzk|Harr|Perc|Perr|Terr|Timoth)y?((?:\]\])?)(ego|emu)\b/$1y$2’$3/g;

	$linia =~ s/(Andrew|Matthew)('|’|`|-|–|—)?(a|em|ie|owi)/$1/g; # Andrew'a -> Andrew
	$linia =~ s/(François)('|’|`|-)?(a|em)\b/$1/g; # Françoisa -> François

	$linia =~ s/Charles(a|em|owi) de Gaulle/Charles’$1 de Gaulle/gi;
	$linia =~ s/(Barthes|Jacques|Yves)(owi|em|a)\b/$1’$2/g;
	$linia =~ s/Yves('|’|`|-)?ie\b/Ywie/g;

	$linia =~ s/Diksie/Dixie/g; # z powrotem
	$linia =~ s/(WiF|TD|HD|HiF)-i/$1i/g;   # z powrotem
	
	$linia =~ s/\bsmsy\b/SMS-y/g;
	$linia =~ s/\b((MSZ|ONZ)(\]\])?)(-| -|- |'|’|`|–|—)(tu|u)/$1-etu/g;
	$linia =~ s/\b((MSZ|ONZ)(\]\])?)(-| -|- |'|’|`|–|—)(cie)/$1-ecie/g;

	$linia =~ s/\[\[([^|]+)\|\1(a|e|u|ie|em)\]\]/[[$1]]$2/g; # [[boks|boksu]] -> [[boks]]u
	$linia =~ s/:\s*==/==/g;
	
	# pisownia, literówki, częste błędy
	$linia =~ s/(bieżni|elektrowni|głębi|jaskini|Korei|powierzchni|pustyni|skoczni|skrobi|uczelni|ziemi)i/$1/gi; # "Koreii", "ziemii" itp.
	$linia =~ s/\b(Austri|Australi|Algieri|amfibi|Armeni|Belgi|[bB]ibli|Brazyli|Brytani|Bułgari|Cynthi|Estoni|Etiopi|Finlandi|Grenlandi|Hiszpani|Holandi|Irlandi|Islandi|Japoni|Jordani|Jugosławi|laryngologi|lini|Mołdawi|Mongoli|Nigeri|Norwegi|opini|Portugali|Serbi|Słoweni|stomatologi|Szwajcari|Tajlandi|Virgini|Zelandi)\b/$1i/g; # Japoni -> Japonii
	$linia =~ s/\b(ale|knie|kole|mierze|nadzie|Okrze|ru|szy|Zia)ji\b/$1i/gi; # szyji -> szyi
	$linia =~ s/(analfabety|anarchi|buddy|fanaty|faszy|femini|judai|kapitali|katechi|komuni|marksi|masochi|mechani|mesjani|nazi|nihili|oportuni|optymi|organi|pesymi|platoni|pozytywi|protestanty|radykali|romanty|sady|socjali|syndykali|totalitary|trocki)źmie/${1}zmie/gi; # komuniźmie -> komunizmie
	
	$linia =~ s/\bz pośród\b/spośród/g;
	$linia =~ s/\bZ pośród\b/Spośród/g;
	$linia =~ s/\b(W|w) śród\b/$1śród/g;
	$linia =~ s/\b(W|w)(?:ogóle|ogule|ogle)\b/$1 ogóle/g;
	$linia =~ s/\b(W|w) skutek\b/$1skutek/g;
	$linia =~ s/\b([wW])iekszy\b/$1iększy/g;
	$linia =~ s/\bspowrotem\b/z powrotem/g;
	$linia =~ s/\bSpowrotem\b/Z powrotem/g;
	$linia =~ s/\bspowodu\b/z powodu/g;
	$linia =~ s/\bz pod\b/spod/g;
	$linia =~ s/\bZ pod\b/Spod/g;
	$linia =~ s/\bz nad\b(?! wyraz)/znad/g;
	$linia =~ s/\bZ nad\b(?! wyraz)/Znad/g;
	$linia =~ s/\bz przed\b/sprzed/g;
	$linia =~ s/\bZ przed\b/Sprzed/g;
	$linia =~ s/\bz poza\b/spoza/g;
	$linia =~ s/\bZ poza\b/Spoza/g;
	$linia =~ s/\b(p|P)onad to\b/$1onadto/g;
	$linia =~ s/\b(p|P)o środku\b/$1ośrodku/g;
	$linia =~ s/\bz pod\b/spod/g;
	$linia =~ s/\bZ pod\b/Spod/g;
	$linia =~ s/\bz\s?tąd\b/stąd/g;
	$linia =~ s/\bZ\s?tąd\b/Stąd/g;
	$linia =~ s/\bz tamtąd\b/stamtąd/g;
	$linia =~ s/\bZ tamtąd\b/Stamtąd/g;
	$linia =~ s/\bz nikąd\b/znikąd/g;
	$linia =~ s/\bZ nikąd\b/Znikąd/g;
	$linia =~ s/\b(Na|na) codzień\b/$1 co dzień/g;
	$linia =~ s/\b(Po|po)prostu\b/$1 prostu/g;
	$linia =~ s/\b(Na|na)pewno\b/$1 pewno/g;
	$linia =~ s/\b(Co|co)najmniej\b/$1 najmniej/g;
	$linia =~ s/\b(Na|na)razie\b/$1 razie/g;
	$linia =~ s/\b(Od|od)razu\b/$1 razu/g;
	$linia =~ s/\b(Na|na) codzień\b/$1 co dzień/g;
	$linia =~ s/\b(Co|co) dzienn(ych|ymi|ym|ie|ej|e|y|a|ą)\b/$1dzienn$2/g;
	$linia =~ s/\b(Na|na) prawdę\b/$1prawdę/g;
	$linia =~ s/\b(Na|na) przeciwko\b/$1przeciwko/g;
	$linia =~ s/\b(Do|do) okoła\b/$1okoła/g;
	$linia =~ s/\bporaz\b/po raz/g;
	$linia =~ s/\b([Ww])(głąb|skład)\b/$1 $2/g;
	$linia =~ s/\b(Do|do) tond\b/$1tąd/g;
	$linia =~ s/\b(?:stond|z tąd|z tond)\b/stąd/g;
	$linia =~ s/\b(?:Stond|Z tąd|Z tond)\b/Stąd/g;
	$linia =~ s/\bwszechczasów\b/wszech czasów/g;
	$linia =~ s/\b((s|S)tandar)t(owymi|owym|owy|owa|owych|owe|ową|ów|om|u|y)?\b/$1d$3/g;
	$linia =~ s/\bstandarcie\b/standardzie/g;
	$linia =~ s/\bmożnaby\b/można by/g;
	$linia =~ s/\b(P|p)ożąd(ek|ku|kiem)\b/$1orząd$2/g;
	$linia =~ s/\bna prawdę\b/naprawdę/g;
	$linia =~ s/\b(W|w) raz z\b/$1raz z/g;
	$linia =~ s/\b(W|w) skutek\b/$1skutek/g;
	$linia =~ s/\b(W|w)razie\b/w razie/g;
	$linia =~ s/\bZ przed\b/Sprzed/g;
	$linia =~ s/\bz przed\b/sprzed/g;
	$linia =~ s/\b(N|n)ie dług(o|i)\b/$1iedług$2/g;
	$linia =~ s/\b(P|p)oprostu\b/$1o prostu/g;
	
	$linia =~ s/\b(imi|książ|mas|par|plemi|zwierz)e\b/$1ę/g;
	$linia =~ s/\btą (mapę|jaskinię)\b/tę $1/g;
	
	$linia =~ s/\b(a|A)bsorbcj(a|i|ą)\b/$1bsorpcj$2/g;
	$linia =~ s/\b(b|B)ierząc(ej|ych|ego|ym|o|y|a)\b/$1ieżąc$2/g;
	$linia =~ s/\bbieże\b/bierze/g;
	$linia =~ s/\b(B|b)yc\b/$1yć/g;
	$linia =~ s/\b(B|b)yl\b/$1ył/g;
	$linia =~ s/\b(C|c)jan(ku|ek|owodór|owodoru)\b/$1yjan$2/g;
	$linia =~ s/\b(C|c)zest(ych|ymi|o|y|ą|a|e)\b/$1zęst$2/g;
	$linia =~ s/\b(D|d)osc\b/$1ość/g;
	$linia =~ s/\b(D|d)uz(o|y|a|e|ych|ą)\b/$1uż$2/g;
	$linia =~ s/\b(F|f)ir(nam|man)en(tem|tu|cie|t)\b/$1irmamen$3/g;
	$linia =~ s/\bfrancuzk(iego|imi|im|ich|iej|ie|a|i|ą)/francusk$1/g;
	$linia =~ s/\b(ł|Ł)abądź\b/$1abędź/g;
	$linia =~ s/\b(G|g)dyz\b/$1dyż/g;
	$linia =~ s/\b(G|g)łown(a|e|i|ych|ymi|y|ą)\b/$1łówn$2/g;
	$linia =~ s/\bgodź\. /godz. /g;
	$linia =~ s/\bjak(a|i|ie)s\b/jak$1ś/g;
	$linia =~ s/\bktor(zy|ego|ych|ymi|ym|a|ą|y)\b/któr$1/g;
	$linia =~ s/\bludzią\b/ludziom/g;
	$linia =~ s/\błać\./łac./g;
	$linia =~ s/\bmln\. ([a-ząćęłńóśżź])/mln $1/g; # 100 mln. dolarów -> 100 mln dolarów
	$linia =~ s/\bmoze\b/może/g;
	$linia =~ s/\bmo[zż]naby\b/można by/g;
	$linia =~ s/\b(N|n)astepn(ego|ej|ych|a|e|y|i|ą)\b/$1astępn$2/g;
	$linia =~ s/\b(O|o)procz\b/$1prócz/g;
	$linia =~ s/\bzaden\b/żaden/g;
	$linia =~ s/\b(O|o)rgina(łu|łów|ły|łem|łami|ł|lni|lnych|lny|lna|lnej|lnego|lnymi|lnym|lną|lne)\b/$1rygina$2/g;
	$linia =~ s/\b(P|p)iersz(ymi|ym|ych|ej|ego|a|y|e|ą)\b/$1ierwsz$2/g;
	$linia =~ s/\b(P|p)ojecie\b/$1ojęcie/g;
	$linia =~ s/\b(p|P)ojedyńcz(ego|ymi|ym|ych|ej|e|y|ą|a|o)\b/$1ojedyncz$2/g;
	$linia =~ s/\b(p|P)ożąd(ek|ku|kiem|kowy)\b/$1orząd$2/g;
	$linia =~ s/\b(P|p)zrez\b/$1rzez/g;
	$linia =~ s/\b(P|p)rzyklad\b/$1rzykład/g;
	$linia =~ s/\b(R|r)ownie(ż|z)\b/$1ównież/g;
	$linia =~ s/\bsciśle\b/ściśle/g;
	$linia =~ s/\b(S|s)pógłos(ce|ek|kom|kami|kach|ka|ki)\b/$1półgłos$2/g;
	$linia =~ s/\bszweck(iego|imi|im|ich|iej|ie|a|i|ą)/szwedzk$1/g;
	$linia =~ s/\btranzakcj(a|i|om|ę|ami|ach|e)/transakcj$1/g;
	$linia =~ s/\btyś\. /tys. /g;
	$linia =~ s/\bwach(ać|ało|ał|a)\b/wah$1/g;
	$linia =~ s/\b(W|w)iecej\b/$1ięcej/g;
	$linia =~ s/\b(W|w)iedze\b/$1iedzę/g;
	$linia =~ s/\b(W|w)ieksz(ych|a|y|e)\b/$1iększ$2/g;
	$linia =~ s/\b(W|w)i[eę]kszo(sc|sć|ść|śc)\b/$1iększość/g;
	$linia =~ s/\bwłaść\./właśc./g;
	$linia =~ s/\b(?:wziąść|wziąźć)\b/wziąć/g;
	$linia =~ s/\b(W|w)sród\b/$1śród/g;
	$linia =~ s/\bza wyjątkiem\b/z wyjątkiem/g;
	$linia =~ s/\bzarząda(ła|li|ł)\b/zażąda$1/g;
	$linia =~ s/\bznaleść\b/znaleźć/g;
	$linia =~ s/\b(Z|z)wiaz(ek|ku|kiem)\b/$1wiąz$2/g;
	$linia =~ s/\b([Zz])wycięsc(a|ów)\b/$1wycięzc$2/g;
	$linia =~ s/\bżadko\b/rzadko/g;
	
	if ($linia =~ s/\b(v ?- ?ce|vice|wice)[ -]?(\w)/wice\l$2/g) { # "v-ce"
		$linia =~ s/\bwice([vV]ersa|[cC]ity)\b/vice $1/g;
	}
	if ($linia =~ /\b(V ?- ?ce|Vice|Wice)[ -]?(\w)/ && $' !~ /^(ity|ersa)\b/) { # "V-ce"
		if ($linia =~ s/\b(V ?- ?ce|Vice|Wice)[ -]?(\w)/Wice\l$2/g) {
			$linia =~ s/W(icente?|icenz)/V$1/g; # cofamy: Vincente, Vicenza
		}
	}
	
	# interpunkcja
	if ($interpunkcja) {
		$linia = interpunkcja($linia);
	}
	
	$linia =~ s/\b(wschodni|zachodni)o(?:-|–|—| )(północn|południow)/${2}o-$1/g;
	$linia =~ s/\b(wschodn|zachodn)iy/${1}i/g;
	
	$linia =~ s/(t|T)rash( |-|–|—)metal/$1hrash metal/g;
	$linia =~ s/\b(art|black|death|doom|glam|gothic|groove|hard|heavy|nu|pop|punk|speed|thrash)( |-)(rock|metal|punk)(owych|owy|owej|owa|owym|owe|ową|owo|owiec)/$1$3$4/gi;
	$linia =~ s/\[\[(art|black|death|doom|glam|gothic|groove|hard|heavy|nu|pop|punk|speed|thrash)( |-)(rock|metal|punk)\]\](owych|owy|owa|owej|owym|owe|ową|owo|owiec)/[[$1 $3|$1$3$4]]/g;
	$linia =~ s/hip hop(owym|owy|owa|owej|owym|owe)/hip-hop$1/g;
	$linia =~ s/\[\[hip hop\]\](owy|owa|owej|owym|owe)/[[hip hop|hip-hop$1]]/g;
	
	#typografia
	if ($typografia) {
		$linia = typografia($linia);
	}
	
	# techniczne
	#$linia =~ s/\[\[([0-9a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŻŹ]+( [a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŻŹ]+)?)\|\1\]\]/[[$1]]/g; # [[a|a]] -> [[a]], [[a b|a b]] -> [[a b]]
	$linia =~ s/\[\[([^|]+)\|\1\]\]/[[$1]]/g; # [[a|a]] -> [[a]], [[a b|a b]] -> [[a b]]
	
	$linia =~ s/(==\s*)Zobacz także/${1}Zobacz też/i;
	$linia =~ s/Zewnętrzne linki/Linki zewnętrzne/i;
	$linia =~ s/\[\[(Image|Grafika|Plik|File): */[[Plik:/gi;
		
	if ($kasuj_bry) {
		$linia =~ s/(<br( ?\/)?>){2}/\n\n/g;
	}
	
	return $linia;
}

sub popraw_kategorie {
	my $linia = shift;
	$linia =~ s/\[\[Category:/[[Kategoria:/gi;
# 	if ($linia =~ /\[\[\s*(k|K)ategoria\s*:\s*([^ \]]+)/) {
# 		my $slowo = ucfirst($2);
# 		$linia = "$PREMATCH\[\[Kategoria:$slowo$POSTMATCH";
# 	}
	$linia =~ s/\[\[\s*(?:k|K)ategoria\s*:\s*([^ |\]]+)/[[Kategoria:\u$1/g;
	$linia =~ s/(\]\])\s*(\[\[Kategoria:)/$1\n$2/g;  # rozbicie [[Kategoria:A]][[Kategoria:B]]
	return $linia;
}

1;
