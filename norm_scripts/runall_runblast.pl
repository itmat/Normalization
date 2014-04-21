#!/usr/bin/env perl

$USAGE = "\nUsage: perl runall_runblast.pl <sample dirs> <loc> <samfile name> <blast dir> <db> [option]

where:
<sample dirs> is a file with the names of the sample directories
<loc> is the directory with the sample directories
<samfile> is the name of the sam file (without path)
<blast dir> is the blast dir (full path)
<db> database (full path)

option:  
 -lsf : set this if you want to submit batch jobs to LSF (PMACS cluster).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI cluster).

 -other <submit> <jobname_option> <request_memory_option> <queue_name_for_6G>:
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_6G> : is queue name for 6G (e.g. plus, 6G)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 6G

 -h : print usage

";
if(@ARGV < 5) {
    die $USAGE;
}

$replace_mem = "false";
$numargs = 0;
$submit = "";
$jobname_option = "";
$request_memory_option = "";
$mem = "";

for ($i=5; $i<@ARGV; $i++){
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
        $mem = "plus";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "6G";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs++;
        $option_found = "true";
        $submit = $ARGV[$i+1];
        $jobname_option = $ARGV[$i+2];
        $request_memory_option = $ARGV[$i+3];
        $mem = $ARGV[$i+4];
        $i++;
        $i++;
        $i++;
        $i++;
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""){
            die "please provide <submit>, <jobname_option>, and <request_memory_option> <queue_name_for_6G>\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other <submit> <jobname_option> <request_memory_option> <queue_name_for_6G>.\n";
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
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other <submit> <jobname_option> <request_memory_option> <queue_name_for_6G>.\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}

use Cwd 'abs_path';
open(INFILE, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";  
$LOC = $ARGV[1];  
$LOC =~ s/\/$//;
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$study = $fields[@fields-2];
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

$path = abs_path($0);
$path =~ s/runall_//;
$samfile = $ARGV[2]; # the name of the sam file (without path)
$blastdir = $ARGV[3];
$db = $ARGV[4];

while($line = <INFILE>) {
    chomp($line);
    $dir = $line;
    $line =~ s/Sample_//;
    $line =~ s/\//_/g;
    $id = $line;
    $shfile = "$shdir/a" . $id . "runblast.sh";
    $jobname = "$study.runblast";
    $logname = "$logdir/runblast.$id";
    open(OUTFILE, ">$shfile");
    print OUTFILE "perl $path $dir $LOC $samfile $blastdir $db\n";
    close(OUTFILE);
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
}
close(INFILE);
