if(@ARGV<3) {
    die "usage: perl run_annotate.pl <file of features files> <annotation file> <loc> [options]

where:
<file of features files> is a file with the names of the features files to be annotated
<annotation file> should be downloaded from UCSC known-gene track including
at minimum name, chrom, strand, exonStarts, exonEnds, all kgXref fields and hgnc, spDisease, protein and gene fields from the
Linked Tables table.
<loc> is the path to the sample directories.

option: 
 -bsub : set this if you want to submit batch jobs to LSF.

 -qsub : set this if you want to submit batch jobs to Sun Grid Engine.

";
}
$bsub = "false";
$qsub = "false";
$numargs = 0;
for($i=3; $i<@ARGV; $i++) {
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
    if($option_found eq 'false') {
	die "option \"$ARGV[$i]\" not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose either -bsub or -qsub.\n
";
}
use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/run_annotate.pl//;
$annot_file = $ARGV[1];
$LOC = $ARGV[2];
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
$norm_dir = $study_dir . "NORMALIZED_DATA";

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while ($line = <INFILE>){
    chomp($line);
    $shfile = "$shdir/annotate.$line.sh";
    open(OUT, ">$shfile");
    print OUT "perl $path/annotate.pl $annot_file $norm_dir/$line > $norm_dir/master_$line";
    close(OUT);
    if($bsub eq "true"){
	`bsub -o $logdir/annotate_$line.out -e $logdir/annotate_$line.err sh $shfile`;
    }
    if ($qsub eq "true"){
	`qsub -cwd -N annotate_$line -e $logdir -o $logdir $shfile`;
    }
}
close(INFILE);
