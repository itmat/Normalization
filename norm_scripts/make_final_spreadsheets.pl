if(@ARGV<2) {
    die "usage: perl make_final_spreadsheets.pl <sample dirs> <loc> [options]

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the sample directories.

options:
 -u  :  set this if you want to return only unique, otherwise by default
         it will use merged files and return min and max files.

 -nu :  set this if you want to return only non-unique, otherwise by default
         it will use merged files and return min and max files.

";
}

$U = "true";
$NU = "true";
$numargs = 0;
$option_found = "false";
for($i=2; $i<@ARGV; $i++) {
    $option_found = "false";
    if($ARGV[$i] eq '-nu') {
        $U = "false";
        $option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
        $numargs++;
        $option_found = "true";
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs > 1) {
    die "you cannot specify both -u and -nu, it will use merged files and return min and max files by default so if that's what you want don't use either arg -u or -nu.
";
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/\/make_final_spreadsheets.pl//;
$LOC = $ARGV[1];
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
$norm_dir = $study_dir . "NORMALIZED_DATA";
$FILE = $ARGV[0];

if ($option_found eq "false"){
    $sh_exon = "$shdir/exonquants2spreadsheet_min_max.sh";
    open(OUTexon, ">$sh_exon");
    print OUTexon "perl $path/quants2spreadsheet_min_max.pl $FILE $LOC exonquants";
    close(OUTexon);
    $sh_intron = "$shdir/intronquants2spreadsheet_min_max.sh";
    open(OUTintron, ">$sh_intron");
    print OUTintron "perl $path/quants2spreadsheet_min_max.pl $FILE $LOC intronquants";
    close(OUTintron);
    $sh_junctions = "$shdir/juncs2spreadsheet_min_max.sh";
    open(OUTjunctions, ">$sh_junctions");
    print OUTjunctions "perl $path/juncs2spreadsheet_min_max.pl $FILE $LOC";
    (OUTjunctions);
    `bsub -q max_mem30 -o $logdir/exonquants2spreadsheet_min_max.out -e $logdir/exonquants2spreadsheet_min_max.err sh $sh_exon`;
    `bsub -q max_mem30 -o $logdir/intronquants2spreadsheet_min_max.out -e $logdir/intronquants2spreadsheet_min_max.err sh $sh_intron`;
    `bsub -q plus -o $logdir/juncs2spreadsheet_min_max.out -e $logdir/juncs2spreadsheet_min_max.err sh $sh_junctions`;
}
else{
    if ($U eq "true"){
	$sh_exon = "$shdir/exonquants2spreadsheet.u.sh";
	open(OUTexon, ">$sh_exon");
	print OUTexon "perl $path/quants2spreadsheet.1.pl $FILE $LOC exonquants";
	close(OUTexon);
	$sh_intron = "$shdir/intronquants2spreadsheet.u.sh";
	open(OUTintron, ">$sh_intron");
	print OUTintron "perl $path/quants2spreadsheet.1.pl $FILE $LOC intronquants";
	close(OUTintron);
	$sh_junctions = "$shdir/juncs2spreadsheet.u.sh";
	open(OUTjunctions, ">$sh_junctions");
	print OUTjunctions "perl $path/juncs2spreadsheet.1.pl $FILE $LOC";
	(OUTjunctions);
	`bsub -q max_mem30 -o $logdir/exonquants2spreadsheet.u.out -e $logdir/exonquants2spreadsheet.u.err sh $sh_exon`;
	`bsub -q max_mem30 -o $logdir/intronquants2spreadsheet.u.out -e $logdir/intronquants2spreadsheet.u.err sh $sh_intron`;
	`bsub -q plus -o $logdir/juncs2spreadsheet.u.out -e $logdir/juncs2spreadsheet.u.err sh $sh_junctions`;
    }
    if ($NU eq "true"){
        $sh_exon = "$shdir/exonquants2spreadsheet.nu.sh";
        open(OUTexon, ">$sh_exon");
        print OUTexon "perl $path/quants2spreadsheet.1.pl $FILE $LOC exonquants -NU";
        close(OUTexon);
        $sh_intron = "$shdir/intronquants2spreadsheet.nu.sh";
        open(OUTintron, ">$sh_intron");
        print OUTintron "perl $path/quants2spreadsheet.1.pl $FILE $LOC intronquants -NU";
        close(OUTintron);
        $sh_junctions = "$shdir/juncs2spreadsheet.nu.sh";
        open(OUTjunctions, ">$sh_junctions");
        print OUTjunctions "perl $path/juncs2spreadsheet.1.pl $FILE $LOC -NU";
        (OUTjunctions);
        `bsub -q max_mem30 -o $logdir/exonquants2spreadsheet.nu.out -e $logdir/exonquants2spreadsheet.nu.err sh $sh_exon`;
        `bsub -q max_mem30 -o $logdir/intronquants2spreadsheet.nu.out -e $logdir/intronquants2spreadsheet.nu.err sh $sh_intron`;
        `bsub -q plus -o $logdir/juncs2spreadsheet.nu.out -e $logdir/juncs2spreadsheet.nu.err sh $sh_junctions`;
    }
}
