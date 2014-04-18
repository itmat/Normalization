#!/usr/bin/env perl
if(@ARGV<2) {
    die "usage: perl make_final_samfile.pl <sample dirs> <loc> [options]

where:
<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are

option:
  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers to merged sam file.
  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers to merged sam file.

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
and non-unique to merged file by default so if that's what you want don't 
use either arg -u or -nu.
";
}

$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
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
open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";
while ($line = <INFILE>){
    chomp($line);
    $dir = $line;
    $id = $line;
    $id =~ s/Sample_//;
    $in_UE = "$exon_dir/Unique/$id.exonmappers.norm_u.sam";
    $in_NUE = "$exon_dir/NU/$id.exonmappers.norm_nu.sam";
    $in_UI = "$nexon_dir/Unique/$id.intronmappers.norm_u.sam";
    $in_NUI = "$nexon_dir/NU/$id.intronmappers.norm_nu.sam";
    $in_UG = "$nexon_dir/Unique/$id.intergenicmappers.norm_u.sam";
    $in_NUG = "$nexon_dir/NU/$id.intergenicmappers.norm_nu.sam";
    $out_U = "$final_U_dir/$id.FINAL.norm_u.sam";
    $out_NU = "$final_NU_dir/$id.FINAL.norm_nu.sam";
    $out_M = "$final_M_dir/$id.FINAL.norm.sam";
    if ($option_found eq "false"){
	unless (-d $final_M_dir){
	    `mkdir $final_M_dir`;
	}
	#merged
	open(OUTM, ">$out_M");
	open(INUE, $in_UE);
	while($line = <INUE>){
	    chomp($line);
	    $line = $line . "\tXT:A:E";
	    print OUTM "$line\n";
	}
	close(INUE);

	open(INUI, $in_UI);
	while($line = <INUI>){
	    chomp($line);
            $line = $line . "\tXT:A:I";
            print OUTM "$line\n";
	}
	close(INUI);

	open(INUG, $in_UG);
	while($line = <INUG>){
            chomp($line);
            $line = $line . "\tXT:A:G";
            print OUTM "$line\n";
	}
	close(INUG);

	open(INNUE, $in_NUE);
	while($line = <INNUE>){
	    chomp($line);
	    $line = $line . "\tXT:A:E";
	    print OUTM "$line\n";
	}
	close(INNUE);

	open(INNUI, $in_NUI);
	while($line = <INNUI>){
	    chomp($line);
            $line = $line . "\tXT:A:I";
            print OUTM "$line\n";
	}
	close(INNUI);

	open(INNUG, $in_NUG);
	while($line = <INNUG>){
            chomp($line);
            $line = $line . "\tXT:A:G";
            print OUTM "$line\n";
	}
	close(INNUG);
	close(OUTM);
    }
    else{
	if ($U eq "true"){
	    unless (-d $final_U_dir){
		`mkdir $final_U_dir`;
	    }
	    #unique 
	    open(OUTU, ">$out_U");
	    open(INUE, $in_UE);
	    while($line = <INUE>){
		chomp($line);
		$line = $line . "\tXT:A:E";
		print OUTU "$line\n";
	    }
	    close(INUE);
	    
	    open(INUI, $in_UI);
	    while($line = <INUI>){
		chomp($line);
		$line = $line . "\tXT:A:I";
		print OUTU "$line\n";
	    }
	    close(INUI);
	    
	    open(INUG, $in_UG);
	    while($line = <INUG>){
		chomp($line);
		$line = $line . "\tXT:A:G";
		print OUTU "$line\n";
	    }
	    close(INUG);
	    close(OUTU);
	}
	
	if ($NU eq "true"){
            unless (-d $final_NU_dir){
                `mkdir $final_NU_dir`;
            }
	    #non-unique
	    open(OUTNU, ">$out_NU");
	    open(INNUE, $in_NUE);
	    while($line = <INNUE>){
		chomp($line);
		$line = $line . "\tXT:A:E";
		print OUTNU "$line\n";
	    }
	    close(INNUE);
	    open(INNUI, $in_NUI);
	    while($line = <INNUI>){
		chomp($line);
		$line = $line . "\tXT:A:I";
		print OUTNU "$line\n";
	    }
	    close(INNUI);
	    open(INNUG, $in_NUG);
	    while($line = <INNUG>){
		chomp($line);
		$line = $line . "\tXT:A:G";
		print OUTNU "$line\n";
	    }
	    close(INNUG);
	    close(OUTNU);
	}
    }
}
close(INFILE);
