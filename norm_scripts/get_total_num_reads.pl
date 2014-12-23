#!/usr/bin/env perl

$USAGE = "\nUsage: perl get_total_num_reads.pl <sample dirs> <loc> <file of input forward fa/fq files> [options]

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
                                  (e.g. -q, -l h_vmem=)
         <queue_name_for_3G> : is queue name for 3G (e.g. normal, 3G)
         <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 3G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -h : print usage

";
if(@ARGV<3) {
    die $USAGE;
}

$fa = "false";
$fq = "false";
$gz = "false";
$njobs = 200;
$numargs = 0;
$numargs_2 = 0;
$jobname_option = "";
$mem = "";
$new_mem = "";
$replace_mem = "false";
for ($i=3; $i<@ARGV; $i++){
    $option_found = "false";
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
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
	die $USAGE;
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs_2++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
	$request_memory_option = "-q";
	$mem = "normal";
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
	$argv_all = $ARGV[$i+1];
        @a = split(",", $argv_all);
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
$sample_dirs = $ARGV[0];
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study = $fields[@fields-2];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$stats_dir = $study_dir . "STATS";
$logdir = $study_dir . "logs";
unless (-d $logdir){
    `mkdir $logdir`;}
unless (-d $stats_dir){
    `mkdir $stats_dir`;}
$input_files = $ARGV[2];
$temp_file = "$stats_dir/temp";
@t = glob ("$temp_file*$study");
if (@t > 0){
    `rm $temp_file*$study`;
}

$jobname = "numreads";
$logname = "$logdir/$study.numreads";
@l = glob ("$logname*");
if (@l > 0){
    `rm $logname*`;
}

open(INFILE, $input_files) or die "cannot find file '$input_files'\n";
$i = 0;
while($line = <INFILE>){
    chomp($line);
    unless (-e $line){
	die "ERROR: cannot find \"$line\"\n";
    }
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    if ($gz eq "true"){
	`echo "zcat $line | wc -l | xargs echo -n >> $temp_file.$i.$study && echo -e '\t$line' >> $temp_file.$i.$study" | $submit $request_memory_option$mem $jobname_option $jobname -e $logname.$i.err -o $logname.$i.out`;
    }
    else {
	`echo "wc -l < $line | xargs echo -n >> $temp_file.$i.$study && echo -e '\t$line' >> $temp_file.$i.$study" | $submit $request_memory_option$mem $jobname_option $jobname -e $logname.$i.err -o $logname.$i.out`;
    }
    $i++;
}
close(INFILE);

$outfile_final = "$stats_dir/total_num_reads.txt";
while (qx{$status | grep $jobname | wc -l} > 0){
    sleep(10);
}
if (qx{cat $logname.*.err | wc -l} > 0){
    die "ERROR: wc -l step had errors\n";
}

open(DIRS, $sample_dirs) or die "cannot find file '$sample_dirs'\n";
open(OUTFINAL, ">$outfile_final");
while($dir = <DIRS>){
    chomp($dir);
    $id = $dir;
    $total_num_reads = `grep -w $id $temp_file.*.$study`;
    @fields = split(" ", $total_num_reads);
    $first = $fields[0];
    @a = split(":", $first);
    $num = $a[1];
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
