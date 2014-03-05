if(@ARGV<4) {
    die "usage: runall_quantify_introns.pl <sample dirs> <loc> <introns> <output sam?> [options]

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the dir with the sample dirs
<introns> is the name (with full path) of a file with introns, one per line as chr:start-end
<output sam?> = true if you want it to output two sam files, one of things that map to introns 
 
option:
 -NU-only

";
}
use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/runall_//;

$nuonly = 'false';
for($i=4; $i<@ARGV; $i++) {
    $arg_recognized = 'false';
    if($ARGV[$i] eq '-NU-only') {
        $nuonly = 'true';
        $arg_recognized = 'true';
    }
    if($arg_recognized eq 'false') {
        die "arg \"$ARGV[$i]\" not recognized.\n";
    }
}
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
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

$introns = $ARGV[2];
$outputsam = $ARGV[3];
while($line = <INFILE>) {
    chomp($line);
    $dir = $line;
    $id = $line;
    $id =~ s/Sample_//;
    if($outputsam eq "true"){
	$filename = "$id.filtered_u_notexonmappers.sam";
	if ($nuonly eq "true"){
	    $filename =~ s/u_notexonmappers.sam$/nu_notexonmappers.sam/;
	    $dir = $dir . "/NU";
	}
	if ($nuonly eq "false"){
	    $dir = $dir . "/Unique";
	}
    }
    if($outputsam eq "false"){
	$filename = "$id.intronmappers.norm_u.sam";
	@fields = split("/", $LOC);
        $size = @fields;
        $last_dir = $fields[@size-1];
        $norm_dir = $LOC;
        $norm_dir =~ s/$last_dir//;
        $norm_dir = $norm_dir . "NORMALIZED_DATA";
        $nexon_dir = $norm_dir . "/notexonmappers";
        $unique_nexon_dir = $nexon_dir . "/Unique";
        $nu_nexon_dir = $nexon_dir . "/NU";
	$final_nexon_dir = $unique_nexon_dir;
	if ($nuonly eq "true"){
	    $filename =~ s/norm_u.sam$/norm_nu.sam/;
	    $final_nexon_dir = $nu_nexon_dir;
	}
    }

    $shfile = "IQ" . $filename . ".sh";
    $shfile2 = "IQ" . $filename . ".2.sh";
    $outfile = $filename;
    $outfile =~ s/.sam/_intronquants/;
    if($outputsam eq "true") {
	open(OUTFILE, ">$shdir/$shfile");
	print OUTFILE "perl $path $introns $LOC/$dir/$filename $LOC/$dir/$outfile true\n";
    } else {
	open(OUTFILE, ">$shdir/$shfile2");
	print OUTFILE "perl $path $introns $final_nexon_dir/$filename $final_nexon_dir/$outfile false\n";
    }
    close(OUTFILE);
    if($outputsam eq "true") {
	`bsub -q plus -e $logdir/$id.quantifyintrons.err -o $logdir/$id.quantifyintrons.out sh $shdir/$shfile`;
    }
    else {
	`bsub -q plus -e $logdir/$id.quantifyintrons.err -o $logdir/$id.quantifyintrons.out sh $shdir/$shfile2`;
    }
}
close(INFILE);
