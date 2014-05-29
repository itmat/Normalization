#!/usr/bin/env perl

$USAGE = "\nUsage: runall_sam2cov.pl <sample dirs> <loc> <fai file> <sam2cov> [options]

<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<fai file> fai file (full path)
<sam2cov> is full path of sam2cov

***Sam files produced by aligners other than STAR and RUM are currently not supported***

option:  
 -u  :  set this if you want to use only unique mappers to generate coverage files, 
        otherwise by default it will use merged(unique+non-unique) mappers.

 -nu  :  set this if you want to use only non-unique mappers to generate coverage files,
         otherwise by default it will use merged(unique+non-unique) mappers.

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
$numargs_a = 0;
$numargs_u_nu = 0;
$U = "true";
$NU = "true";
$star = "false";
$rum = "false";
$njobs = 200;
$replace_mem = "false";
$numargs = 0;
$submit = "";
$jobname_option = "";
$request_memory_option = "";
$mem = "";
for ($i=4; $i<@ARGV; $i++){
    $option_found = "false";
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
	$numargs_u_nu++;
        $option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
        $numargs_u_nu++;
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
	$argv_all = $ARGV[$i+1];
        @a = split(",", $argv_all);
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

if($numargs_u_nu > 1) {
    die "you cannot specify both -u and -nu\n.
";
}
if($numargs_a ne '1'){
    die "you have to specify which aligner was used to align your reads. sam2cov only works with sam files aligned with STAR or RUM\n
";
}


$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study = $fields[@fields-2];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
$norm_dir = $study_dir . "NORMALIZED_DATA";
$cov_dir = $norm_dir . "/COV";
unless (-d $cov_dir){
    `mkdir $cov_dir`;
}
$finalsam_dir = "$norm_dir/FINAL_SAM";
$final_U_dir = "$finalsam_dir/Unique";
$final_NU_dir = "$finalsam_dir/NU";
$final_M_dir = "$finalsam_dir/MERGED";
$fai_file = $ARGV[2]; # fai file
$sam2cov = $ARGV[3];

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; # dirnames
while($line =  <INFILE>){
    chomp($line);
    $dir = $line;
    $id = $dir;
    if ($numargs_u_nu eq '0'){
	$filename = "$final_M_dir/$id.FINAL.norm.sam";
	unless (-d "$cov_dir/MERGED"){
	    `mkdir "$cov_dir/MERGED"`;
	}
	$prefix = "$cov_dir/MERGED/$id.FINAL.norm.sam";
	$prefix =~ s/norm.sam//;
    }
    else {
	if ($U eq 'true'){
	    $filename = "$final_U_dir/$id.FINAL.norm_u.sam";
	    unless (-d "$cov_dir/Unique"){
		`mkdir "$cov_dir/Unique"`;
	    }
	    $prefix = "$cov_dir/Unique/$id.FINAL.norm_u.sam";
	    $prefix =~ s/norm_u.sam//;
	}
	if ($NU eq 'true'){
	    $filename = "$final_NU_dir/$id.FINAL.norm_nu.sam";
	    unless (-d "$cov_dir/NU"){
		`mkdir "$cov_dir/NU"`;
	    }
	    $prefix = "$cov_dir/NU/$id.FINAL.norm_nu.sam";
	    $prefix =~ s/norm_nu.sam//;
	}
    }
    $shfile = "C.$id.sam2cov.sh";
    $jobname = "$study.sam2cov";
    $logname = "$logdir/sam2cov.$id";
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
close(INFILE);
print "got here\n";

