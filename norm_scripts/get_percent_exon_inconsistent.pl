#!/usr/bin/env perl
use strict;
use warnings;

if(@ARGV<2) {
    die "Usage: perl get_percent_exon_inconsistent.pl <sample dirs> <loc> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

options:
 -stranded : set this if your data are strand-specific.

 -u  :  set this if you want to return only unique stats, otherwise by default
         it will return both unique and non-unique stats.

 -nu :  set this if you want to return only non-unique stats, otherwise by default
         it will return both unique and non-unique stats.

";
}
#Percent of exon_inconsistent reads (out of all reads)
my $U = "true";
my $NU = "true";
my $numargs = 0;
my $stranded = "false";
for(my $i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
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

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS/EXON_INTRON_JUNCTION";
unless (-d $stats_dir){
    `mkdir -p $stats_dir`;}
my $outfileU = "$stats_dir/percent_exon_inconsistent_Unique.txt";
my $outfileNU = "$stats_dir/percent_exon_inconsistent_NU.txt";


open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; 
if ($U eq "true"){
    open(OUTU, ">$outfileU") or die "file '$outfileU' cannot open for writing.\n";
    print OUTU "sample\t%exon_inconsistentU\t(%unique exon_inconsistent reads out of total unique mappers)\n";
}
if ($NU eq "true"){
    open(OUTNU, ">$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
    print OUTNU "sample\t%exon_inconsistentNU\t(%non-unique exon_inconsistent reads out of total non-unique mappers)\n";
}
while(my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $dirU = $dir . "/EIJ/Unique";
    my $dirNU = $dir . "/EIJ/NU";
    my $id = $line;
    my $fileU = "$LOC/$dirU/$id.filtered_u.exonquants";
    if ($stranded eq "true"){
	$fileU = "$LOC/$dirU/sense/$id.filtered_u.sense.exonquants";
    }
    my $undU = "$LOC/$dirU/$id.filtered_u_exon_inconsistent_reads.sam";
    my $fileNU = "$LOC/$dirNU/$id.filtered_nu.exonquants";
    if ($stranded eq "true"){
	$fileNU = "$LOC/$dirNU/sense/$id.filtered_nu.sense.exonquants";
    }
    my $undNU = "$LOC/$dirNU/$id.filtered_nu_exon_inconsistent_reads.sam";
    if ($U eq "true"){
	my ($xU, $tot_undU, $tot_nonexonU, $tot_exonU, $ratioU);
	$xU = `tail -1 $undU`;
	$xU =~ /(\d+)$/;
	$tot_undU = $1;
	$xU = `head -4 $fileU | tail -1`;
	$xU =~ /(\d+)$/;
	$tot_nonexonU = $1;
	$xU = `head -1 $fileU`;
	$xU =~ /(\d+)$/;
	$tot_exonU = $1;
	$ratioU = int($tot_undU / ($tot_exonU + $tot_nonexonU) * 10000) / 100;
	$ratioU = sprintf("%.2f", $ratioU);
	print OUTU "$dir\t$ratioU\n";
    }
    if ($NU eq "true"){
	my ($xNU, $tot_undNU, $tot_nonexonNU, $tot_exonNU, $ratioNU);
        $xNU = `tail -1 $undNU`;
        $xNU =~ /(\d+)$/;
        $tot_undNU = $1;
	$xNU = `head -4 $fileNU | tail -1`;
        $xNU =~ /(\d+)$/;
	$tot_nonexonNU = $1;
	$xNU = `head -1 $fileNU`;
	$xNU =~ /(\d+)$/;
        $tot_exonNU = $1;
        $ratioNU = int($tot_undNU / ($tot_exonNU + $tot_nonexonNU) * 10000) / 100;
	$ratioNU = sprintf("%.2f", $ratioNU);
	print OUTNU "$dir\t$ratioNU\n";
    }
}
close(INFILE);
close(OUTU);
close(OUTNU);
print "got here\n";
