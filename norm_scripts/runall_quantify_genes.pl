#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl runall_quantify_genes.pl <sample dirs> <loc> <ensGene file>

<sample dirs> is  a file of sample directories with alignment output wi
thout path
<loc> is where the sample directories are
<ensGene file> ensembl table must contain columns with the following suffixes: name, chrom, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value

option:
 -u  :  set this if your final (normalized) sam files have unique mappers only.
        otherwise by default it will use merged(unique+non-unique) mappers.

 -nu  :  set this if your final (normalized) sam files have non-unique mappers only.
         otherwise by default it will use merged(unique+non-unique) mappers.

 -lsf : set this if you want to submit batch jobs to LSF (PMACS) cluster.

 -sge : set this if you want to submit batch jobs to Sun Grid Engine (PGFI) cluster.

 -other \"<submit>,<jobname_option>,<request_memory_option>, <queue_name_for_10G>,<status>\":
        set this if you're not on LSF (PMACS) or SGE (PGFI) cluster.
        **make sure the arguments are comma separated inside the quotes**

        <submit> : is command for submitting batch jobs from current working directory (e.g. bsub, qsub -cwd)
        <jobname_option> : is option for setting jobname for batch job submission command (e.g. -J, -N)
        <request_memory_option> : is option for requesting resources for batch job submission command
                                  (e.g. -q, -l h_vmem=)
        <queue_name_for_10G> : is queue name for 10G (e.g. max_mem30, 10G)
        <status> : command for checking batch job status (e.g. bjobs, qstat)

 -max_jobs <n>  :  set this if you want to control the number of jobs submitted.
                   by default it will submit 200 jobs at a time.

 -mem <s> : set this if your job requires more memory.
            <s> is the queue name for required mem.
            Default: 10G

 -h : print usage

\n";

if (@ARGV < 3){
    die $USAGE
}
use Cwd 'abs_path';
my $path = abs_path($0);
$path =~ s/\/runall_quantify_genes.pl//;

my $numargs_u_nu = 0;
my $numargs = 0;
my $U = "true";
my $NU = "true";
my $njobs = 200;
my $replace_mem = "false";
my $submit = "";
my $request_memory_option = "";
my $mem = "";
my $new_mem = "";
my $jobname_option = "";
my $status;

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
        $mem = "10G";
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
        if ($submit eq "-max_jobs" | $submit eq "" | $jobname_option eq "" |  $request_memory_option eq "" | $mem eq "" | $status eq ""){
            die "please provide \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_10G> ,<status>\"\n";
        }
        if ($submit eq "-lsf" | $submit eq "-sge"){
            die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>, <jobname_option>, <request_memory_option>, <queue_name_for_10G>,<status>\".\n";
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
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose -lsf, -sge, or -other \"<submit>,<jobname_option>, <request_memory_option>, \
<queue_name_for_10G>,<status>\".\n
";
}
if($numargs_u_nu > 1) {
    die "you cannot specify both -u and -nu\n.
";
}
if ($replace_mem eq "true"){
    $mem = $new_mem;
}


my $samples = $ARGV[0];
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study = $fields[@fields-2];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
my $norm_dir = $study_dir . "NORMALIZED_DATA";
my $finalsam_dir = $norm_dir . "/FINAL_SAM";
my $final_U_dir = "$finalsam_dir/Unique";
my $final_NU_dir = "$finalsam_dir/NU";
my $final_M_dir = "$finalsam_dir/MERGED";
my $ensFile = $ARGV[2];
my (%ID, %GENECHR, %GENEST, %GENEEND);

open(ENS, $ensFile) or die "cannot find file \"$ensFile\"\n";
my $header = <ENS>;
chomp($header);
my @ENSHEADER = split(/\t/, $header);
my ($genenamecol, $genesymbolcol, $txchrcol, $txstartcol, $txendcol);
for(my $i=0; $i<@ENSHEADER; $i++){
    if ($ENSHEADER[$i] =~ /.name2$/){
        $genenamecol = $i;
    }
    if ($ENSHEADER[$i] =~ /.ensemblToGeneName.value$/){
        $genesymbolcol = $i;
    }
    if ($ENSHEADER[$i] =~ /.chrom/){
	$txchrcol = $i;
    }
    if ($ENSHEADER[$i] =~ /.txStart/){
	$txstartcol = $i;
    }
    if ($ENSHEADER[$i] =~ /.txEnd/){
	$txendcol = $i;
    }
}
if (!defined($genenamecol) || !defined($genesymbolcol) || !defined($txchrcol) || !defined($txstartcol)|| !defined($txendcol)){
    die "Your header must contain columns with the following suffixes: chrom, txStart, txEnd, name2, ensemblToGeneName.value\n";
}
while(my $line = <ENS>){
    chomp($line);
    my @a = split(/\t/,$line);
    my $txchr = $a[$txchrcol];
    my $txst = $a[$txstartcol];
    my $txend = $a[$txendcol];
    my $geneid = $a[$genenamecol];
    my $genesym = $a[$genesymbolcol];
    $ID{$geneid}= $genesym;
    $GENECHR{$geneid} = $txchr;
    push (@{$GENEST{$geneid}}, $txst);
    push (@{$GENEEND{$geneid}}, $txend);
}
close(ENS);

my $master_list_of_genes = "$LOC/master_list_of_ensGeneIDs.txt";
open(MAS, ">$master_list_of_genes");
foreach my $key (keys %ID){
    my $chr = $GENECHR{$key};
    my $min_st = &get_min(@{$GENEST{$key}});
    my $max_end = &get_max(@{$GENEEND{$key}});
    print MAS "$key\t$ID{$key}\t$chr:$min_st-$max_end\n";
}
close(MAS);

open(IN, $samples) or die "cannot find file '$samples'\n"; # dirnames;
while(my $line = <IN>){
    chomp($line);
    my $id = $line;
    my ($filename, $outname);
    if ($numargs_u_nu eq '0'){
        $filename = "$final_M_dir/$id.FINAL.norm.genes.txt";
    }
    elsif ($U eq 'true'){
        $filename = "$final_U_dir/$id.FINAL.norm_u.genes.txt";
    }
    elsif ($NU eq 'true'){
        $filename = "$final_NU_dir/$id.FINAL.norm_nu.genes.txt";
    }
    $outname = $filename;
    $outname =~ s/genes.txt/genequants/g;
    my $shfile = "$shdir/GQ.$id.quantifygenes.sh";
    my $jobname = "$study.quantifygenes";
    my $logname = "$logdir/quantifygenes.$id";

    open(OUT, ">$shfile");
    print OUT "perl $path/quantify_genes.pl $filename $master_list_of_genes $outname\n";
    close(OUT);
    while (qx{$status | wc -l} > $njobs){
        sleep(10);
    }
    `$submit $jobname_option $jobname $request_memory_option$mem -o $logname.out -e $logname.err < $shfile`;

}
close(IN);
print "got here\n";

sub get_min(){
    (my @array) = @_;
    my @sorted_array = sort {$a <=> $b} @array;
    return $sorted_array[0];
}

sub get_max(){
    (my @array) = @_;
    my @sorted_array = sort {$a <=> $b} @array;
    return $sorted_array[@sorted_array-1];
}

