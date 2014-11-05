#!/usr/bin/env perl
use warnings;
use strict;
my $USAGE =  "\nUsage: perl runall_get_high_genes.pl <sample dirs> <loc> <cutoff> [options]

where:
<sample dir> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<cutoff> cutoff %

option:
 -stranded : set this if the data are strand-specific.

 -nu :  set this if you want to return only non-unique genepercents, otherwise by default
         it will return unique genepercents.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_6G> : is queue name for 6G (e.g. plus, 6G)

        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 6G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -h : print usage

";
if(@ARGV<3) {
    die $USAGE;
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/runall_get_high_genes.pl//;
my $stranded = "";
my $U = "true";
my $NU = "false";
my $njobs = 200;
my $replace_mem = "false";
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $numargs = 0;
my $status;
my $new_mem;
for(my $i=3; $i<@ARGV; $i++) {
    my $option_found = 'false';
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if($ARGV[$i] eq '-nu') {
        $U = "false";
	$NU = "true";
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-stranded'){
        $option_found = "true";
	$stranded = "-stranded";
    }
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
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
        die $USAGE;
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

my $cutoff = $ARGV[2];

if ($cutoff !~ /(\d+$)/){
    die "ERROR: <cutoff> needs to be a number\n";
}
else{
    if ((0 > $cutoff) || (100 < $cutoff)){
	die "ERROR: <cutoff> needs to be a number between 0-100\n";
    }
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while(my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $sampledir = "$LOC/$line";
    my $outfile = "$LOC/$line/$id.genepercents.txt";
    my $shfile = "$shdir/$id.get_genepercents.sh";
    my $logname = "$logdir/$id.get_genepercents";
    my $jobname = "$study.get_genepercents";
    open(OUT, ">$shfile");
    if ($U eq "true"){
	print OUT "perl $path/get_genepercents.pl $sampledir $cutoff $outfile $stranded\n";
    }
    if ($NU eq "true"){
	print OUT "perl $path/get_genepercents.pl $sampledir $cutoff $outfile -nu $stranded\n";
    }
    close(OUT);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
}
close(INFILE);

print "got here\n";
