#!/usr/bin/env perl

$USAGE = "\nUsage: perl runall_get_ribo_percents.pl <sample dirs> <loc> [option]

<sample dirs> is a file with the names of the sample directories
<loc> is the location where the sample directories are

option:  
 -pmacs : set this if you want to submit batch jobs to PMACS cluster (LSF).

 -pgfi : set this if you want to submit batch jobs to PGFI cluster (Sun Grid Engine).

 -other <submit> <jobname_option> <request_memory_option> <queue_name_for_10G>: 
        set this if you're not on PMACS (LSF) or PGFI (SGE) cluster.

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_10G> : is queue name for 10G (e.g. max_mem30, 10G)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 10G

 -h : print usage

";
if(@ARGV<2) {
    die $USAGE;
}
$replace_mem = "false";
$numargs = 0;
$submit = "";
$jobname_option = "";
$request_memory_option = "";
$mem = "";

for ($i=2; $i<@ARGV; $i++){
    $option_found = "false";
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
	die $USAGE;
    }
    if ($ARGV[$i] eq '-pmacs'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-q";
        $mem = "max_mem30";
    }
    if ($ARGV[$i] eq '-pgfi'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "10G";
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
            die "please provide <submit>, <jobname_option>, and <request_memory_option> <queue_name_for_10G>\n";
        }
        if ($submit eq "-pmacs" | $submit eq "-pgfi"){
            die "you have to specify how you want to submit batch jobs. choose -pmacs, -pgfi, or -other <submit> <jobname_option> <request_memory_option> <queue_name_for_10G>.\n";
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
    die "you have to specify how you want to submit batch jobs. choose -pmacs, -pgfi, or -other <submit> <jobname_option> <request_memory_option> <queue_name_for_10G>.\n";
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
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

$shfile = "$shdir/$study.get_ribo_percents.sh";
$jobname = "$study.getribopercents";
$logname = "$logdir/$study.getribopercents";
open(OUT, ">$shfile");
print OUT "perl $path $sampledirs $LOC\n";
close(OUT);
`$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
