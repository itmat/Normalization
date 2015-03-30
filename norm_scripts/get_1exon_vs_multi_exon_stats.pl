#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<2) {
    die "Usage: perl get_1exon_vs_multi_exon_stats.pl <sample dirs> <loc> [option]

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
#percent 1exonmapper/all exonmappers
my $U = "true";
my $NU = "true";
my $numargs = 0;
my $stranded = "false";
for(my $i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
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
my $stats_dir = $study_dir . "STATS/EXON_INTRON_JUNCTION/";
unless (-d $stats_dir){
    `mkdir -p $stats_dir`;}
my $outfileU = "$stats_dir/1exon_vs_multi_exon_stats_Unique.txt";
my $outfileNU = "$stats_dir/1exon_vs_multi_exon_stats_NU.txt";
my ($outfileU_A, $outfileNU_A);
if ($stranded eq "true"){
    $outfileU = "$stats_dir/1exon_vs_multi_exon_stats_Unique_sense.txt";
    $outfileU_A = "$stats_dir/1exon_vs_multi_exon_stats_Unique_antisense.txt";
    $outfileNU = "$stats_dir/1exon_vs_multi_exon_stats_NU_sense.txt";
    $outfileNU_A = "$stats_dir/1exon_vs_multi_exon_stats_NU_antisense.txt";
}


open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
if ($U eq "true"){
    open(OUTU, ">$outfileU") or die "file '$outfileU' cannot open for writing.\n";
    if ($stranded eq "false"){
	print OUTU "sample\t%1exonmappersU\t(# of unique 1 exonmapppers / # total unique exonmappers)\n";
    }
    else{
	print OUTU "sample\t%1exonmappersU-sense\t(# of unique 1 exonmapppers-sense / # total unique exonmappers-sense)\n";
    }
    if ($stranded eq "true"){
	open(OUTU_A, ">$outfileU_A") or die "file '$outfileU_A' cannot open for writing.\n";;
	print OUTU_A "sample\t%1exonmappersU-antisense\t(# of unique 1 exonmapppers-antisense / # total unique exonmappers-antisense)\n";
    }
}
if ($NU eq "true"){
    open(OUTNU, ">$outfileNU") or die "file '$outfileNU' cannot open for writing.\n";
    if ($stranded eq "false"){
	print OUTNU "sample\t%1exonmappersNU\t(# of non-unique 1 exonmapppers / # total non-unique exonmappers)\n";
    }
    else{
	print OUTNU "sample\t%1exonmappersNU-sense\t(# of non-unique 1 exonmapppers-sense / # total non-unique exonmappers-sense)\n";
    }
    if ($stranded eq "true"){
	open(OUTNU_A, ">$outfileNU_A") or die "file '$outfileNU_A' cannot open for writing.\n";
	print OUTNU_A "sample\t%1exonmappersNU-antisense\t(# of non-unique 1 exonmapppers-antisense / # total non-unique exonmappers-antisense)\n";
    }
}

while(my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $dirU = $dir . "/EIJ/Unique";
    my $dirNU = $dir . "/EIJ/NU";
    my $id = $line;
    my $fileU = "$LOC/$dirU/$id.filtered_u.exonquants";
    my $fileNU = "$LOC/$dirNU/$id.filtered_nu.exonquants";
    my ($fileU_A, $fileNU_A);
    if ($stranded eq "true"){
	$fileU = "$LOC/$dirU/sense/$id.filtered_u.sense.exonquants";
	$fileU_A = "$LOC/$dirU/antisense/$id.filtered_u.antisense.exonquants";
	$fileNU = "$LOC/$dirNU/sense/$id.filtered_nu.sense.exonquants";
	$fileNU_A = "$LOC/$dirNU/antisense/$id.filtered_nu.antisense.exonquants";
    }
    if ($U eq "true"){
	my ($xU, $tot_exonU, $one_exonU,$ratioU);
	$xU = `head -1 $fileU`;
	$xU =~ /(\d+)$/;
	$tot_exonU = $1;
	$xU = `head -5 $fileU | tail -1`;
	$xU =~ /(\d+)$/;
	$one_exonU = $1;
	$ratioU = int($one_exonU / ($tot_exonU) * 10000) / 100;
	$ratioU = sprintf("%.2f", $ratioU);
	print OUTU "$dir\t$ratioU\n";
	if ($stranded eq "true"){
	    $xU = `head -1 $fileU_A`;
	    $xU =~ /(\d+)$/;
	    $tot_exonU = $1;
	    $xU = `head -5 $fileU_A | tail -1`;
	    $xU =~ /(\d+)$/;
	    $one_exonU = $1;
	    $ratioU = int($one_exonU / ($tot_exonU) * 10000) / 100;
	    $ratioU = sprintf("%.2f", $ratioU);
	    print OUTU_A "$dir\t$ratioU\n";
	}
    }
    if ($NU eq "true"){
	my ($xNU, $tot_exonNU, $one_exonNU,$ratioNU);
	$xNU = `head -1 $fileNU`;
	$xNU =~ /(\d+)$/;
	$tot_exonNU = $1;
	$xNU = `head -5 $fileNU | tail -1`;
	$xNU =~ /(\d+)$/;
	$one_exonNU = $1;
	$ratioNU = int($one_exonNU/ ($tot_exonNU) * 10000) / 100;
	$ratioNU = sprintf("%.2f", $ratioNU);
	print OUTNU "$dir\t$ratioNU\n";
	if ($stranded eq "true"){
	    $xNU = `head -1 $fileNU_A`;
	    $xNU =~ /(\d+)$/;
	    $tot_exonNU = $1;
	    $xNU = `head -5 $fileNU_A | tail -1`;
	    $xNU =~ /(\d+)$/;
	    $one_exonNU = $1;
	    $ratioNU = int($one_exonNU/ ($tot_exonNU) * 10000) / 100;
	    $ratioNU = sprintf("%.2f", $ratioNU);
	    print OUTNU_A "$dir\t$ratioNU\n";
	}
    }
}
close(INFILE);
close(OUTU);
close(OUTU_A);
if ($stranded eq "true"){
    close(OUTNU);
    close(OUTNU_A);
}

print "got here\n";
