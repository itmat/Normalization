#!/usr/bin/env perl

$USAGE = "\nUsage: runall_sam2cov_gnorm.pl <sample dirs> <loc> <fai file> <sam2cov> [options]

<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<fai file> fai file (full path)
<sam2cov> is full path of sam2cov

***Sam files produced by aligners other than STAR and RUM are currently not supported***

option:  
 -se : set this if the data are single end, otherwise by default it will assume it's a paired end data.

 -str : set this if your library is strand-specific

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
$strand = "false";
$rum = "false";
$njobs = 200;
$replace_mem = "false";
$numargs = 0;
$submit = "";
$jobname_option = "";
$request_memory_option = "";
$mem = "";
$se = "false";
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
    if ($ARGV[$i] eq "-se"){
	$option_found = "true";
	$se = "true";
    }
    if($ARGV[$i] eq '-str') {
        $strand = "true";
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
$norm_dir = $study_dir . "NORMALIZED_DATA/GENE/";
$cov_dir = $norm_dir . "/COV";
unless (-d $cov_dir){
    `mkdir $cov_dir`;
}
$finalsam_dir = "$norm_dir/FINAL_SAM";
$final_M_dir = "$finalsam_dir/merged";
$fai_file = $ARGV[2]; # fai file
$sam2cov = $ARGV[3];

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; # dirnames
while($line =  <INFILE>){
    chomp($line);
    $dir = $line;
    $id = $dir;
    if ($strand eq "true"){
	$filename = "$final_M_dir/$id.merged.sam";
	$prefix = "$cov_dir/$id.merged.sam";
	$prefix_fwd = $prefix;
	$prefix_rev = $prefix;
	$prefix =~ s/sam$//;
	$prefix_fwd =~ s/sam$/fwd./g;
	$prefix_rev =~ s/sam$/rev./g;
    }
    else {
	if ($numargs_u_nu eq "0"){
	    $filename = "$finalsam_dir/$id.gene.norm.sam";
	    $prefix = "$cov_dir/$id.gene.norm.sam";
	}
	elsif ($U eq "true"){
	    $filename = "$finalsam_dir/$id.gene.norm_u.sam";
	    $prefix = "$cov_dir/$id.gene.norm_u.sam";
	}
	elsif ($NU eq "true"){
	    $filename = "$finalsam_dir/$id.gene.norm_nu.sam";
	    $prefix = "$cov_dir/$id.gene.norm_nu.sam";
	}
	$prefix =~ s/sam$//;
    }
    $shfile = "C.$id.sam2cov_gnorm.sh";
    $jobname = "$study.sam2cov_gnorm";
    $logname = "$logdir/sam2cov_gnorm.$id";
    if ($strand eq "true"){
	$shfile_fwd = "C.$id.sam2cov_gnorm.fwd.sh";
	$shfile_rev = "C.$id.sam2cov_gnorm.rev.sh";
	$logname_fwd = "$logdir/sam2cov_gnorm.fwd.$id";
	$logname_rev = "$logdir/sam2cov_gnorm.rev.$id";
    }
    if ($strand eq "false"){
	open(OUTFILE, ">$shdir/$shfile");
	if ($rum eq 'true'){
	    if ($se eq "true"){
		print OUTFILE "$sam2cov -r 1 -e 0 -u -p $prefix $fai_file $filename"; 
	    }
	    if ($se eq "false"){
		print OUTFILE "$sam2cov -r 1 -e 1 -u -p $prefix $fai_file $filename"; 
	    }
	}
	if ($star eq 'true'){
	    if ($se eq "true"){
		print OUTFILE "$sam2cov -u -e 0 -p $prefix $fai_file $filename"; 
	    }
	    if ($se eq "false"){
		print OUTFILE "$sam2cov -u -e 1 -p $prefix $fai_file $filename"; 
	    }
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
	    if ($se eq "true"){
		print OUTFILEF "$sam2cov -r 1 -e 0 -s 1 -u -p $prefix_fwd $fai_file $filename"; 
	    }
	    if ($se eq "false"){
		print OUTFILEF "$sam2cov -r 1 -e 1 -s 1 -u -p $prefix_fwd $fai_file $filename"; 
	    }
	}
	if ($star eq 'true'){
	    if ($se eq "true"){
		print OUTFILEF "$sam2cov -u -e 0 -s 1 -p $prefix_fwd $fai_file $filename"; 
	    }
	    if ($se eq "false"){
		print OUTFILEF "$sam2cov -u -e 1 -s 1 -p $prefix_fwd $fai_file $filename"; 
	    }
	}
	close(OUTFILEF);
	open(OUTFILER, ">$shdir/$shfile_rev");
	if ($rum eq 'true'){
	    if ($se eq "true"){
		print OUTFILER "$sam2cov -r 1 -e 0 -s 2 -u -p $prefix_rev $fai_file $filename"; 
	    }
	    if ($se eq "false"){
		print OUTFILER "$sam2cov -r 1 -e 1 -s 2 -u -p $prefix_rev $fai_file $filename"; 
	    }
	}
	if ($star eq 'true'){
	    if ($se eq "true"){
		print OUTFILER "$sam2cov -u -e 0 -s 2 -p $prefix_rev $fai_file $filename"; 
	    }
	    if ($se eq "false"){
		print OUTFILER "$sam2cov -u -e 1 -s 2 -p $prefix_rev $fai_file $filename"; 
	    }
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

