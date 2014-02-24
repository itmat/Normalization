if(@ARGV<4) {
    die "usage: runall_quantify_exons.pl <sample dir> <loc> <exons> <output sam?> [options]

where:
<sample dir> is the name of a file with the names of sample directories (no paths)
<loc> is the path to the dir with the sample directories
<exons> is the name (with full path) of a file with exons, one per line as chr:start-end
<output sam?> is \"true\" or \"false\" depending on whether you want to output the
sam files of exon mappers, etc...

option:
 -NU-only

";
}
use Cwd 'abs_path';
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

$path = abs_path($0);
$path =~ s/runall_//;

unless (-e $ARGV[0]){
    die "ERROR: cannot find file $ARGV[0] \n";}
open(INFILE, $ARGV[0]);  # sample dirs
$LOC = $ARGV[1];
$LOC =~ s/\/$//;
$exons = $ARGV[2];
unless (-e $exons){
    die "ERROR: cannot find file $exons \n";} 
$outputsam = $ARGV[3];
while($line = <INFILE>) {
    chomp($line);
    $dir = $line;
    $id = $line;
    $id =~ s/Sample_//;
    if($outputsam eq "true"){
	$filename = "$id.filtered.sam";
	if ($nuonly eq "true"){
	    $filename =~ s/.sam$/_nu.sam/;
	    $dir = $dir . "/NU";
	}
	if ($nuonly eq "false"){
	    $filename =~ s/.sam$/_u.sam/;
	    $dir = $dir . "/Unique";
	}
    }
    if($outputsam eq "false"){
	$filename = "$id.exonmappers.norm.sam";
	@fields = split("/", $LOC);
	$size = @fields;
	$last_dir = $fields[@size-1];
	$norm_dir = $LOC;
	$norm_dir =~ s/$last_dir//;
	$norm_dir = $norm_dir . "NORMALIZED_DATA";
	$exon_dir = $norm_dir . "/exonmappers";
	$merged_exon_dir = $exon_dir . "/MERGED";
	$unique_exon_dir = $exon_dir . "/Unique";
	$nu_exon_dir = $exon_dir . "/NU";
	if ($nuonly eq "false"){
	    if (-d $merged_exon_dir){
		$final_exon_dir = $merged_exon_dir;
	    }
	    else {
		$final_exon_dir = $unique_exon_dir;
		$filename =~ s/.sam$/_u.sam/;
	    }
	}
	if ($nuonly eq "true"){
	    $final_exon_dir = $nu_exon_dir;
	    $filename =~ s/.sam$/_nu.sam/;
	}
    }

    $shfile = "EQ" . $filename . ".sh";
    $outfile = $filename;
    $outfile =~ s/.sam/_exonquants/;
    $exonsamoutfile = $filename;
    $exonsamoutfile =~ s/.sam/_exonmappers.sam/;
    $intronsamoutfile = $filename;
    $intronsamoutfile =~ s/.sam/_notexonmappers.sam/;
    if($outputsam eq "true") {
	open(OUTFILE, ">$LOC/$dir/$shfile");
		if($nuonly eq 'false') {
		    print OUTFILE "perl $path $exons $LOC/$dir/$filename $LOC/$dir/$outfile $LOC/$dir/$exonsamoutfile $LOC/$dir/$intronsamoutfile\n";
		} else {
		    print OUTFILE "perl $path $exons $LOC/$dir/$filename $LOC/$dir/$outfile $LOC/$dir/$exonsamoutfile $LOC/$dir/$intronsamoutfile -NU-only\n";
		}
    } 
    else {
	open(OUTFILE, ">$final_exon_dir/$shfile");
	if($nuonly eq 'false') {
	    print OUTFILE "perl $path $exons $final_exon_dir/$filename $final_exon_dir/$outfile none none \n";
	}
	else{
	    print OUTFILE "perl $path $exons $final_exon_dir/$filename $final_exon_dir/$outfile none none -NU-only\n";
	}
    }
    close(OUTFILE);
    if($outputsam eq "true") {
	`bsub -q plus -e $LOC/$dir/$id.quantifyexons.err -o $LOC/$dir/$id.quantifyexons.out sh $LOC/$dir/$shfile`;
    }
    if($outputsam eq "false") {
	`bsub -q plus -e $final_exon_dir/$id.quantifyexons.err -o $final_exon_dir/$id.quantifyexons.out sh $final_exon_dir/$shfile`;
    }
}
close(INFILE);
