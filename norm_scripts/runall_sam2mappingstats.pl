if(@ARGV < 4) {
    die "Usage: perl runall_sam2mappingstats.pl <sample dir> <loc> <sam file name> <total_num_reads?> [options]

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

option:  -bsub : set this if you want to submit batch jobs to LSF.

         -qsub : set this if you want to submit batch jobs to Sun Grid Engine.

";
}
$bsub = "false";
$qsub = "false";
$numargs = 0;
for ($i=4; $i<@ARGV; $i++){
    $option_found = "false";
    if ($ARGV[$i] eq '-bsub'){
	$bsub = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-qsub'){
	$qsub = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose either -bsub or -qsub.\n
";
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/runall_//;
$sampledirs = $ARGV[0];
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
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
    	close(OUTFILE);
	if ($bsub eq "true"){
	    `bsub -q max_mem30 -o $logdir/$id.sam2mappingstats.out -e $logdir/$id.sam2mappingstats.err sh $shfile`;
	}
	if ($qsub eq "true"){
	    `qsub -cwd -N $dir.sam2mappingstats -o $logdir -e $logdir -l h_vmem=15G $shfile`;
	}
    }
}
close(INFILE);


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
	if ($bsub eq "true"){
	    `bsub -q max_mem30 -o $logdir/$id.sam2mappingstats.out -e $logdir/$id.sam2mappingstats.err sh $shfile`;
	}
	if ($qsub eq "true"){
	    `qsub -cwd -N $dir.sam2mappingstats -o $logdir -e $logdir -l h_vmem=15G $shfile`;
	}
    }
}
close(INFILE);

