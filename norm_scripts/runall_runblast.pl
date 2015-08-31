#!/usr/bin/env perl
use warnings;
use strict;
my $USAGE = "\nUsage: perl runall_runblast.pl <sample dirs> <loc> <unaligned> <blast dir> <query> [option]

where:
<sample dirs> is a file with the names of the sample directories
<loc> is the directory with the sample directories
<unaligned> is a file with the full path of all unaligned files
<blast dir> is the blast dir (full path)
<query> query file (full path)

option:  
 -fa : set this if the unaligned files are in fasta format

 -fq : set this if the unaligned files are in fastq format

 -gz : set this if the unaligned files are compressed

 -lsf : set this if you want to submit batch jobs to LSF (PMACS cluster).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI cluster).

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_15G>, <status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -M, -l h_vmem=)
        <queue_name_for_15G> : is queue name for 15G (e.g. 15360, 15G)

        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 15G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -h : print usage

";
if(@ARGV < 5) {
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
my $gz = "";
my $fafq = "";
my $req_unaligned=0;
my $status = "";
my $sepe = "";
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for (my $i=5; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-M";
        $mem = "15360";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "15G";
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
            die "please provide \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_15G>, <status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> ,<jobname_option>, <request_memory_option> ,<queue_name_for_15G>, <status>\".\n";
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
    if ($ARGV[$i] eq '-gz'){
	$option_found = "true";
	$gz = "-gz";
    }
    if ($ARGV[$i] eq '-fa'){
	$option_found = "true";
	$fafq = "-fa";
	$req_unaligned++;
    }
    if ($ARGV[$i] eq '-fq'){
	$option_found = "true";
	$fafq = "-fq";
	$req_unaligned++;
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_15G>, <status>\".\n";
}
if ($req_unaligned ne '1'){
    die "please specify the type of the unaligned files : '-fa' or '-fq'\n";
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
$path =~ s/runall_runblast.pl//;
my $unaligned = $ARGV[2];
my $blastdir = $ARGV[3];
my $query = $ARGV[4];

open(INFILE, $ARGV[0]) or die "cannot find file \"$ARGV[0]\"\n";  
while(my $line = <INFILE>) {
    chomp($line);
    my $id = $line;
    my $a = `grep -w $id $unaligned`;
    my @u = split(/\n/,$a);
    my $size = @u;
    my $shfile = "$shdir/a." . $id . "runblast.sh";
    my $jobname = "$study.runblast";
    my $logname = "$logdir/runblast.$id";
    if ($size == 1){
	$sepe = "-se";
	my $fwd = $u[0];
	open(OUTFILE, ">$shfile");
	print OUTFILE "perl $path/runblast.pl $id $LOC $blastdir $query $gz $fafq $sepe $fwd\n";
	close(OUTFILE);
    }
    elsif ($size == 2){
	my $fwd = $u[0];
	my $rev = $u[1];
	$sepe = "-pe";
	open(OUTFILE, ">$shfile");
        print OUTFILE "perl $path/runblast.pl $id $LOC $blastdir $query $gz $fafq $sepe \"$fwd,$rev\"\n";	
	close(OUTFILE);
    }
    else{
	die "something is wrong with the <unaligned> file.\n";
    }
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
    sleep(2);
}
close(INFILE);
print "got here\n";
