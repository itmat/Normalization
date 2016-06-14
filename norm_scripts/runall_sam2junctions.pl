#!/usr/bin/env perl
use strict;
use warnings;
my $USAGE =  "\nUsage: runall_sam2junctions.pl <sample dirs> <loc> <genes> <genome> [options]

where:
<sample dirs> is a file with the names of the sample directories
<loc> is the directory with the sample directories
<genes> is the gene info file (with full path)
<genome> is the genome sequene fasta file (with full path)

option:
 -normdir <s>
 -bam <samtools> : bam input
 -samfilename <s> : set this to create junctions files using unfiltered aligned samfile.
                    <s> is the name of aligned sam file (e.g. RUM.sam, Aligned.out.sam)
                    and all sam files in each sample directory should have the same name.

 -gnorm : set this to create junctions files for gene normalization output. 
          (By default, only Exon-Intron-Junction normalization output will be used).

 -stranded : set this if the data are strand-specific. 

 -lsf : set this if you want to submit batch jobs to LSF cluster (PMACS).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI).

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

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -h : print usage

";
if(@ARGV<4) {
    die $USAGE;
}

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_sam2junctions.pl//;
my $samfilename = "false";
my $samname;
my $status;
my $njobs = 200;
my $numargs_c = 0;
my $new_mem ="";
my $replace_mem = "false";
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $gnorm = "false";
my $stranded = "false";
my $b_option = "";
my $normdir = "";
my $ncnt =0;
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for(my $i=4; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-bam'){
	$b_option = "-bam $ARGV[$i+1]";
	$option_found = "true";
	$i++;
    }
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
    if ($ARGV[$i] eq '-gnorm'){
	$option_found = "true";
	$gnorm = "true";
    }
    if ($ARGV[$i] eq '-normdir'){
	$option_found = "true";
	$normdir = $ARGV[$i+1];
	$i++;
	$ncnt++;
    }
    if ($ARGV[$i] eq '-stranded'){
        $option_found = "true";
        $stranded = "true";
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs_c++;
	$option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-M";
        $mem = "6144";
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
        my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
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
if($numargs_c ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> <jobname_option> <request_memory_option> <queue_name_for_6G>\".\n";
}
if ($samfilename eq "false"){
    if ($ncnt ne '1'){
	die "please specify -normdir path\n";
    }
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}

open(INFILE, $ARGV[0]);

my $LOC = $ARGV[1];
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
my $norm_dir = "$normdir/EXON_INTRON_JUNCTION/";
if ($gnorm eq "true"){
    $norm_dir = "$normdir/GENE/";
}
my $finalsam_dir = "$norm_dir/FINAL_SAM";
my $final_M_dir = "$finalsam_dir/merged";
my $junctions_dir = "$norm_dir/JUNCTIONS";

my $genes = $ARGV[2];
my $genome = $ARGV[3];
while(my $line = <INFILE>) {
    chomp($line);
    my $dir = $line;
    my $id = $line;
    my ($final_dir, $filename);
    if ($samfilename eq "true"){
	$final_dir = "$LOC/$dir";
	$filename = $samname;
	$junctions_dir = "$LOC/$dir";
    }
    else {
	$final_dir = $final_M_dir;
	unless (-d $junctions_dir){
	    `mkdir $junctions_dir`;
	}
	$filename = "$id.merged.sam";
	if ($gnorm eq "true"){
	    if ($stranded eq "true"){
		$filename = "$id.merged.sam";
		$final_dir = $final_M_dir;
	    }
	    if ($stranded eq "false"){
		$final_dir = $finalsam_dir;
		$filename = "$id.gene.norm.sam";
	    }
	}
    }
    my $shfile = "$shdir/J" . $id . $filename . ".sh";
    my $jobname = "$study.sam2junctions";
    my $logname = "$logdir/sam2junctions.0.$id";
    if ($samfilename eq "true"){
	$logname = "$logdir/sam2junctions.1.$id";
    }
    if ($gnorm eq "true"){
	$jobname = "$study.sam2junctions_gnorm";
	$logname = "$logdir/sam2junctions_gnorm.$id";
    }
    my $outfile1 = $filename;
    $outfile1 =~ s/.sam$/_junctions_all.rum/i;
    $outfile1 =~ s/.bam$/_junctions_all.rum/i;
    my $outfile2 = $filename;
    $outfile2 =~ s/.sam$/_junctions_all.bed/i;
    $outfile2 =~ s/.bam$/_junctions_all.bed/i;
    my $outfile3 = $filename;
    $outfile3 =~ s/.sam$/_junctions_hq.bed/i;
    $outfile3 =~ s/.bam$/_junctions_hq.bed/i;
    open(OUTFILE, ">$shfile");
    print OUTFILE "perl $path/rum-2.0.5_05/bin/make_RUM_junctions_file.pl --genes $genes --sam-in $final_dir/$filename --genome $genome --all-rum-out $junctions_dir/$outfile1 --all-bed-out $junctions_dir/$outfile2 --high-bed-out $junctions_dir/$outfile3 -faok $b_option\n";
    close(OUTFILE);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
}
close(INFILE);
print "got here\n";
