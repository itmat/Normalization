#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "\nUsage: runall_filter_and_resolve.pl <file of sample dirs> <loc> <sam file name> <exons file> <introns file> <intergenic regions file> [options]

where:
<sample dirs> is a file with the names of the sample directories
<loc> is the directory with the sample directories
<sam file name> is the name of sam file
<exons file> master list of exons file (full path)
<introns file> master list of introns file (full path)
<intergenic regions file> master list of intergenic regions file (full path)

option:
  -str_f : if forward read is in the same orientation as the transcripts/genes.

  -str_r : if reverse read is in the same orientation as the transcripts/genes.

  -se :  set this if the data are single end, otherwise by default it will assume it's a paired end data.

  -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

  -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

  -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_30G>, <status>\":
         set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
         **make sure the arguments are comma separated inside the quotes**

         <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
         <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
         <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
         <queue_name_for_30G> : is queue name for 30G (e.g. max_mem30, 30G)
         <status> : command for checking batch job status (e.g. bjobs, qstat)

  -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 30G

  -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

  -h : print usage

This will remove all rows from input samfile except those that satisfy all of the following:
1. Unique mapper / NU mapper
2. Both forward and reverse map consistently
3. id not in (the appropriate) file specified in <more ids>
4. Only on a numbered chromosome, X or Y
5. Is a forward mapper (script outputs forward mappers only)

";
if(@ARGV < 6) {
    die $USAGE;
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_filter_and_resolve.pl//;
my $sam_name = $ARGV[2];
my $njobs = 200;
my $pe = "true";

my $replace_mem = "false";
my $numargs = 0;
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $status = "";
my $str = "";
my $new_mem = "";
for(my $i=6; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-str_r'){
	$option_found = "true";
	$str = "-str_r";
    }
    if ($ARGV[$i] eq '-str_f'){
	$option_found = "true";
	$str = "-str_f";
    }
    if ($ARGV[$i] eq '-se'){
        $pe = "false";
        $option_found = "true";
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
        $mem = "max_mem30";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
        $request_memory_option = "-l h_vmem=";
        $mem = "30G";
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
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""| $status eq ""){
            die "please provide \"<submit>, <jobname_option>,<request_memory_option>, <queue_name_for_30G>, <status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_30G>, <status>\".\n";
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
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> ,<jobname_option>, <request_memory_option>, <queue_name_for_30G>, <status>\".\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}

my $exon = $ARGV[3];
my $intron = $ARGV[4];
my $ig = $ARGV[5];

open(INFILE, $ARGV[0]);  # file of sample dirs (without path)
my $LOC = $ARGV[1];  # the location where the sample dirs are
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $study = $fields[@fields-2];
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;
}
unless (-d $logdir){
    `mkdir $logdir`;
}

while(my $line = <INFILE>) {
    chomp($line);
    my $dir = $line;
    my $id = $line;
    $id =~ s/\//_/g;
    my $idsfile = "$LOC/$dir/$id.ribosomalids.txt";
    my $shfile = "$shdir/a" . $id . "filter.sh";
    my $jobname = "$study.filtersam";
    my $logname = "$logdir/filtersam.$id";
    open(OUTFILE, ">$shfile");
    if ($pe eq "true"){
	print OUTFILE "perl $path/filter_and_resolve.pl $LOC/$dir/$sam_name $exon $intron $ig $idsfile $LOC/$dir/$id.filtered.sam\n";
    }
    else {
	print OUTFILE "perl $path/filter_and_resolve.pl $LOC/$dir/$sam_name $exon $intron $ig $idsfile $LOC/$dir/$id.filtered.sam -se\n";
    }
    close(OUTFILE);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
}
close(INFILE);
print "got here\n";
