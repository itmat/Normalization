#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<2) {
    die "Usage: perl get_percent_genemappers.pl <sample dirs> <loc> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

options:
 -stranded : set this if the data are strand-specific.

 -u  :  set this if you want to return only unique stats, otherwise by default
         it will return both unique and non-unique stats.

 -nu :  set this if you want to return only non-unique stats, otherwise by default
         it will return both unique and non-unique stats.

 -alt_stats <s>

";
}
my $stranded = "false";
my $U = "true";
my $NU = "true";
my $numargs = 0;
my $option_found = "false";
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS/GENE/";

for(my $i=2; $i<@ARGV; $i++) {
    $option_found = "false";
    if($ARGV[$i] eq '-alt_stats') {
        $stats_dir = "$ARGV[$i+1]/GENE/";
        $i++;
        $option_found = "true";
    }
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
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
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

unless (-d $stats_dir){
    `mkdir -p $stats_dir`;}
my $outfileU = "$stats_dir/percent_genemappers_Unique.txt";
my $outfileNU = "$stats_dir/percent_genemappers_NU.txt";
my ($outfileU_A, $outfileNU_A);
if ($stranded eq "true"){
    $outfileU = "$stats_dir/percent_genemappers_Unique_sense.txt";
    $outfileNU = "$stats_dir/percent_genemappers_NU_sense.txt";
    $outfileU_A = "$stats_dir/percent_genemappers_Unique_antisense.txt";
    $outfileNU_A = "$stats_dir/percent_genemappers_NU_antisense.txt";
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
if ($U eq "true"){
    open(OUTU, ">$outfileU") or die "file '$outfileU' cannot open for writing.\n";
    if ($stranded eq "false"){
	print OUTU "sample\t%geneU\t(%unique genemappers out of total unique mappers)\n";
    }
    else{
	print OUTU "sample\t%geneU-sense\t(%unique genemappers-sense out of total unique mappers)\n";
    }
    if ($stranded eq "true"){
	open(OUTU_A, ">$outfileU_A") or die "file '$outfileU_A' cannot open for writing.\n";
	print OUTU_A "sample\t%geneU-antisense\t(%unique genemappers-antisense out of total unique mappers)\n";
    }
}
if ($NU eq "true"){
    open(OUTNU, ">$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
    if ($stranded eq "false"){
        print OUTNU "sample\t%geneNU\t(%non-unique genemappers out of total non-unique mappers)\n";
    }
    else{
	print OUTNU "sample\t%geneNU-sense\t(%non-unique genemappers-sense out of total non-unique mappers)\n";
    }
    if ($stranded eq "true"){
	open(OUTNU_A, ">$outfileNU_A") or die "file '$outfileNU_A' cannot open for writing.\n";
	print OUTNU_A "sample\t%geneNU-antisense\t(%non-unique genemappers-antisense out of total non-unique mappers)\n";
    }
}
while(my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $dirU = $dir . "/GNORM/Unique";
    my $dirNU = $dir . "/GNORM/NU";
    my $id = $line;
    my $fileU = "$LOC/$dirU/$id.filtered_u.sam.gz";
    my $fileU2 = "$LOC/$dirU/$id.filtered_u.genes.linecount.txt";
    my $fileNU = "$LOC/$dirNU/$id.filtered_nu.sam.gz";
    my $fileNU2 = "$LOC/$dirNU/$id.filtered_nu.genes.linecount.txt";
    my ($fileU2_A, $fileNU2_A);
    if ($stranded eq "true"){
	$fileU2 = "$LOC/$dirU/$id.filtered_u.genes.sense.linecount.txt";
	$fileNU2 = "$LOC/$dirNU/$id.filtered_nu.genes.sense.linecount.txt";
	$fileU2_A = "$LOC/$dirU/$id.filtered_u.genes.antisense.linecount.txt";
	$fileNU2_A = "$LOC/$dirNU/$id.filtered_nu.genes.antisense.linecount.txt";
    }
    if($U eq "true") {
	my $xU = `zcat $fileU|wc -l`;
	chomp($xU);
	my @x = split(" ", $xU);
	my $totalU = $x[0];
	my $xU2 = `cat $fileU2`;
	@x = split(" ", $xU2);
	my $filteredU = $x[1];
	my $ratioU = int($filteredU / $totalU * 10000) / 100;
	$ratioU = sprintf("%.2f", $ratioU);
	print OUTU "$dir\t$ratioU\n";
	if ($stranded eq "true"){
	    my $xU2 = `cat $fileU2_A`;
	    @x = split(" ", $xU2);
	    my $filteredU_A = $x[1];
	    my $ratioU_A = int($filteredU_A / $totalU * 10000) / 100;
	    $ratioU_A = sprintf("%.2f", $ratioU_A);
	    print OUTU_A "$dir\t$ratioU_A\n";
	}
    }
    if ($NU eq "true"){
	my $xNU = `zcat $fileNU | wc -l`;
	chomp($xNU);
	my @x = split(" ", $xNU);
	my $totalNU = $x[0];
	my $xNU2 = `cat $fileNU2`;
	@x = split(" ", $xNU2);
	my $filteredNU = $x[1];
	my $ratioNU = int($filteredNU / $totalNU * 10000) / 100;
	$ratioNU = sprintf("%.2f", $ratioNU);
	print OUTNU "$dir\t$ratioNU\n";
	if ($stranded eq "true"){
            my $xNU2 = `cat $fileNU2_A`;
            @x = split(" ", $xNU2);
            my $filteredNU_A = $x[1];
            my $ratioNU_A = int($filteredNU_A / $totalNU * 10000) / 100;
	    $ratioNU_A = sprintf("%.2f", $ratioNU_A);
            print OUTNU_A "$dir\t$ratioNU_A\n";
	}
    }
}
close(INFILE);
if ($U eq "true"){
    close(OUTU);
    close(OUTU_A);
}
if ($NU eq "true"){
    close(OUTNU);
    close(OUTNU_A);
}
print "got here\n";
