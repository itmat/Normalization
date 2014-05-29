#!/usr/bin/env perl
$USAGE =  "\nUsage: run_normalization --sample_dirs <file of sample_dirs> --loc <s> --unaligned <file of fa/fqfiles> --samfilename <s> --cfg <cfg file> [options]

where:
--sample_dirs <file of sample_dirs> : is a file of sample directories with alignment output without path
--loc <s> : /path/to/directory with the sample directories
--unaligned <file of fa/fqfiles> : is a file with the full path of input forward fa or forward fq files
--samfilename <s> : is the name of aligned sam file (e.g. RUM.sam, Aligned.out.sam) 
--cfg <cfg file> : is a cfg file for the study

OPTIONS:
     [pipeline options]
     -preprocess_only : set this if you want to run steps in \"1) Preprocess\" only.
     -skip_preprocess : set this if you've already run all steps in \"1) Preprocess\" and want to skip them. 

     [data type]
     -se : set this if the data is single end, otherwise by default it will assume it's a paired end data
     -fa : set this if the unaligned files are in fasta format 
     -fq : set this if the unaligned files are in fastq format 
     -gz : set this if the unaligned files are compressed

     [normalization parameters]
     -novel_off : set this if you DO NOT want to generate/use a study-specific master list of exons
                  (By default, the pipeline will add inferred exons to the list of exons)
     -min <n> : is minimum size of inferred exon for get_novel_exons.pl script (Default = 10)
     -max <n> : is maximum size of inferred exon for get_novel_exons.pl script (Default = 2000)
     -cutoff_highexp <n> : is cutoff % value to identify highly expressed exons. 
                           the script will consider exons with exonpercents greater than n(%) as high expressors, 
                           and remove them from the list of exons.
                           (Default = 100; with the default cutoff, exons expressed >10% will be reported)
     -depthE <n> : the pipeline splits filtered sam files into 1,2,3...n exonmappers and downsamples each separately.
                   (Default = 20)
     -depthI <n> : the pipeline splits filtered sam files into 1,2,3...n intronmappers and downsamples each separately.
                   (Default = 10)
     -cutoff_lowexp <n> : is cutoff counts to identify low expressors in the final spreadsheets (exon, intron and junc).
                          the script will consider features with sum of counts for all samples less than <n> as low expressors
                          and remove them from all samples for the final spreadsheets.
                          (Default = 0; this will remove features with sum of counts = 0)
     -h : print usage 

";

if(@ARGV < 10) {
    die $USAGE;
}

