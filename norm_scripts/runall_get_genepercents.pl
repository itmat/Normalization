#!/usr/bin/env perl
use warnings;
use strict;
use FindBin qw($Bin);
use lib ("$Bin/pm/lib/perl5");
use Net::OpenSSH;

my $USAGE =  "\nUsage: perl runall_get_genepercents.pl <sample dirs> <loc> [options]

where:
<sample dir> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories

option:
 -stranded : set this if the data are strand-specific.

 -se : set this for single end data.

 -u :  set this if you want to return only unique genepercents, otherwise by default
       it will return non-unique genepercents.

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

 -i <n> : index for logname (default: 0)

 -headnode <name> : For clusters which only allows job submissions from the head node, use this option.

 -h : print usage

";
if(@ARGV<2) {
    die $USAGE;
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/runall_get_genepercents.pl//;
my $stranded = "";
my $U = "false";
my $NU = "true";
my $njobs = 200;
my $replace_mem = "false";
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $numargs = 0;
my $status;
my $new_mem;
my $index = 0;
my $se_option = "";
my $hn_only = "false";
my $hn_name = "";
my $ssh;
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for(my $i=2; $i<@ARGV; $i++) {
    my $option_found = 'false';
    if ($ARGV[$i] eq '-headnode'){
        $option_found = "true";
        $hn_only = "true";
        $hn_name = $ARGV[$i+1];
        $i++;
        $ssh = Net::OpenSSH->new($hn_name,
                                 master_opts => [-o => "StrictHostKeyChecking=no", -o => "BatchMode=yes"]);
    }
    if ($ARGV[$i] eq '-se'){
        $option_found = "true";
	$se_option = "-se";
    }
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-i'){
        $option_found = "true";
        $index = $ARGV[$i+1];
        if ($index !~ /(\d+$)/ ){
            die "-i <n> : <n> needs to be a number\n";
        }
	$i++;
    }
    if($ARGV[$i] eq '-u') {
        $U = "true";
	$NU = "false";
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-stranded'){
        $option_found = "true";
	$stranded = "-stranded";
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
            die "please provide \"<submit>, <jobname_option>, <request_memory_option> ,<queue_name_for_6G>,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> ,<jobname_option>, <request_memory_option>, <queue_name_for_6G>,<status>\".\n";
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
        die "arg \"$ARGV[$i]\" not recognized.\n";
    }
}

if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option> ,<request_memory_option>, <queue_name_for_6G>,<status>\".\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}


my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my$study = $fields[@fields-2];
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";

unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

my $cutoff = 100;

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while(my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $sampledir = "$LOC/$line";
    my $outfile = "$LOC/$line/$id.genepercents.txt";
    my $shfile = "$shdir/$id.get_genepercents.$index.sh";
    my $logname = "$logdir/get_genepercents.$index.$id";
    my $jobname = "$study.get_genepercents";
    open(OUT, ">$shfile");
    if ($U eq "true"){
	print OUT "perl $path/get_genepercents.pl $sampledir $cutoff $outfile $stranded $se_option\n";
    }
    if ($NU eq "true"){
	$outfile =~ s/.txt$/.nu.txt/;
	print OUT "perl $path/get_genepercents.pl $sampledir $cutoff $outfile -nu $stranded $se_option\n";
    }
    close(OUT);
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
}
close(INFILE);

print "got here\n";
