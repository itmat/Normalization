#!/usr/bin/env perl
use warnings;
use strict;
my $USAGE =  "\nUsage: perl runall_get_exon_intron_percents.pl <sample dirs> <loc> [options]

where:
<sample dir> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories

option:
 -stranded : set this if your data are strand-specific. 
 
 -u :   set this if you want to return only unique exonpercents/intronpercents, 
        otherwise by default it will return non-unique exonpercents/intronpercents only.

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

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time. (Default <n> = 200)

 -i <n> : index for logname (default: 0)

 -h : print usage

";
if(@ARGV<2) {
    die $USAGE;
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/runall_get_exon_intron_percents.pl//;
my $strand_info = "";
my $stranded = "false";
my $NU = "true";
my $njobs = 200;
my $replace_mem = "false";
my $new_mem = "";
my $status = "";
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $numargs = 0;
my $index = 0;
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for(my $i=2; $i<@ARGV; $i++) {
    my $option_found = 'false';
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
    if ($ARGV[$i] eq '-stranded'){
	$option_found = "true";
	$strand_info = "-stranded";
	$stranded = "true";
    }
    if($ARGV[$i] eq '-u') {
	$NU = "false";
        $option_found = "true";
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
        if (($submit eq "-mem") || ($submit eq "") || ($jobname_option eq "") || ($request_memory_option eq "") || ($mem eq "") || ($status eq "")){
            die "please provide \"<submit>, <jobname_option>, <request_memory_option> ,<queue_name_for_6G>,<status>\"\n";
        }
        if (($submit eq "-lsf") || ($submit eq "-sge")){
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

my $cutoff = 100;
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while(my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $sampledir = "$LOC/$line";
    my $outfile = "$LOC/$line/$id.exonpercents.txt";
    my $outfile_i = "$LOC/$line/$id.intronpercents.txt";
    my $shfile = "$shdir/$id.get_exon_intron_percents.sh";
    my $jobname = "$study.get_exon_intron_percents";
    my $logname = "$logdir/get_exon_intron_percents.$index.$id";
    open(OUT, ">$shfile");
    if ($NU eq "false"){
	print OUT "perl $path/get_exon_intron_percents.nu.pl $sampledir $cutoff $outfile $outfile_i $strand_info\n";
    }
    if ($NU eq "true"){
	$outfile =~ s/.txt$/.nu.txt/;
	$outfile_i =~ s/.txt$/.nu.txt/;
	print OUT "perl $path/get_exon_intron_percents.nu.pl $sampledir $cutoff $outfile $outfile_i -nu $strand_info\n";
    }
    close(OUT);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
}
close(INFILE);

print "got here\n";
