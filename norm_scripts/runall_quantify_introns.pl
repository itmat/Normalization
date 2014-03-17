if(@ARGV<4) {
    die "usage: runall_quantify_introns.pl <sample dirs> <loc> <introns> <output sam?> [options]

where:
<sample dirs> is the name of a file with the names of the sample directories (no paths)
<loc> is the path to the dir with the sample dirs
<introns> is the name (with full path) of a file with introns, one per line as chr:start-end
<output sam?> = true if you want it to output two sam files, one of things that map to introns 
 
option:
 -NU-only

 -bsub : set this if you want to submit batch jobs to LSF.

 -qsub : set this if you want to submit batch jobs to Sun Grid Engine.

 -depth <n> : by default, it will output 10 intronmappers

";
}
use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/runall_//;

$nuonly = 'false';
$bsub = "false";
$qsub = "false";
$numargs = 0;
$i_intron = 10;
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
	$i_intron = $ARGV[$i+1];
	$i++;
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

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
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
        $last_dir = $fields[@fields-1];
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
	print OUTFILE "perl $path $introns $LOC/$dir/$filename $LOC/$dir/$outfile true -depth $i_intron\n";
	close(OUTFILE);
    } 
    else {
	open(OUTFILE, ">$shdir/$shfile2");
	print OUTFILE "perl $path $introns $final_nexon_dir/$filename $final_nexon_dir/$outfile false\n";
	close(OUTFILE);
    }
    if($outputsam eq "true") {
	if ($bsub eq "true"){
	    `bsub -e $logdir/$id.quantifyintrons.err -o $logdir/$id.quantifyintrons.out sh $shdir/$shfile`;
	}
	if ($qsub eq "true"){
	    `qsub -cwd -N $line.quantifyintrons -o $logdir -e $logdir  $shdir/$shfile`;
	}
    }
    else {
	if ($bsub eq "true"){
	    `bsub -e $logdir/$id.quantifyintrons_2.err -o $logdir/$id.quantifyintrons_2.out sh $shdir/$shfile2`;
	}
	if ($qsub eq "true"){
	    `qsub -cwd -N $line.quantifyintrons_2 -e $logdir -o $logdir  $shdir/$shfile2`;
	}
    }
}
close(INFILE);
