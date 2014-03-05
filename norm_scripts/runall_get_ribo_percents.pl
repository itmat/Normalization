if(@ARGV<2) {
    die "Usage: perl runall_get_ribo_percents.pl <sample dirs> <loc>

<sample dirs> is a file with the names of the sample directories
<loc> is the location where the sample directories are

";
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/runall_//;
$sampledirs = $ARGV[0];
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$size = @fields;
$last_dir = $fields[@size-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

$shfile = "$shdir/get_ribo_percents.sh";
open(OUT, ">$shfile");
print OUT "perl $path $sampledirs $LOC\n";
`bsub -q max_mem30 -o $logdir/getribopercents.out -e $logdir/getribopercents.err sh $shfile`;