$required = 0;
$unaligned = 0;
$count_b = 0;
$se = "";
$unaligned_z = "";
$min = 10;
$max = 2000;
$cutoff_he = 100;
$filter_high_expressors = "false";
$i_exon = 20;
$i_intron = 10;
$filter_low_expressors = "false";
$novel = "true";
$run_blast = "true";
$run_norm = "true";
for($i=0; $i<@ARGV; $i++) {
    $option_found = "false";
    if ($ARGV[$i] eq '-preprocess_only'){
	$option_found = "true";
	$run_blast = "true";
	$run_norm = "false";
	$count_b++;
    }
    if ($ARGV[$i] eq '-skip_preprocess'){
	$option_found = "true";
	$run_blast = "false";
	$run_norm = "true";
	$count_b++;
    }
    if ($ARGV[$i] eq '-h'){
	$option_found = "true";
	die $USAGE;
    }
    if ($ARGV[$i] eq '-novel_off'){
        $option_found = "true";
        $novel = "false";
    }
    if ($ARGV[$i] eq '--sample_dirs'){
	$option_found = "true";
	$sample_dir = $ARGV[$i+1];
	if ($sample_dir =~ /^-/ | $sample_dir eq ""){
	    die "\nplease provide <file of sample_dirs> for --sample_dirs\n";
	}
	$i++;
	$required++;
    }
    if ($ARGV[$i] eq '--loc'){
	$option_found = "true";
        $LOC = $ARGV[$i+1];
	if ($LOC =~ /^-/ | $LOC eq ""){
	    die "\nplease provide '/path/to/directory with the sample directories' for --loc\n";
	}
        $i++;
	$required++;
    }
    if ($ARGV[$i] eq '--unaligned'){
	$option_found = "true";
        $unaligned_file = $ARGV[$i+1];
	if ($unalgined_file =~ /^-/ | $unaligned_file eq ""){
	    die "\nplease provide <file of fa/fqfiles> for --unaligned\n";
	}
        $i++;
	$required++;
    }
    if ($ARGV[$i] eq '--samfilename'){
	$option_found = "true";
	$samfilename = $ARGV[$i+1];
	if ($samfilename =~ /^-/ | $samfilename eq ""){
	    die "\nplease provide the 'name of aligned samfile' for --samfilename\n";
	}
	$i++;
	$required++;
    }
    if ($ARGV[$i] eq '--cfg'){
	$option_found = "true";
	$cfg_file = $ARGV[$i+1];
	if ($cfg_file =~ /^-/ | $cfg_file eq ""){
	    die "\nplease provide <cfg file> for --cfg\n";
	}
	$i++;
	$required++;
    }
    if ($ARGV[$i] eq '-se'){
        $option_found = "true";
	$se = "-se";
    }
    if ($ARGV[$i] eq '-fa'){
        $option_found = "true";
	$unaligned++;
	$unaligned_type = "-fa";
    }
    if ($ARGV[$i] eq '-fq'){
        $option_found = "true";
	$unaligned++;
	$unaligned_type = "-fq";
    }
    if ($ARGV[$i] eq '-gz'){
        $option_found = "true";
        $unaligned_z = "-gz";
    }
    if($ARGV[$i] eq '-min') {
	$min = $ARGV[$i+1];
	$i++;
	$option_found = "true";
        if ($min !~ /(\d+$)/ ){
            die "-min <n> : <n> needs to be a number\n";
        }
    }
    if($ARGV[$i] eq '-max') {
	$max = $ARGV[$i+1];
	$i++;
	$option_found = "true";
        if ($max !~ /(\d+$)/ ){
            die "-max <n> : <n> needs to be a number\n";
        }
    }
    if($ARGV[$i] eq '-cutoff_highexp') {
        $cutoff_he = $ARGV[$i+1];
        $i++;
        $option_found = "true";
	$filter_high_expressors = "true";
        if ($cutoff_he !~ /(\d+$)/ ){
            die "-cutoff_highexp <n> : <n> needs to be a number\n";
        }
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
    if($ARGV[$i] eq '-cutoff_lowexp') {
        $cutoff_temp = $ARGV[$i+1];
        $i++;
        $option_found = "true";
        $filter_low_expressors = "true";
        if ($cutoff_temp !~ /(\d+$)/ ){
            die "-cutoff_lowexp <n> : <n> needs to be a number\n";
        }
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if ($required ne '5'){
    die "please specify the required parameters: --sample_dirs, --loc, --unaligned, --samfilename and --cfg\n";
}
if ($unaligned ne '1'){
    die "you have to specify the type of your unaligned files: '-fa' or '-fq'\n"
}
if ($count_b > 1){
    die "you cannot set both -preprocess_only and -skip_preprocess\n";
}

$dirs = `wc -l $sample_dir`;
@a = split(" ", $dirs);
$num_samples = $a[0];
$cutoff_le = 0;
if ($filter_low_expressors eq "true"){
    $cutoff_le = $cutoff_temp;
}
$LOC =~ s/\/$//;
@fields = split("/", $LOC);
$last_dir = $fields[@fields-1];
$study_dir = $LOC;
$study_dir =~ s/$last_dir//;
$study = $fields[@fields-2];

unless (-e $cfg_file){
    die "ERROR: cannot find file \"$cfg_file\". please provide a cfg file for the study\n";
}

&parse_config_file ($cfg_file, \%Config);

use Cwd 'abs_path';
$norm_script_dir = abs_path($0);
$norm_script_dir =~ s/\/runall_normalization.pl//;

$geneinfo = $GENE_INFO_FILE;
$genome = $GENOME_FA;
$annot = $ANNOTATION_FILE;
$fai = $GENOME_FAI;
$sam2cov = "false";
if ($SAM2COV =~ /^true/ | $SAM2COV =~ /^TRUE/){
    $sam2cov = "true";
    $num_cov = 0;
    unless (-e $SAM2COV_LOC){
	die "You need to provide sam2cov location. (#4 DATA VISUALIZATION in your cfg file \"$cfg_file\")\n";
    }
    $sam2cov_loc = $SAM2COV_LOC;
    if ($RUM =~ /^true/ | $RUM =~ /^TRUE/){
	$aligner = "-rum";
	$num_cov++;
    }
    if ($STAR =~ /^true/ | $STAR =~ /^TRUE/){
	$aligner = "-star";
	$num_cov++;
    }
    if ($num_cov ne '1'){
	die "Please specify which aligner was used. (#4 DATA VISUALIZATION in your cfg file \"$cfg_file\")\n";
    }
}
$delete_int_sam = "true";
$convert_sam2bam = "false";
$gzip_cov = "false";
if ($DELETE_INT_SAM ne ""){
    if ($DELETE_INT_SAM =~ /^true/ | $DELETE_INT_SAM =~ /^TRUE/){
	$delete_int_sam = "true";
    }
    if ($DELETE_INT_SAM=~ /^false/ | $DELETE_INT_SAM =~/^FALSE/){
	$delete_int_sam = "false";
    }
}
if ($CONVERT_SAM2BAM ne ""){
    if ($CONVERT_SAM2BAM =~ /^true/ | $CONVERT_SAM2BAM =~ /^TRUE/){
	$convert_sam2bam = "true";
    }
    if ($CONVERT_SAM2BAM =~ /^false/ | $CONVERT_SAM2BAM =~ /^FALSE/){
	$convert_sam2bam= "false";
    }
}
if ($GZIP_COV ne ""){
    if ($GZIP_COV =~ /^true/ | $GZIP_COV =~ /^TRUE/){
        $gzip_cov = "true";
    }
    if ($GZIP_COV =~ /^false/ | $GZIP_COV =~ /^FALSE/){
        $gzip_cov = "false";
    }
}

$lsf = "false";
$sge = "false";
$other = "false";
$num_cluster = 0;
if ($SGE_CLUSTER =~ /^true/ | $SGE_CLUSTER =~ /^TRUE/) {
    $num_cluster++;
    if ($QUEUE_NAME_4G_sge eq "" | $QUEUE_NAME_6G_sge eq "" | $QUEUE_NAME_10G_sge eq "" |  $QUEUE_NAME_15G_sge eq "" | $QUEUE_NAME_30G_sge eq "" | $QUEUE_NAME_45G_sge eq "" | $QUEUE_NAME_60G_sge eq "" | $MAX_JOBS_sge eq ""){
        die "ERROR: please provide all required CLUSTER INFO for SGE_CLUSTER in the $cfg_file file\n";
    }
    else{
	$batchjobs = "qsub -cwd";
	$jobname = "-N";
	$status = "qstat -r";
	$request = "-l h_vmem=";
	$queue_4G = $QUEUE_NAME_4G_sge;
	$queue_6G = $QUEUE_NAME_6G_sge;
	$queue_10G = $QUEUE_NAME_10G_sge;
	$queue_15G = $QUEUE_NAME_15G_sge;
	$queue_30G = $QUEUE_NAME_30G_sge;
	$queue_45G = $QUEUE_NAME_45G_sge;
	$queue_60G = $QUEUE_NAME_60G_sge;
	$submit = "-sge";
	$sge = "true";
	$c_option = $submit;
	$maxjobs = $MAX_JOBS_sge;
    }
}
if ($LSF_CLUSTER =~ /^true/ | $LSF_CLUSTER =~ /^TRUE/){
    $num_cluster++;
    if ($QUEUE_NAME_4G_lsf eq "" | $QUEUE_NAME_6G_lsf eq "" | $QUEUE_NAME_10G_lsf eq "" |  $QUEUE_NAME_15G_lsf eq "" | $QUEUE_NAME_30G_lsf eq "" | $QUEUE_NAME_45G_lsf eq "" | $QUEUE_NAME_60G_lsf eq "" | $MAX_JOBS_lsf eq ""){
        die "ERROR: please provide all required CLUSTER INFO for LSF_CLUSTER in the $cfg_file file\n";
    }
    else{
	$batchjobs = "bsub";
	$jobname = "-J";
	$status = "bjobs -w";
	$request = "-q";
	$queue_4G = $QUEUE_NAME_4G_lsf;
	$queue_6G = $QUEUE_NAME_6G_lsf;
	$queue_10G = $QUEUE_NAME_10G_lsf;
	$queue_15G = $QUEUE_NAME_15G_lsf;
	$queue_30G = $QUEUE_NAME_30G_lsf;
	$queue_45G = $QUEUE_NAME_45G_lsf;
	$queue_60G = $QUEUE_NAME_60G_lsf;
	$submit = "-lsf";
	$lsf = "true";
	$c_option = $submit;
	$maxjobs = $MAX_JOBS_lsf;
    }
}
if ($OTHER_CLUSTER =~ /^true/ | $OTHER_CLUSTER =~ /^TRUE/){
    $num_cluster++;
    if ($SUBMIT_BATCH_JOBS eq "" | $JOB_NAME_OPTION eq "" | $CHECK_STATUS_FULLNAME eq "" | $REQUEST_RESOURCE_OPTION eq "" | $QUEUE_NAME_4G eq "" | $QUEUE_NAME_6G eq "" | $QUEUE_NAME_10G eq "" |  $QUEUE_NAME_15G eq "" | $QUEUE_NAME_30G eq "" | $QUEUE_NAME_45G eq "" | $QUEUE_NAME_60G eq "" | $MAX_JOBS eq ""){
	die "ERROR: please provide all required CLUSTER INFO for OTHER_CLUSTER in the $cfg_file file\n";
    }
    else {
	$batchjobs = $SUBMIT_BATCH_JOBS;
	$jobname = $JOB_NAME_OPTION;
	$status = $CHECK_STATUS_FULLNAME;
	$request = $REQUEST_RESOURCE_OPTION;
	$queue_4G = $QUEUE_NAME_4G;
	$queue_6G = $QUEUE_NAME_6G;
	$queue_10G = $QUEUE_NAME_10G;
	$queue_15G = $QUEUE_NAME_15G;
	$queue_30G = $QUEUE_NAME_30G;
	$queue_45G = $QUEUE_NAME_45G;
	$queue_60G = $QUEUE_NAME_60G;
	$submit = "-other";
	$other = "true";
	$maxjobs = $MAX_JOBS;
    }
}
if ($num_cluster ne '1'){
    die "ERROR: please specify which cluster you're using in your $cfg_file file\n";
}

$exon_list = "$LOC/master_list_of_exons.txt";
$novel_list = "$LOC/master_list_of_exons.$study.txt";
$shdir = $study_dir . "shell_scripts";
$normdir = $study_dir . "NORMALIZED_DATA";
$logdir = $study_dir . "logs";
$logfile = $logdir . "/$study.run_normalization.log";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

$cluster_max = "";
if ($maxjobs ne '200'){
    $cluster_max = "-max_jobs $maxjobs";
}


@s = split(" ", $status);
$stat = $s[0];

$input = `cat $shdir/runall_normalization.sh`;


open(LOG, ">>$logfile");
print LOG "\n*************\n$input\n*************\n";
if (-e "$logdir/$study.runall_normalization.out"){
    `rm $logdir/$study.runall_normalization.out`;

}
if (-e "$logdir/$study.runall_normalization.err"){
    `rm $logdir/$study.runall_normalization.err`;
}

if ($run_blast eq "true"){
    $job_num = 1;
    print LOG "\nPreprocessing\n-------------\n";

#get_total_num_reads.pl
    $name_of_job = "$study.get_total_num_reads";
    $err_name = "$name_of_job.err";
    
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }

    $job = "echo \"perl $norm_script_dir/get_total_num_reads.pl $sample_dir $LOC $unaligned_file $unaligned_type $unaligned_z\" | $batchjobs $jobname \"$study.get_total_num_reads\" -o $logdir/$study.get_total_num_reads.out -e $logdir/$study.get_total_num_reads.err";
    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;

#sam2mappingstats.pl
    $name_of_alljob = "$study.runall_sam2mappingstats";
    $name_of_job = "$study.sam2mappingstats";
    $err_name = "sam2mappingstats.*.err";
    &clear_log($name_of_alljob, $err_name);

    $total = "$study_dir/STATS/total_num_reads.txt";
    $sorted = `cut -f 2 $total | sort`;
    @a = split (/\n/, $sorted);
    $max = $a[@a-1];
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs,$jobname,$request,$queue_30G,$stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_30G";
    }
    if ($max > 200000000){
	$new_queue = "-mem 60G";
    }
    else{
	if ($max > 150000000){
	    $new_queue = "-mem 45G";
	}
    }
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_sam2mappingstats.pl $sample_dir $LOC $samfilename true $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_sam2mappingstats\" -o $logdir/$study.runall_sam2mappingstats.out -e $logdir/$study.runall_sam2mappingstats.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;

#getstats.pl
    $name_of_job = "$study.getstats";
    $err_name = "$name_of_job.err";
    
    &clear_log($name_of_job, $err_name);
        
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }

    $job = "echo \"perl $norm_script_dir/getstats.pl $sample_dir $LOC\" | $batchjobs  $jobname \"$study.getstats\" -o $logdir/$study.getstats.out -e $logdir/$study.getstats.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;

#blast
    $name_of_alljob = "$study.runall_runblast";
    $name_of_job = "$study.runblast";
    $err_name = "runblast.*.err";
    &clear_log($name_of_alljob, $err_name);
    
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs,$jobname, $request, $queue_6G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_6G";
    }

    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }

    $job = "echo \"perl $norm_script_dir/runall_runblast.pl $sample_dir $LOC $samfilename $norm_script_dir/ncbi-blast-2.2.27+ $norm_script_dir/ncbi-blast-2.2.27+/ribomouse $c_option $new_queue $cluster_max\" | $batchjobs $jobname \"$study.runall_runblast\" -o $logdir/$study.runall_runblast.out -e $logdir/$study.runall_runblast.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;

