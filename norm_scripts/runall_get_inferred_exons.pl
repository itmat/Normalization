#!/usr/bin/env perl
use strict;
use warnings;
if(@ARGV<3){
    my $USAGE = "\nUsage: perl runall_get_inferred_exons.pl <sample dirs> <loc> <sam file name> [options]

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<sam file name> name of the aligned sam file

options: 
 -min <n> : min is set at 10 by default

 -max <n> : max is set at 1200 by default

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\":
         set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
         **make sure the arguments are comma separated inside the quotes**
 
         <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
         <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
         <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -M, -l h_vmem=)
         <queue_name_for_3G> : is queue name for 3G (e.g. 3072, 3G)
         <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 3G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted.
                   by default it will submit 200 jobs at a time.


";
    die $USAGE;
}

my $min = 10;
my $max = 1200;

my $numargs = 0;
my $njobs = 200;
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $status;
my $se = "";
my $replace_mem = "false";
my $new_mem = "";

for(my $i=3; $i<@ARGV; $i++) {
    my $argument_recognized = 0;
    if($ARGV[$i] eq '-min') {
	$min = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($ARGV[$i] eq '-max') {
	$max = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $argument_recognized = 1;
        $submit = "bsub";
        $jobname_option = "-J";
	$request_memory_option = "-M";
	$mem = "3072";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $argument_recognized = 1;
        $submit = "qsub -cwd";
        $jobname_option = "-N";
	$request_memory_option = "-l h_vmem=";
	$mem = "3G";
	$status = "qstat";
    }

    if ($ARGV[$i] eq '-other'){
        $numargs++;
        $argument_recognized = 1;
	my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
	$request_memory_option = $a[2];
	$mem = $a[3];
	$status = $a[4];
        $i++;
	if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""| $status eq ""){
	    die "please provide \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\".\n";
        }
    }
    if ($ARGV[$i] eq '-mem'){
	$argument_recognized = 1;
	$new_mem = $ARGV[$i+1];
	$replace_mem = "true";
	$i++;
	if ($new_mem eq ""){
	    die "please provide a queue name.\n";
	}
    }
    if ($ARGV[$i] eq '-max_jobs'){
        $argument_recognized = 1;
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if($argument_recognized == 0) {
	die "ERROR: command line arugument '$ARGV[$i]' not recognized.\n";
    }
}

if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\".\n
";
}

if ($replace_mem eq "true"){
    $mem = $new_mem;
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_get_inferred_exons.pl//;

my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $study = $fields[@fields-2];
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";

my $sam_name = $ARGV[2];
my $junc_name = $sam_name;
$junc_name =~ s/.sam$/_junctions_all.rum/i;
$junc_name =~ s/.bam$/_junctions_all.rum/i;
my $sorted_junc = $junc_name;
$sorted_junc =~ s/.rum/.sorted.rum/;
my $jobname = "$study.get_inferred_exons";
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while (my $line = <INFILE>){
    chomp($line);
    my $dir = $line;
    my $id = $line;
    my $shfile = "$shdir/I.$id.get_inferred_exons.sh";
    my $logname = "$logdir/get_inferred_exons.$id";
    my $outfile = "$id.list_of_inferred_exons.txt";
    my $x = `perl $path/rum-2.0.5_05/bin/sort_by_location.pl --skip 1 -o $LOC/$dir/$sorted_junc --location 1 $LOC/$dir/$junc_name`;
    open(SH, ">$shfile");
    print SH "perl $path/get_inferred_exons.pl $LOC/$dir/$sorted_junc $LOC/$dir/$outfile -min $min -max $max\n";
    close(SH);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
    
}
close(INFILE);
print "got here\n";
