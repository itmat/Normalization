if(@ARGV<2) {
    die "usage: runstar_workshop.pl <sample dir> <loc> 

where:
<sample dir> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories

"}

$LOC = $ARGV[1];
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

open(INFILE, $ARGV[0]); #sample directories
while($line = <INFILE>){
    chomp($line);
    $shfile = "$shdir/$line.runstar.sh";
    open(OUT, ">$shfile");
    print OUT "STAR --outFileNamePrefix $LOC/$line/ --genomeDir /opt/rna_seq/data/star_chr1and2/ --outSAMunmapped Within --readFilesIn $LOC/$line/forward_"."$line.fq $LOC/$line/reverse_"."$line.fq\n";
    close(OUT);
    `bsub -o $logdir/$line.star.out -e $logdir/$line.star.err sh $shfile`;
}
close(INFILE); 