#ribopercents
    $name_of_alljob = "$study.runall_getribopercents";
    $name_of_job = "$study.getribopercents";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_alljob, $err_name);
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_10G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_10G";
    }
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_get_ribo_percents.pl $sample_dir $LOC $c_option $new_mem $cluster_max \" | $batchjobs  $jobname \"$study.runall_getribopercents\" -o $logdir/$study.runall_getribopercents.out -e $logdir/$study.runall_getribopercents.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;

#predict_num_reads
    $name_of_job = "$study.predict_num_reads";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/predict_num_reads.pl $sample_dir $LOC $se\" | $batchjobs $jobname \"$study.predict_num_reads\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;
    $exp_num_reads = `grep Expected $study_dir/STATS/expected_num_reads.txt`;
    print LOG "\n* $exp_num_reads\n";
}

if ($run_norm eq "true"){
    $job_num = 1;
    print LOG "\nNormalization\n-------------\n";
#filter_sam
    $name_of_alljob = "$study.runall_filtersam";
    $name_of_job = "$study.filtersam";
    $err_name = "filtersam.*.err";
    &clear_log($name_of_alljob, $err_name);
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_4G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_4G";
    }
    while(qx{$stat | wc -l} > $maxjobs){
	sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_filter.pl $sample_dir $LOC $samfilename $se $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_filtersam\" -o $logdir/$study.runall_filtersam.out -e $logdir/$study.runall_filtersam.err";
    
    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;

#get_master_list_of_exons
    $name_of_job = "$study.get_master_list_of_exons_from_geneinfofile";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/get_master_list_of_exons_from_geneinfofile.pl $geneinfo $LOC\" | $batchjobs $jobname \"$study.get_master_list_of_exons_from_geneinfofile\" -o $logdir/$study.get_master_list_of_exons_from_geneinfofile.out -e $logdir/$study.get_master_list_of_exons_from_geneinfofile.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;
    
    if ($novel eq "true"){
    #junctions
	$name_of_alljob = "$study.runall_sam2junctions.samfilename";
	$name_of_job = "$study.sam2junctions";
	$err_name = "sam2junctions.*.err";
	&clear_log($name_of_alljob, $err_name);
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	    $new_queue = "";
	}
	else{
	    $new_queue = "-mem $queue_6G";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}	
	$job = "echo \"perl $norm_script_dir/runall_sam2junctions.pl $sample_dir $LOC $geneinfo $genome -samfilename $samfilename $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_sam2junctions.samfilename\" -o $logdir/$study.runall_sam2junctions.samfilename.out -e $logdir/$study.runall_sam2junctions.samfilename.err";

	&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    
    #novel_exons 
	$name_of_job = "$study.runall_get_novel_exons";
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	$min_option = "";
	$max_option = "";
	$mem = "$request$queue_4G";
	if ($min ne '10'){
	    $min_option = "-min $min";
	}
	if ($max ne '2000'){
	    $max_option = "-max $max";
	}
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
	$job = "echo \"perl $norm_script_dir/runall_get_novel_exons.pl $sample_dir $LOC $samfilename $min_option $max_option\" | $batchjobs  $jobname \"$study.runall_get_novel_exons\" $mem -o $logdir/$study.runall_get_novel_exons.out -e $logdir/$study.runall_get_novel_exons.err";

	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }    

