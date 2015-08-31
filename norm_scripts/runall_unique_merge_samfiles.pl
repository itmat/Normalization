#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "perl runall_unique_merge_samfiles.pl <sample dirs> <loc> [options]

<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are

options:
 -stranded : set this if the data are strand-specific.

 -u  :  set this if you are using unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -nu  :  set this if you are using non-unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\":
       set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
       **make sure the arguments are comma separated inside the quotes**

       <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
       <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
       <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -M, -l h_vmem=)
       <queue_name_for_6G> : is queue name for 6G (e.g. 6144, 6G)
       <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
           <s> is the queue name for required mem.
           Default: 6G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -h : print usage

";

if (@ARGV<2){
    die $USAGE;
}

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_unique_merge_samfiles.pl//;
my $numargs = 0;
my $type = "";
my $stranded = "";
my $njobs = 200;
my $replace_mem = "false";
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $new_mem = "";
my $status;
my $numargs_c = 0;
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for (my $i=2; $i<@ARGV; $i++){
    my $option_found = "false";
    if($ARGV[$i] eq '-nu') {
	$type = "-nu";
	$numargs++;
        $option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
	$type = "-u";
        $numargs++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq "-stranded"){
	$stranded = "-stranded";
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs_c++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-M";
        $mem = "6144";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs_c++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "6G";
	$status = "qstat";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs_c++;
        $option_found = "true";
	my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
        $request_memory_option = $a[2];
        $mem = $a[3];
	$status = $a[4];
        $i++;
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq ""
	    | $mem eq ""| $status eq ""){
            die "please provide \"<submit>, <jobname_option>,<request_memory_option>, <queue_name_for_6G>, <status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\".\n";
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
    if($option_found eq 'false') {
	die "option \"$ARGV[$i]\" not recognized.\n";
    }
}
if($numargs > 1) {
    die "you cannot use both -u and -nu\n.
";
}
if($numargs_c ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> ,<jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\".\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; # dirnames;
while(my $line = <IN>){
    chomp($line);
    my $id = $line;
    my $shfile = "$shdir/a" . $id . "unique_merge_samfiles.$id.sh";
    my $jobname = "$study.unique_merge_samfiles";
    my $logname = "$logdir/unique_merge_samfiles.$id";
    open(OUTFILE, ">$shfile");
    print OUTFILE "perl $path/unique_merge_samfiles.pl $id $LOC $type $stranded\n";
    close(OUTFILE);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    my $x = `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
    sleep(2);
}
close(IN);


print "got here\n";

