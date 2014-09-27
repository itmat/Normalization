#!/usr/bin/env perl
if(@ARGV<2) {
    die "Usage: perl get_percent_intergenic.pl <sample dirs> <loc> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

options:
 -u  :  set this if you want to return only unique stats, otherwise by default
         it will return both unique and non-unique stats.

 -nu :  set this if you want to return only non-unique stats, otherwise by default
         it will return both unique and non-unique stats.

";
}
#Percent of non-exonic signal that is intergenic (as opposed to intronic)
$U = "true";
$NU = "true";
$numargs = 0;
$option_found = "false";
for($i=2; $i<@ARGV; $i++) {
    $option_found = "false";
    if($ARGV[$i] eq '-nu') {
        $U = "false";
	$numargs++;
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
$stats_dir = $study_dir . "STATS/EXON_INTRON_JUNCTION";
unless (-d $stats_dir){
    `mkdir -p $stats_dir`;}
$outfileU = "$stats_dir/percent_intergenic_Unique.txt";
$outfileNU = "$stats_dir/percent_intergenic_NU.txt";


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
    $dirU = $dir . "/EIJ/Unique";
    $dirNU = $dir . "/EIJ/NU";
    $id = $line;
    $fileU = "$LOC/$dirU/$id.filtered_u_exonquants";
    $interU = "$LOC/$dirU/$id.filtered_u_notexonmappers_intergenicmappers.sam";
    $fileNU = "$LOC/$dirNU/$id.filtered_nu_exonquants";
    $interNU = "$LOC/$dirNU/$id.filtered_nu_notexonmappers_intergenicmappers.sam";
    if ($option_found eq "false"){
	$xU = `wc -l $interU`;
	chomp($xU);
	@x = split(" ", $xU);
	$tot_interU = $x[0];
	$xU = `head -4 $fileU | tail -1`;
	$xU =~ /(\d+)$/;
	$tot_nonexonU = $1;
	$ratioU = int($tot_interU / $tot_nonexonU * 10000) / 100;
	print OUTU "$dir\t$ratioU\n";

	$xNU = `wc -l $interNU`;
	chomp($xNU);
	@x = split(" ", $xNU);
	$tot_interNU = $x[0];
	$xNU = `head -4 $fileNU | tail -1`;
	$xNU =~ /(\d+)$/;
	$tot_nonexonNU = $1;
	$ratioNU = int($tot_interNU / $tot_nonexonNU * 10000) / 100;
	print OUTNU "$dir\t$ratioNU\n";
    }
    else{
	if($U eq "true") {
	    $xU = `wc -l $interU`;
	    chomp($xU);
	    @x = split(" ", $xU);
	    $tot_interU = $x[0];
	    $xU = `head -4 $fileU | tail -1`;
	    $xU =~ /(\d+)$/;
	    $tot_nonexonU = $1;
	    $ratioU = int($tot_interU / $tot_nonexonU * 10000) / 100;
	    print OUTU "$dir\t$ratioU\n";
	}
	if ($NU eq "true"){
	    $xNU = `wc -l $interNU`;
	    chomp($xNU);
	    @x = split(" ", $xNU);
	    $tot_interNU = $x[0];
	    $xNU = `head -4 $fileNU | tail -1`;
	    $xNU =~ /(\d+)$/;
	    $tot_nonexonNU = $1;
	    $ratioNU = int($tot_interNU / $tot_nonexonNU * 10000) / 100;
	    print OUTNU "$dir\t$ratioNU\n";
	}
    }
}
close(INFILE);
close(OUTU);
close(OUTNU);
print "got here\n";
