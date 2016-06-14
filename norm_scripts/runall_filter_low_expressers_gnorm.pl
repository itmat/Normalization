use warnings;
use strict;

#!/usr/bin/env perl
if(@ARGV < 4) {
    die  "usage: perl runall_filter_low_expresers.pl <file of quants files> <number_of_samples> <cutoff> <loc>

where
<file of quants files> is a file with the names of the quants file without path
<number_of_samples> is number of samples
<cutoff> cutoff value
<loc> normdir

";
}

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/runall_//;
$path =~ s/_gnorm//;
my $num_samples = $ARGV[1];
my $cutoff = $ARGV[2];
my $normdir = $ARGV[3];
$normdir =~ s/\/$//;
my $norm_dir = "$normdir/GENE/";
my $spread_dir = $norm_dir . "/SPREADSHEETS";

unless (-d $spread_dir){
    `mkdir $spread_dir`;
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while (my $line = <INFILE>){
    chomp($line);
    my $final_file = $line;
    `perl $path $spread_dir/$line $num_samples $cutoff > $spread_dir/FINAL_$final_file`;
}
close(INFILE);
print "got here\n";
