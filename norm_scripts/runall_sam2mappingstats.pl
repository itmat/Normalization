#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE =  "\nUsage: perl runall_sam2mappingstats.pl <sample dir> <loc> <sam file name> <total_num_reads?> [options]

where:
<sample dir> is a file with the names of the sample directories. 
<loc> is the directory with the sample directories
<sam file name> is the name of the sam file 
                (*SAM file must use the IH or NH tags to indicate multi-mappers)
<total_num_reads> if you have the total_num_reads.txt file,
                  use \"true\". If not, use \"false\".

**If you have > 150,000,000 reads, use -mem option to request 45G mem. 
**If you have > 200,000,000 reads, use -mem option to request 60G mem. 

option:  
 -lsf : set this if you want to submit batch jobs to LSF (PMACS cluster).

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI cluster).

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_30G>, <status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -M, -l h_vmem=)
        <queue_name_for_30G> : is queue name for 30G (e.g. 30720, 30G)

        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -bam <samtools>: bam input

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 30G

 -norm : set this if you want to compute mapping statistics for normalized sam files (Unique + NU MERGED)

 -norm_u : set this if you want to compute mapping statistics for normalized sam files (Unique)

 -norm_nu : set this if you want to compute mapping statistics for normalized sam files (NU)

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time.
                   by default, <n> = 200.

 -h : print usage

";
if(@ARGV < 4) {
    die $USAGE;
}

my $njobs = 200;
my $replace_mem = "false";
my $numargs = 0;
my $submit = "";
my $jobname_option = "";
my $request_memory_option = "";
my $mem = "";
my $norm = "false";
my $norm_u = "false";
my $norm_nu = "false";
my $total_reads_file = $ARGV[3];
my $b_option = "";
my $status = "";
my $new_mem = "";
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
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
    if ($ARGV[$i] eq '-bam'){
	$option_found = "true";
	$b_option = "-bam $ARGV[$i+1]";
	$i++;
    }
    if ($ARGV[$i] eq '-norm'){
	$option_found = "true";
	$norm = "true";
	$total_reads_file = "false";
    }
    if ($ARGV[$i] eq '-norm_u'){
	$option_found = "true";
	$norm_u = "true";
	$total_reads_file = "false";
    }
    if ($ARGV[$i] eq '-norm_nu'){
	$option_found = "true";
	$norm_nu = "true";
	$total_reads_file = "false";
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-M";
        $mem = "30720";
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
        if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""|$status eq ""){
            die "please provide \"<submit>,<jobname_option>,<request_memory_option>,<queue_name_for_30G>,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>,<request_memory_option>,<queue_name_for_30G>,<status>\".\n";
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
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other <submit>,<jobname_option>,<request_memory_option>,<queue_name_for_30G>,<status>.\n";
}

if ($replace_mem eq "true"){
    $mem = $new_mem;
}

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/runall_//;
my $sampledirs = $ARGV[0];
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
my $stats_dir = $study_dir . "STATS";
unless (-d $stats_dir){
    `mkdir $stats_dir`;}
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}
my $sam_name = $ARGV[2];

my %DIRS;
open(D, $sampledirs) or die "cannot find file '$sampledirs'\n";
while(my $dir = <D>){
    chomp($dir);
    $DIRS{$dir} = 1;
}
close(D);

if ($total_reads_file eq "true"){
    my $dirs_reads = "$stats_dir/total_num_reads.txt";
    open(INFILE, $dirs_reads) or die "cannot find file '$dirs_reads'\n";
    while(my $line = <INFILE>){
	chomp($line);
	my @fields = split(" ", $line);
	my $size = @fields;
	my $dir = $fields[0];
	my $num_id = $fields[1];
	my $id = $dir;
	if (exists $DIRS{$id}){
	    my $shfile = "$shdir/m." . $id . "runsam2mappingstats.sh";
	    my $jobname = "$study.sam2mappingstats";
	    my $logname = "$logdir/sam2mappingstats.$id";
	    open(OUTFILE, ">$shfile");
	    print OUTFILE "perl $path $LOC/$dir/$sam_name $LOC/$dir/$id.mappingstats.txt -numreads $num_id $b_option\n";
	    close(OUTFILE);
	    while (qx{$status | wc -l} > $njobs){
		sleep(10);
	    }
	    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
	    sleep(2);
	}
    }
}
close(INFILE);


if ($total_reads_file eq "false"){
    open(INFILE, $sampledirs);
    while(my $line = <INFILE>){
	chomp($line);
	my $dir = $line;
	my $id = $dir;
	$id =~ s/\//_/g;
	my ($shfile, $jobname, $logname);
	if ($norm eq "true"){
	    $shfile = "$shdir/sam2mapping.FINALSAM.$id.sh";
	    $jobname = "$study.sam2mappingstats.norm";
	    $logname = "$logdir/sam2mappingstats.norm.$id";
	}
	elsif ($norm_u eq "true"){
	    $shfile = "$shdir/sam2mapping.FINALSAM.u.$id.sh";
	    $jobname = "$study.sam2mappingstats.norm.u";
	    $logname = "$logdir/sam2mappingstats.norm.u.$id";
	}
	elsif ($norm_nu eq "true"){
	    $shfile = "$shdir/sam2mapping.FINALSAM.nu.$id.sh";
	    $jobname = "$study.sam2mappingstats.norm.nu";
	    $logname = "$logdir/sam2mappingstats.norm.nu.$id";
	}
	else{
	    $shfile = "$shdir/m." . $id . "runsam2mappingstats.sh";
	    $jobname = "$study.sam2mappingstats";
	    $logname = "$logdir/sam2mappingstats.$id";
	}
	open(OUTFILE, ">$shfile");
	if ($norm eq "true"){
	    print OUTFILE "perl $path $study_dir/NORMALIZED_DATA/EXON_INTRON_JUNCTION/FINAL_SAM/MERGED/$id.FINAL.norm.sam $study_dir/NORMALIZED_DATA/EXON_INTRON_JUNCTION/FINAL_SAM/MERGED/$id.FINAL.norm.mappingstats.txt $b_option";
	}
	elsif ($norm_u eq "true"){
	    print OUTFILE "perl $path $study_dir/NORMALIZED_DATA/EXON_INTRON_JUNCTION/FINAL_SAM/Unique/$id.FINAL.norm_u.sam $study_dir/NORMALIZED_DATA/EXON_INTRON_JUNCTION/FINAL_SAM/Unique/$id.FINAL.norm_u.mappingstats.txt $b_option";
	}
	elsif ($norm_nu eq "true"){
	    print OUTFILE "perl $path $study_dir/NORMALIZED_DATA/EXON_INTRON_JUNCTION/FINAL_SAM/NU/$id.FINAL.norm_nu.sam $study_dir/NORMALIZED_DATA/EXON_INTRON_JUNCTION/FINAL_SAM/NU/$id.FINAL.norm_nu.mappingstats.txt $b_option";
	}
	else{
	    print OUTFILE "perl $path $LOC/$dir/$sam_name $LOC/$dir/$id.mappingstats.txt $b_option\n";
	}
	close(OUTFILE);
	while (qx{$status | wc -l} > $njobs){
	    sleep(10);
	}
	`$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;
	sleep(2);
    }
}
close(INFILE);
print "got here\n";
