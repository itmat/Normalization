#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl runall_quantify_genes_gnorm.pl <sample dirs> <loc> <genes>

<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<genes> master list of genes file

option:
 -norm : set this to quantify normalized sam.

 -u  :  set this if your sam files have unique mappers only.
        otherwise by default it will use merged(unique+non-unique) mappers.

 -nu  :  set this if your sam files have non-unique mappers only.
         otherwise by default it will use merged(unique+non-unique) mappers.
 
 -se :  set this if the data is single end, otherwise by default it will assume it's a paired end data.

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

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted.
                   by default it will submit 200 jobs at a time.

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 10G

 -h : print usage

\n";

if (@ARGV < 3){
    die $USAGE
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_quantify_genes_gnorm.pl//;
my $se = "false";
my $numargs_u_nu = 0;
my $numargs = 0;
my $U = "true";
my $NU = "true";
my $njobs = 200;
my $replace_mem = "false";
my $submit = "";
my $request_memory_option = "";
my $mem = "";
my $new_mem = "";
my $jobname_option = "";
my $status;
my $norm = "false";
for (my $i=3; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
	$i++;
    }
    if ($ARGV[$i] eq "-norm"){
	$norm = "true";
	$option_found = "true";
    }
    if($ARGV[$i] eq '-nu') {
        $U = "false";
	$numargs_u_nu++;
        $option_found = "true";
    }
    if($ARGV[$i] eq '-se') {
        $se = "true";
        $option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
        $numargs_u_nu++;
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
        $mem = "10G";
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
        if ($submit eq "-max_jobs" | $submit eq "" | $jobname_option eq "" |  $request_memory_option eq "" | $mem eq "" | $status eq ""){
            die "please provide \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_10G> ,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_10G>,<status>\".\n";
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
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>, <request_memory_option>, \
<queue_name_for_10G>,<status>\".\n
";
}
if($numargs_u_nu > 1) {
    die "you cannot specify both -u and -nu\n.
";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}


my $samples = $ARGV[0];
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
my $gnorm_dir = $study_dir . "NORMALIZED_DATA/GENE";
my $gnorm_U_dir = "$gnorm_dir/FINAL_SAM/Unique";
my $gnorm_NU_dir = "$gnorm_dir/FINAL_SAM/NU";
my $gnorm_M_dir = "$gnorm_dir/FINAL_SAM/MERGED";
my $ensFile = $ARGV[2];

open(IN, $samples) or die "cannot find file '$samples'\n"; # dirnames;
while(my $line = <IN>){
    chomp($line);
    my $id = $line;
    my ($filename, $outname, $jobname, $logname, $shfile);
    if ($norm eq "true"){
	$shfile = "$shdir/GQ.$id.quantifygenes.gnorm2.sh";
	$jobname = "$study.quantifygenes.gnorm2";
	$logname = "$logdir/quantifygenes.gnorm2.$id";
	if (-d $gnorm_M_dir){
	    $filename = "$gnorm_M_dir/$id.GNORM.genes.txt";
	}
	elsif ($U eq 'true'){
	    $filename = "$gnorm_U_dir/$id.GNORM.Unique.genes.txt";
	}
	elsif ($NU eq 'true'){
	    $filename = "$gnorm_NU_dir/$id.GNORM.NU.genes.txt";
	}
    }
    if ($norm eq "false"){
	$shfile = "$shdir/GQ.$id.quantifygenes.gnorm.sh";
        $jobname = "$study.quantifygenes.gnorm";
        $logname = "$logdir/quantifygenes.gnorm.$id";
	if ($U eq "true"){
	    $filename = "$LOC/$id/GNORM/Unique/$id.filtered_u.genes.txt";
	}
	elsif ($NU eq "true"){
	    $filename = "$LOC/$id/GNORM/NU/$id.filtered_nu.genes.txt";
	}
    }
    $outname = $filename;
    $outname =~ s/genes.txt/genequants/g;
    
    open(OUT, ">$shfile");
    if ($se eq "false"){
	print OUT "perl $path/quantify_genes_gnorm.pl $filename $ensFile $outname\n";
    }
    if ($se eq "true"){
	print OUT "perl $path/quantify_genes.pl $filename $ensFile $outname\n";
    }
    close(OUT);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
}
close(IN);
print "got here\n";

