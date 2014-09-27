#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<3) {
    die "usage: perl cat_gnorm_Unique_NU.pl <sample dirs> <loc> <samfilename>

where:
<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the path to the sample directories
<samfilename> 

";
}

my $LOC = $ARGV[1];
my $samfilename = $ARGV[2];
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $loc_study = $LOC;
$loc_study =~ s/$last_dir//;
my $gnorm_dir = $loc_study."NORMALIZED_DATA/GENE/FINAL_SAM/";
my $loc_merged = $gnorm_dir . "MERGED";
unless (-d $loc_merged){
    `mkdir $loc_merged`;
}
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while (my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $original = "$LOC/$id/$samfilename";
    my $header = `grep ^@ $original`;
    my $file_U = "$gnorm_dir/Unique/$id.GNORM.Unique.sam";
    my $file_NU = "$gnorm_dir/NU/$id.GNORM.NU.sam";
    my $outfile = "$loc_merged/$id.GNORM.sam";
    open (OUT, ">$outfile");
    print OUT $header;
    close(OUT);
    `cat $file_U $file_NU >> $outfile`;
}
close(INFILE);

print "got here\n";
