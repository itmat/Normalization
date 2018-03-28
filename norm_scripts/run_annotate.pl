#!/usr/bin/env perl
use FindBin qw($Bin);
use lib ("$Bin/pm/lib/perl5");
use Net::OpenSSH;

$USAGE = "\nUsage: perl run_annotate.pl <file of features files> <annotation file> <loc> [options]

where:
<file of features files> is a file with the names of the features files to be annotated
<annotation file> should be downloaded from UCSC known-gene track including
at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, spDisease, 
protein and gene fields from the Linked Tables table.
<loc> is the path to the sample directories.

option:  
 -normdir <s>
 -outputdesc : set this if you don't want to output description. it will print the description by default.

 -lsf : set this if you want to submit batch jobs to LSF cluster (PMACS).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine cluster (PGFI).

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_15G>,<status>\": 
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

 -headnode <name> : For clusters which only allows job submissions from the head node, use this option.

 -h : print usage

";

if(@ARGV<3) {
    die $USAGE;
}

$replace_mem = "false";
$numargs = 0;
$submit = "";
$jobname_option = "";
$request_memory_option = "";
$mem = "";
$outputdesc = "";
$njobs = 200;
my $normdir = "";
my $ncnt=0;
my $hn_only = "false";
my $hn_name = "";
my $ssh;
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for($i=3; $i<@ARGV; $i++) {
    $option_found = 'false';
    if ($ARGV[$i] eq '-headnode'){
        $option_found = "true";
        $hn_only = "true";
        $hn_name = $ARGV[$i+1];
        $i++;
        $ssh = Net::OpenSSH->new($hn_name,
                                 master_opts => [-o => "StrictHostKeyChecking=no", -o => "BatchMode=yes"]);
    }
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-normdir'){
	$option_found = "true";
	$normdir = $ARGV[$i+1];
	$i++;
	$ncnt++;
    }

    if($ARGV[$i] eq '-outputdesc') {
	$option_found = 'true';
	$outputdesc = "-outputdesc";
    }
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
        $argv_all = $ARGV[$i+1];
        @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
        $request_memory_option = $a[2];
        $mem = $a[3];
	$status = $a[4];
        $i++;
	if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq "" | $status eq ""){
	    die "please provide \"<submit>, <jobname_option>, and <request_memory_option> <queue_name_for_15G>, <status>\"\n";
	}
	if ($submit eq "-lsf" | $submit eq "-sge"){
	    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_15G>,<status>\".\n";
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
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_15G>,<status>\".\n
";
}
if ($ncnt ne '1'){
    die "please specify -normdir path\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/run_annotate.pl//;
$annot_file = $ARGV[1];
$LOC = $ARGV[2];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study = $fields[@fields-2];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir -p $shdir`;}
unless (-d $logdir){
    `mkdir -p $logdir`;}
$norm_dir = "$normdir/EXON_INTRON_JUNCTION";
$spread_dir = $norm_dir . "/SPREADSHEETS";

unless (-d $spread_dir){
    `mkdir -p $spread_dir`;
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while ($line = <INFILE>){
    chomp($line);
    $shfile = "$shdir/annotate.$line.sh";
    $jobname = "$study.annotate";
    $logname = "$logdir/annotate.$line";
    open(OUT, ">$shfile");
    print OUT "perl $path/annotate.pl $annot_file $spread_dir/$line $outputdesc $spread_dir/annotated_$line";
    close(OUT);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    my $x ="$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile";
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
