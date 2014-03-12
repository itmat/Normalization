if(@ARGV<5) {
    die "Usage: perl runall_get_high_expressors.pl <sample dirs> <loc> <cutoff> <annotation file> <exons>[options]

where:
<sample dir> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<cutoff> cutoff %
<annotation file> should be downloaded from UCSC known-gene track including
 at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, 
 spDisease, protein and gene fields from the Linked Tables table.
<exons> master list of exons file

option:
  -u  :  set this if you want to return only unique exonpercents, otherwise by default
         it will return both unique and non-unique exonpercents.

  -nu :  set this if you want to return only non-unique exonpercents, otherwise by default
         it will return both unique and non-unique exonpercents.

 -bsub : set this if you want to submit batch jobs to LSF.

 -qsub : set this if you want to submit batch jobs to Sun Grid Engine.

";
}
use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/runall_get_high_expressors.pl//;

$bsub = "false";
$qsub = "false";
$U = "true";
$NU = "true";
$numargs = 0;
$numargs_2 = 0;
for($i=5; $i<@ARGV; $i++) {
    $option_found = 'false';
    if ($ARGV[$i] eq '-bsub'){
	$bsub = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-qsub'){
	$qsub = "true";
	$numargs++;
	$option_found = "true";
    }
    if($ARGV[$i] eq '-nu') {
        $U = "false";
        $option_found = "true";
        $numargs_2++;
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
        $numargs_2++;
        $option_found = "true";
    }
    if($option_found eq 'false') {
        die "arg \"$ARGV[$i]\" not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose either -bsub or -qsub.\n
";
}
if($numargs_2 > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";

unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

$cutoff = $ARGV[2];

if ($cutoff !~ /(\d+$)/){
    die "ERROR: <cutoff> needs to be a number\n";
}
else{
    if (0 > $cutoff | 100 < $cutoff){
	die "ERROR: <cutoff> needs to be a number between 0-100\n";
    }
}

$annot_file = $ARGV[3];
$exons = $ARGV[4];
$annotated_exons = $exons;
$annotated_exons =~ s/master_list/annotated_master_list/;
$master_sh = "$shdir/annotate_master_list_of_exons.sh";
open(OUTFILE, ">$master_sh");
print OUTFILE "perl $path/annotate.pl $annot_file $exons > $annotated_exons\n";
close(OUTFILE);
if($bsub eq "true"){
    `bsub -q max_mem30 -o $logdir/masterexon.annotate.out -e $logdir/masterexon.annotate.err sh $master_sh`;
}
if ($qsub eq "true"){
    `qsub -cwd -N masterexon.annotate -o $logdir -e $logdir -l h_vmem=6G $master_sh`;
}

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while($line = <INFILE>){
    chomp($line);
    $id = $line;
    $id =~ s/Sample_//;
    $sampledir = "$LOC/$line";
    $outfile = "$LOC/$line/$id.exonpercents.txt";
    $highfile = "$LOC/$line/$id.high_expressors.txt";
    $annotated = "$LOC/$line/$id.high_expressors_annot.txt";
    $shfile = "$shdir/$id.highexpressor.annotate.sh";
    open(OUT, ">$shfile");
    if ($numargs_2 eq "0"){
	print OUT "perl $path/get_exonpercents.pl $sampledir $cutoff $outfile\n";
    }
    else { 
	if ($U eq "true"){
	    print OUT "perl $path/get_exonpercents.pl $sampledir $cutoff $outfile -u \n";
	}
	if ($NU eq "true"){
	    print OUT "perl $path/get_exonpercents.pl $sampledir $cutoff $outfile -nu \n";
	}
    }
    print OUT "perl $path/annotate.pl $annot_file $highfile > $annotated\n";
    print OUT "rm $highfile";
    close(OUT);
    if ($bsub eq "true"){
	`bsub -q max_mem30 -o $logdir/$id.highexpressor.annotate.out -e $logdir/$id.highexpressor.annotate.err sh $shfile`;
    }
    if ($qsub eq "true"){
	`qsub -cwd -N $line.highexpressor.annotate -o $logdir -e $logdir -l h_vmem=6G $shfile`;
    }
}
close(INFILE);

