#!/usr/bin/env perl
use strict;
use warnings;
my $USAGE = "\nUsage: perl runall_sam2genes_gnorm.pl <sample dirs> <loc> <ensGene file> 
 
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<ensGene file> ensembl table must contain columns with the following suffixes: name, chrom, strand, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value

option:
 -se :  set this if the data is single end, otherwise by default it will assume it's a paired end data.

 -str_f : set this if the data is strand-specific AND forward read is in the same orientation as the transcripts/genes.
 
 -str_r : set this if the data is strand-specific AND reverse read is in the same orientation as the transcripts/genes.

 -u  :  set this if you are using unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -nu  :  set this if you are using non-unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -norm : set this to get genes file for the gene-normalized sam files.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>,<jobname_option>,<status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. 
                   by default it will submit 200 jobs at a time.

 -h : print usage

\n";
if (@ARGV<3){
    die $USAGE;
}

use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_sam2genes_gnorm.pl//;
my $norm = "false";
my $numargs_u_nu = 0;
my $numargs = 0;
my $U = "true";
my $NU = "true";
my $njobs = 200;
my $submit = "";
my $jobname_option = "";
my $status;
my $se = "";
my $stranded = "false";
my $orientation = "";
my $str_args = 0;
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
    if ($ARGV[$i] eq "-se"){
        $se = "-se";
        $option_found = "true";
    }
    if ($ARGV[$i] eq "-str_f"){
	$stranded = "true";
	$orientation = "-str_f";
        $option_found = "true";
	$str_args++;
    }
    if ($ARGV[$i] eq "-str_r"){
	$stranded = "true";
	$orientation = "-str_r";
        $option_found = "true";
	$str_args++;
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
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
	$status = "qstat";
    }
    if ($ARGV[$i] eq '-other'){
        $numargs++;
        $option_found = "true";
	my $argv_all = $ARGV[$i+1];
        my @a = split(",", $argv_all);
        $submit = $a[0];
        $jobname_option = $a[1];
	$status = $a[2];
        $i++;
        if ($submit eq "-max_jobs" | $submit eq "" | $jobname_option eq "" |  $status eq ""){
            die "please provide \"<submit>, <jobname_option>,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option> ,<status>\".\n";
        }
    }
    if($option_found eq 'false') {
	die "option \"$ARGV[$i]\" not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>,<status>\".\n
";
}
if($numargs_u_nu > 1) {
    die "you cannot use both -u and -nu\n.
";
}
if ($stranded eq "true"){
    if ($str_args ne '1'){
	die "please specify read orientation of stranded data: -str_f or -str-r\n";
    }
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
my $ens_file = $ARGV[2];
my $gnormdir = $study_dir . "NORMALIZED_DATA/GENE/FINAL_SAM";
my $NORM_M = "false";
open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; # dirnames;
while(my $line = <IN>){
    chomp($line);
    my $id = $line;
    my ($filename_u, $filename_nu, $shfile_u, $shfile_nu, $logname_u, $logname_nu, $filename, $shfile, $logname);
    my ($filename_a, $shfile_a, $logname_a);
    my $genedir = "$LOC/$id/GNORM";
    if ($norm eq "false"){
	$filename_u = "$genedir/Unique/$id.filtered_u.sam";
	$filename_nu = "$genedir/NU/$id.filtered_nu.sam";
	$shfile_u = "$shdir/G.$id.sam2genes_gnorm_u.sh";
	$logname_u = "$logdir/sam2genes_gnorm_u.$id";
	$shfile_nu = "$shdir/G.$id.sam2genes_gnorm_nu.sh";
	$logname_nu = "$logdir/sam2genes_gnorm_nu.$id";
    }
    if ($norm eq "true"){
	$U = "false";
	$NU = "false";
	$NORM_M = "true";
	if ($stranded eq "false"){
	    $filename = "$gnormdir/$id.gene.norm.sam";
	    $shfile = "$shdir/G.$id.sam2genes_gnorm2.sh";
	    $logname = "$logdir/sam2genes_gnorm2.$id";
	}
	if ($stranded eq "true"){
	    $filename = "$gnormdir/sense/$id.gene.norm.sam";
            $shfile = "$shdir/G.$id.sam2genes_gnorm2.sense.sh";
            $logname = "$logdir/sam2genes_gnorm2.sense.$id";
	    $filename_a = "$gnormdir/antisense/$id.gene.norm.sam";
            $shfile_a = "$shdir/G.$id.sam2genes_gnorm2.antisense.sh";
            $logname_a = "$logdir/sam2genes_gnorm2.antisense.$id";
	}
    }
    my $jobname = "$study.sam2genes_gnorm";

    if ($U eq "true"){
	my $outname_u = $filename_u;
	$outname_u =~ s/.sam$/.txt/;
	open(OUT, ">$shfile_u");
	print OUT "perl $path/sam2genes.pl $filename_u $ens_file $outname_u $se $orientation\n";
	close(OUT);
	while (qx{$status | wc -l} > $njobs){
	    sleep(10);
	}
	`$submit $jobname_option $jobname -o $logname_u.out -e $logname_u.err < $shfile_u`;
    }
    if ($NU eq "true"){
	my $outname_nu = $filename_nu;
	$outname_nu =~ s/.sam$/.txt/;
	open(OUT, ">$shfile_nu");
	print OUT "perl $path/sam2genes.pl $filename_nu $ens_file $outname_nu $se $orientation\n";
	close(OUT);
	while (qx{$status | wc -l} > $njobs){
	    sleep(10);
	}
	`$submit $jobname_option $jobname -o $logname_nu.out -e $logname_nu.err < $shfile_nu`;
    }
    if ($NORM_M eq "true"){
	my $outname = $filename;
	$outname =~ s/.sam$/.txt/;
	open(OUT, ">$shfile");
	print OUT "perl $path/sam2genes.pl $filename $ens_file $outname $se $orientation\n";
	close(OUT);
	while (qx{$status | wc -l} > $njobs){
	    sleep(10);
	}
	`$submit $jobname_option $jobname -o $logname.out -e $logname.err < $shfile`;
	if ($stranded eq "true"){
	    my $outname_a = $filename_a;
	    $outname_a =~ s/.sam$/.txt/;
	    open(OUT, ">$shfile_a");
	    print OUT "perl $path/sam2genes.pl $filename_a $ens_file $outname_a $se $orientation\n";
	    close(OUT);
	    while (qx{$status | wc -l} > $njobs){
		sleep(10);
	    }
	    `$submit $jobname_option $jobname -o $logname_a.out -e $logname_a.err < $shfile_a`;
	}
    }
}
close(IN);
print "got here\n";