#quantify_exons for filter
    $name_of_alljob = "$study.quantifyexons.filter.u";
    $name_of_job = "$study.quantifyexons2";
    $err_name = "quantifyexons2.*.err";
    &clear_log($name_of_alljob, $err_name);

    if ($novel eq "true"){
	$list_for_quant = $novel_list;
    }
    if ($novel eq "false"){
	$list_for_quant = $exon_list;
    }
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_4G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_4G";
    }
    while(qx{$stat | wc -l} > $maxjobs){
	sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_quantify_exons.pl $sample_dir $LOC $list_for_quant false $se $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.quantifyexons.filter.u\" -o $logdir/$study.quantifyexons.filter.u.out -e $logdir/$study.quantifyexons.filter.u.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#quantify_exons for filter nu
    $name_of_alljob = "$study.quantifyexons.filter.nu";
    $name_of_job = "$study.quantifyexons2";
    $err_name = "nu.quantifyexons2.*.err";
    &clear_log($name_of_alljob, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
	sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_quantify_exons.pl $sample_dir $LOC $list_for_quant false $se -NU-only $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.quantifyexons.filter.nu\" -o $logdir/$study.quantifyexons.filter.nu.out -e $logdir/$study.quantifyexons.filter.nu.err";
    
    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#get_high_expressors 
    $name_of_alljob = "$study.runall_get_high_expressors";
    $name_of_job = "$study.get_high_expressor";
    $err_name = "*annotate*.err";
    &clear_log($name_of_alljob, $err_name);
    if ($filter_high_expressors eq "false" | $cutoff_he eq '100'){
	$cutoff_he = 10;
    }
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_15G";
    }
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_get_high_expressors.pl $sample_dir $LOC $cutoff_he $annot $list_for_quant $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_get_high_expressors\" -o $logdir/$study.runall_get_high_expressors.out -e $logdir/$study.runall_get_high_expressors.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob,  $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
    if ($filter_high_expressors eq 'true'){
    #filter_high_expressors
	$name_of_job = "$study.filter_high_expressors";
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}	
	$job = "echo \"perl $norm_script_dir/filter_high_expressors.pl $sample_dir $LOC $list_for_quant\" | $batchjobs  $jobname \"$study.filter_high_expressors\" -o $logdir/$study.filter_high_expressors.out -e $logdir/$study.filter_high_expressors.err";

	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }
    
#get_percent_high_expressor
    $name_of_job = "$study.get_percent_high_expressor";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/get_percent_high_expressor.pl $sample_dir $LOC\" | $batchjobs  $jobname \"$study.get_percent_high_expressor\" -o $logdir/$study.get_percent_high_expressor.out -e $logdir/$study.get_percent_high_expressor.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;
    
