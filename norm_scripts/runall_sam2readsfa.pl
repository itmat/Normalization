if(@ARGV < 3) {
    die "Usage: perl runall_sam2readsfa.pl <sample dirs> <loc> <sam file name>

<sample dirs> a file with the names of the sample directories with sam file (without paths)

<loc> is the path of the directory with the sample directories

<sam file name> is the name of the sam file

";}
use Cwd 'abs_path';
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
    $shfile = "$shdir/a" . $id . "runsam2fa.sh";
    open(OUTFILE, ">$shfile");
    print OUTFILE "perl $path $LOC/$dir/$sam $LOC/$dir/reads.fa\n";
    close(OUTFILE);
    `bsub -e $logdir/sam2readsfa.err -o $logdir/sam2readsfa.out sh $shfile`;
}
close(INFILE);
