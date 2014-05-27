#!/usr/bin/env perl
if(@ARGV<3) {
    die "Usage: perl get_total_num_reads.pl <sample dirs> <loc> <file of input forward fa/fq files> [options]

<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the location where the sample directories are
<file of input forward fa/fq files> is a file with the names of input forward fa/fq files (full path)

option:  -fa : set this if the input files are in fasta format
         -fq : set this if the input files are in fastq format
         -gz : set this if your input files are compressed

";
}
$fa = "false";
$fq = "false";
$gz = "false";
$numargs = 0;
for ($i=3; $i<@ARGV; $i++){
    $option_found = "false";
    if ($ARGV[$i] eq '-fa'){
	$fa = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-fq'){
	$fq = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-gz'){
	$gz = "true";
	$option_found = "true";
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify an input file type. use either '-fa' or '-fq'\n
";
}

$sample_dirs = $ARGV[0];
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$stats_dir = $study_dir . "STATS";
unless (-d $stats_dir){
    `mkdir $stats_dir`;}
$input_files = $ARGV[2];

open(INFILE, $input_files) or die "cannot find file '$input_files'\n";
$outfile_all = "$LOC/total_reads_temp.txt";
open(OUT, ">$outfile_all");
while($line = <INFILE>){
    chomp($line);
    unless (-e $line){
	die "ERROR: cannot find \"$line\"\n";
    }
    if ($gz eq "true"){
	$lc = `zcat $line | wc -l`;
	$num = $lc;
	$name = $line;
    }
    else {
	$lc = `wc -l $line`;
	@a = split(" ", $lc);
	$num = $a[0];
	$name = $a[1];
    }

    if ($fq eq "true"){
	$num = $num/4;
    }
    if ($fa eq "true"){
	$num = $num/2;
    }
    print OUT "$num\t$name\n";
}
close(INFILE);
close(OUT);

$outfile_final = "$stats_dir/total_num_reads.txt";
open(DIRS, $sample_dirs) or die "cannot find file '$sample_dirs'\n";
open(OUTFINAL, ">$outfile_final");
while($dir = <DIRS>){
    chomp($dir);
    $id = $dir;
    $id =~ s/Sample_//g;
    $total_num_reads = `grep -w $id $outfile_all`;
    @fields = split(" ", $total_num_reads);
    $num = $fields[0];
    print OUTFINAL "$id\t$num\n";
}
close(DIRS);
close(OUTFINAL);
print "got here\n";
`rm $outfile_all`;
