if (@ARGV<4){
  die "usage: runall_sam2cov.pl <sample dirs> <loc> <fai file> <sam2cov> [options]

<sample dirs> is  a file of sample directories with alignment output without path
<loc> is where the sample directories are
<fai file> fai file (full path)
<sam2cov> is full path of sam2cov

***Sam files produced by aligners other than STAR and RUM are currently not supported

option:  -u  :  set this if you want to use only unique mappers to generate coverage files, 
                otherwise by default it will use merged(unique+non-unique) mappers.

         -nu  :  set this if you want to use only non-unique mappers to generate coverage files,
                 otherwise by default it will use merged(unique+non-unique) mappers.

         -rum  :  set this if you used RUM to align your reads 

         -star  : set this if you used STAR to align your reads 

         -bsub : set this if you want to submit batch jobs to LSF.

         -qsub : set this if you want to submit batch jobs to Sun Grid Engine.


";
}
$bsub = "false";
$qsub = "false";
$numargs = 0;
$numargs_a = 0;
$numargs_u_nu = 0;
$U = "true";
$NU = "true";
$star = "false";
$rum = "false";
for ($i=4; $i<@ARGV; $i++){
    $option_found = "false";
    if($ARGV[$i] eq '-nu') {
        $U = "false";
	$numargs_u_nu++;
        $option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
        $NU = "false";
        $numargs_u_nu++;
        $option_found = "true";
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
    if ($ARGV[$i] eq '-star'){
        $star = "true";
        $numargs_a++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-rum'){
        $rum = "true";
        $numargs_a++;
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
    die "you cannot specify both -u and -nu\n.
";
}
if($numargs_a ne '1'){
    die "you have to specify which aligner was used to align your reads. sam2cov only works with sam files aligned with STAR or RUM\n
";
}


$LOC = $ARGV[1];
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$shdir = $study_dir . "shell_scripts";
$logdir = $study_dir . "logs";
$norm_dir = $study_dir . "NORMALIZED_DATA";
$finalsam_dir = "$norm_dir/FINAL_SAM";
$final_U_dir = "$finalsam_dir/Unique";
$final_NU_dir = "$finalsam_dir/NU";
$final_M_dir = "$finalsam_dir/MERGED";
$fai_file = $ARGV[2]; # fai file
$sam2cov = $ARGV[3];

open(INFILE, $ARGV[0]) or die "cannot find file '$ARGV[0]'\n"; # dirnames
while($line =  <INFILE>){
    chomp($line);
    $dir = $line;
    $id = $dir;
    $id =~ s/Sample_//;
    if ($numargs_u_nu eq '0'){
	$filename = "$final_M_dir/$id.FINAL.norm.sam";
	$prefix = $filename;
	$prefix =~ s/norm.sam//;
    }
    else {
	if ($U eq 'true'){
	    $filename = "$final_U_dir/$id.FINAL.norm_u.sam";
	    $prefix = $filename;
	    $prefix =~ s/norm_u.sam//;
	}
	if ($NU eq 'true'){
	    $filename = "$final_NU_dir/$id.FINAL.norm_nu.sam";
	    $prefix = $filename;
	    $prefix =~ s/norm_nu.sam//;
	}
    }
    $shfile = "C.$id.sam2cov.sh";
    open(OUTFILE, ">$shdir/$shfile");
    if ($rum eq 'true'){
	print OUTFILE "$sam2cov -r 1 -u -p $prefix $fai_file $filename"; 
    }
    if ($star eq 'true'){
	print OUTFILE "$sam2cov -u -p $prefix $fai_file $filename"; 
    }
    close(OUTFILE);
    if ($bsub eq "true"){
	`bsub -q max_mem30 -o $logdir/$id.sam2cov.out -e $logdir/$id.sam2cov.err sh $shdir/$shfile`;
    }
    if ($qsub eq "true"){
	`qsub -cwd -l h_vmem=16G -N $dir.sam2cov -o $logdir -e $logdir $shfile`;
    }
}
close(INFILE);


