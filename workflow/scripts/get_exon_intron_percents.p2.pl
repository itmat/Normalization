#!/usr/bin/env perl
use strict;
use warnings;

if(@ARGV<4) {
    die "Usage: perl get_exon_intron_percents.pl <sample directory> <cutoff> <outfile_exon> <outfile_intron> [options]

<sample directory> 
<cutoff> cutoff %
<outfile_exon> output exonpercents file with full path
<outfile_intron> output intronpercents file with full path

option:
  -stranded : set this if your data are strand-specific.

";
}

my $U = "true";
my $stranded = "false";
for(my $i=4; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}


my $sampledir = $ARGV[0];
my @a = split("/", $sampledir);
my $dirname = $a[@a-1];
my $id = $dirname;
#non-stranded
##exon
my $outfile = $ARGV[2];
my $highfile = $outfile;
if ($U eq "true"){
    $highfile =~ s/.exonpercents.txt/.high_expressers_exon.txt/;
}
my (%UNIQUE, %NU);
##intron
my $outfile_i = $ARGV[3];
my $highfile_i = $outfile_i;
if ($U eq "true"){
    $highfile_i =~ s/.intronpercents.txt/.high_expressers_intron.txt/;
}
my (%UNIQUE_I, %NU_I);

#stranded
##exon

my $outfile_sense = $outfile;
$outfile_sense =~ s/.txt$/_sense.txt/;
my $outfile_antisense = $outfile;
$outfile_antisense =~ s/.txt$/_antisense.txt/;
my ($highfile_sense,$highfile_antisense);
if ($U eq "true"){
    $highfile_sense = $highfile;
    $highfile_sense =~ s/.txt$/_sense.txt/;
    $highfile_antisense = $highfile;
    $highfile_antisense =~ s/.txt$/_antisense.txt/;
}
my (%UNIQUE_S, %NU_S, %UNIQUE_A, %NU_A);
##intron

my $outfile_sense_i = $outfile_i;
$outfile_sense_i =~ s/.txt$/_sense.txt/;
my $outfile_antisense_i = $outfile_i;
$outfile_antisense_i =~ s/.txt$/_antisense.txt/;
my ($highfile_sense_i, $highfile_antisense_i);
if ($U eq "true"){
    $highfile_sense_i = $highfile_i;
    $highfile_sense_i =~ s/.txt$/_sense.txt/;
    $highfile_antisense_i = $highfile_i;
    $highfile_antisense_i =~ s/.txt$/_antisense.txt/;
}
my (%UNIQUE_S_I, %NU_S_I, %UNIQUE_A_I, %NU_A_I);
my $cutoff = $ARGV[1];

if ($cutoff !~ /(\d+$)/){
    die "ERROR: <cutoff> needs to be a number\n";
}
else{
    if ((0 > $cutoff) || (100 < $cutoff)){
	die "ERROR: <cutoff> needs to be a number between 0-100\n";
    }
}

if($U eq "true"){
    if ($stranded eq "false"){
	#exon
	open(IN, "$outfile");
	open(OUT2, ">$highfile");
	my $header_e = <IN>;
	print OUT2 "exon\t%unique\n";
	while(my $line = <IN>){
	    chomp($line);
	    my @a = split(/\t/,$line);
	    my $exon = $a[0];
	    my $percent = $a[1];
	    if ($percent >= $cutoff){
		print OUT2 "$exon\t$percent\n";
	    }
	}
	close(IN);
	close(OUT2);
	#intron
        open(IN_I, "$outfile_i");
        open(OUT2_I, ">$highfile_i");
        my $header_i = <IN_I>;
        print OUT2_I "intron\t%unique\n";
	while(my $line = <IN_I>){
	    chomp($line);
            my @a = split(/\t/,$line);
            my $intron = $a[0];
            my $percent = $a[1];
            if ($percent >= $cutoff){
                print OUT2_I "$intron\t$percent\n";
            }
        }
        close(IN_I);
        close(OUT2_I);
    }
    if ($stranded eq "true"){
	#exon
	open(IN_S, "$outfile_sense");
	open(OUT2_S, ">$highfile_sense");
	my $header_s = <IN_S>;
        print OUT2_S "exon\t%unique\n";
	while(my $line = <IN_S>){
            chomp($line);
            my @a = split(/\t/,$line);
            my $exon = $a[0];
            my $percent = $a[1];
            if ($percent >= $cutoff){
		print OUT2_S "$exon\t$percent\n";
            }
	}
        close(IN_S);
        close(OUT2_S);
	#antisense
	open(IN_A, "$outfile_antisense");
	open(OUT2_A, ">$highfile_antisense");
	my $header_a = <IN_A>;
        print OUT2_A "exon\t%unique\n";
        while(my $line = <IN_A>){
            chomp($line);
            my @a = split(/\t/,$line);
            my $exon = $a[0];
            my $percent = $a[1];
            if ($percent >= $cutoff){
                print OUT2_A "$exon\t$percent\n";
            }
        }
        close(IN_A);
        close(OUT2_A);
	#intron
        open(IN_S_I, "$outfile_sense_i");
        open(OUT2_S_I, ">$highfile_sense_i");
	my $header_s_i = <IN_S_I>;
	print OUT2_S_I "intron\t%unique\n";
	while(my $line = <IN_S_I>){
            chomp($line);
            my @a = split(/\t/,$line);
            my $intron = $a[0];
            my $percent = $a[1];
            if ($percent >= $cutoff){
                print OUT2_S_I "$intron\t$percent\n";
            }
        }
        close(IN_S_I);
        close(OUT2_S_I);
	#antisense
        open(IN_A_I, "$outfile_antisense_i");
        open(OUT2_A_I, ">$highfile_antisense_i");
	my $header_a_i = <IN_A_I>;
        print OUT2_A_I "intron\t%unique\n";
	while(my $line = <IN_A_I>){
            chomp($line);
            my @a = split(/\t/,$line);
            my $intron = $a[0];
            my $percent = $a[1];
            if ($percent >= $cutoff){
                print OUT2_A_I "$intron\t$percent\n";
            }
        }
        close(IN_A_I);
        close(OUT2_A);
    }
}
#print "got here\n";

