#!/usr/bin/env perl
use strict;
use warnings;
my $USAGE = "\nUsage: perl runall_genefilter.pl <sample dirs> <loc> 
 
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are

option:
 -filter_highexp : use this if you want to filter high expressors.

 -se :  set this if the data is single end, otherwise by default it will assume it's a paired end data.
 
 -u  :  set this if you are using unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -nu  :  set this if you are using non-unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>,<jobname_option>,<request_memory_option>, <queue_name_for_10G>,<status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_10G> : is queue name for 10G (e.g. max_mem30, 10G)
        <status> : command for checking batch job status (e.g. bjobs, qstat)

  -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 10G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. 
                   by default it will submit 200 jobs at a time.

 -h : print usage

\n";
if (@ARGV<2){
    die $USAGE;
}

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_genefilter.pl//;
my $request_memory_option = "";
my $mem = "";
my $replace_mem = "false";
my $new_mem = "";
my $numargs_u_nu = 0;
my $numargs = 0;
my $U = "true";
my $NU = "true";
my $njobs = 200;
my $submit = "";
my $jobname_option = "";
my $status;
my $pe = "true";
my $filter = "false";
for (my $i=2; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
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
    if ($ARGV[$i] eq '-se'){
	$pe = "false";
	$option_found = "true";
    }
    if($ARGV[$i] eq '-nu') {
        $U = "false";
	$numargs_u_nu++;
        $option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
        $numargs_u_nu++;
        $option_found = "true";
    }
    if($ARGV[$i] eq '-filter_highexp') {
        $filter = "true";
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
	$status = "bjobs";
        $request_memory_option = "-q";
        $mem = "max_mem30";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
	$status = "qstat";
        $request_memory_option = "-l h_vmem=";
        $mem = "10G";
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
        if ($submit eq "-max_jobs" | $submit eq "" | $jobname_option eq "" |  $status eq ""){
            die "please provide \"<submit>, <jobname_option>,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>,<request_memory_option>, <queue_name_for_10G> ,<status>\".\n";
        }
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>,<request_memory_option>, <queue_name_for_10G>,<status>\".\n
";
}
if($numargs_u_nu > 1) {
    die "you cannot specify both -u and -nu\n.
";
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
    my $genedir = "$LOC/$id/GNORM";
    my $samname_u = "$genedir/Unique/$id.filtered_u.sam";
    my $samname_nu = "$genedir/NU/$id.filtered_nu.sam";
    my $genefile_u = $samname_u;
    my $outname_u = $samname_u;
    $outname_u =~ s/.sam$/_genes.sam/;
    my $genefile_nu = $samname_nu;
    my $outname_nu = $samname_nu;
    $outname_nu =~ s/.sam$/_genes.sam/;
    my ($shfile_u, $jobname, $logname_u, $shfile_nu, $logname_nu);
    if ($filter eq "false"){
	$genefile_u =~ s/.sam$/.genes.txt/;
	$genefile_nu =~ s/.sam$/.genes.txt/;
	$shfile_u = "$shdir/F.$id.genefilter_u.sh";
	$jobname = "$study.genefilter_gnorm";
	$logname_u = "$logdir/genefilter_u.$id";
	$shfile_nu = "$shdir/F.$id.genefilter_nu.sh";
	$logname_nu = "$logdir/genefilter_nu.$id";
    }
    if ($filter eq "true"){
	$genefile_u =~ s/.sam$/.genes2.txt/;
	$genefile_nu =~ s/.sam$/.genes2.txt/;
	$shfile_u = "$shdir/F.$id.genefilter2_u.sh";
	$jobname = "$study.genefilter_gnorm2";
	$logname_u = "$logdir/genefilter2_u.$id";
	$shfile_nu = "$shdir/F.$id.genefilter2_nu.sh";
	$logname_nu = "$logdir/genefilter2_nu.$id";
    }
    if ($U eq "true"){
	open(OUT, ">$shfile_u");
	if ($pe eq "true"){
	    print OUT "perl $path/genefilter.pl $samname_u $genefile_u $outname_u\n";
	}
	else{
	    print OUT "perl $path/genefilter.pl $samname_u $genefile_u $outname_u -se\n";
	}
	close(OUT);
	while (qx{$status | wc -l} > $njobs){
	    sleep(10);
	}
	`$submit $jobname_option $jobname $request_memory_option$mem -o $logname_u.out -e $logname_u.err < $shfile_u`;
    }
    if ($NU eq "true"){
	open(OUT, ">$shfile_nu");
	if ($pe eq "true"){
	    print OUT "perl $path/genefilter.pl $samname_nu $genefile_nu $outname_nu\n";
	}
	else{
	    print OUT "perl $path/genefilter.pl $samname_nu $genefile_nu $outname_nu -se\n";
	}
	close(OUT);
	while (qx{$status | wc -l} > $njobs){
	    sleep(10);
	}
	`$submit $jobname_option $jobname $request_memory_option$mem -o $logname_nu.out -e $logname_nu.err < $shfile_nu`;
    }
}
close(IN);
print "got here\n";

