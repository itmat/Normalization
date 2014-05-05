#!/usr/bin/env perl

$USAGE =  "\nUsage: perl runall_sam2mappingstats.pl <sample dir> <loc> <sam file name> <total_num_reads?> [options]

where:
<sample dir> is a file with the names of the sample directories. 
<loc> is the directory with the sample directories
<sam file name> is the name of the sam file 
                (*SAM file must use the IH or NH tags to indicate multi-mappers)
<total_num_reads> if you have the total_num_reads.txt file,
                  use \"true\". If not, use \"false\".

**If you have > 150,000,000 reads, use -mem option to request 45G mem. 
**If you have > 200,000,000 reads, use -mem option to request 60G mem. 

option:  
 -lsf : set this if you want to submit batch jobs to LSF (PMACS cluster).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI cluster).

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_30G>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_30G> : is queue name for 30G (e.g. max_mem30, 30G)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 30G

 -h : print usage

";
if(@ARGV < 4) {
    die $USAGE;
}

$replace_mem = "false";
$numargs = 0;
$submit = "";
$jobname_option = "";
$request_memory_option = "";
$mem = "";
for ($i=4; $i<@ARGV; $i++){
    $option_found = "false";
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
	die $USAGE;
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-q";
        $mem = "max_mem30";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "30G";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs++;
	$option_found = "true";
	$argv_all = $ARGV[$i+1];
	@a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
        $request_memory_option = $a[2];
        $mem = $a[3];
	$i++;
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""){
            die "please provide \"<submit>,<jobname_option>,<request_memory_option>,<queue_name_for_30G>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>,<request_memory_option>,<queue_name_for_30G>\".\n";
        }
    }
    if ($ARGV[$i] eq '-mem'){
        $option_found = "true";
        $new_mem = $ARGV[$i+1];
        $replace_mem = "true";
        $i++;
        if ($new_mem eq ""){
            die "please provide a queue name.\n";
        }
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }

}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other <submit>,<jobname_option>,<request_memory_option>,<queue_name_for_30G>.\n";
}

if ($replace_mem eq "true"){
    $mem = $new_mem;
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/runall_//;
$sampledirs = $ARGV[0];
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study = $fields[@fields-2];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
$stats_dir = $study_dir . "STATS";
unless (-d $stats_dir){
    `mkdir $stats_dir`;}
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}
$sam_name = $ARGV[2];
$total_reads_file = $ARGV[3];
$dirs = `wc -l $sample_dir`;
@a = split(" ", $dirs);
$num_samples = $a[0];

if ($total_reads_file eq "true"){
    $dirs_reads = "$stats_dir/total_num_reads.txt";
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
	$jobname = "$study.sam2mappingstats";
	$logname = "$logdir/sam2mappingstats.$id";
	open(OUTFILE, ">$shfile");
	print OUTFILE "perl $path $LOC/$dir/$sam_name $LOC/$dir/$id.mappingstats.txt -numreads $num_id\n";
    	close(OUTFILE);
	`$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
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
	$jobname = "$study.sam2mappingstats";
	$logname = "$logdir/$dir.sam2mappingstats";
	open(OUTFILE, ">$shfile");
	print OUTFILE "perl $path $LOC/$dir/$sam_name $LOC/$dir/$id.mappingstats.txt\n";
	close(OUTFILE);
	`$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
    }
}
close(INFILE);
print "got here\n";
