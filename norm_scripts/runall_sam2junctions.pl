#!/usr/bin/env perl

$USAGE =  "\nUsage: runall_sam2junctions.pl <sample dirs> <loc> <genes> <genome> [options]

where:
<sample dirs> is a file with the names of the sample directories
<loc> is the directory with the sample directories
<genes> is the gene info file (with full path)
<genome> is the genome sequene fasta file (with full path)

option:
 -samfilename <s> : set this to create junctions files using unfiltered aligned samfile.
                    <s> is the name of aligned sam file (e.g. RUM.sam, Aligned.out.sam)
                    and all sam files in each sample directory should have the same name.

 -u  :  set this if you want to return only unique junctions, otherwise by default
         it will return merged(unique+non-unique) junctions.

 -nu :  set this if you want to return only non-unique junctions, otherwise by default
         it will return merged(unique+non-unique) junctions.

 -lsf : set this if you want to submit batch jobs to LSF cluster (PMACS).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI).

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_6G> : is queue name for 6G (e.g. plus, 6G)

        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 6G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -h : print usage

";
if(@ARGV<4) {
    die $USAGE;
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/runall_sam2junctions.pl//;
$U = "true";
$NU = "true";
$numargs = 0;
$samfilename = "false";
$njobs = 200;
$numargs_c = 0;
$replace_mem = "false";
$submit = "";
$jobname_option = "";
$request_memory_option = "";
$mem = "";
for($i=4; $i<@ARGV; $i++) {
    $option_found = "false";
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-samfilename'){
	$option_found = "true";
	$samname = $ARGV[$i+1];
	$i++;
	$samfilename = "true";
    }
    if($ARGV[$i] eq '-nu') {
        $U = "false";
	$numargs++;
        $option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
        $numargs++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-h'){
        $option_found = "true";
	die $USAGE;
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs_c++;
	$option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-q";
        $mem = "plus";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs_c++;
        $option_found = "true";
        $submit = "qsub -cwd";
	$jobname_option = "-N";
	$request_memory_option = "-l h_vmem=";
        $mem = "6G";
	$status = "qstat";
    }
    if ($ARGV[$i] eq '-other'){
	$numargs_c++;
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
            die "please provide \"<submit>, <jobname_option>, and <request_memory_option> <queue_name_for_6G>, <status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_6G>, <status>\".\n";
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
if($numargs > 1) {
    die "you cannot specify both -u and -nu. 
";
}
if($numargs_c ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> <jobname_option> <request_memory_option> <queue_name_for_6G>\".\n";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}

open(INFILE, $ARGV[0]);
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$study = $fields[@fields-2];
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}
$norm_dir = $study_dir . "NORMALIZED_DATA";
$finalsam_dir = "$norm_dir/FINAL_SAM";
$final_U_dir = "$finalsam_dir/Unique";
$final_NU_dir = "$finalsam_dir/NU";
$final_M_dir = "$finalsam_dir/MERGED";
$junctions_dir = "$norm_dir/JUNCTIONS";

$genes = $ARGV[2];
$genome = $ARGV[3];
while($line = <INFILE>) {
    chomp($line);
    $dir = $line;
    $id = $line;
    if ($samfilename eq "true"){
	$final_dir = "$LOC/$dir";
	$filename = $samname;
	$junctions_dir = "$LOC/$dir";
    }
    else {
	unless (-d $junctions_dir){
	    `mkdir $junctions_dir`;
	}
	if ($numargs eq "0"){
	    $final_dir = $final_M_dir;
	    $filename = "$id.FINAL.norm.sam";
	}
	else{
	    if ($U eq "true"){
		$final_dir = $final_U_dir;
		$filename ="$id.FINAL.norm_u.sam";
	    }
	    if ($NU eq "true"){
		$final_dir = $final_NU_dir;
		$filename = "$id.FINAL.norm_nu.sam";
	    }
	}
    }
    $shfile = "$shdir/J" . $id . $filename . ".sh";
    $jobname = "$study.sam2junctions";
    $logname = "$logdir/sam2junctions.$id";
    $outfile1 = $filename;
    $outfile1 =~ s/.sam/_junctions_all.rum/;
    $outfile2 = $filename;
    $outfile2 =~ s/.sam/_junctions_all.bed/;
    $outfile3 = $filename;
    $outfile3 =~ s/.sam/_junctions_hq.bed/;
    open(OUTFILE, ">$shfile");
    print OUTFILE "perl $path/rum-2.0.5_05/bin/make_RUM_junctions_file.pl --genes $genes --sam-in $final_dir/$filename --genome $genome --all-rum-out $junctions_dir/$outfile1 --all-bed-out $junctions_dir/$outfile2 --high-bed-out $junctions_dir/$outfile3 -faok\n";
    close(OUTFILE);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
}
close(INFILE);
print "got here\n";
