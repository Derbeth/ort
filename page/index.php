<?php

$has_params = 0;
$by_get = 0;
$input = '';
$output = '';

$interp = 0;
$typogr = 0;
$br = 0;
$kropki = 0;
$rzymskie = 0;
$ryzykowne = 0;

function writeToFile($name, $text) {
	$src = fopen($name, 'w');
	if (!$src) {
		echo "cannot write";
		die;
	}
	fwrite($src, $text);
	fclose($src);
}

function readFromFile($name) {
	$text = '';
	$result = fopen($name, 'r');
	if (!$result) {
		echo "cannot read";
		unlink($name);
		die;
	}
	while (!feof($result)) {
		$buffer = fgets($result, 8096);
		$text .= $buffer;
	}
	fclose($result);
	return $text;
}

function toChkd($var) {
	if ($var) {
		echo 'checked="checked"';
	}
}

if (!$_POST['input'] && !$_GET['title']) {
	$interp = 1;
	$typogr = 1;
	$br = 1;
	$kropki = 1;
	$rzymskie = 0;
	$ryzykowne = 1;
} else {
	if ($_POST['interp']) $interp = (int)$_POST['interp'];
	if ($_GET['interp']) $interp = (int)$_GET['interp'];

	if ($_POST['typogr']) $typogr = (int)$_POST['typogr'];
	if ($_GET['typogr']) $typogr = (int)$_GET['typogr'];

	if ($_POST['br']) $br = (int)$_POST['br'];
	if ($_GET['br']) $br = (int)$_GET['br'];

	if ($_POST['kropki']) $kropki = (int)$_POST['kropki'];
	if ($_GET['kropki']) $kropki = (int)$_GET['kropki'];

	if ($_POST['rzymskie']) $rzymskie = (int)$_POST['rzymskie'];
	if ($_GET['rzymskie']) $rzymskie = (int)$_GET['rzymskie'];

	if ($_POST['ryzykowne']) $ryzykowne = (int)$_POST['ryzykowne'];
	if ($_GET['ryzykowne']) $ryzykowne = (int)$_GET['ryzykowne'];
}

if ($_POST['input']) {
	$input = stripslashes($_POST['input']);
	$has_params = 1;
}
if ($_GET['input']) {
	$input = stripslashes($_GET['input']);
	$has_params = 1;
	$by_get = 1;
}
# TODO artykuł But It's Better If You Do
if ($_GET['server']) {
	$title = $_GET['title'];
	$title = stripslashes($title);
	$title = urlencode($title);
	$server = $_GET['server'];
	if (!preg_match('/^http/', $server)) {
		$server = "http:$server";
	}
	$url = $server.$_GET['script'].'?title='.$title.'&action=raw';
	$url = escapeshellarg($url);
	$command = "wget -v -O - $url";
	$input = shell_exec($command);
	$has_params = 1;
	$by_get = 1;
}

if( $_POST['diff']) {
	$after = stripslashes($_POST['output']);

	$no = rand(0,2000);
	$infile1 = "diffb$no.txt";
	$infile2 = "diffa$no.txt";
	$outfile = "diff$no.txt";

	writeToFile($infile1, $input);
	writeToFile($infile2, $after);

	exec("./diff2html.py --only-changes $infile1 $infile2 > $outfile");
	unlink($infile1);
	unlink($infile2);

	$result = readFromFile($outfile);
	unlink($outfile);

	echo $result;
	exit;
}
if ($has_params) {
	$no = rand(0,2000);
	$infile = "in$no.txt";
	$outfile = "out$no.txt";

	writeToFile($infile, $input);

	exec("cd script && ./text.pl ../$infile ../$outfile -i $interp -t $typogr -k $kropki -b $br -r $rzymskie -x $ryzykowne");
	unlink($infile);

	$output = readFromFile($outfile);
	#$output = "-i $interp -t $typogr -k $kropki -b $br -r $rzymskie -x $ryzykowne\n" . $output;

    unlink($outfile);

    if (!$by_get) {
    	$input = htmlspecialchars($input);
		$output = htmlspecialchars($output);
	}
}

if ($_GET['input']) {
	#$output = str_replace("/\\r/", '', $output);
	#$output = str_replace("/\\n/", "\\\\n", $output);
	$output = str_replace("/'/", "\\'", $output);
	#echo "alert(\"$output\");";
	$partNum = $_GET['c'];
	echo "setTimeout('finishOrt(\"$output\",$partNum)',1);";
	exit;
}
if ($_GET['server']) {
	#$tf = fopen('out.txt','w');
	#fwrite($tf,$output);
	#fclose($tf);

	#$output = stripslashes($output);
	$output = str_replace("\n", "`_", $output);
	$output = str_replace("\\", "\\\\", $output);
	$output = str_replace("'", "\\'", $output);
	#echo "setTimeout('finishAll(\"$output\")',1);";
	echo "wp_ort.finishAll('".$output."');";
	exit;
}

