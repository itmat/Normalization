#!/usr/bin/env perl
use strict;
use warnings;

if(@ARGV<2) {
    die "Usage: perl get_percent_intergenic.pl <sample dirs> <loc> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

options:
 -stranded : set this if your data are strand-specific.

 -u  :  set this if you want to return only unique stats, otherwise by default
         it will return both unique and non-unique stats.

 -nu :  set this if you want to return only non-unique stats, otherwise by default
         it will return both unique and non-unique stats.
 -alt_stats <s>


";
}
#Percent of intergenic mappers (out of all reads)
my $U = "true";
my $NU = "true";
my $numargs = 0;
my $stranded = "false";
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS/EXON_INTRON_JUNCTION";
my $lc_dir = $study_dir . "STATS/lineCounts";
for(my $i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-alt_stats'){
	$option_found = "true";
	$stats_dir = "$ARGV[$i+1]/EXON_INTRON_JUNCTION";
	$lc_dir = "$ARGV[$i+1]/lineCounts";
	$i++;
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
    if($ARGV[$i] eq '-stranded') {
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
unless (-d $lc_dir){
    `mkdir -p $lc_dir`;}
my $outfileU = "$stats_dir/percent_intergenic_Unique.txt";
my $outfileNU = "$stats_dir/percent_intergenic_NU.txt";
my $ig_lc_U = "$lc_dir/intergenic.unique.lc.txt";
my $ig_lc_NU = "$lc_dir/intergenic.nu.lc.txt";

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
if ($U eq "true"){
    open(OUTU, ">$outfileU") or die "file '$outfileU' cannot open for writing.\n";
    print OUTU "sample\t%intergenicU\t(%unique intergenic mappers out of total unique mappers)\n";
}
if ($NU eq "true"){
    open(OUTNU, ">$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
    print OUTNU "sample\t%intergenicNU\t(%non-unique intergenic mappers out of total non-unique mappers)\n";
}
while(my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $dirU = $dir . "/EIJ/Unique";
    my $dirNU = $dir . "/EIJ/NU";
    $dir = "/" . $dir . "/";
    my $id = $line;
    my $fileU = "$LOC/$dirU/$id.filtered_u.exonquants";
    if ($stranded eq "true"){
	$fileU = "$LOC/$dirU/sense/$id.filtered_u.sense.exonquants";
    }
    my $fileNU = "$LOC/$dirNU/$id.filtered_nu.exonquants";
    if ($stranded eq "true"){
	$fileNU = "$LOC/$dirNU/sense/$id.filtered_nu.sense.exonquants";
    }
    if ($U eq "true"){
	my ($xU, $tot_interU, $tot_nonexonU, $tot_exonU, $ratioU);
	$xU = `grep -F $dir $ig_lc_U`;
	$xU =~ /(\d+)$/;
	$tot_interU = $1;
	$xU = `head -4 $fileU | tail -1`;
	$xU =~ /(\d+)$/;
	$tot_nonexonU = $1;
	$xU = `head -1 $fileU`;
	$xU =~ /(\d+)$/;
	$tot_exonU = $1;
#	print "$dir\ntotexonU:$tot_exonU\ttotnonexonU:$tot_nonexonU\ntotinterg:$tot_interU\n";
	$ratioU = int($tot_interU / ($tot_exonU + $tot_nonexonU) * 10000) / 100;
	$ratioU = sprintf("%.2f", $ratioU);
	print OUTU "$id\t$ratioU\n";
    }
    if ($NU eq "true"){
	my ($xNU, $tot_interNU, $tot_nonexonNU, $tot_exonNU, $ratioNU);
        $xNU = `grep -F $dir $ig_lc_NU`;
        $xNU =~ /(\d+)$/;
        $tot_interNU = $1;
	$xNU = `head -4 $fileNU | tail -1`;
        $xNU =~ /(\d+)$/;
	$tot_nonexonNU = $1;
	$xNU = `head -1 $fileNU`;
	$xNU =~ /(\d+)$/;
        $tot_exonNU = $1;
        $ratioNU = int($tot_interNU / ($tot_exonNU + $tot_nonexonNU) * 10000) / 100;
	$ratioNU = sprintf("%.2f", $ratioNU);
	print OUTNU "$id\t$ratioNU\n";
    }
}
close(INFILE);
close(OUTU);
close(OUTNU);
print "got here\n";
