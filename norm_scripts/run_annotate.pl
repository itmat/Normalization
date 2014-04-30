#!/usr/bin/env perl

$USAGE = "\nUsage: perl run_annotate.pl <file of features files> <annotation file> <loc> [options]

where:
<file of features files> is a file with the names of the features files to be annotated
<annotation file> should be downloaded from UCSC known-gene track including
at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, spDisease, 
protein and gene fields from the Linked Tables table.
<loc> is the path to the sample directories.

option: 
 -outputdesc : set this if you don't want to output description. it will print the description by default.

 -lsf : set this if you want to submit batch jobs to LSF cluster (PMACS).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine cluster (PGFI).

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_15G>\": 
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes** 

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command 
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_15G> : is queue name for 15G (e.g. max_mem30, 15G)

 -mem <s> : set this if your job requires more memory. 
            <s> is the queue name for required mem. 
            Default: 15G

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
for($i=3; $i<@ARGV; $i++) {
    $option_found = 'false';
    if ($ARGV[$i] eq '-h'){
	$option_found = "true";
	die $USAGE;
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
	$request_memory_option = "-q";
	$mem = "max_mem30";
    }
    if ($ARGV[$i] eq '-sge'){
	$numargs++;
	$option_found = "true";
	$submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "15G";
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
        $i++;
	if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""){
	    die "please provide \"<submit>, <jobname_option>, and <request_memory_option> <queue_name_for_15G>\"\n";
	}
	if ($submit eq "-lsf" | $submit eq "-sge"){
	    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_15G>\".\n";
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
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_15G>\".\n
";
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
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}
$norm_dir = $study_dir . "NORMALIZED_DATA";
$spread_dir = $norm_dir . "/SPREADSHEETS";

unless (-d $spread_dir){
    `mkdir $spread_dir`;
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while ($line = <INFILE>){
    chomp($line);
    $shfile = "$shdir/annotate.$line.sh";
    $jobname = "$study.annotate";
    $logname = "$logdir/annotate.$line";
    open(OUT, ">$shfile");
    print OUT "perl $path/annotate.pl $annot_file $spread_dir/$line $outputdesc > $spread_dir/annotated_$line";
    close(OUT);
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
}
close(INFILE);
