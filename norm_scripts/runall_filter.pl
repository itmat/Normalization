if(@ARGV < 3) {
    die "Usage: runall_filter.pl <file of sample dirs> <loc> <sam file name> [options]

option:
  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.  

  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.  

  -bsub : set this if you want to submit batch jobs to LSF.

  -qsub : set this if you want to submit batch jobs to Sun Grid Engine.

<file of sample dirs> without paths
<loc> is the path of the dir with the sample dirs
<sam file name> is the name of sam file

This will remove all rows from <sam infile> except those that satisfy all of the following:
1. Unique mapper / NU mapper
2. Both forward and reverse map consistently
3. id not in (the appropriate) file specified in <more ids>
4. Only on a numbered chromosome, X or Y
5. Is a forward mapper (script outputs forward mappers only)

";
}
use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/runall_filter.pl//;
$sam_name = $ARGV[2];

$U = "true";
$NU = "true";
$bsub = "false";
$qsub = "false";
$numargs_1 = 0;
$numargs_2 = 0;
$option_found = "false";
for($i=3; $i<@ARGV; $i++) {
    $option_found = "false";
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$option_found = "true";
	$numargs_1++;
    }
    if($ARGV[$i] eq '-u') {
	$NU = "false";
	$numargs_1++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-bsub'){
	$bsub = "true";
	$numargs_2++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-qsub'){
	$qsub = "true";
	$numargs_2++;
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs_1 > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

if($numargs_2 ne '1'){
    die "you have to specify how you want to submit batch jobs. choose either -bsub or -qsub.\n
";
}

open(INFILE, $ARGV[0]);  # file of sample dirs (without path)
$LOC = $ARGV[1];  # the location where the sample dirs are
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$size = @fields;
$last_dir = $fields[@size-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

while($line = <INFILE>) {
    chomp($line);
    $dir = $line;
    $id = $line;
    $id =~ s/Sample_//;
    $id =~ s/\//_/g;
    $idsfile = "$LOC/$dir/$id.ribosomalids.txt";
    $shfile = "$shdir/a" . $id . "filter.sh";

    open(OUTFILE, ">$shfile");
    if ($numargs_1 eq "0"){
	print OUTFILE "perl $path/filter_sam.pl $LOC/$dir/$sam_name $LOC/$dir/$id.filtered.sam $idsfile\n";
    }
    else {
	if($U eq "true") {
	    print OUTFILE "perl $path/filter_sam.pl $LOC/$dir/$sam_name $LOC/$dir/$id.filtered.sam $idsfile -u\n";
	}
	if($NU eq "true") {
	    print OUTFILE "perl $path/filter_sam.pl $LOC/$dir/$sam_name $LOC/$dir/$id.filtered.sam $idsfile -nu\n";
	}
    }
    close(OUTFILE);
    if ($bsub eq "true"){
	`bsub -q plus -e $logdir/$id.filtersam.err -o $logdir/$id.filtersam.out sh $shfile`;
    }
    if ($qsub eq "true"){
	`qsub -N $id.filtersam -o $logdir -e $logdir -l h_vmem=4G $shfile`;
    }
}
close(INFILE);
