#!/usr/bin/env perl
use warnings;
use strict;
my $USAGE = "\nUsage: runall_sam2cov.pl <sample dirs> <loc> <fai file> <sam2cov> [options]

<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<fai file> fai file (full path)
<sam2cov> is full path of sam2cov

***Sam files produced by aligners other than STAR and RUM are currently not supported***

option:  
 -str : set this if your library is strand-specific

 -rum  :  set this if you used RUM to align your reads 

 -star  : set this if you used STAR to align your reads 

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>,<jobname_option>,<request_memory_option>,<queue_name_for_15G>,<status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_15G> : is queue name for 15G (e.g. max_mem30, 15G)
        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 15G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -h : print usage

";
if (@ARGV<4){
  die $USAGE;
}

my $numargs_a = 0;
my $status;
my $star = "false";
my $strand = "false";
my $rum = "false";
my $njobs = 200;
my $replace_mem = "false";
my $numargs = 0;
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $new_mem;
for (my $i=4; $i<@ARGV; $i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if($ARGV[$i] eq '-str') {
        $strand = "true";
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-star'){
        $star = "true";
        $numargs_a++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-rum'){
        $rum = "true";
        $numargs_a++;
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
            die "please provide \"<submit>, <jobname_option>, and <request_memory_option> <queue_name_for_15G>,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option> ,<request_memory_option> ,<queue_name_for_15G>,<status>\".\n";
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
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>,<request_memory_option>,<queue_name_for_15G>,<status>\".\n
";
}

if ($replace_mem eq "true"){
    $mem = $new_mem;
}

if($numargs_a ne '1'){
    die "you have to specify which aligner was used to align your reads. sam2cov only works with sam files aligned with STAR or RUM\n
";
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
my $norm_dir = $study_dir . "NORMALIZED_DATA/EXON_INTRON_JUNCTION/";
my $cov_dir = $norm_dir . "/COV";
unless (-d $cov_dir){
    `mkdir $cov_dir`;
}
my $finalsam_dir = "$norm_dir/FINAL_SAM";
my $final_M_dir = "$finalsam_dir/merged";
my $fai_file = $ARGV[2]; # fai file
my $sam2cov = $ARGV[3];

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; # dirnames
while(my $line =  <INFILE>){
    chomp($line);
    my $dir = $line;
    my $id = $dir;
    my $filename = "$final_M_dir/$id.merged.sam";
    my $prefix = "$cov_dir/$id.norm.sam";
    my $prefix_fwd = $prefix;
    my $prefix_rev = $prefix;
    $prefix =~ s/norm.sam//;
    if ($strand eq "true"){
	$prefix_fwd =~ s/norm.sam/fwd./g;
	$prefix_rev =~ s/norm.sam/rev./g;
    }
    my $shfile = "C.$id.sam2cov.sh";
    my $jobname = "$study.sam2cov";
    my $logname = "$logdir/sam2cov.$id";
    my ($shfile_fwd, $shfile_rev, $logname_fwd, $logname_rev);
    if ($strand eq "true"){
	$shfile_fwd = "C.$id.sam2cov.fwd.sh";
	$shfile_rev = "C.$id.sam2cov.rev.sh";
	$logname_fwd = "$logdir/sam2cov.fwd.$id";
	$logname_rev = "$logdir/sam2cov.rev.$id";
    }
    if ($strand eq "false"){
	open(OUTFILE, ">$shdir/$shfile");
	if ($rum eq 'true'){
	    print OUTFILE "$sam2cov -r 1 -e 0 -u -p $prefix $fai_file $filename"; 
	}
	if ($star eq 'true'){
	    print OUTFILE "$sam2cov -u -e 0 -p $prefix $fai_file $filename"; 
	}
	close(OUTFILE);
	while (qx{$status | wc -l} > $njobs){
	    sleep(10);
	}
	`$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shdir/$shfile`;
    }
    if ($strand eq "true"){
	open(OUTFILEF, ">$shdir/$shfile_fwd");
	if ($rum eq 'true'){
	    print OUTFILEF "$sam2cov -r 1 -e 0 -s 1 -u -p $prefix_fwd $fai_file $filename"; 
	}
	if ($star eq 'true'){
	    print OUTFILEF "$sam2cov -u -e 0 -s 1 -p $prefix_fwd $fai_file $filename"; 
	}
	close(OUTFILEF);
	open(OUTFILER, ">$shdir/$shfile_rev");
	if ($rum eq 'true'){
	    print OUTFILER "$sam2cov -r 1 -e 0 -s 2 -u -p $prefix_rev $fai_file $filename"; 
	}
	if ($star eq 'true'){
	    print OUTFILER "$sam2cov -u -e 0 -s 2 -p $prefix_rev $fai_file $filename"; 
	}
	close(OUTFILER);
	while (qx{$status | wc -l} > $njobs){
	    sleep(10);
	}
	`$submit $jobname_option $jobname $request_memory_option$mem -o $logname_fwd.out -e $logname_fwd.err < $shdir/$shfile_fwd`;
	while (qx{$status | wc -l} > $njobs){
	    sleep(10);
	}
	`$submit $jobname_option $jobname $request_memory_option$mem -o $logname_rev.out -e $logname_rev.err < $shdir/$shfile_rev`;
    }
}
close(INFILE);
print "got here\n";

