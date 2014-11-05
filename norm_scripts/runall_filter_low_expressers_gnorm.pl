#!/usr/bin/env perl
if(@ARGV < 4) {
    die  "usage: perl runall_filter_low_expresers.pl <file of quants files> <number_of_samples> <cutoff> <loc>

where
<file of quants files> is a file with the names of the quants file without path
<number_of_samples> is number of samples
<cutoff> cutoff value
<loc> is the path to the sample directories

";
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/runall_//;
$path =~ s/_gnorm//;
$num_samples = $ARGV[1];
$cutoff = $ARGV[2];
$LOC = $ARGV[3];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$norm_dir = $LOC;
$norm_dir =~ s/$last_dir//;
$norm_dir = $norm_dir . "NORMALIZED_DATA/GENE/";
$spread_dir = $norm_dir . "/SPREADSHEETS";

unless (-d $spread_dir){
    `mkdir $spread_dir`;
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while ($line = <INFILE>){
    chomp($line);
    $final_file = $line;
    `perl $path $spread_dir/$line $num_samples $cutoff > $spread_dir/FINAL_$final_file`;
}
close(INFILE);
print "got here\n";