#run_quantify_exons unique
    $name_of_alljob = "$study.runall_quantify_exons.true.u";
    $name_of_job = "$study.quantifyexons";
    $err_name = "quantifyexons.*.err";
    &clear_log($name_of_alljob, $err_name);
    $filtered_list = $list_for_quant;
    $filtered_list =~ s/master_list/filtered_master_list/g;
    if ($filter_high_expressors eq "true"){
	$list_for_quant2 = $filtered_list;
    }
    else {
	$list_for_quant2 = $list_for_quant;
    }
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_4G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_4G";
    }
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_quantify_exons.pl $sample_dir $LOC $list_for_quant2 true $se $c_option -depth $i_exon $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_quantify_exons.true.u\" -o $logdir/$study.runall_quantify_exons.true.u.out -e $logdir/$study.runall_quantify_exons.true.u.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;

#run_quantify_exons nu
    $name_of_alljob = "$study.runall_quantify_exons.true.nu";
    $name_of_job = "$study.quantifyexons";
    $err_name = "nu.quantifyexons.*.err";
    &clear_log($name_of_alljob, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }    
    $job = "echo \"perl $norm_script_dir/runall_quantify_exons.pl $sample_dir $LOC $list_for_quant2 true $se $c_option -NU-only -depth $i_exon $new_queue\" | $batchjobs  $jobname \"$study.runall_quantify_exons.true.nu\" -o $logdir/$study.runall_quantify_exons.true.nu.out -e $logdir/$study.runall_quantify_exons.true.nu.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#exon2nonexon
    $name_of_job = "$study.get_exon2nonexon_stats";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }    
    $job = "echo \"perl $norm_script_dir/get_exon2nonexon_signal_stats.pl $sample_dir $LOC\" | $batchjobs  $jobname \"$study.get_exon2nonexon_stats\" -o $logdir/$study.get_exon2nonexon_stats.out -e $logdir/$study.get_exon2nonexon_stats.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;
    
#1exonvsmultiexons
    $name_of_job = "$study.get_1exonvsmultiexons_stats";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/get_1exon_vs_multi_exon_stats.pl $sample_dir $LOC\" | $batchjobs  $jobname \"$study.get_1exonvsmultiexons_stats\" -o $logdir/$study.get_1exonvsmultiexons_stats.out -e $logdir/$study.get_1exonvsmultiexons_stats.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;

#get_master_list_of_introns
    $name_of_job = "$study.get_master_list_of_introns_from_geneinfofile";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/get_master_list_of_introns_from_geneinfofile.pl $geneinfo $LOC\" | $batchjobs  $jobname \"$study.get_master_list_of_introns_from_geneinfofile\" -o $logdir/$study.get_master_list_of_introns_from_geneinfofile.out -e $logdir/$study.get_master_list_of_introns_from_geneinfofile.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;

#run_quantify_introns unique 
    $name_of_alljob = "$study.runall_quantify_introns.true.u";
    $name_of_job = "$study.quantifyintrons";
    $err_name = "quantifyintrons.*.err";
    &clear_log($name_of_alljob, $err_name);
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_4G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_4G";
    }
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_quantify_introns.pl $sample_dir $LOC $LOC/master_list_of_introns.txt true $c_option -depth $i_intron $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_quantify_introns.true.u\" -o $logdir/$study.runall_quantify_introns.true.u.out -e $logdir/$study.runall_quantify_introns.true.u.err";
    
    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#run_quantify_introns nu
    $name_of_alljob = "$study.runall_quantify_introns.true.nu";
    $name_of_job = "$study.quantifyintrons";
    $err_name = "nu.quantifyintrons.*.err";
    &clear_log($name_of_alljob, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_quantify_introns.pl $sample_dir $LOC $LOC/master_list_of_introns.txt true $c_option -NU-only -depth $i_intron $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_quantify_introns.true.nu\" -o $logdir/$study.runall_quantify_introns.true.nu.out -e $logdir/$study.runall_quantify_introns.true.nu.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#get_percent_intergenic
    $name_of_job = "$study.get_percent_intergenic";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/get_percent_intergenic.pl $sample_dir $LOC\" | $batchjobs  $jobname \"$study.get_percent_intergenic\" -o $logdir/$study.get_percent_intergenic.out -e $logdir/$study.get_percent_intergenic.err ";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;

#runall_head
    $name_of_alljob = "$study.runall_head";
    $name_of_job = "$study.head";
    $err_name = "*_head.*.err";
    &clear_log($name_of_alljob, $err_name);
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs, $jobname, $stat\\\"";
    }
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_head.pl $sample_dir $LOC $c_option $cluster_max -depthE $i_exon -depthI $i_intron\" | $batchjobs  $jobname \"$study.runall_head\" -o $logdir/$study.runall_head.out -e $logdir/$study.runall_head.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#cat_headfiles
    $name_of_job = "$study.cat_headfiles";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/cat_headfiles.pl $sample_dir $LOC\" | $batchjobs  $jobname \"$study.cat_headfiles\" -o $logdir/$study.cat_headfiles.out -e $logdir/$study.cat_headfiles.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;
    
#make_final_samfile
    $name_of_job = "$study.make_final_samfile";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/make_final_samfile.pl $sample_dir $LOC $samfilename\" | $batchjobs  $jobname \"$study.make_final_samfile\" -o $logdir/$study.make_final_samfile.out -e $logdir/$study.make_final_samfile.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;
    
#runall_sam2junctions
    $name_of_alljob = "$study.runall_sam2junctions";
    $name_of_job = "$study.sam2junctions";
    $err_name = "sam2junctions.*.err";
    &clear_log($name_of_alljob, $err_name);
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_6G";
    }
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }    
    $job = "echo \"perl $norm_script_dir/runall_sam2junctions.pl $sample_dir $LOC $geneinfo $genome $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_sam2junctions\" -o $logdir/$study.runall_sam2junctions.out -e $logdir/$study.runall_sam2junctions.err";
    
    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#cat_exonmappers
    $name_of_job = "$study.cat_exonmappers";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/cat_exonmappers_Unique_NU.pl $sample_dir $LOC\" | $batchjobs  $jobname \"$study.cat_exonmappers\" -o $logdir/$study.cat_exonmappers.out -e $logdir/$study.cat_exonmappers.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;

