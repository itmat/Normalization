#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<2) {
    die "Usage: perl get_percent_genemappers.pl <sample dirs> <loc> [option]

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
my $U = "true";
my $NU = "true";
my $numargs = 0;
my $option_found = "false";
for(my $i=2; $i<@ARGV; $i++) {
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

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS/GENE/";
unless (-d $stats_dir){
    `mkdir -p $stats_dir`;}
my $outfileU = "$stats_dir/percent_genemappers_Unique.txt";
my $outfileNU = "$stats_dir/percent_genemappers_NU.txt";


open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
if ($U eq "true"){
    open(OUTU, ">$outfileU") or die "file '$outfileU' cannot open for writing.\n";
}
if ($NU eq "true"){
    open(OUTNU, ">$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
}
while(my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $dirU = $dir . "/GNORM/Unique";
    my $dirNU = $dir . "/GNORM/NU";
    my $id = $line;
    my $fileU = "$LOC/$dirU/$id.filtered_u.sam";
    my $fileU2 = "$LOC/$dirU/$id.filtered_u_genes.linecount.txt";
    my $fileNU = "$LOC/$dirNU/$id.filtered_nu.sam";
    my $fileNU2 = "$LOC/$dirNU/$id.filtered_nu_genes.linecount.txt";
    if($U eq "true") {
	my $xU = `wc -l $fileU`;
	chomp($xU);
	my @x = split(" ", $xU);
	my $totalU = $x[0];
	my $xU2 = `cat $fileU2`;
	@x = split(" ", $xU2);
	my $filteredU = $x[1];
	my $ratioU = int($filteredU / $totalU * 10000) / 100;
	print OUTU "$dir\t$ratioU\n";
    }
    if ($NU eq "true"){
	my $xNU = `wc -l $fileNU`;
	chomp($xNU);
	my @x = split(" ", $xNU);
	my $totalNU = $x[0];
	my $xNU2 = `cat $fileNU2`;
	@x = split(" ", $xNU2);
	my $filteredNU = $x[1];
	my $ratioNU = int($filteredNU / $totalNU * 10000) / 100;
	print OUTNU "$dir\t$ratioNU\n";
    }
}
close(INFILE);
if ($U eq "true"){
    close(OUTU);
}
if ($NU eq "true"){
    close(OUTNU);
}
print "got here\n";
