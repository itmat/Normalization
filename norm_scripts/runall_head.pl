if(@ARGV < 2) {
    die "usage: perl runall_head.pl <dirs> <loc> [options]

where
<dirs> is directory names without path
<loc> is the path to the sample directories

will output the same number of rows from each file in <loc>/<dirs>/Unique
of the same type. (ditto for NU)

The output file names will be modified from the input file names.

option:  -u  :  set this if you want to return only unique mappers, otherwise by default it will return both unique and non-unique mappers

         -nu  :  set this if you want to return only non-unique mappers, otherwise by default it will return both unique and non-unique mappers

         -bsub : set this if you want to submit batch jobs to LSF.

         -qsub : set this if you want to submit batch jobs to Sun Grid Engine.

         -depthE <n> : This is the number of exonmappers file used for normalization.
                       By default, <n> = 20.

         -depthI <n> : This is the number of intronmappers file used for normalization.
                       By default, <n> = 10. 
";
}
$bsub = "false";
$qsub = "false";
$U = 'true';
$NU = 'true';
$numargs = 0;
$numargs_n_nu = 0;
$i_exon = 20;
$i_intron = 10;
for ($i=2; $i<@ARGV; $i++){
    $option_found = "false";
    $option_u_nu = "false";
    if ($ARGV[$i] eq '-u'){
	$NU = "false";
	$option_found = "true";
	$option_u_nu = "true";
	$numargs_n_nu++;
    }
    if ($ARGV[$i] eq '-nu'){
	$U = "false";
	$option_found = "true";
	$option_u_nu = "true";
	$numargs_u_nu++;
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
    if ($ARGV[$i] eq '-depthE'){
	$i_exon = $ARGV[$i+1];
	if ($i_exon !~ /(\d+$)/ ){
	    die "-depthE <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-depthI'){
	$i_intron = $ARGV[$i+1];
	if ($i_intron !~ /(\d+$)/ ){
	    die "-depthI <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if ($option_found eq "false"){
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs ne '1'){
    die "you have to specify how you want to submit batch jobs. choose either -bsub or -qsub.\n
";
}
if($numargs_u_nu > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}
#print "$i_exon\t$i_intron\n";

$LOC = $ARGV[1];
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

if ($optionfound_u_nu eq 'false'){
    #EXON
    $exonuniques = "false";
    $exonnu = "false";
    $warnUE = "";
    $warnNUE = "";
    for($i=1; $i<=$i_exon; $i++) {
	open(INFILE, $ARGV[0]);  # file of dirs
	$minEU[$i] = 1000000000000;
	$minENU[$i] = 1000000000000;
	while($dirname = <INFILE>) {
	    chomp($dirname);
	    $id = $dirname;
	    $id =~ s/Sample_//;
	    if(-e "$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam") {
		$N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam`;
		$exonuniques = "true";
	    } else {
		die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
#	    $warnUE = $warnUE . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
		die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to have the proper last line...\n";
	    }
	    $N =~ s/[^\d]//g;
	    if($N < $minEU[$i]) {
		$minEU[$i] = $N;
	    }
	    if(-e "$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam") {
		$N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam`;
		$exonnu = "true";
	    } else {
		die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
#	     $warnNUE = $warnNUE . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
		die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to have the proper last line...\n";
	    }
	    $N =~ s/[^\d]//g;
	    if($N < $minENU[$i]) {
		$minENU[$i] = $N;
	    }
	}
	close(INFILE);
#    print "minEU[$i] = $minEU[$i]\n";
#    print "minENU[$i] = $minENU[$i]\n";
    }
    if($exonuniques eq 'true' && $warnUE =~ /\S/) {
	die "$warnUE\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
    }
    if($exonnu eq 'true' && $warnNUE =~ /\S/) {
	die "$warnNUE\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
    }

#INTRON
    if ($i_intron ne '0'){
	$intronuniques = "false";
	$intronnu = "false";
	$warnUI = "";
	$warnNUI = "";
	for($i=1; $i<=$i_intron; $i++) {
	    open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";  # file of dirs
	    $minIU[$i] = 1000000000000;
	    $minINU[$i] = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		$id =~ s/Sample_//;
		if(-e "$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam") {
		    $N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam`;
		    $intronuniques = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
#	    $warnUI = $warnUI . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		if($N < $minIU[$i]) {
		    $minIU[$i] = $N;
		}
		if(-e "$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam") {
		    $N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam`;
		    $intronnu = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
#	    $warnNUI = $warnNUI . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		if($N < $minINU[$i]) {
		    $minINU[$i] = $N;
		}
	    }
	    close(INFILE);
#    print "minIU[$i] = $minIU[$i]\n";
#    print "minINU[$i] = $minINU[$i]\n";
	}
	if($intronuniques eq 'true' && $warnUI =~ /\S/) {
	    die "$warnUI\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}
	if($intronnu eq 'true' && $warnNUI =~ /\S/) {
	    die "$warnNUI\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}
	
	#INTERGENIC
	$iguniques = "false";
	$ignu = "false";
	$warnUIG = "";
	$warnNUIG = "";
	open(INFILE, $ARGV[0]);  # file of dirs
	$minIGU = 1000000000000;
	$minIGNU = 1000000000000;
	while($dirname = <INFILE>) {
	    chomp($dirname);
	    $id = $dirname;
	    $id =~ s/Sample_//;
	    if(-e "$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam") {
		$N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam`;
		$iguniques = "true";
	    } else {
		die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
#	$warnUIG = $warnUIG . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
		die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to have the proper last line...\n";
	    }
	    $N =~ s/[^\d]//g;
	    if($N < $minIGU) {
		$minIGU = $N;
	    }
	    if(-e "$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam") {
		$N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam`;
		$ignu = "true";
	    } else {
		die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
#	$warnNUIG = $warnNUIG . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
	    }
	    if($N !~ /line count/) {
		die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to have the proper last line...\n";
	    }
	    $N =~ s/[^\d]//g;
	    if($N < $minIGNU) {
		$minIGNU = $N;
	    }
	}
	close(INFILE);
#print "minIGU = $minIGU\n";
#print "minIGNU = $minIGNU\n";
	if($iguniques eq 'true' && $warnUIG =~ /\S/) {
	die "$warnUIG\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}
	if($ignu eq 'true' && $warnNUIG =~ /\S/) {
	    die "$warnNUIG\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}
    }
}
else{
    if ($U eq 'true'){
	#EXON
	$exonuniques = "false";
	$warnUE = "";
	for($i=1; $i<=$i_exon; $i++) {
	    open(INFILE, $ARGV[0]);  # file of dirs
	    $minEU[$i] = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		$id =~ s/Sample_//;
		if(-e "$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam") {
		    $N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam`;
		    $exonuniques = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
#	    $warnUE = $warnUE . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_exonmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		if($N < $minEU[$i]) {
		    $minEU[$i] = $N;
		}
	    }
	    close(INFILE);
	}
	if($exonuniques eq 'true' && $warnUE =~ /\S/) {
	    die "$warnUE\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}

	if ($i_intron ne '0'){
	#INTRON
	    $intronuniques = "false";
	    $warnUI = "";
	    for($i=1; $i<=$i_intron; $i++) {
		open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";  # file of dirs
		$minIU[$i] = 1000000000000;
		while($dirname = <INFILE>) {
		    chomp($dirname);
		    $id = $dirname;
		    $id =~ s/Sample_//;
		    if(-e "$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam") {
			$N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam`;
			$intronuniques = "true";
		    } else {
			die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
#	    $warnUI = $warnUI . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
		    }
		    if($N !~ /line count/) {
			die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		    }
		    $N =~ s/[^\d]//g;
		    if($N < $minIU[$i]) {
			$minIU[$i] = $N;
		    }
		}
		close(INFILE);
#    print "minIU[$i] = $minIU[$i]\n";
#    print "minINU[$i] = $minINU[$i]\n";
	    }
	    if($intronuniques eq 'true' && $warnUI =~ /\S/) {
		die "$warnUI\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	    }
	    
	    #INTERGENIC
	    $iguniques = "false";
	    $warnUIG = "";
	    open(INFILE, $ARGV[0]);  # file of dirs
	    $minIGU = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		$id =~ s/Sample_//;
		if(-e "$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam") {
		    $N = `tail -1 $LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam`;
		$iguniques = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
#	$warnUIG = $warnUIG . "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/Unique/$id.filtered_u_notexonmappers_intergenicmappers.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		if($N < $minIGU) {
		    $minIGU = $N;
		}
	    }
	    close(INFILE);
	    if($iguniques eq 'true' && $warnUIG =~ /\S/) {
		die "$warnUIG\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	    }
	}
    }
    if ($NU eq 'true'){
	#EXON
	$exonnu = "false";
	$warnNUE = "";
	for($i=1; $i<=$i_exon; $i++) {
	    open(INFILE, $ARGV[0]);  # file of dirs
	    $minENU[$i] = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		$id =~ s/Sample_//;
		if(-e "$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam") {
		    $N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam`;
		    $exonnu = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
#	     $warnNUE = $warnNUE . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_exonmappers.$i.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		if($N < $minENU[$i]) {
		    $minENU[$i] = $N;
		}
	    }
	close(INFILE);
#    print "minEU[$i] = $minEU[$i]\n";
#    print "minENU[$i] = $minENU[$i]\n";
	}
	if($exonnu eq 'true' && $warnNUE =~ /\S/) {
	    die "$warnNUE\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	}
	
	if ($i_intron ne '0'){
#INTRON
	    $intronnu = "false";
	    $warnNUI = "";
	    for($i=1; $i<=$i_intron; $i++) {
		open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n";  # file of dirs
		$minINU[$i] = 1000000000000;
		while($dirname = <INFILE>) {
		    chomp($dirname);
		    $id = $dirname;
		    $id =~ s/Sample_//;
		    if(-e "$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam") {
			$N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam`;
			$intronnu = "true";
		    } else {
			die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
#	    $warnNUI = $warnNUI . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to exist...\n";
		    }
		    if($N !~ /line count/) {
			die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intronmappers.$i.sam' does not seem to have the proper last line...\n";
		    }
		    $N =~ s/[^\d]//g;
		    if($N < $minINU[$i]) {
			$minINU[$i] = $N;
		    }
		}
		close(INFILE);
#    print "minIU[$i] = $minIU[$i]\n";
#    print "minINU[$i] = $minINU[$i]\n";
	    }
	    if($intronnu eq 'true' && $warnNUI =~ /\S/) {
		die "$warnNUI\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	    }
	    
	    #INTERGENIC
	    $ignu = "false";
	    $warnNUIG = "";
	    open(INFILE, $ARGV[0]);  # file of dirs
	    $minIGNU = 1000000000000;
	    while($dirname = <INFILE>) {
		chomp($dirname);
		$id = $dirname;
		$id =~ s/Sample_//;
		if(-e "$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam") {
		    $N = `tail -1 $LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam`;
		    $ignu = "true";
		} else {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
#	$warnNUIG = $warnNUIG . "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to exist...\n";
		}
		if($N !~ /line count/) {
		    die "ERROR: The file '$LOC/$dirname/NU/$id.filtered_nu_notexonmappers_intergenicmappers.sam' does not seem to have the proper last line...\n";
		}
		$N =~ s/[^\d]//g;
		if($N < $minIGNU) {
		    $minIGNU = $N;
		}
	    }
	    close(INFILE);
#print "minIGU = $minIGU\n";
#print "minIGNU = $minIGNU\n";
	    if($ignu eq 'true' && $warnNUIG =~ /\S/) {
		die "$warnNUIG\nAre you sure the directories in '$ARGV[0]' are exactly the ones you want?  Please check and fix and rerun...\n\n";
	    }
	}
    }
}
    
##run head
#exonmappers
for($i=1; $i<=$i_exon; $i++) {
    open(INFILE, $ARGV[0]);
    while($dirname = <INFILE>) {
	chomp($dirname);
	$id = $dirname;
	$id =~ s/Sample_//;
	$numU = $minEU[$i];
	$numNU = $minENU[$i];
	$filenameU = "$id.filtered_u_exonmappers.$i.sam";
	$outfileU = $filenameU;
	$outfileU =~ s/.sam/_head_$numU.sam/;
	$filenameNU = "$id.filtered_nu_exonmappers.$i.sam";
	$outfileNU = $filenameNU;
	$outfileNU =~ s/.sam/_head_$numNU.sam/;
	$dirU = $dirname . "/Unique";
	$dirNU = $dirname . "/NU";
	$shfileU[$i] = "$shdir/a" . $id . "exonmappers.u_runhead.$i.sh";
	$shfileNU[$i] = "$shdir/a" . $id . "exonmappers.nu_runhead.$i.sh";
	if($exonuniques eq 'true') {
	    open(OUTFILEU, ">$shfileU[$i]");
	    print OUTFILEU "head -$numU $LOC/$dirU/$filenameU > $LOC/$dirU/$outfileU\n";
	    close(OUTFILEU);
	    if ($bsub eq "true"){
		`bsub -o $logdir/$id.exonmappers.u_head.$i.out -e $logdir/$id.exonmappers.u_head.$i.err sh $shfileU[$i]`;
	    }
	    if ($qsub eq "true"){
		`qsub -cwd -N $dirname.exonmappers.u_head.$i -o $logdir -e $logdir $shfileU[$i]`;
	    }
	}
	if($exonnu eq 'true') {
	    open(OUTFILENU, ">$shfileNU[$i]");
	    print OUTFILENU "head -$numNU $LOC/$dirNU/$filenameNU > $LOC/$dirNU/$outfileNU\n";
	    close(OUTFILENU);
	    if ($bsub eq "true"){
		`bsub -o $logdir/$id.exonmappers.nu_head.$i.out -e $logdir/$id.exonmappers.nu_head.$i.err sh $shfileNU[$i]`;
	    }
	    if ($qsub eq "true"){
		`qsub -cwd -N $dirname.exonmappers.nu_head.$i -e $logdir -o $logdir $shfileNU[$i]`;
	    }
	}
    }
    close(INFILE);
}

#intronmappers
for($i=1; $i<=$i_intron; $i++) {
    open(INFILE, $ARGV[0]);
    while($dirname = <INFILE>) {
	chomp($dirname);
	$id = $dirname;
	$id =~ s/Sample_//;
	$numU = $minIU[$i];
	$numNU = $minINU[$i];
	$filenameU = "$id.filtered_u_notexonmappers_intronmappers.$i.sam";
	$outfileU = $filenameU;
	$outfileU =~ s/.sam/_head_$numU.sam/;
	$filenameNU = "$id.filtered_nu_notexonmappers_intronmappers.$i.sam";
	$outfileNU = $filenameNU;
	$outfileNU =~ s/.sam/_head_$numNU.sam/;
	$dirU = $dirname . "/Unique";
	$dirNU = $dirname . "/NU";
	$shfileU[$i] = "$shdir/a" . $id . "intronmappers.u_runhead.$i.sh";
	$shfileNU[$i] = "$shdir/a" . $id . "intronmappers.nu_runhead.$i.sh";
	if($intronuniques eq 'true') {
	    open(OUTFILEU, ">$shfileU[$i]");
	    print OUTFILEU "head -$numU $LOC/$dirU/$filenameU > $LOC/$dirU/$outfileU\n";
	    close(OUTFILEU);
	    if ($bsub eq "true"){
		`bsub -o $logdir/$id.intronmappers.u_head.$i.out -e $logdir/$id.intronmappers.u_head.$i.err sh $shfileU[$i]`;
	    }
	    if ($qsub eq "true"){
		`qsub -cwd -N $dirname.intronmappers.u_head.$i -o $logdir -e $logdir $shfileU[$i]`;
	    }
	}
	if($intronnu eq 'true') {
	    open(OUTFILENU, ">$shfileNU[$i]");
	    print OUTFILENU "head -$numNU $LOC/$dirNU/$filenameNU > $LOC/$dirNU/$outfileNU\n";
	    close(OUTFILENU);
	    if ($bsub eq "true"){
		`bsub -o $logdir/$id.intronmappers.nu_head.$i.out -e $logdir/$id.intronmappers.nu_head.$i.err sh $shfileNU[$i]`;
	    }
	    if ($qsub eq "true"){
		`qsub -cwd -N $dirname.intronmappers.nu_head.$i -o $logdir -e $logdir $shfileNU[$i]`;
	    }
	}
    }
    close(INFILE);
}

#intergenicmappers
open(INFILE, $ARGV[0]);
while($dirname = <INFILE>) {
    chomp($dirname);
    $id = $dirname;
    $id =~ s/Sample_//;
    $numU = $minIGU;
    $numNU = $minIGNU;
    $filenameU = "$id.filtered_u_notexonmappers_intergenicmappers.sam";
    $outfileU = "$id.intergenicmappers.norm_u.sam";
    $filenameNU = "$id.filtered_nu_notexonmappers_intergenicmappers.sam";
    $outfileNU = "$id.intergenicmappers.norm_nu.sam";
    $dirU = $dirname . "/Unique";
    $dirNU = $dirname . "/NU";
    $shfileU = "$shdir/a" . $id . "intergenic.u_runhead.sh";
    $shfileNU = "$shdir/a" . $id . "intergenic.nu_runhead.sh";
    if($iguniques eq 'true') {
	open(OUTFILEU, ">$shfileU");
	print OUTFILEU "head -$numU $LOC/$dirU/$filenameU > $LOC/$dirU/$outfileU\n";
	close(OUTFILEU);
	if ($bsub eq "true"){
	    `bsub -o $logdir/$id.intergenic.u_head.out -e $logdir/$id.intergenic.u_head.err sh $shfileU`;
	}
	if ($qsub eq "true"){
	    `qsub -cwd -N $dirname.intergenic.u_head -o $logdir -e $logdir $shfileU`;
	}
    }
    if($ignu eq 'true') {
	open(OUTFILENU, ">$shfileNU");
	print OUTFILENU "head -$numNU $LOC/$dirNU/$filenameNU > $LOC/$dirNU/$outfileNU\n";
	close(OUTFILENU);
	if ($bsub eq "true"){
	    `bsub -o $logdir/$id.intergenic.nu_head.out -e $logdir/$id.intergenic.nu_head.err sh $shfileNU`;
	}
	if ($qsub eq "true"){
	    `qsub -cwd -N $dirname.intergenic.nu_head -o $logdir -e $logdir $shfileNU`;
	}
    }
}
close(INFILE);
