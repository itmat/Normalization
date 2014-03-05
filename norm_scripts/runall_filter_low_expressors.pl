if(@ARGV < 4) {
    die  "usage: perl runall_filter_low_expressors.pl <file of quants files> <number_of_samples> <cutoff> <loc>

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
$num_samples = $ARGV[1];
$cutoff = $ARGV[2];
$LOC = $ARGV[3];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$size = @fields;
$last_dir = $fields[@size-1];
$norm_dir = $LOC;
$norm_dir =~ s/$last_dir//;
$norm_dir = $norm_dir . "NORMALIZED_DATA";

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while ($line = <INFILE>){
    chomp($line);
    `perl $path $norm_dir/$line $num_samples $cutoff > $norm_dir/FINAL_$line`;
}
close(INFILE);
