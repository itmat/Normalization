#!/usr/bin/env perl
use warnings;
use strict;
use FindBin qw($Bin);
use lib ("$Bin/pm/lib/perl5");
use Net::OpenSSH;
my $USAGE = "\nUsage: perl runall_parseblastout.pl <sample dirs> <loc> [option]

where:
<sample dirs> is a file with the names of the sample directories
<loc> is the directory with the sample directories

option:  
 -lsf : set this if you want to submit batch jobs to LSF (PMACS cluster).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI cluster).

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -M, -l h_vmem=)
        <queue_name_for_3G> : is queue name for 6G (e.g. 6144, 6G)

        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 6G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -headnode <name> : For clusters which only allows job submissions from the head node, use this option.

 -h : print usage

";
if(@ARGV < 2) {
    die $USAGE;
}

my $replace_mem = "false";
my $numargs = 0;
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $new_mem = "";
my $njobs = 200;
my $status = "";
my $hn_only = "false";
my $hn_name = "";
my $ssh;
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for (my $i=2; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-headnode'){
        $option_found = "true";
        $hn_only = "true";
        $hn_name = $ARGV[$i+1];
        $i++;
        $ssh = Net::OpenSSH->new($hn_name,
                                 master_opts => [-o => "StrictHostKeyChecking=no", -o => "BatchMode=yes"]);
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-M";
        $mem = "6144";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "6G";
	$status = "qstat";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs++;
        $option_found = "true";
	my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
        $request_memory_option = $a[2];
        $mem = $a[3];
	$status = $a[4];
        $i++;
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq "" | $status eq ""){
            die "please provide \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> ,<jobname_option>, <request_memory_option> ,<queue_name_for_6G>, <status>\".\n";
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
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\".\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}

use Cwd 'abs_path';

my $LOC = $ARGV[1];  
$LOC =~ s/\/$//;
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $study = $fields[@fields-2];
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

my $path = abs_path($0);
$path =~ s/runall_parseblastout.pl//;

open(INFILE, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";  
while(my $line = <INFILE>) {
    chomp($line);
    my $id = $line;
    my $jobname = "$study.parseblastout";
    my $logname = "$logdir/parseblastout.$id";
    my $shfile = "$shdir/a." . $id . "parseblastout.sh";
    open(OUTFILE, ">$shfile");
    print OUTFILE "perl $path/parseblastout.pl $id $LOC\n";
    close(OUTFILE);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    my $x = "$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile";
    if ($hn_only eq "true"){
        $ssh->system($x) or
            die "remote command failed: " . $ssh->error;
    }
    else{
        `$x`;
    }
    sleep(2);
}
close(INFILE);
print "got here\n";
