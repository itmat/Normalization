if (@ARGV < 2){
    die "usage: perl cat_headfiles.pl <sample dirs> <loc> [options]

where:
<sample dirs> is  a file of sample directories 
<loc> is the path to the sample directories

option:
  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.
";
}


$NU = "true";
$U = "true";
$numargs = 0;
for($i=2; $i<@ARGV; $i++) {
    $option_found = "false";
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$numargs++;
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
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

$LOC = $ARGV[1];
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$loc_study = $LOC;
$loc_study =~ s/$last_dir//;
$norm_dir = $loc_study."NORMALIZED_DATA";
unless (-d $norm_dir){
    `mkdir $norm_dir`;
}
$norm_exon_dir = $norm_dir . "/exonmappers";
unless (-d $norm_exon_dir){
    `mkdir $norm_exon_dir`;
}
$norm_exon_dirU = $norm_exon_dir . "/Unique";
$norm_exon_dirNU= $norm_exon_dir . "/NU";

$norm_notexon_dir = $norm_dir . "/notexonmappers";
unless (-d $norm_notexon_dir){
    `mkdir $norm_notexon_dir`;
}
$norm_notexon_dirU = $norm_notexon_dir . "/Unique";
$norm_notexon_dirNU = $norm_notexon_dir . "/NU";

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while ($line = <INFILE>){
    chomp($line);
    $dir = $line;
    $dirU = $dir . "/Unique";
    $dirNU = $dir . "/NU";
    $id = $line;
    $id =~ s/Sample_//;
    if ($option_found eq "false"){
	unless (-d $norm_exon_dirU){
	    `mkdir $norm_exon_dirU`;
	}
	unless (-d $norm_exon_dirNU){
	    `mkdir $norm_exon_dirNU`;
	}
	#exonmappers
	`cat $LOC/$dirU/$id.*_exonmappers.*_head_*.sam > $norm_exon_dirU/$id.exonmappers.norm_u.sam`;
	`cat $LOC/$dirNU/$id.*_exonmappers.*_head_*.sam > $norm_exon_dirNU/$id.exonmappers.norm_nu.sam`;
        unless (-d $norm_notexon_dirU){
            `mkdir $norm_notexon_dirU`;
        }
        unless (-d $norm_notexon_dirNU){
            `mkdir $norm_notexon_dirNU`;
        }
	#intronmappers
	`cat $LOC/$dirU/$id.*_notexonmappers_intronmappers.*_head_*.sam > $norm_notexon_dirU/$id.intronmappers.norm_u.sam`;
	`cat $LOC/$dirNU/$id.*_notexonmappers_intronmappers.*_head_*.sam > $norm_notexon_dirNU/$id.intronmappers.norm_nu.sam`;
	#intergenicmappers
	`cp $LOC/$dirU/$id.intergenicmappers.norm_u.sam $norm_notexon_dirU/`;
	`cp $LOC/$dirNU/$id.intergenicmappers.norm_nu.sam $norm_notexon_dirNU/`;
    }
    else{
	if ($U eq "true"){
	    unless (-d $norm_exon_dirU){
		`mkdir $norm_exon_dirU`;
	    }
	    unless (-d $norm_notexon_dirU){
		`mkdir $norm_notexon_dirU`;
	    }

	    `cat $LOC/$dirU/$id.*_exonmappers.*_head_*.sam > $norm_exon_dirU/$id.exonmappers.norm_u.sam`;
	    `cat $LOC/$dirU/$id.*_notexonmappers_intronmappers.*_head_*.sam > $norm_notexon_dirU/$id.intronmappers.norm_u.sam`;
	    `cp $LOC/$dirU/$id.intergenicmappers.norm_u.sam $norm_notexon_dirU/`;
	}
	if ($NU eq "true"){
            unless (-d $norm_exon_dirNU){
                `mkdir $norm_exon_dirNU`;
            }
            unless (-d $norm_notexon_dirNU){
                `mkdir $norm_notexon_dirNU`;
            }
	    `cat $LOC/$dirNU/$id.*_exonmappers.*_head_*.sam > $norm_exon_dirNU/$id.exonmappers.norm_nu.sam`;
	    `cat $LOC/$dirNU/$id.*_notexonmappers_intronmappers.*_head_*.sam > $norm_notexon_dirNU/$id.intronmappers.norm_nu.sam`;
	    `cp $LOC/$dirNU/$id.intergenicmappers.norm_nu.sam $norm_notexon_dirNU/`;
	}
    }
}
close(INFILE);

