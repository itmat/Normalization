#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<2) {
    die "Usage: perl get_sense2antisense_stats.pl <sample dirs> <loc> [option]

<sample dirs> is the file with the names of the sample directories
<loc> is the location where the sample directories are

options:
 -gnorm : set this if you want the stats for gene normalization. 
          (by default, it will only output exon-intron-junction stats).

 -u  :  set this if you want to return only unique stats, otherwise by default
         it will return both unique and non-unique stats.

 -nu :  set this if you want to return only non-unique stats, otherwise by default
         it will return both unique and non-unique stats.

";

}
#percent sense /all (sense+antisense)
my $U = "true";
my $NU = "true";
my $numargs = 0;
my $gnorm = "false";
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

    if($ARGV[$i] eq '-gnorm') {
        $gnorm = "true";
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
if ($gnorm eq "false"){
    my $stats_dir = $study_dir . "STATS/EXON_INTRON_JUNCTION/";
    unless (-d $stats_dir){
	`mkdir -p $stats_dir`;}
    my $outfileU_EX = "$stats_dir/sense_vs_antisense_exonmappers_Unique.txt";
    my $outfileNU_EX = "$stats_dir/sense_vs_antisense_exonmappers_NU.txt";
    my $outfileU_INT = "$stats_dir/sense_vs_antisense_intronmappers_Unique.txt";
    my $outfileNU_INT = "$stats_dir/sense_vs_antisense_intronmappers_NU.txt";
    
    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    if ($U eq "true"){
	open(OUTU_EX, ">$outfileU_EX") or die "file '$outfileU_EX' cannot open for writing.\n";
	print OUTU_EX "sample\t%senseExon\t(#unique sense exonmappers / #unique sense exonmappers + antisense exonmappers)\n";
	open(OUTU_INT, ">$outfileU_INT") or die "file '$outfileU_INT' cannot open for writing.\n";
	print OUTU_INT "sample\t%senseIntron\t(#unique sense intronmappers / #unique sense intronmappers + antisense intronmappers)\n";
    }
    if ($NU eq "true"){
	open(OUTNU_EX, ">$outfileNU_EX") or die "file '$outfileNU_EX' cannot open for writing.\n";
	print OUTNU_EX "sample\t%senseExon\t(#non-unique sense exonmappers / #non-unique sense exonmappers + antisense exonmappers)\n";
	open(OUTNU_INT, ">$outfileNU_INT") or die "file '$outfileNU_INT' cannot open for writing.\n";
	print OUTNU_INT "sample\t%senseIntron\t(#non-unique sense intronmappers / #non-unique sense intronmappers + antisense intronmappers)\n";
    }
    
    while(my $line = <INFILE>){
	chomp($line);
	my $dir = $line;
	my $dirU = $dir . "/EIJ/Unique";
	my $dirNU = $dir . "/EIJ/NU";
	my $id = $line;
	my $fileU = "$LOC/$dirU/sense/$id.filtered_u.sense.exonquants";
	my $fileU_A = "$LOC/$dirU/antisense/$id.filtered_u.antisense.exonquants";
	my $fileNU = "$LOC/$dirNU/sense/$id.filtered_nu.sense.exonquants";
	my $fileNU_A = "$LOC/$dirNU/antisense/$id.filtered_nu.antisense.exonquants";
	my $fileU_I = "$LOC/$dirU/sense/$id.filtered_u.sense.intronquants";
	my $fileU_A_I = "$LOC/$dirU/antisense/$id.filtered_u.antisense.intronquants";
	my $fileNU_I = "$LOC/$dirNU/sense/$id.filtered_nu.sense.intronquants";
	my $fileNU_A_I = "$LOC/$dirNU/antisense/$id.filtered_nu.antisense.intronquants";
	if ($U eq "true"){
	    #sense exon to antisense exon
	    my ($xUE, $tot_exonU, $sense_exonU, $antisense_exonU, $ratioU_EX);
	    $xUE = `head -1 $fileU`;
	    $xUE =~ /(\d+)$/;
	    $sense_exonU = $1;
	    $xUE = `head -1 $fileU_A`;
	    $xUE =~ /(\d+)$/;
	    $antisense_exonU = $1;
	    $tot_exonU = $sense_exonU + $antisense_exonU;
	    $ratioU_EX = int($sense_exonU / ($tot_exonU) * 10000) / 100;
	    $ratioU_EX = sprintf("%.2f",  $ratioU_EX);
	    print OUTU_EX "$dir\t$ratioU_EX\n";
	    #sense intron to antisense intron
	    my ($xUI, $tot_intronU, $sense_intronU, $antisense_intronU, $ratioU_INT);
	    $xUI = `head -1 $fileU_I`;
	    $xUI =~ /(\d+)$/;
	    $sense_intronU = $1;
	    $xUI = `head -1 $fileU_A_I`;
	    $xUI =~ /(\d+)$/;
	    $antisense_intronU = $1;
	    $tot_intronU = $sense_intronU + $antisense_intronU;
	    $ratioU_INT = int($sense_intronU / ($tot_intronU) * 10000) / 100;
	    $ratioU_INT = sprintf("%.2f", $ratioU_INT);
	    print OUTU_INT "$dir\t$ratioU_INT\n";
	}
	if ($NU eq "true"){
	    #sense exon to antisense exon
	    my ($xNUE, $tot_exonNU, $sense_exonNU, $antisense_exonNU, $ratioNU_EX);
	    $xNUE = `head -1 $fileNU`;
	    $xNUE =~ /(\d+)$/;
	    $sense_exonNU = $1;
	    $xNUE = `head -1 $fileNU_A`;
	    $xNUE =~ /(\d+)$/;
	    $antisense_exonNU = $1;
	    $tot_exonNU = $sense_exonNU + $antisense_exonNU;
	    $ratioNU_EX = int($sense_exonNU / ($tot_exonNU) * 10000) / 100;
	    $ratioNU_EX = sprintf("%.2f", $ratioNU_EX);
	    print OUTNU_EX "$dir\t$ratioNU_EX\n";
	    #sense intron to antisense intron
	    my ($xNUI, $tot_intronNU, $sense_intronNU, $antisense_intronNU, $ratioNU_INT);
	    $xNUI = `head -1 $fileNU_I`;
	    $xNUI =~ /(\d+)$/;
	    $sense_intronNU = $1;
	    $xNUI = `head -1 $fileNU_A_I`;
	    $xNUI =~ /(\d+)$/;
	    $antisense_intronNU = $1;
	    $tot_intronNU = $sense_intronNU + $antisense_intronNU;
	    $ratioNU_INT = int($sense_intronNU / ($tot_intronNU) * 10000) / 100;
	    $ratioNU_INT = sprintf("%.2f", $ratioNU_INT);
	    print OUTNU_INT "$dir\t$ratioNU_INT\n";
	}
    }
    close(INFILE);
    close(OUTU_EX);
    close(OUTNU_EX);
    close(OUTU_INT);
    close(OUTNU_INT);
}
if ($gnorm eq "true"){
    my $stats_dir = $study_dir . "STATS/GENE/";
    unless (-d $stats_dir){
        `mkdir -p $stats_dir`;}
    my $outfileU_G = "$stats_dir/sense_vs_antisense_genemappers_Unique.txt";
    my $outfileNU_G = "$stats_dir/sense_vs_antisense_genemappers_NU.txt";

    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
    if ($U eq "true"){
        open(OUTU_G, ">$outfileU_G") or die "file '$outfileU_G' cannot open for writing.\n";
        print OUTU_G "sample\t%senseGene\t(#unique sense genemappers / #unique sense genemappers + antisense genemappers)\n";
    }
    if ($NU eq "true"){
        open(OUTNU_G, ">$outfileNU_G") or die "file '$outfileNU_G' cannot open for writing.\n";
        print OUTNU_G "sample\t%senseGene\t(#non-unique sense genemappers / #non-unique sense genemappers + antisense genemappers)\n";
    }
    while(my $line = <INFILE>){
        chomp($line);
	my $dir = $line;
        my $dirU = $dir . "/GNORM/Unique";
        my $dirNU = $dir . "/GNORM/NU";
	my $id = $line;
        my $fileU = "$LOC/$dirU/$id.filtered_u.genes.sense.linecount.txt";
        my $fileU_A = "$LOC/$dirU/$id.filtered_u.genes.antisense.linecount.txt";
        my $fileNU = "$LOC/$dirNU/$id.filtered_nu.genes.sense.linecount.txt";
	my $fileNU_A = "$LOC/$dirNU/$id.filtered_nu.genes.antisense.linecount.txt";
	if ($U eq "true"){
            #sense gene to antisense gene
            my ($xUE, $tot_geneU, $sense_geneU, $antisense_geneU, $ratioU_G);
            $xUE = `cat $fileU`;
            $xUE =~ /(\d+)$/;
            $sense_geneU = $1;
            $xUE = `cat $fileU_A`;
            $xUE =~ /(\d+)$/;
	    $antisense_geneU = $1;
	    $tot_geneU = $sense_geneU + $antisense_geneU;
            $ratioU_G = int($sense_geneU / ($tot_geneU) * 10000) / 100;
	    $ratioU_G = sprintf("%.2f",$ratioU_G);
            print OUTU_G "$dir\t$ratioU_G\n";
	}
	if ($NU eq "true"){
	    #sense gene to antisense gene
            my ($xUE, $tot_geneNU, $sense_geneNU, $antisense_geneNU, $ratioNU_G);
            $xUE = `cat $fileNU`;
            $xUE =~ /(\d+)$/;
            $sense_geneNU = $1;
            $xUE = `cat $fileNU_A`;
            $xUE =~ /(\d+)$/;
            $antisense_geneNU = $1;
            $tot_geneNU = $sense_geneNU + $antisense_geneNU;
            $ratioNU_G = int($sense_geneNU / ($tot_geneNU) * 10000) / 100;
	    $ratioNU_G = sprintf("%.2f", $ratioNU_G);
            print OUTNU_G "$dir\t$ratioNU_G\n";
        }
    }
    close(INFILE);
    close(OUTU_G);
    close(OUTNU_G);
}

print "got here\n";
