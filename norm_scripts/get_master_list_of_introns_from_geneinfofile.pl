#!/usr/bin/perl

# Written by Gregory R. Grant
# Universiry of Pennsylvania, 2010

if(@ARGV < 2) {
    die "
Usage: get_master_list_of_exons_from_geneinfofile.pl <gene info file> <loc>

This script takes a UCSC gene annotation file and outputs a file of all unique
exons.  The annotation file has to be downloaded with the following fields:
1) chrom
2) strand
3) txStart
4) txEnd
5) exonCount
6) exonStarts
7) exonEnds
8) name

<loc> full path of the directory with the sample directories

This script is part of the pipeline of scripts used to create RUM indexes.
For more information see the library file: 'how2setup_genome-indexes_forPipeline.txt'.

";
}

open(INFILE, $ARGV[0]) or die "file '$ARGV[0]' cannot open for reading.\n";
while($line = <INFILE>) {
    chomp($line);
    @a = split(/\t/,$line);
    $a[5]=~ s/\s*,\s*$//;
    $a[5]=~ s/^\s*,\s*//;
    $a[6]=~ s/\s*,\s*$//;
    $a[6]=~ s/^\s*,\s*//;
    @S = split(/,/,$a[5]);
    @E = split(/,/,$a[6]);
    $N = @S;
    for($e=0; $e<@S-1; $e++) {
	$E[$e]++;
	$intron = "$a[0]:$E[$e]-$S[$e+1]";
	$INTRONS{$intron}++;
    }
}
close(INFILE);

$LOC = $ARGV[1];
open(OUTFILE, ">$LOC/master_list_of_introns.txt");
foreach $intron (keys %INTRONS) {
    print OUTFILE "$intron\n";
}
close(OUTFILE);
print "got here\n";
