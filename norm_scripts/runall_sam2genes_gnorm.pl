#!/usr/bin/env perl
use strict;
use warnings;
my $USAGE = "\nUsage: perl runall_sam2genes_gnorm.pl <sample dirs> <loc> <ensGene file> 
 
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<ensGene file> ensembl table must contain columns with the following suffixes: name, chrom, strand, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value

option:
 -se :  set this if the data are single end, otherwise by default it will assume it's a paired end data.

 -str_f : set this if the data are strand-specific AND forward read is in the same orientation as the transcripts/genes.
 
 -str_r : set this if the data are strand-specific AND reverse read is in the same orientation as the transcripts/genes.

 -u  :  set this if you are using unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -nu  :  set this if you are using non-unique mappers only.
        otherwise by default it will use both unique and non-unique mappers.

 -norm <s> : set this to get genes file for the gene-normalized sam files.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\":
         set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
         **make sure the arguments are comma separated inside the quotes**

         <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
         <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
         <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -M, -l h_vmem=)
         <queue_name_for_3G> : is queue name for 3G (e.g. 3072, 3G)
         <status> : command for checking batch job status (e.g. bjobs, qstat)

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 3G

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted. 
                   by default it will submit 200 jobs at a time.

 -samtools <samtools>

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
my $request_memory_option = "";
my $mem = "";
my $status;
my $se = "";
my $stranded = "false";
my $orientation = "";
my $str_args = 0;
my $replace_mem = "false";
my $new_mem = "";
my $normdir = "";
my $cat = "zcat";
my $samtools = "";
for (my $i=0;$i<@ARGV;$i++){
    if ($ARGV[$i] eq '-h'){
        die $USAGE;
    }
}
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
    if ($ARGV[$i] eq '-samtools'){
	$option_found = "true";
	$samtools = $ARGV[$i+1];
	$i++;
	unless (-e $samtools){
	    die "$samtools does not exist\n";
	}
    }
    if ($ARGV[$i] eq "-norm"){
	$norm = "true";
	$U = "false";
	$NU = "false";
	$option_found = "true";
	$normdir = $ARGV[$i+1];
	$i++;
	$cat = "cat";
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
    if ($ARGV[$i] eq '-lsf'){
        $numargs++;
        $option_found = "true";
        $submit = "bsub";
        $jobname_option = "-J";
	$request_memory_option = "-M";
	$mem = "3072";
	$status = "bjobs";
    }
    if ($ARGV[$i] eq '-sge'){
        $numargs++;
        $option_found = "true";
        $submit = "qsub -cwd";
        $jobname_option = "-N";
	$request_memory_option = "-l h_vmem=";
	$mem = "3G";
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
	if ($submit eq "-mem" | $submit eq "" | $jobname_option eq "" | $request_memory_option eq "" | $mem eq ""| $status eq ""){
	    die "please provide \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\"\n";
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
    if($option_found eq 'false') {
	die "option \"$ARGV[$i]\" not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_3G>, <status>\".\n
";
}
if($numargs_u_nu > 1) {
    die "you cannot use both -u and -nu\n.
";
}
if ($stranded eq "true"){
    if ($str_args ne '1'){
	die "please specify read orientation of stranded data: -str_f or -str_r\n";
    }
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
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
my $gnormdir = "$normdir/GENE/FINAL_SAM";
open(IN, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; # dirnames;
while(my $line = <IN>){
    chomp($line);
    my $id = $line;
    my ($filename_a, $shfile_a, $logname_a, $filedir_a);
    my $genedir = "$LOC/$id/GNORM";
    my $filedir_u = "$genedir/Unique/";
    my $filedir_nu = "$genedir/NU/";
    my $filename_u = "$genedir/Unique/$id.filtered_u.sam.gz";
    my $filename_nu = "$genedir/NU/$id.filtered_nu.sam.gz";
    my $shfile_u = "$shdir/G.$id.sam2genes_gnorm_u.sh";
    my $logname_u = "$logdir/sam2genes_gnorm_u.$id";
    my $shfile_nu = "$shdir/G.$id.sam2genes_gnorm_nu.sh";
    my $logname_nu = "$logdir/sam2genes_gnorm_nu.$id";
    my $filedir = "$gnormdir/";
    my $filename = "$gnormdir/$id.gene.norm.sam";
    my $shfile = "$shdir/G.$id.sam2genes_gnorm2.sh";
    my $logname = "$logdir/sam2genes_gnorm2.$id";
    if ($stranded eq "true"){
	$filedir = "$gnormdir/sense/";
	$filedir_a = "$gnormdir/antisense/";
	$filename = "$gnormdir/sense/$id.gene.norm.sam";
	$shfile = "$shdir/G.$id.sam2genes_gnorm2.sense.sh";
	$logname = "$logdir/sam2genes_gnorm2.sense.$id";
	$filename_a = "$gnormdir/antisense/$id.gene.norm.sam";
	$shfile_a = "$shdir/G.$id.sam2genes_gnorm2.antisense.sh";
	$logname_a = "$logdir/sam2genes_gnorm2.antisense.$id";
    }
    my $jobname = "$study.sam2genes_gnorm";

    if ($U eq "true"){
	unless (-e $filename_u){
	    die "ERROR: $filename_u does not exist\n";
	}
	my @check = glob("$filedir_u/sam2genes_temp.*");
	if (@check > 0){
	    `rm $filedir_u/sam2genes_temp.*`;
	}
	my $x = `$cat $filename_u | split -l 5000000 - $filedir_u/sam2genes_temp.`;
	my $temp_prefix = "$filedir_u/sam2genes_temp.";
	my @list = glob("$temp_prefix*");
	foreach my $infile (@list){
	    my @x = split(/\./, $infile);
	    my $index = $x[@x-1];
	    my $outfile = $infile . ".txt.gz";
	    my $sh = $shfile_u;
	    $sh =~ s/.sh$/.$index.sh/;
	    open(OUT, ">$sh");
	    print OUT "perl $path/sam2genes.pl $infile $ens_file $outfile $se $orientation\n";
	    close(OUT);
	    while (qx{$status | wc -l} > $njobs){
		sleep(10);
	    }
	    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname_u.$index.out -e $logname_u.$index.err < $sh`;
	    sleep(2);
	}
    }
    if ($NU eq "true"){
	unless (-e $filename_nu){
	    die "ERROR: $filename_nu does not exist\n";
	}
	my @check = glob("$filedir_nu/sam2genes_temp.*");
	if (@check > 0){
            `rm $filedir_nu/sam2genes_temp.*`;
	}
	my $x = `$cat $filename_nu | split -l 5000000 - $filedir_nu/sam2genes_temp.`;
	my $temp_prefix = "$filedir_nu/sam2genes_temp.";
	my @list = glob("$temp_prefix*");
        foreach my $infile (@list){
            my @x = split(/\./, $infile);
            my $index = $x[@x-1];
            my $outfile = $infile . ".txt.gz";
	    my $sh = $shfile_nu;
	    $sh =~ s/.sh$/.$index.sh/;
	    open(OUT, ">$sh");
	    print OUT "perl $path/sam2genes.pl $infile $ens_file $outfile $se $orientation\n";
	    close(OUT);
	    while (qx{$status | wc -l} > $njobs){
		sleep(10);
	    }
	    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname_nu.$index.out -e $logname_nu.$index.err < $sh`;
	    sleep(2);
	}
    }
    if ($norm eq "true"){
	unless (-e $filename){
	    my $bam = $filename;
	    $bam =~ s/.sam$/.bam/;
	    if (-e $bam){
		my $x = `$samtools view -h $bam > $filename`;
	    }
	    else{
		die "ERROR: $filename does not exist\n";
	    }
	}
	my @check = glob("$filedir/$id.sam2genes_temp.*");
	if (@check > 0){
            `rm $filedir/$id.sam2genes_temp.*`;
	}
	my $x = `$cat $filename | split -l 2500000 - $filedir/$id.sam2genes_temp.`;
	my $temp_prefix = "$filedir/$id.sam2genes_temp.";
        my @list = glob("$temp_prefix*");
        foreach my $infile (@list){
            my @x = split(/\./, $infile);
            my $index = $x[@x-1];
	    my $outfile = $infile . ".txt.gz";
	    my $sh = $shfile;
	    $sh =~ s/.sh$/.$index.sh/;
	    open(OUT, ">$sh");
	    print OUT "perl $path/sam2genes.pl $infile $ens_file $outfile $se $orientation\n";
	    close(OUT);
	    while (qx{$status | wc -l} > $njobs){
		sleep(10);
	    }
	    `$submit $request_memory_option$mem $jobname_option $jobname -o $logname.$index.out -e $logname.$index.err < $sh`;
	    sleep(2);
	}
	if ($stranded eq "true"){
	    unless (-e $filename_a){
		my $bam = $filename_a;
		$bam =~ s/.sam$/.bam/;
		if (-e $bam){
		    my $x = `$samtools view -h $bam > $filename_a`;
		}
		else{
		    die "ERROR: $filename_a does not exist\n";
		}
	    }
	    my @check = glob("$filedir_a/$id.sam2genes_temp.*");
	    if (@check > 0){
		`rm $filedir_a/$id.sam2genes_temp.*`;
	    }
	    my $x = `$cat $filename_a | split -l 2500000 - $filedir_a/$id.sam2genes_temp.`;
	    my $temp_prefix = "$filedir_a/$id.sam2genes_temp.";
	    my @list = glob("$temp_prefix*");
	    foreach my $infile (@list){
		my @x = split(/\./, $infile);
		my $index = $x[@x-1];
		my $outfile = $infile . ".txt.gz";
		my $sh = $shfile_a;
		$sh =~ s/.sh$/.$index.sh/;
		open(OUT, ">$sh");
		print OUT "perl $path/sam2genes.pl $infile $ens_file $outfile $se $orientation\n";
		close(OUT);
		while (qx{$status | wc -l} > $njobs){
		    sleep(10);
		}
		`$submit $request_memory_option$mem $jobname_option $jobname -o $logname_a.$index.out -e $logname_a.$index.err < $sh`;
		sleep(2);
	    }
	}
    }
}
close(IN);
print "got here\n";