print "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';

?>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="pl" lang="pl">
<head>
<meta http-equiv="content-type" content="text/html;charset=utf-8" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta name="author" content="Derbeth" />
<meta name="keywords" content="Wikipedia, tool, narzędzie, online, skrypt, wolne oprogramowanie, ortografia, automatyczne, poprawianie, pisownia, interpunkcja" />
<meta name="description" content="Skrypt wykonujący automatyczne poprawianie pisowni w tekstach" />
<link rel="stylesheet" type="text/css" href="style.css"/>
<title>ort - skrypt automatycznie poprawiający ortografię</title>
</head>
<body>

<p>Skrypt poprawia ortografię w hasłach z Wikipedii, Wikibooks itp. (korzystających z formatowania MediaWiki) albo czystym, zwykłym tekście.</p> <p>Poprawia nieprawidłowe użycie apostrofu ("Disney'a"), nieprawidłową odmianę skrótowców ("SMSa" <abbr title="względnie">wzgl.</abbr> "SMS'a"), błędną odmianę liczebników ("13-stego/-tego/-ego/-go", "5-cio osobowy", "4 bajtowy"), nieprawidłowy zapis skrótów ("wg."), częste błędy pisowni ("ziemii", "wogóle", "z tąd"). Ogólnie - usuwa dużą część błędów ze strony <a href="http://pl.wikipedia.org/wiki/Pomoc:Powszechne_błędy_językowe">Powszechne będy językowe</a> i trochę dodatkowych. Wykonuje też proste sprzątanie wikikodu (gł. poprawę linków). Problemów wskazywanych przez skrypt <strong>nie wykryje</strong> zazwyczaj ani Word ani OpenOffice (chyba że doinstalujemy <a href="http://www.languagetool.org/">LanguageTool</a>, co mocno polecam).</p>
<p>Skrypt był rozwijany przez około rok, więc jest dość stabilny i nie robi głupot. Wciąż jednak może psuć adresy internetowe i nazwy grafik (nazwa po francusku nie musi stosować się do polskiej ortografii), więc na Wikipedii <strong>można go stosować tylko wraz z użyciem podglądu zmian</strong> (przycisk "Podgląd zmian" na prawo od "Pokaż podgląd"). Dla wikipedystów istnieje wersja działająca jako <a href="http://pl.wikipedia.org/wiki/Wikipedysta:Derbeth/ort">przycisk w polu edycji</a>.</p>
<form method="post" action=".">
<fieldset>
<legend>Tekst wejściowy</legend>
<textarea id="input" name="input" cols="120" rows="8">
<?php echo $input; ?>
</textarea>
</fieldset>
<fieldset>
<legend>Tekst wyjściowy</legend>
<textarea id="output" name="output" cols="120" rows="13">
<?php echo $output; ?>
</textarea>
</fieldset>
<p><input type="submit"/>
<input type="submit" name="diff" value="Pokaż różnice"/>
<label>Interpunkcja<input type="checkbox" name="interp" value="1" <?php toChkd($interp); ?>/></label>
<label>Typografia<input type="checkbox" name="typogr" value="1" <?php toChkd($typogr); ?>/></label>
<label>Usuwanie <abbr title="wielokrotnych">wielokr.</abbr> &lt;br>
<input type="checkbox" name="br" value="1" <?php toChkd($br); ?>/></label>
<label>Zapis tysięcy<input type="checkbox" name="kropki" value="1" <?php toChkd($kropki); ?>/></label>
<label>Ryzykowne <abbr title="poprawki">popr.</abbr> liczb rzymskich
<input type="checkbox" name="rzymskie" value="1" <?php toChkd($rzymskie); ?>/></label>
<label>Pozostałe ryzykowne
<input type="checkbox" name="ryzykowne" value="1" <?php toChkd($ryzykowne); ?>/></label>
</p>
</form>
<?php if ($output) { ?>
	<script type="text/javascript">
document.getElementById('output').focus();
document.getElementById('output').select();
	</script>
<?php } ?>
<hr/>
<p>Autorem skryptu jest <a href="http://pl.wikipedia.org/wiki/Wikipedysta:Derbeth">Derbeth</a>. Program jest Wolnym Oprogramowaniem na <a href="http://www.opensource.org/licenses/mit-license.php" title="MIT license">licencji MIT</a>. <a href="https://github.com/Derbeth/ort">Kod źródłowy</a>. Autor nie udziela żadnych gwarancji ani rękojmi na jego działanie.</p>
<p><a href="http://validator.w3.org/check?uri=referer"><img
src="http://www.w3.org/Icons/valid-xhtml10-blue"
alt="Valid XHTML 1.0 Strict" height="31" width="88" /></a>
</p>

<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
var pageTracker = _gat._getTracker("UA-2632685-4");
pageTracker._trackPageview();
</script>
</body>
</html>
