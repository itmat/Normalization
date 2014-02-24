if(@ARGV<2) {
    die "usage: perl make_final_samfile.pl <sample dirs> <loc> [options]

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are

option:
  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.
  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

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
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$size = @fields;
$last_dir = $fields[@size-1];
$norm_dir = $LOC;
$norm_dir =~ s/$last_dir//;
$norm_dir = $norm_dir . "NORMALIZED_DATA";
$exon_dir = $norm_dir . "/exonmappers";
$nexon_dir = $norm_dir . "/notexonmappers";
$finalsam_dir = "$norm_dir/FINAL_SAM";
$final_U_dir = "$finalsam_dir/Unique";
$final_NU_dir = "$finalsam_dir/NU";
$final_M_dir = "$finalsam_dir/MERGED";
unless (-d $finalsam_dir){
    `mkdir $finalsam_dir`;
}
open(INFILE, $ARGV[0]);
while ($line = <INFILE>){
    chomp($line);
    $dir = $line;
    $id = $line;
    $id =~ s/Sample_//;
    if ($option_found eq "false"){
	unless (-d $final_U_dir){
	    `mkdir $final_U_dir`;
	}
	unless (-d $final_NU_dir){
	    `mkdir $final_NU_dir`;
	}
	unless (-d $final_M_dir){
	    `mkdir $final_M_dir`;
	}
	`cat $exon_dir/Unique/$id.*norm_u.sam $nexon_dir/Unique/$id.*intronmappers.norm_u.sam $nexon_dir/Unique/$id.*intergenicmappers.norm_u.sam > $final_U_dir/$id.FINAL.norm_u.sam`;
	`cat $exon_dir/NU/$id.*norm_nu.sam $nexon_dir/NU/$id.*intronmappers.norm_nu.sam $nexon_dir/NU/$id.*intergenicmappers.norm_nu.sam > $final_NU_dir/$id.FINAL.norm_nu.sam`;
	`cat $exon_dir/*/$id.*norm*.sam $nexon_dir/*/$id.*intronmappers.norm*.sam $nexon_dir/*/$id.*intergenicmappers.norm*.sam > $final_M_dir/$id.FINAL.norm.sam`;
    }
    else{
	if ($U eq "true"){
	    unless (-d $final_U_dir){
		`mkdir $final_U_dir`;
	    }
	    `cat $exon_dir/Unique/$id.*norm_u.sam $nexon_dir/Unique/$id.*intronmappers.norm_u.sam $nexon_dir/Unique/$id.*intergenicmappers.norm_u.sam > $final_U_dir/$id.FINAL.norm_u.sam`;
	}
	if ($NU eq "true"){
            unless (-d $final_NU_dir){
                `mkdir $final_NU_dir`;
            }
	        `cat $exon_dir/NU/$id.*norm_nu.sam $nexon_dir/NU/$id.*intronmappers.norm_nu.sam $nexon_dir/NU/$id.*intergenicmappers.norm_nu.sam > $final_NU_dir/$id.FINAL.norm_nu.sam`;
	}
    }
}
close(INFILE);
