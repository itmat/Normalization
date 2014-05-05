#!/usr/bin/env perl
if(@ARGV<2) {
    die "Usage: perl get_exon2nonexon_signal_stats.pl <sample dirs> <loc> [option]

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
	$numargs++;
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
$outfileU = "$stats_dir/exon2nonexon_signal_stats_Unique.txt";
$outfileNU = "$stats_dir/exon2nonexon_signal_stats_NU.txt";


open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
if ($option_found eq "false"){
    open(OUTU, ">$outfileU") or die "file '$outfileU' cannot open for writing.\n";
    open(OUTNU, ">$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
}
else{
    if ($U eq "true"){
	open(OUTU, ">$outfileU") or die "file '$outfileU' cannot open for writing.\n";
    }
    if ($NU eq "true"){
	open(OUTNU, ">$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
    }
}
while($line = <INFILE>){
    chomp($line);
    $dir = $line;
    $dirU = $dir . "/Unique";
    $dirNU = $dir . "/NU";
    $id = $line;
    $id =~ s/Sample_//;
    $fileU = "$LOC/$dirU/$id.filtered_u_exonquants";
    $fileNU = "$LOC/$dirNU/$id.filtered_nu_exonquants";
    if ($option_found eq "false"){
	$xU = `head -1 $fileU`;
	$xU =~ /(\d+)$/;
	$tot_exonU = $1;
	$xU = `head -4 $fileU | tail -1`;
	$xU =~ /(\d+)$/;
	$tot_nonexonU = $1;
	$ratioU = int($tot_exonU / ($tot_exonU + $tot_nonexonU) * 10000) / 100;
	print OUTU "$dir\t$ratioU\n";

	$xNU = `head -1 $fileNU`;
	$xNU =~ /(\d+)$/;
	$tot_exonNU = $1;
	$xNU = `head -4 $fileNU | tail -1`;
	$xNU =~ /(\d+)$/;
	$tot_nonexonNU = $1;
	$ratioNU = int($tot_exonNU / ($tot_exonNU + $tot_nonexonNU) * 10000) / 100;
	print OUTNU "$dir\t$ratioNU\n";
    }
    else{
	if($U eq "true") {
	    $xU = `head -1 $fileU`;
	    $xU =~ /(\d+)$/;
	    $tot_exonU = $1;
	    $xU = `head -4 $fileU | tail -1`;
	    $xU =~ /(\d+)$/;
	    $tot_nonexonU = $1;
	    $ratioU = int($tot_exonU / ($tot_exonU + $tot_nonexonU) * 10000) / 100;
	    print OUTU "$dir\t$ratioU\n";
	}
	if ($NU eq "true"){
	    $xNU = `head -1 $fileNU`;
	    $xNU =~ /(\d+)$/;
	    $tot_exonNU = $1;
	    $xNU = `head -4 $fileNU | tail -1`;
	    $xNU =~ /(\d+)$/;
	    $tot_nonexonNU = $1;
	    $ratioNU = int($tot_exonNU / ($tot_exonNU + $tot_nonexonNU) * 10000) / 100;
	    print OUTNU "$dir\t$ratioNU\n";
	}
    }
}
close(INFILE);
close(OUTU);
close(OUTNU);
print "got here\n";