#runall_quantify_exons (merged/unique)
    $name_of_alljob = "$study.runall_quantify_exons.false";
    $name_of_job = "$study.quantifyexons2";
    $err_name = "quantifyexons2.*.err";
    &clear_log($name_of_alljob, $err_name);
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_4G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_4G";
    }
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_quantify_exons.pl $sample_dir $LOC $list_for_quant2 false $se $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_quantify_exons.false\" -o $logdir/$study.runall_quantify_exons.false.out -e $logdir/$study.runall_quantify_exons.false.err";
    
    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#runall_quantify_introns unique
    $name_of_alljob = "$study.runall_quantify_introns.false.u";
    $name_of_job = "$study.quantifyintrons2";
    $err_name = "quantifyintrons2.*.err";
    &clear_log($name_of_alljob, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_quantify_introns.pl $sample_dir $LOC $LOC/master_list_of_introns.txt false $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_quantify_introns.false.u\" -o $logdir/$study.runall_quantify_introns.false.u.out -e $logdir/$study.runall_quantify_introns.false.u.err";
    
    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#runall_quantify_introns nu
    $name_of_alljob = "$study.runall_quantify_introns.false.nu";
    $name_of_job = "$study.quantifyintrons2";
    $err_name = "nu.quantifyintrons2.*.err";
    &clear_log($name_of_alljob, $err_name);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_quantify_introns.pl $sample_dir $LOC $LOC/master_list_of_introns.txt false $c_option -NU-only $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_quantify_introns.false.nu\" -o $logdir/$study.runall_quantify_introns.false.nu.out -e $logdir/$study.runall_quantify_introns.false.nu.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;

#make_final_spreadsheets
    $name_of_alljob = "$study.make_final_spreadsheets";
    $name_of_job = "$study.final_spreadsheet";
    $err_name = "*2spreadsheet_min_max.err";
    &clear_log($name_of_alljob, $err_name);
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs,$jobname, $request, $queue_6G, $queue_10G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_10G";
    }
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }

    $job = "echo \"perl $norm_script_dir/make_final_spreadsheets.pl $sample_dir $LOC $c_option $new_queue \" | $batchjobs  $jobname \"$study.make_final_spreadsheets\" -o $logdir/$study.make_final_spreadsheets.out -e $logdir/$study.make_final_spreadsheets.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#run_annotate
    $name_of_alljob = "$study.run_annotate";
    $name_of_job = "$study.annotate";
    $err_name = "annotate.*.txt.err";
    &clear_log($name_of_alljob, $err_name);
    $to_annotate = "$study_dir/NORMALIZED_DATA/to_annotate.txt";
    open(out, ">$to_annotate");
    print out "master_list_of_exons_counts_MIN.$study.txt\nmaster_list_of_exons_counts_MAX.$study.txt\nmaster_list_of_introns_counts_MIN.$study.txt\nmaster_list_of_introns_counts_MAX.$study.txt\nmaster_list_of_junctions_counts_MIN.$study.txt\nmaster_list_of_junctions_counts_MAX.$study.txt\n";
    close(out);
    if ($other eq "true"){
	$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_15G";
    }
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/run_annotate.pl $to_annotate $annot $LOC $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.run_annotate\" -o $logdir/$study.run_annotate.out -e $logdir/$study.run_annotate.err";
    
    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;
    
