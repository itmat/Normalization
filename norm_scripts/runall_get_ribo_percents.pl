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

$shfile = "$LOC/get_ribo_percents.sh";
open(OUT, ">$shfile");
print OUT "perl $path $sampledirs $LOC\n";
`bsub -q max_mem30 -o getribo.out -e getribo.err sh $shfile`;
