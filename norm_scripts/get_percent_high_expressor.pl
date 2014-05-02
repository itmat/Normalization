#!/usr/bin/env perl
if(@ARGV<2) {
    die "Usage: perl get_percent_high_expressor.pl <sample dirs> <loc> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

options:
 -u  :  set this if you want to return only unique stats, otherwise by default
         it will return both unique and non-unique stats.

 -nu :  set this if you want to return only non-unique stats, otherwise by default
         it will return both unique and non-unique stats.

";
}
$U = "true";
$NU = "true";
$numargs = 0;
$option_found = "false";
for($i=2; $i<@ARGV; $i++) {
    $option_found = "false";
    if($ARGV[$i] eq '-nu') {
        $U = "false";
	$option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
	$numargs++;
        $option_found = "true";
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$stats_dir = $study_dir . "STATS";
unless (-d $stats_dir){
    `mkdir $stats_dir`;}
$outfileU = "$stats_dir/percent_high_expressor_Unique.txt";
$outfileNU = "$stats_dir/percent_high_expressor_NU.txt";

open(INFILE, "<$ARGV[0]");
@dirs = <INFILE>;
close(INFILE);
foreach $dir (@dirs){
    chomp($dir);
    $id = $dir;
    $id =~ s/Sample_//;
    $file = "$LOC/$dir/$id.high_expressors_annot.txt";
    open(IN, "<$file");
    @exons = <IN>;
    close(IN);
    foreach $exon (@exons){
	chomp($exon);
	if ($exon =~ /^exon/){
	    next;
	}
	@e = split(" ", $exon);
	$name = $e[0];
	$symbol_list = $e[4];
	@s = split(',' , $symbol_list);
	@symbol = ();
	for ($i=0;$i<@s;$i++){
	    push(@symbol,$s[$i]);
	}
	my %hash = map {$_ => 1} @symbol;
	@list = keys %hash;
	$symlist = join(',',@list);
	$HIGH_EXON{$name} =  $symlist;
    }
}

$firstrow = "exon";
$lastrow = "gene";
while (($key, $value) = each (%HIGH_EXON)){
    $firstrow = $firstrow . "\t$key";
    $lastrow = $lastrow . "\t$value";
}

if ($option_found eq "false"){
    if(-e $outfileU){
	`rm $outfileU`;
    }
    if(-e $outfileNU){
	`rm $outfileNU`;
    }
    open(OUTU, ">>$outfileU") or die "file '$outfileU' cannot open for writing.\n";
    print OUTU "$firstrow\n";
    open(OUTNU, ">>$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
    print OUTNU "$firstrow\n";
}
else{
    if ($U eq "true"){
	if(-e $outfileU){
	    `rm $outfileU`;
	}
	open(OUTU, ">>$outfileU") or die "file '$outfileU' cannot open for writing.\n";
	print OUTU "$firstrow\n";	
    }
    if ($NU eq "true"){
	if(-e $outfileNU){
	    `rm $outfileNU`;
	}
	open(OUTNU, ">>$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
        print OUTNU "$firstrow\n";
    }
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
while($line = <INFILE>){
    chomp($line);
    $dir = $line;
    $id = $line;
    $id =~ s/Sample_//;
    $rowU = "$id\t";
    $rowNU = "$id\t";
    foreach $exon (keys %HIGH_EXON){
	chomp($exon);
	$exon =~ s/exon://;
	$exonpercent = "$LOC/$dir/$id.exonpercents.txt";
	$value = `grep -w $exon $exonpercent`;
	@v = split(" ", $value);
	$valU = $v[1];
	$valNU = $v[2];
	$rowU = $rowU . "$valU\t";
	$rowNU = $rowNU . "$valNU\t";
    }
    if ($option_found eq "false"){
	print OUTU "$rowU\n";
	print OUTNU "$rowNU\n";
    }
    else{
	if($U eq "true") {
	    print OUTU "$rowU\n";
	}
	if ($NU eq "true"){
	    print OUTNU "$rowNU\n";
	}
    }
}
print OUTU "$lastrow\n";
print OUTNU "$lastrow\n";
close(INFILE);
close(OUTU);
close(OUTNU);

print "got here\n";
