if(@ARGV < 3) {
    die "Usage: perl runall_sam2readsfa.pl <sample dirs> <loc> <sam file name>

<sample dirs> a file with the names of the sample directories with sam file (without paths)

<loc> is the path of the directory with the sample directories

<sam file name> is the name of the sam file

";}
use Cwd 'abs_path';
$LOC = $ARGV[1];
$sam = $ARGV[2];
$path = abs_path($0);
$path =~ s/runall_//;
open(INFILE, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";
while($line = <INFILE>) {
    chomp($line);
    $dir = $line;
    $line =~ s/Sample_//;
    $line =~ s/\//_/g;
    $id = $line;
    $shfile = "$LOC/$dir/a" . $id . "runsam2fa.sh";
    open(OUTFILE, ">$shfile");
    print OUTFILE "perl $path $LOC/$dir/$sam $LOC/$dir/reads.fa\n";
    close(OUTFILE);
    `bsub -e $LOC/$dir/sam2readsfa.err -o $LOC/$dir/sam2readsfa.out sh $shfile`;
}
close(INFILE);
