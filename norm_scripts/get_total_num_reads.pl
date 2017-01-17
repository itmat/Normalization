#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib ("$Bin/pm/lib/perl5");
use Net::OpenSSH;
my $USAGE = "\nUsage: perl get_total_num_reads.pl <sample dirs> <loc> <file of input forward fa/fq files> [options]

<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the location where the sample directories are
<file of input forward fa/fq files> is a file with the names of input forward fa/fq files (full path)

option:  

 -fa : set this if the input files are in fasta format
 -fq : set this if the input files are in fastq format
 -gz : set this if your input files are compressed

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

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.
 -alt_stats <s>

 -headnode <name> : For clusters which only allows job submissions from the head node, use this option.

 -h : print usage

";
if(@ARGV<3) {
    die $USAGE;
}

my $fa = "false";
my $fq = "false";
my $gz = "false";
my $njobs = 200;
my $numargs = 0;
my $numargs_2 = 0;
my $jobname_option = "";
my $mem = "";
my $new_mem = "";
my $replace_mem = "false";
my ($submit, $request_memory_option, $status);
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $stats_dir = $study_dir . "STATS";
my $hn_only = "false";
my $hn_name = "";
my $ssh;
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for (my $i=3; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-headnode'){
        $option_found = "true";
        $hn_only = "true";
        $hn_name = $ARGV[$i+1];
        $i++;
        $ssh = Net::OpenSSH->new($hn_name,
                                 master_opts => [-o => "StrictHostKeyChecking=no", -o => "BatchMode=yes"]);
    }

    if ($ARGV[$i] eq '-fa'){
	$fa = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-fq'){
	$fq = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-gz'){
	$gz = "true";
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-alt_stats'){
	$option_found = "true";
	$stats_dir = $ARGV[$i+1];
	$i++;
    }
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs_2++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
	$request_memory_option = "-M";
	$mem = "3072";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs_2++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
	$request_memory_option = "-l h_vmem=";
        $mem = "3G";
	$status = "qstat";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs_2++;
        $option_found = "true";
	my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
        $request_memory_option = $a[2];
        $mem = $a[3];
	$status = $a[4];
        $i++;
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""| $status eq ""){
            die "please provide \"<submit>, <jobname_option>,<request_memory_option>, <queue_name_for_3G>, <status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\".\n";
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
    die "you have to specify an input file type. use either '-fa' or '-fq'\n
";
}
if($numargs_2 ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>,<request_memory_option>, <queue_name_for_3G>,<status>\".\n
";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}
my $sample_dirs = $ARGV[0];
my $logdir = $study_dir . "logs";
unless (-d $logdir){
    `mkdir $logdir`;}
unless (-d $stats_dir){
    `mkdir $stats_dir`;}
my $input_files = $ARGV[2];
my $temp_file = "$stats_dir/temp";
my @t = glob ("$temp_file*$study");
if (@t > 0){
    `rm $temp_file*$study`;
}

my $jobname = "numreads";
my $logname = "$logdir/$study.numreads";
my @l = glob ("$logname*");
if (@l > 0){
    `rm $logname*`;
}

open(INFILE, $input_files) or die "cannot find file '$input_files'\n";
my $i = 0;
while(my $line = <INFILE>){
    chomp($line);
    unless (-e $line){
	die "ERROR: cannot find \"$line\"\n";
    }
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    my $x;
    if ($gz eq "true"){
	$x= "echo \"zcat $line | wc -l | xargs echo -n >> $temp_file.$i.$study && echo -e '\t$line' >> $temp_file.$i.$study\" | $submit $request_memory_option$mem $jobname_option $jobname -e $logname.$i.err -o $logname.$i.out";
    }
    else {
	$x ="echo \"wc -l < $line | xargs echo -n >> $temp_file.$i.$study && echo -e '\t$line' >> $temp_file.$i.$study\" | $submit $request_memory_option$mem $jobname_option $jobname -e $logname.$i.err -o $logname.$i.out";
    }
    if ($hn_only eq "true"){
	$ssh->system($x) or
	    die "remote command failed: " . $ssh->error;
    }
    else{
	`$x`;
    }
    sleep(2);
    $i++;
}
close(INFILE);

my $outfile_final = "$stats_dir/total_num_reads.txt";
while (qx{$status | grep -c $jobname} > 0){
    sleep(10);
}
my @g = glob("$logname.*.err");
if (@g > 0){
    if (qx{cat $logname.*.err | wc -l} > 0){
	die "ERROR: wc -l step had errors\n";
    }
}
else{
    die "ERROR: wc -l step did not run\n";
}
my @g2 = glob("$temp_file.*.$study");
if (@g2 eq 0){
    die "ERROR: wc -l step did not run\n";
}
open(DIRS, $sample_dirs) or die "cannot find file '$sample_dirs'\n";
open(OUTFINAL, ">$outfile_final");
while(my $dir = <DIRS>){
    chomp($dir);
    my $num;
    my $id = $dir;
    my $total_num_reads = `grep -w $id $temp_file.*.$study`;
    my @fields = split(" ", $total_num_reads);
    my @t = glob ("$temp_file*$study");
    if (@t > 1){
	my $first = $fields[0];
	my @a = split(":", $first);
	$num = $a[1];
    }
    else{
	$num = $fields[0];
    }
    if ($fq eq "true"){
	$num = $num/4;
    }
    if ($fa eq "true"){
	$num = $num/2;
    }    
    print OUTFINAL "$id\t$num\n";
}
close(DIRS);
close(OUTFINAL);

print "got here\n";
`rm $temp_file*$study`;
