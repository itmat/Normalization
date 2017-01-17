#!/usr/bin/env perl
use warnings;
use strict;
use FindBin qw($Bin);
use lib ("$Bin/pm/lib/perl5");
use Net::OpenSSH;

my $USAGE =  "\nUsage: perl runall_get_high_expressers.pl <sample dirs> <loc> <cutoff> <annotation file> <exons> [options]

where:
<sample dir> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<cutoff> cutoff %
<annotation file> should be downloaded from UCSC known-gene track including
 at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, 
 spDisease, protein and gene fields from the Linked Tables table.
<exons> master list of exons file

option:
 -part2 

 -stranded : set this if your data are strand-specific. 
 
 -nu :  set this if you want to return only non-unique exonpercents/intronpercents, 
        otherwise by default it will return unique exonpercents/intronpercents only.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_15G>, <status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -M, -l h_vmem=)
        <queue_name_for_15G> : is queue name for 15G (e.g. 15360, 15G)

        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 15G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. by default it will submit 200 jobs at a time. (Default <n> = 200)

 -i <n> : index for logname (default: 0)

 -headnode <name> : For clusters which only allows job submissions from the head node, use this option.

 -h : print usage

";
if(@ARGV<5) {
    die $USAGE;
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/runall_get_high_expressers.pl//;
my $strand_info = "";
my $stranded = "false";
my $NU = "false";
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
my $part2 = "false";
my $hn_only = "false";
my $hn_name = "";
my $ssh;

for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
for(my $i=5; $i<@ARGV; $i++) {
    my $option_found = 'false';
    if ($ARGV[$i] eq '-headnode'){
        $option_found = "true";
        $hn_only = "true";
        $hn_name = $ARGV[$i+1];
        $i++;
        $ssh = Net::OpenSSH->new($hn_name,
                                 master_opts => [-o => "StrictHostKeyChecking=no", -o => "BatchMode=yes"]);
    }
    if ($ARGV[$i] eq '-max_jobs'){
        $option_found = "true";
        $njobs = $ARGV[$i+1];
        if ($njobs !~ /(\d+$)/ ){
            die "-max_jobs <n> : <n> needs to be a number\n";
        }
        $i++;
    }
    if ($ARGV[$i] eq '-part2'){
	$option_found = "true";
	$part2 = "true";
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
    if($ARGV[$i] eq '-nu') {
	$NU = "true";
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
        $request_memory_option = "-M";
        $mem = "15360";
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
        if (($submit eq "-mem") || ($submit eq "") || ($jobname_option eq "") || ($request_memory_option eq "") || ($mem eq "") || ($status eq "")){
            die "please provide \"<submit>, <jobname_option>, <request_memory_option> ,<queue_name_for_15G>,<status>\"\n";
        }
        if (($submit eq "-lsf") || ($submit eq "-sge")){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit> ,<jobname_option>, <request_memory_option>, <queue_name_for_15G>,<status>\".\n";
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
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option> ,<request_memory_option>, <queue_name_for_15G>,<status>\".\n";
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

my $cutoff = $ARGV[2];

if ($cutoff !~ /(\d+$)/){
    die "ERROR: <cutoff> needs to be a number\n";
}
else{
    if ((0 > $cutoff) || (100 < $cutoff)){
	die "ERROR: <cutoff> needs to be a number between 0-100\n";
    }
}

my $annot_file = $ARGV[3];
my $exons = $ARGV[4];
unless (-e $exons){
    die "Cannot find $exons file\n";
}
my $exons_to_annot = "$exons.tmp";
my $x = `cut -f 1 $exons > $exons_to_annot`;
my $annotated_exons = $exons;
$annotated_exons =~ s/master_list/annotated_master_list/;
my $master_sh = "$shdir/annotate_master_list_of_exons.sh";
my $master_jobname = "$study.get_high_expresser";
my $master_logname = "$logdir/annotate.$index.master_exon";
open(OUTFILE, ">$master_sh");
print OUTFILE "perl $path/annotate.pl $annot_file $exons_to_annot $annotated_exons\n";
print OUTFILE "rm $exons_to_annot\n";
close(OUTFILE);
while (qx{$status | wc -l} > $njobs){
    sleep(10);
}
$x = "$submit $jobname_option $master_jobname $request_memory_option$mem -o $master_logname.out -e $master_logname.err < $master_sh";
if ($hn_only eq "true"){
    $ssh->system($x) or
	die "remote command failed: " . $ssh->error;
}
else{
    `$x`;
}

my $getscript = "$path/get_exon_intron_percents.pl";
if ($part2 eq "true"){
    $getscript = "$path/get_exon_intron_percents.p2.pl";
}
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while(my $line = <INFILE>){
    chomp($line);
    my $id = $line;
    my $sampledir = "$LOC/$line";
    my $outfile = "$LOC/$line/$id.exonpercents.txt";
    my $outfile_i = "$LOC/$line/$id.intronpercents.txt";
    my $highfile = "$LOC/$line/$id.high_expressers_exon.txt";
    my $highfile_s = "$LOC/$line/$id.high_expressers_exon_sense.txt";
    my $highfile_i = "$LOC/$line/$id.high_expressers_intron.txt";
    my $annotated = "$LOC/$line/$id.high_expressers_exon_annot.txt";
    my $annotated_s = "$LOC/$line/$id.high_expressers_exon_annot_sense.txt";
    my $annotated_i = "$LOC/$line/$id.high_expressers_intron_annot.txt";
    my $shfile = "$shdir/$id.highexpresser.annotate.sh";
    my $jobname = "$study.get_high_expresser";
    my $logname = "$logdir/annotate.$index.highexpresser.$id";
    open(OUT, ">$shfile");
    if ($NU eq "false"){
	print OUT "perl $getscript $sampledir $cutoff $outfile $outfile_i $strand_info\n";
    }
    if ($NU eq "true"){
	print OUT "perl $getscript $sampledir $cutoff $outfile $outfile_i -nu $strand_info\n";
    }
    if ($stranded eq "false"){
	print OUT "perl $path/annotate.pl $annot_file $highfile $annotated\n";
	print OUT "rm $highfile\n";
    }
    if ($stranded eq "true"){
	print OUT "perl $path/annotate.pl $annot_file $highfile_s $annotated_s\n";
	print OUT "rm $highfile_s\n";
    }
    close(OUT);
    while (qx{$status | wc -l} > $njobs){
	sleep(10);
    }
    $x = "$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile";
    if ($hn_only eq "true"){
        $ssh->system($x) or
            die "remote command failed: " . $ssh->error;
    }
    else{
        `$x`;
    }
}
close(INFILE);

print "got here\n";
