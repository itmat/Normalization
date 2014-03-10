if(@ARGV < 4) {
    die "Usage: perl runall_sam2mappingstats.pl <sample dir> <loc> <sam file name> <total_num_reads?>

<sample dir> is a file with the names of the sample directories. 

             No options will be used if you give a file with 
             just the names of the sample directories.

             If you provide a file with 'sample dir \t total_num_reads',
             -numreads option will be used with the number provided.

<loc> is the directory with the sample directories
<sam file name> is the name of the sam file
<total_num_reads>  if you have the total_num_reads.txt file,
                   use \"true\". If not, use \"false\".

SAM file must use the IH or NH tags to indicate multi-mappers

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
$sam_name = $ARGV[2];
$total_reads_file = $ARGV[3];
if ($total_reads_file eq "true"){
    $dirs_reads = "$LOC/total_num_reads.txt";
    open(INFILE, $dirs_reads) or die "cannot find file '$dirs_reads'\n";
    while($line = <INFILE>){
	chomp($line);
	@fields = split(" ", $line);
	$size = @fields;
	$dir = $fields[0];
	$num_id = $fields[1];
	$id = $dir;
	$id =~ s/Sample_//;
	$shfile = "$shdir/m." . $id . "runsam2mappingstats.sh";
	open(OUTFILE, ">$shfile");
	print OUTFILE "perl $path $LOC/$dir/$sam_name -numreads $num_id > $LOC/$dir/$id.mappingstats.txt\n";
	}
	close(OUTFILE);
	`bsub -q max_mem30 -o $logdir/$id.sam2mappingstats.out -e $logdir/$id.sam2mappingstats.err sh $shfile`;
    }
    close(INFILE);
}

if ($total_reads_file eq "false"){
    open(INFILE, $sampledirs);
    while($line = <INFILE>){
	chomp($line);
	$dir = $line;
	$id = $dir;
	$id =~ s/Sample_//;
	$id =~ s/\//_/g;
	$shfile = "$shdir/m." . $id . "runsam2mappingstats.sh";
	open(OUTFILE, ">$shfile");
	print OUTFILE "perl $path $LOC/$dir/$sam_name > $LOC/$dir/$id.mappingstats.txt\n";
	close(OUTFILE);
	`bsub -q max_mem30 -o $logdir/$id.sam2mappingstats.out -e $logdir/$id.sam2mappingstats.err sh $shfile`;
    }
    close(INFILE);
}
