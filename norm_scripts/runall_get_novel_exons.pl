if(@ARGV<3){
    die "usage: perl runall_get_novel_exons.pl <sample dirs> <loc> <sam file name> [options]

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<sam file name> name of the aligned sam file

options: -min <n> : min is set at 10 by default

         -max <n> : max is set at 2000 by default

";
}

$min = 10;
$max = 2000;

for($i=3; $i<@ARGV; $i++) {
    $argument_recognized = 0;
    if($ARGV[$i] eq '-min') {
	$min = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($ARGV[$i] eq '-max') {
	$max = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($argument_recognized == 0) {
	die "ERROR: command line arugument '$ARGV[$i]' not recognized.\n";
    }
}
use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/runall_get_novel_exons.pl//;

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
#@fields = split("/", $LOC);
#$last_dir = $fields[@fields-1];
#$study_dir = $LOC;
#$study_dir =~ s/$last_dir//;
#$shdir = $study_dir . "shell_scripts";
#$logdir = $study_dir . "logs";
#unless (-d $shdir){
#    `mkdir $shdir`;}
#unless (-d $logdir){
#    `mkdir $logdir`;}

$sam_name = $ARGV[2];
$junc_name = $sam_name;
$junc_name =~ s/.sam/_junctions_all.rum/;
$sorted_junc = $junc_name;
$sorted_junc =~ s/.rum/.sorted.rum/;
$master_list = "$LOC/master_list_of_exons.txt";
$filtered_list = "$LOC/filtered_master_list_of_exons.txt";
$final_list = "$LOC/FINAL_master_list_of_exons.txt";

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while ($line = <INFILE>){
    chomp($line);
    $dir = $line;
    $id = $line;
    $id =~ s/Sample_//;
    $outfile = "$id.list_of_novel_exons.txt";
    `perl $path/rum-2.0.5_05/bin/sort_by_location.pl --skip 1 -o $LOC/$dir/$sorted_junc --location 1 $LOC/$dir/$junc_name`;
    `perl $path/get_novel_exons.pl $LOC/$dir/$sorted_junc $LOC/$dir/$outfile -min $min -max $max`;
    open(IN, "<$LOC/$dir/$outfile") or die "cannot find file '$LOC/$dir/$outfile'\n";
    @exons = <IN>;
    close(IN);
    foreach $exon (@exons){
	chomp($exon);
	$EXON_LIST{$exon} = 1;
    }
}
close(INFILE);

if (-e $master_list){
    open(IN, "<$master_list");
    @exons = <IN>;
    close(IN);
    foreach $exon (@exons){
	chomp($exon);
	$EXON_LIST{$exon} = 1;
    }
}
else{
    die "cannot find the 'master_list_of_exons.txt' file\n";
}

open(OUT, ">$final_list");
foreach $exon (keys %EXON_LIST){
    print OUT "$exon\n";
}
close(OUT);