#filter_low_expressors
    $name_of_job = "$study.filter_low_expressors";
    $err_name = "$name_of_job.err";
    &clear_log($name_of_job, $err_name);
    $to_filter = "$study_dir/NORMALIZED_DATA/to_filter.txt";
    open(out, ">$to_filter");
    print out "annotated_master_list_of_exons_counts_MIN.$study.txt\nannotated_master_list_of_exons_counts_MAX.$study.txt\nannotated_master_list_of_introns_counts_MIN.$study.txt\nannotated_master_list_of_introns_counts_MAX.$study.txt\nannotated_master_list_of_junctions_counts_MIN.$study.txt\nannotated_master_list_of_junctions_counts_MAX.$study.txt\n";
    close(out);
    while(qx{$stat | wc -l} > $maxjobs){
        sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_filter_low_expressors.pl $to_filter $num_samples $cutoff_le $LOC\" | $batchjobs  $jobname \"$study.filter_low_expressors\" -o $logdir/$study.filter_low_expressors.out -e $logdir/$study.filter_low_expressors.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;

#runall_sam2cov
    print LOG "\nPostprocessing\n--------------\n";
    $job_num = 1;
    $name_of_alljob = "$study.runall_sam2cov";
    $name_of_job = "$study.sam2cov";
    $err_name = "sam2cov.*.err";
    &clear_log($name_of_alljob, $err_name);
    if ($sam2cov eq "true"){
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
	    $new_queue = "";
	}
	else{
	    $new_queue = "-mem $queue_15G";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/runall_sam2cov.pl $sample_dir $LOC $fai $sam2cov_loc $aligner $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_sam2cov\" -o $logdir/$study.runall_sam2cov.out -e $logdir/$study.runall_sam2cov.err";
	
	&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&only_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }

#mappingstats_norm
    $name_of_alljob = "$study.runall_sam2mappingstats.norm";
    $name_of_job = "$study.sam2mappingstats.norm";
    $err_name = "sam2mappingstats.norm.*.err";

    &clear_log($name_of_alljob, $err_name);

    $total = "$study_dir/STATS/total_num_reads.txt";
    $sorted = `cut -f 2 $total | sort`;
    @a = split (/\n/, $sorted);
    $min = $a[0];
    if ($other eq "true"){
        $c_option = "$submit \\\"$batchjobs,$jobname,$request,$queue_30G,$stat\\\"";
        $new_queue = "";
    }
    else{
        $new_queue = "-mem $queue_30G";
    }
    if ($min > 200000000){
        $new_queue = "-mem 60G";
    }
    else{
        if ($min > 150000000){
            $new_queue = "-mem 45G";
        }
    }
    while (qx{$status | wc -l} > $maxjobs){
	sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/runall_sam2mappingstats.pl $sample_dir $LOC $samfilename false -norm $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_sam2mappingstats.norm\" -o $logdir/$study.runall_sam2mappingstats.norm.out -e $logdir/$study.runall_sam2mappingstats.norm.err";

    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
    &check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
    &check_err ($name_of_alljob, $err_name, $job_num);
    $job_num++;

#getstats_normsam
    $name_of_job = "$study.getstats.norm";
    $err_name = "$name_of_job.err";

    &clear_log($name_of_job, $err_name);
    while (qx{$status | wc -l} > $maxjobs){
	sleep(10);
    }
    $job = "echo \"perl $norm_script_dir/getstats.pl $sample_dir $LOC -norm\" | $batchjobs  $jobname \"$study.getstats.norm\" -o $logdir/$study.getstats.norm.out -e $logdir/$study.getstats.norm.err";

    &onejob($job, $name_of_job, $job_num);
    &check_exit_onejob($job, $name_of_job, $job_num);
    &check_err ($name_of_job, $err_name, $job_num);
    $job_num++;
    
#cleanup: delete intermediate sam
    $name_of_job = "$study.cleanup";
    $err_name = "$name_of_job.err";
    if ($delete_int_sam eq "true"){
	&clear_log($name_of_job, $err_name);
	while (qx{$status | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/cleanup.pl $sample_dir $LOC\" | $batchjobs  $jobname \"$study.cleanup\" -o $logdir/$study.cleanup.out -e $logdir/$study.cleanup.err";
	
	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }

#cleanup: compress 
    $name_of_alljob = "$study.runall_compress";
    $name_of_job = "$study.compress";
    $err_name = "sam2bam.*.err";
    if ($convert_sam2bam eq "true" | $gzip_cov eq "true"){
	&clear_log($name_of_job, $err_name);
	$option = "-dont_cov -dont_bam";
	if ($convert_sam2bam eq "true"){
	    $option =~ s/-dont_bam//g;
	}
	if ($gzip_cov eq 'true'){
	    $option =~ s/-dont_cov//g;
	}
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	    $new_queue = "";
	}
	else{
	    $new_queue = "-mem $queue_6G";
	}
	while (qx{$status | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/runall_compress.pl $sample_dir $LOC $samfilename $fai $c_option $new_queue $cluster_max\" | $batchjobs  $jobname \"$study.runall_compress\" -o $logdir/$study.runall_compress.out -e $logdir/$study.runall_compress.err ";
	&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_exit_alljob($job, $name_of_alljob, $job_num, $err_name);
	&only_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }
    print LOG "\n* Normalization completed successfully.\n\n";
}

close(LOG);

sub parse_config_file () {
    ($File, $Config) = @_;
    open(CONFIG, "$File") or die "ERROR: Config file not found : $File\n";
    while ($config_line = <CONFIG>) {
	chomp($config_line);
        $config_line =~ s/^\s*//;
        $config_line =~ s/\s*$//;
        if ( ($config_line !~ /^#/) && ($config_line ne "") ){
	    my ($Name, $Value) = split(/\s*=\s*/, $config_line, 2);
	    if ($Value =~ /^"/){
		$Value =~ s/^"//;
		$Value =~ s/"$//;
	    }
	    $Config{$Name} = $Value;
	    $$Name = $Value;
	}
    }
}


sub onejob {
    my ($job, $name_of_job, $job_num) = @_;
    `$job`;
    $date = `date`;
    print LOG "$job_num  \"$name_of_job\"\n\tSTARTED: $date";

    sleep(10);
    $check = `$status | grep -w "$name_of_job"  | wc -l`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -w "$name_of_job" | wc -l`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
}

sub runalljob{
    my ($job, $name_of_alljob, $name_of_job, $job_num, $err_name) =@_;
    $out_name = $err_name;
    $out_name =~ s/err/out/g;
    `$job`;
    $date = `date`;
    print LOG "$job_num  \"$name_of_alljob\"\n\tSTARTED: $date";

    sleep(10);
    $check = `$status | grep -C 1 -w "$name_of_alljob" | egrep 'PEND|qw|hqw' | wc -l`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -C 1 -w "$name_of_alljob" | egrep 'PEND|qw|hqw' | wc -l`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
    $check = `$status | grep -w "$name_of_alljob" | wc -l`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -w "$name_of_alljob" | wc -l`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
    $check = `$status | grep -w "$name_of_job" | wc -l`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -w "$name_of_job"  | wc -l`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
}
    
sub check_exit_onejob {
    my ($job, $name_of_job, $job_num) = @_;
    $outfile = "$logdir/$name_of_job.out";
    until (-e $outfile){
	sleep(10);
    }
    $check_out = `grep "got here" $outfile | grep -v echo | wc -l`;
    chomp($check_out);
    if ($check_out eq '0'){
	if (-e "$logdir/$name_of_job.err"){
	    `rm $logdir/$name_of_job.err`;
	}
	if (-e "$logdir/$name_of_job.out"){
	    `rm $logdir/$name_of_job.out`;
	}
	$jobnum_rep = "\t**Job exited before completing\n\tretrying...";
	&onejob($job, $name_of_job, $jobnum_rep);
    }
}

sub check_exit_alljob{
    my ($job, $name_of_alljob, $job_num, $err_name) = @_;
    $outfile_all = "$logdir/$name_of_alljob.out";
    while (qx{ls $outfile_all | wc -l} < 1){
	sleep(10);
    }

    $check_out_all = `grep "got here" $outfile_all | grep -v echo | wc -l`;
    chomp($check_out_all);
    if ($check_out_all eq '0'){
	if (-e "$logdir/$name_of_alljob.err"){
	    `rm $logdir/$name_of_alljob.err`;
	}
	if (-e "$logdir/$name_of_alljob.out"){
	    `rm $logdir/$name_of_alljob.out`;
	}
	@g = glob("$logdir/$out_name");
	if (@g ne '0'){
	    `rm $logdir/$out_name`;
	}
	@g = glob("$logdir/$err_name");
	if (@g ne '0'){
	    `rm $logdir/$err_name`;
	}
	$jobnum_rep = "\t**Job exited before completing\n\tretrying...";
        &runalljob($job, $name_of_alljob, $name_of_job, $jobnum_rep, $err_name, $count);
    }
    else{
	$out_name = $err_name;
	$out_name =~ s/err/out/g;
	$wc_out = `ls $logdir/$out_name | wc -l`;
	$check_out = `grep "got here" $logdir/$out_name | grep -v echo | wc -l`;
	if (qx{grep "SAM header" $logdir/$err_name | wc -l} > 0){
	    `sed -i '/SAM header/d' $logdir/$err_name`;
	}
	chomp($wc_out);
	chomp($check_out);
	if ($check_out ne $wc_out){
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
	    @g = glob("$logdir/$out_name");
	    if (@g ne '0'){
		`rm $logdir/$out_name`;
	    }
	    @g = glob("$logdir/$err_name");
	    if (@g ne '0'){
		`rm $logdir/$err_name`;
	    }
	    $jobnum_rep = "\t**Job exited before completing\n\tretrying...";
	    &runalljob($job, $name_of_alljob, $name_of_job, $jobnum_rep, $err_name, $count);
	}
    }
}

sub check_err {
    my ($name_of_job, $err_name, $job_num) = @_;
    $out_name = $err_name;
    $out_name =~ s/err/out/g;
    $outfile = "$logdir/$name_of_job.out";
    $check_out = `grep "got here" $outfile | grep -v echo | wc -l`;
    chomp($check_out);
    $file_count = 1;
    $finish_count = $check_out;
    if ($out_name ne "$name_of_job.out"){ 
	$out_count = `ls $logdir/$out_name | wc -l`;
	chomp($out_count);
	$check_out_count = `grep "got here" $logdir/$out_name | grep -v echo | wc -l`;
	chomp($check_out_count);
	$file_count = $out_count + 1;
	$finish_count = $check_out_count + $check_out;
    }
    if ($file_count ne $finish_count){
	$date = `date`;
	print LOG "***Job killed:\tjob exited before completing\t$date\n";
	die "\nERROR: \"$job_num\t\"$name_of_job\" exited before completing\n";
    }
    else{
	$wc_err = `wc -l $logdir/$name_of_job.err`;
	@wc = split(/\n/, $wc_err);
	$last_wc = $wc[@wc-1];
	@w = split(" ", $last_wc);
	$wc_num = $w[0];
	$err = `cat $logdir/$name_of_job.err`;
	if ($wc_num ne '0'){
	    print LOG "***Job killed:\nstderr: $logdir/$name_of_job.err\n";
	    die "\nERROR: \"$job_num $name_of_job\"\n$err\nstderr: $logdir/$name_of_job.err";
	}
	else{
	    if ("$name_of_job.err" ne "$err_name"){
		$wc_err_sample = `wc -l $logdir/$err_name`;
		@wc = split(/\n/, $wc_err_sample);
		$sum = 0;
		$log = `cat $logdir/$err_name`;
		for($i=0;$i<@wc;$i++){
		    $last_wc = $wc[@wc-1-$i];
		    @w = split(" ", $last_wc);
		    $wc_num = $w[0];
		    $sum = $sum + $wc_num;
		}
		if ($sum ne '0'){
		    print LOG "***Job Killed:\nstderr: $logdir/$err_name\n";
		    die "\nERROR: \"$job_num $name_of_job\"\n$log\nstderr: $logdir/$err_name";
		}
		else{
		    $date =`date`;
		    print LOG "\tCOMPLETED: $date";
		}
	    }
	    else{
		$date =`date`;
		print LOG "\tCOMPLETED: $date";
	    }
	}
    }
}

sub only_err{
    my ($name_of_job, $err_name, $job_num) = @_;
    $wc_err = `wc -l $logdir/$name_of_job.err`;
    @wc = split(" ", $wc_err);
    $wc_num = $wc[0];
    $err = `cat $logdir/$name_of_job.err`;
    if ($wc_num ne '0'){
	print LOG "***Job killed:\nstderr: $logdir/$name_of_job.err\n";
	die "\nERROR: \"$job_num $name_of_job\"\n$err\nstderr: $logdir/$name_of_job.err";
    }
    else{
	if ("$name_of_job.err" ne "$err_name"){
	    $wc_err_sample = `wc -l $logdir/$err_name`;
	    @wc = split(/\n/, $wc_err_sample);
	    $sum = 0;
	    $log = `cat $logdir/$err_name`;
	    for($i=0;$i<@wc;$i++){
		$last_wc = $wc[@wc-1-$i];
		@w = split(" ", $last_wc);
		$wc_num = $w[0];
		$sum = $sum + $wc_num;
	    }
	    if ($sum ne '0'){
		print LOG "***Job Killed:\nstderr: $logdir/$err_name\n";
		die "\nERROR: \"$job_num $name_of_job\"\n$log\nstderr: $logdir/$err_name";
	    }
	    else{
		$date =`date`;
		print LOG "\tCOMPLETED: $date";
	    }
	}
	else{
	    $date =`date`;
	    print LOG "\tCOMPLETED: $date";
	}
    }
}

sub clear_log{
    my ($name_of_job, $err_name) = @_;
    $out_name = $err_name;
    $out_name =~ s/err/out/g;
    @g = glob("$logdir/$out_name*");
    if (@g ne '0'){
	`rm $logdir/$out_name`;
    }
    @g = glob("$logdir/$err_name*");
    if (@g ne '0'){
	`rm $logdir/$err_name`;
    }
    if (-e "$logdir/$name_of_job.err"){
	`rm $logdir/$name_of_job.err`;
    }
    if (-e "$logdir/$name_of_job.out"){
	`rm $logdir/$name_of_job.out`;
    }
}    

