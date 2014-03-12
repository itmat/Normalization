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

 -bsub : set this if you want to submit batch jobs to LSF.

 -qsub : set this if you want to submit batch jobs to Sun Grid Engine.

 -depth <n> : by default, it will output 20 exonmappers

";
}
use Cwd 'abs_path';
$nuonly = 'false';
$bsub = "false";
$qsub = "false";
$numargs = 0;
$i_exon = 20;
for($i=4; $i<@ARGV; $i++) {
    $option_found = 'false';
    if($ARGV[$i] eq '-NU-only') {
	$nuonly = 'true';
	$option_found = 'true';
    }
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
    if ($ARGV[$i] eq '-depth'){
	$i_exon = $ARGV[$i+1];
	$i++;
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

$path = abs_path($0);
$path =~ s/runall_//;

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
	    if (-d $unique_exon_dir){
		$final_exon_dir = $unique_exon_dir;
		$filename =~ s/.sam$/_u.sam/;
	    }
	    else {
		$filename = "$id.filtered.sam";
		$filename =~ s/.sam$/_u.sam/;
		$final_exon_dir = "$LOC/$dir/Unique";
	    }
	}
	if ($nuonly eq "true"){
	    if (-d $nu_exon_dir){
		$final_exon_dir = $nu_exon_dir;
		$filename =~ s/.sam$/_nu.sam/;
	    }
	    else{
		$filename = "$id.filtered.sam";
                $filename =~ s/.sam$/_nu.sam/;
		$final_exon_dir = "$LOC/$dir/NU";
	    }
	}
    }

    $shfile = "EQ" . $filename . ".sh";
    $shfile2 = "EQ" . $filename . ".2.sh";
    $outfile = $filename;
    $outfile =~ s/.sam/_exonquants/;
    $exonsamoutfile = $filename;
    $exonsamoutfile =~ s/.sam/_exonmappers.sam/;
    $intronsamoutfile = $filename;
    $intronsamoutfile =~ s/.sam/_notexonmappers.sam/;
    if($outputsam eq "true") {
	open(OUTFILE, ">$shdir/$shfile");
		if($nuonly eq 'false') {
		    print OUTFILE "perl $path $exons $LOC/$dir/$filename $LOC/$dir/$outfile $LOC/$dir/$exonsamoutfile $LOC/$dir/$intronsamoutfile -depth $i_exon\n";
		} else {
		    print OUTFILE "perl $path $exons $LOC/$dir/$filename $LOC/$dir/$outfile $LOC/$dir/$exonsamoutfile $LOC/$dir/$intronsamoutfile -NU-only -depth $i_exon\n";
		}
    } 
    else {
	open(OUTFILE, ">$shdir/$shfile2");
	if($nuonly eq 'false') {
	    print OUTFILE "perl $path $exons $final_exon_dir/$filename $final_exon_dir/$outfile none none\n";
	}
	else{
	    print OUTFILE "perl $path $exons $final_exon_dir/$filename $final_exon_dir/$outfile none none -NU-only\n";
	}
    }
    close(OUTFILE);
    if($outputsam eq "true") {
	if ($bsub eq "true"){
	    `bsub -q plus -e $logdir/$id.quantifyexons.err -o $logdir/$id.quantifyexons.out sh $shdir/$shfile`;
	}
	if ($qsub eq "true"){
	    `qsub -cwd -N $line.quantifyexons -o $logdir -e $logdir -l h_vmem=4G $shdir/$shfile`;
	}
    }
    if($outputsam eq "false") {
	if ($bsub eq "true"){
	    `bsub -q plus -e $logdir/$id.quantifyexons_2.err -o $logdir/$id.quantifyexons_2.out sh $shdir/$shfile2`;
	}
	if ($qsub eq "true"){
	    `qsub -cwd -N $line.quantifyexons2 -o $logdir -e $logdir -l h_vmem=4G $shdir/$shfile2`;
	}
    }
}
close(INFILE);
