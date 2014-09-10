#!/usr/bin/env perl
if(@ARGV<2) {
    die "usage: perl cat_exonmappers_Unique_NU.pl <sample dirs> <loc>

where:
<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the path to the sample directories

";
}

$LOC = $ARGV[1];
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$loc_study = $LOC;
$loc_study =~ s/$last_dir//;
$norm_dir = $loc_study."NORMALIZED_DATA";
$loc_exon = "$norm_dir/exonmappers";
$loc_merged = $loc_exon . "/MERGED";
unless (-d $loc_merged){
    `mkdir $loc_merged`;
}
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while ($line = <INFILE>){
    chomp($line);
    $id = $line;
    $file_U = "$loc_exon/Unique/$id.exonmappers.norm_u.sam";
    $file_NU = "$loc_exon/NU/$id.exonmappers.norm_nu.sam";
    `cat $file_U $file_NU > $loc_merged/$id.exonmappers.norm.sam`;
}
close(INFILE);

print "got here\n";
