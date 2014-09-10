#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<2) {
    die "usage: perl cat_gnorm_Unique_NU.pl <sample dirs> <loc>

where:
<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the path to the sample directories

";
}

my $LOC = $ARGV[1];
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $loc_study = $LOC;
$loc_study =~ s/$last_dir//;
my $gnorm_dir = $loc_study."NORMALIZED_DATA/GENE_NORM/";
my $loc_merged = $gnorm_dir . "MERGED";
unless (-d $loc_merged){
    `mkdir $loc_merged`;
}
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while (my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $file_U = "$gnorm_dir/Unique/$id.GNORM.Unique.sam";
    my $file_NU = "$gnorm_dir/NU/$id.GNORM.NU.sam";
    `cat $file_U $file_NU > $loc_merged/$id.GNORM.sam`;
}
close(INFILE);

print "got here\n";
