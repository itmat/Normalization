#!/usr/bin/env perl
$USAGE =  "\nUsage: run_normalization --sample_dirs <file of sample_dirs> --loc <s> --unaligned <file of fa/fqfiles> --samfilename <s> --cfg <cfg file> [options]

where:
--sample_dirs <file of sample_dirs> : is a file of sample directories with alignment output without path
--loc <s> : /path/to/directory with the sample directories
--unaligned <file of fa/fqfiles> : is a file with the full path of input forward fa or forward fq files
--samfilename <s> : is the name of aligned sam file (e.g. RUM.sam, Aligned.out.sam) 
--cfg <cfg file> : is a cfg file for the study

OPTIONS:
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

if(@ARGV < 8) {
    die $USAGE;
}

$required = 0;
$unaligned = 0;
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
for($i=0; $i<@ARGV; $i++) {
    $option_found = "false";
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
    if ($QUEUE_NAME_4G_sge eq "" | $QUEUE_NAME_6G_sge eq "" | $QUEUE_NAME_10G_sge eq "" |  $QUEUE_NAME_15G_sge eq "" | $QUEUE_NAME_30G_sge eq "" | $WAIT_OPTION_sge eq "" | $WAIT_2JOBS_OPTION_sge eq "" | $MAX_JOBS_sge eq ""){
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
	$submit = "-sge";
	$sge = "true";
	$c_option = $submit;
	$wait_option = $WAIT_OPTION_sge;
	$wait_2jobs_option = $WAIT_2JOBS_OPTION_sge;
	$maxjobs = $MAX_JOBS_sge;
    }
}
if ($LSF_CLUSTER =~ /^true/ | $LSF_CLUSTER =~ /^TRUE/){
    $num_cluster++;
    if ($QUEUE_NAME_4G_lsf eq "" | $QUEUE_NAME_6G_lsf eq "" | $QUEUE_NAME_10G_lsf eq "" |  $QUEUE_NAME_15G_lsf eq "" | $QUEUE_NAME_30G_lsf eq "" | $WAIT_OPTION_lsf eq "" | $WAIT_2JOBS_OPTION_lsf eq "" | $MAX_JOBS_lsf eq ""){
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
	$submit = "-lsf";
	$lsf = "true";
	$c_option = $submit;
	$wait_option = $WAIT_OPTION_lsf;
	$wait_2jobs_option = $WAIT_2JOBS_OPTION_lsf;
	$maxjobs = $MAX_JOBS_lsf;
    }
}
if ($OTHER_CLUSTER =~ /^true/ | $OTHER_CLUSTER =~ /^TRUE/){
    $num_cluster++;
    if ($SUBMIT_BATCH_JOBS eq "" | $JOB_NAME_OPTION eq "" | $CHECK_STATUS_FULLNAME eq "" | $REQUEST_RESOURCE_OPTION eq "" | $QUEUE_NAME_4G eq "" | $QUEUE_NAME_6G eq "" | $QUEUE_NAME_10G eq "" |  $QUEUE_NAME_15G eq "" | $QUEUE_NAME_30G eq "" | $WAIT_OPTION eq "" | $WAIT_2JOBS_OPTION eq "" | $MAX_JOBS eq ""){
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
	$submit = "-other";
	$other = "true";
	$wait_option = $WAIT_OPTION;
	$wait_2jobs_option = $WAIT_2JOBS_OPTION;
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
$job_num = 1;
open(LOG, ">$logfile");

if ($maxjobs > 200){
    $maxjobs = $maxjobs * 0.75;
}
@s = split(" ", $status);
$stat = $s[0];

#get_total_num_reads.pl
`echo "perl $norm_script_dir/get_total_num_reads.pl $sample_dir $LOC $unaligned_file $unaligned_type $unaligned_z" | $batchjobs $jobname "$study.get_total_num_reads" -o $logdir/$study.get_total_num_reads.out -e $logdir/$study.get_total_num_reads.err`;

$date = `date`;
print LOG "$job_num. started \"$study.get_total_num_reads\"\t$date";
$job_num++;

#sam2mappingstats.pl
$to_wait = "$study.get_total_num_reads";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_30G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_30G";
}

$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_sam2mappingstats.pl $sample_dir $LOC $samfilename true $c_option $new_queue" | $batchjobs $wait $jobname "$study.runall_sam2mappingstats" -o $logdir/$study.runall_sam2mappingstats.out -e $logdir/$study.runall_sam2mappingstats.err`;

$date = `date`;
print LOG "$job_num. started \"$study.runall_sam2mappingstats\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 -w "$study.runall_sam2mappingstats" | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 -w "$study.runall_sam2mappingstats" | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w "$study.runall_sam2mappingstats" | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w "$study.runall_sam2mappingstats" | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w "$study.sam2mappingstats" | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w "$study.sam2mappingstats"  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

#getstats.pl
$to_wait = "$study.get_total_num_reads";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/getstats.pl $sample_dir $LOC" | $batchjobs $wait $jobname "$study.getstats" -o $logdir/$study.getstats.out -e $logdir/$study.getstats.err`;
$date = `date`;
print LOG "$job_num. started \"$study.getstats\"\t$date";
$job_num++;

#blast
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_6G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_6G";
}
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_runblast.pl $sample_dir $LOC $samfilename $norm_script_dir/ncbi-blast-2.2.27+ $norm_script_dir/ncbi-blast-2.2.27+/ribomouse $c_option $new_queue" | $batchjobs $jobname "$study.runall_runblast" -o $logdir/$study.runall_runblast.out -e $logdir/$study.runall_runblast.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_runblast\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 -w "$study.runall_runblast" | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 -w "$study.runall_runblast" | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w "$study.runall_runblast" | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w "$study.runall_runblast" | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w "$study.runblast"  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w "$study.runblast"  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

#ribopercents
$to_wait = "$study.runblast";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_10G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_10G";
}
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_get_ribo_percents.pl $sample_dir $LOC $c_option $new_mem" | $batchjobs $wait $jobname "$study.runall_getribopercents" -o $logdir/$study.runall_getribopercents.out -e $logdir/$study.runall_getribopercents.err`;
$date = `date`;
print LOG "$job_num. started \"$study.ribopercents\"\t$date";
$job_num++;

#filter_sam
$to_wait = "$study.runblast";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_4G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_4G";
}
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_filter.pl $sample_dir $LOC $samfilename $se $c_option $new_queue" | $batchjobs $wait $jobname "$study.runall_filtersam" -o $logdir/$study.runall_filtersam.out -e $logdir/$study.runall_filtersam.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_filtersam\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 -w "$study.runall_filtersam" | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 -w "$study.runall_filtersam" | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w "$study.runall_filtersam"  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w "$study.runall_filtersam"  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w "$study.filtersam"  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w "$study.filtersam"  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

#get_master_list_of_exons
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/get_master_list_of_exons_from_geneinfofile.pl $geneinfo $LOC" | $batchjobs $jobname "$study.get_master_list_of_exons_from_geneinfofile" -o $logdir/$study.get_master_list_of_exons_from_geneinfofile.out -e $logdir/$study.get_master_list_of_exons_from_geneinfofile.err`;
$date = `date`;
print LOG "$job_num. started \"get_master_list_of_exons_from_geneinfofile\"\t$date";
$job_num++;


if ($novel eq "true"){
    #junctions
    $to_wait = "$study.get_master_list_of_exons_from_geneinfofile";
    $wait = $wait_option;
    $wait =~ s/JOB/$to_wait/;
    if ($other eq "true"){
	$c_option = "$submit $batchjobs $jobname $request $queue_6G";
	$new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_6G";
    }

    $numq = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $numq + $num_samples;
    until ($qneeded < $maxjobs){
	$x = `$stat | grep "^[0-9]" | wc -l`;
	$qneeded = $x + $num_samples;
	sleep(10);
    }
    `echo "perl $norm_script_dir/runall_sam2junctions.pl $sample_dir $LOC $geneinfo $genome -samfilename $samfilename $c_option $new_queue" | $batchjobs $wait $jobname "$study.runall_sam2junctions.samfilename" -o $logdir/$study.runall_sam2junctions.samfilename.out -e $logdir/$study.runall_sam2junctions.samfilename.err`;
    $date = `date`;
    print LOG "$job_num. started \"$study.runall_sam2junctions.samfilename\"\t$date";
    $job_num++;

    sleep(10);
    $check = `$status | grep -C 1 -w "$study.runall_sam2junctions" | egrep 'PEND|qw|hqw' | wc -l`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -C 1 -w "$study.runall_sam2junctions" | egrep 'PEND|qw|hqw' | wc -l`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
    $check = `$status | grep -w "$study.runall_sam2junctions"  | wc -l`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -w "$study.runall_sam2junctions"  | wc -l`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
    $check = `$status | grep -w "$study.sam2junctions"  | wc -l`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -w "$study.sam2junctions"  | wc -l`;
	sleep(10);
	chomp($check);
    }
    sleep(10);

    #novel_exons 
    $to_wait = "$study.sam2junctions";
    $wait = $wait_option;
    $wait =~ s/JOB/$to_wait/;
    $min_option = "";
    $max_option = "";
    if ($min ne '10'){
	$min_option = "-min $min";
    }
    if ($max ne '2000'){
	$max_option = "-max $max";
    }
    $numq =`$stat | grep "^[0-9]" | wc -l`;
    until ($numq < $maxjobs){
	$x = `$stat | grep "^[0-9]" | wc -l`;
	$numq = $x;
	sleep(10);
    }
    `echo "perl $norm_script_dir/runall_get_novel_exons.pl $sample_dir $LOC $samfilename $min_option $max_option" | $batchjobs $wait $jobname "$study.runall_get_novel_exons" -o $logdir/$study.runall_get_novel_exons.out -e $logdir/$study.runall_get_novel_exons.err`;
    $date = `date`;
    print LOG "$job_num. started \"$study.runall_get_novel_exons\"\t$date";
    $job_num++;
}    
#quantify_exons for filter
if ($novel eq "true"){
    $to_wait1 = "$study.filtersam";
    $to_wait2 = "$study.runall_get_novel_exons";
    $wait = $wait_2jobs_option;
    $wait =~ s/JOB1/$to_wait1/;
    $wait =~ s/JOB2/$to_wait2/;
    $list_for_quant = $novel_list;
}
if ($novel eq "false"){
    $to_wait1 = "$study.filtersam";
    $to_wait2 = "$study.get_master_list_of_exons_from_geneinfofile";
    $wait = $wait_2jobs_option;
    $wait =~ s/JOB1/$to_wait1/;
    $wait =~ s/JOB2/$to_wait2/;
    $list_for_quant = $exon_list;
}
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_4G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_4G";
}

$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}

`echo "perl $norm_script_dir/runall_quantify_exons.pl $sample_dir $LOC $list_for_quant false $se $c_option $new_queue" | $batchjobs $wait $jobname "$study.quantifyexons.filter.u" -o $logdir/$study.quantifyexons.filter.u.out -e $logdir/$study.quantifyexons.filter.u.err`;
$date = `date`;
print LOG "$job_num. started \"$study.quantifyexons.filter.u\"\t$date";
$job_num++;

#quantify_exons for filter nu
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_quantify_exons.pl $sample_dir $LOC $list_for_quant false $se -NU-only $c_option $new_queue" | $batchjobs $wait $jobname "$study.quantifyexons.filter.nu" -o $logdir/$study.quantifyexons.filter.nu.out -e $logdir/$study.quantifyexons.filter.nu.err`;
$date = `date`;
print LOG "$job_num. started \"$study.quantifyexons.filter.nu\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 $study.quantifyexons.filter | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 $study.quantifyexons.filter | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep $study.quantifyexons.filter |  wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep $study.quantifyexons.filter | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.quantifyexons2  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.quantifyexons2  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

#get_high_expressors 
if ($filter_high_expressors eq "false" | $cutoff_he eq '100'){
    $cutoff_he = 10;
}
$to_wait = "$study.quantifyexons2";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_15G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_15G";
}
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_get_high_expressors.pl $sample_dir $LOC $cutoff_he $annot $list_for_quant $c_option $new_queue" | $batchjobs $wait $jobname "$study.runall_get_high_expressors" -o $logdir/$study.runall_get_high_expressors.out -e $logdir/$study.runall_get_high_expressors.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_get_high_expressors\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 -w $study.runall_get_high_expressors | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 -w $study.runall_get_high_expressors | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.runall_get_high_expressors | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.runall_get_high_expressors | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.get_high_expressor  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.get_high_expressor  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

if ($filter_high_expressors eq 'true'){
    #filter_high_expressors
    $to_wait = "$study.get_high_expressor";
    $wait = $wait_option;
    $wait =~ s/JOB/$to_wait/;
    $numq =`$stat | grep "^[0-9]" | wc -l`;
    until ($numq < $maxjobs){
	$x = `$stat | grep "^[0-9]" | wc -l`;
	$numq = $x;
	sleep(10);
    }
    `echo "perl $norm_script_dir/filter_high_expressors.pl $sample_dir $LOC $list_for_quant" | $batchjobs $wait $jobname "$study.filter_high_expressors" -o $logdir/$study.filter_high_expressors.out -e $logdir/$study.filter_high_expressors.err`;
    $date = `date`;
    print LOG "$job_num. started \"$study.filter_high_expressors\"\t$date";
    $job_num++;
}

#get_percent_high_expressor
if ($filter_high_expressors eq "true"){
    $to_wait1 = "$study.get_high_expressor";
    $to_wait2 = "$study.filter_high_expressors";
    $wait = $wait_2jobs_option;
    $wait =~ s/JOB1/$to_wait1/;
    $wait =~ s/JOB2/$to_wait2/;
}
else{
    $to_wait = "$study.get_high_expressor";
    $wait = $wait_option;
    $wait =~ s/JOB/$to_wait/;
}
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/get_percent_high_expressor.pl $sample_dir $LOC" | $batchjobs $wait $jobname "$study.get_percent_high_expressor" -o $logdir/$study.get_percent_high_expressor.out -e $logdir/$study.get_percent_high_expressor.err`;
$date = `date`;
print LOG "$job_num. started \"$study.get_percent_high_expressor\"\t$date";
$job_num++;

#run_quantify_exons unique
$to_wait = "$study.get_percent_high_expressor";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
$filtered_list = $list_for_quant;
$filtered_list =~ s/master_list/filtered_master_list/g;
if ($filter_high_expressors eq "true"){
    $list_for_quant2 = $filtered_list;
}
else {
    $list_for_quant2 = $list_for_quant;
}
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_4G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_4G";
}
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}

`echo "perl $norm_script_dir/runall_quantify_exons.pl $sample_dir $LOC $list_for_quant2 true $se $c_option -depth $i_exon $new_queue" | $batchjobs $wait $jobname "$study.runall_quantify_exons.true.u" -o $logdir/$study.runall_quantify_exons.true.u.out -e $logdir/$study.runall_quantify_exons.true.u.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_quantify_exons.true.u\"\t$date";
$job_num++;

#run_quantify_exons nu
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}

`echo "perl $norm_script_dir/runall_quantify_exons.pl $sample_dir $LOC $list_for_quant2 true $se $c_option -NU-only -depth $i_exon $new_queue" | $batchjobs $wait $jobname "$study.runall_quantify_exons.true.nu" -o $logdir/$study.runall_quantify_exons.true.nu.out -e $logdir/$study.runall_quantify_exons.true.nu.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_quantify_exons.true.nu\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 $study.runall_quantify_exons.true | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 $study.runall_quantify_exons.true | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep $study.runall_quantify_exons.true | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep $study.runall_quantify_exons.true | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.quantifyexons  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.quantifyexons  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

#exon2nonexon
$to_wait = "$study.quantifyexons";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/get_exon2nonexon_signal_stats.pl $sample_dir $LOC" | $batchjobs $wait $jobname "$study.get_exon2nonexon_stats" -o $logdir/$study.exon2nonexon.out -e $logdir/$study.exon2nonexon.err`;
$date = `date`;
print LOG "$job_num. started \"$study.get_exon2nonexon_stats\"\t$date";
$job_num++;

#1exonvsmultiexons
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/get_1exon_vs_multi_exon_stats.pl $sample_dir $LOC" | $batchjobs $wait $jobname "$study.get_1exonvsmultiexons_stats" -o $logdir/$study.1exonvsmultiexons.out -e $logdir/$study.1exonvsmultiexons.err`;
$date = `date`;
print LOG "$job_num. started \"$study.get_1exonvsmultiexons_stats\"\t$date";
$job_num++;

#get_master_list_of_introns
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/get_master_list_of_introns_from_geneinfofile.pl $geneinfo $LOC" | $batchjobs $wait $jobname "$study.get_master_list_of_introns_from_geneinfofile" -o $logdir/$study.get_master_list_of_introns_from_geneinfofile.out -e $logdir/$study.get_master_list_of_introns_from_geneinfofile.err`;
$date = `date`;
print LOG "$job_num. started \"get_master_list_of_introns_from_geneinfofile\"\t$date";
$job_num++;

#run_quantify_introns unique 
$to_wait1 = "$study.quantifyexons";
$to_wait2 = "$study.get_master_list_of_introns_from_geneinfofile";
$wait = $wait_2jobs_option;
$wait =~ s/JOB1/$to_wait1/;
$wait =~ s/JOB2/$to_wait2/;
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_4G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_4G";
}
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}

`echo "perl $norm_script_dir/runall_quantify_introns.pl $sample_dir $LOC $LOC/master_list_of_introns.txt true $c_option -depth $i_intron $new_queue" | $batchjobs $wait $jobname "$study.runall_quantify_introns.true.u" -o $logdir/$study.runall_quantify_introns.true.u.out -e $logdir/$study.runall_quantify_introns.true.u.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_quantify_introns.true.u\"\t$date";
$job_num++;

#run_quantify_introns nu
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_quantify_introns.pl $sample_dir $LOC $LOC/master_list_of_introns.txt true $c_option -NU-only -depth $i_intron $new_queue" | $batchjobs $wait $jobname "$study.runall_quantify_introns.true.nu" -o $logdir/$study.runall_quantify_introns.true.nu.out -e $logdir/$study.runall_quantify_introns.true.nu.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_quantify_introns.true.nu\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 $study.runall_quantify_introns.true | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 $study.runall_quantify_introns.true | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep $study.runall_quantify_introns.true | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep $study.runall_quantify_introns.true | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.quantify_introns  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.quantify_introns  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

#get_percent_intergenic
$to_wait = "$study.quantifyintrons";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/get_percent_intergenic.pl $sample_dir $LOC" | $batchjobs $wait $jobname "$study.get_percent_intergenic" -o $logdir/$study.get_percent_intergenic.out -e $logdir/get_percent_intergenic.err`;
$date = `date`;
print LOG "$job_num. started \"$study.get_percent_intergenic\"\t$date";
$job_num++;

#runall_head
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $stat";
}
$cluster_max = "";
if ($maxjobs ne '200' && $maxjobs < '200'){
    $cluster_max = "-max_jobs $maxjobs";
}
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_head.pl $sample_dir $LOC $c_option $cluster_max -depthE $i_exon -depthI $i_intron" | $batchjobs $wait $jobname "$study.runall_head" -o $logdir/$study.runall_head.out -e $logdir/$study.runall_head.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_head\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 -w $study.runall_head | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 -w $study.runall_head | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.runall_head | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.runall_head | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.head  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.head  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

#cat_headfiles
$to_wait = "$study.head";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/cat_headfiles.pl $sample_dir $LOC" | $batchjobs $wait $jobname "$study.cat_headfiles" -o $logdir/$study.cat_headfiles.out -e $logdir/$study.cat_headfiles.err`;
$date = `date`;
print LOG "$job_num. started \"$study.cat_headfiles\"\t$date";
$job_num++;

#make_final_samfile
$to_wait = "$study.cat_headfiles";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/make_final_samfile.pl $sample_dir $LOC" | $batchjobs $wait $jobname "$study.make_final_samfile" -o $logdir/$study.make_final_samfile.out -e $logdir/$study.make_final_samfile.err`;
$date = `date`;
print LOG "$job_num. started \"$study.make_final_samfile\"\t$date";
$job_num++;

#runall_sam2junctions
$to_wait = "$study.make_final_samfile";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_6G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_6G";
}
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}

`echo "perl $norm_script_dir/runall_sam2junctions.pl $sample_dir $LOC $geneinfo $genome $c_option $new_queue" | $batchjobs $wait $jobname "$study.runall_sam2junctions" -o $logdir/$study.runall_sam2junctions.out -e $logdir/$study.runall_sam2junctions.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_sam2junctions\"\t$date";
$job_num++;

#cat_exonmappers
$to_wait = "$study.cat_headfiles";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
$numq =`$stat | grep "^[0-9]" | wc -l`;
until ($numq < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $numq = $x;
    sleep(10);
}
`echo "perl $norm_script_dir/cat_exonmappers_Unique_NU.pl $sample_dir $LOC" | $batchjobs $wait $jobname "$study.cat_exonmappers" -o $logdir/$study.cat_exonmappers.out -e $logdir/$study.cat_exonmappers.err`;
$date = `date`;
print LOG "$job_num. started \"$study.cat_exonmappers\"\t$date";
$job_num++;

#runall_quantify_exons (merged/unique)
$to_wait = "$study.cat_exonmappers";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_4G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_4G";
}
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}

`echo "perl $norm_script_dir/runall_quantify_exons.pl $sample_dir $LOC $list_for_quant2 false $se $c_option $new_queue" | $batchjobs $wait $jobname "$study.runall_quantify_exons.false" -o $logdir/$study.runall_quantify_exons.false.out -e $logdir/$study.runall_quantify_exons.false.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_quantify_exons.false\"\t$date";
$job_num++;

#runall_quantify_introns unique
$to_wait = "$study.cat_headfiles";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_quantify_introns.pl $sample_dir $LOC $LOC/master_list_of_introns.txt false $c_option $new_queue" | $batchjobs $wait $jobname "$study.runall_quantify_introns.false.u" -o $logdir/$study.runall_quantify_introns.false.u.out -e $logdir/$study.runall_quantify_introns.false.u.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_quantify_introns.false.u\"\t$date";
$job_num++;

#runall_quantify_introns nu
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + $num_samples;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + $num_samples;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_quantify_introns.pl $sample_dir $LOC $LOC/master_list_of_introns.txt false $c_option -NU-only $new_queue" | $batchjobs $wait $jobname "$study.runall_quantify_introns.false.nu" -o $logdir/$study.runall_quantify_introns.false.nu.out -e $logdir/$study.runall_quantify_introns.false.nu.err`;
$date = `date`;
print LOG "$job_num. started \"$study.runall_quantify_introns.false.nu\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 $study.runall_quantify_ | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 $study.runall_quantify_ | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep $study.runall_quantify_ | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep $study.runall_quantify_ | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep $study.quantify  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep $study.quantify | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

#make_final_spreadsheets
$to_wait1 = "$study.quantifyexons2";
$to_wait2 = "$study.quantifyintrons2";
$wait = $wait_2jobs_option;
$wait =~ s/JOB1/$to_wait1/;
$wait =~ s/JOB2/$to_wait2/;
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_6G $queue_10G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_10G";
}

$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + 3;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + 3;
    sleep(10);
}

`echo "perl $norm_script_dir/make_final_spreadsheets.pl $sample_dir $LOC $c_option $new_queue" | $batchjobs $wait $jobname "$study.make_final_spreadsheets" -o $logdir/$study.make_final_spreadsheets.out -e $logdir/$study.make_final_spreadsheets.err`;

$date = `date`;
print LOG "$job_num. started \"$study.make_final_spreadsheets\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 -w $study.make_final_spreadsheets | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 -w $study.make_final_spreadsheets | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.make_final_spreadsheet  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.make_final_spreadsheet  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.final_spreadsheet  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.final_spreadsheet  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

#run_annotate
$to_annotate = "$study_dir/NORMALIZED_DATA/to_annotate.txt";
open(out, ">$to_annotate");
print out "master_list_of_exons_counts_MIN.txt\nmaster_list_of_exons_counts_MAX.txt\nmaster_list_of_introns_counts_MIN.txt\nmaster_list_of_introns_counts_MAX.txt\nmaster_list_of_junctions_counts_MIN.txt\nmaster_list_of_junctions_counts_MAX.txt\n";
close(out);
$to_wait = "$study.final_spreadsheet";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
if ($other eq "true"){
    $c_option = "$submit $batchjobs $jobname $request $queue_15G";
    $new_queue = "";
}
else{
    $new_queue = "-mem $queue_15G";
}
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + 6;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + 6;
    sleep(10);
}
`echo "perl $norm_script_dir/run_annotate.pl $to_annotate $annot $LOC $c_option $new_queue" | $batchjobs $wait $jobname "$study.run_annotate" -o $logdir/$study.run_annotate.out -e $logdir/$study.run_annotate.err`;
$date = `date`;
print LOG "$job_num. started \"$study.run_annotate\"\t$date";
$job_num++;

sleep(10);
$check = `$status | grep -C 1 -w $study.run_annotate | egrep 'PEND|qw|hqw' | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -C 1 -w $study.run_annotate | egrep 'PEND|qw|hqw' | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.run_annotate  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.run_annotate  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);
$check = `$status | grep -w $study.annotate  | wc -l`;
chomp($check);
until ($check eq '0'){
    $check = `$status | grep -w $study.annotate  | wc -l`;
    sleep(10);
    chomp($check);
}
sleep(10);

#filter_low_expressors
$to_filter = "$study_dir/NORMALIZED_DATA/to_filter.txt";
open(out, ">$to_filter");
print out "annotated_master_list_of_exons_counts_MIN.txt\nannotated_master_list_of_exons_counts_MAX.txt\nannotated_master_list_of_introns_counts_MIN.txt\nannotated_master_list_of_introns_counts_MAX.txt\nannotated_master_list_of_junctions_counts_MIN.txt\nannotated_master_list_of_junctions_counts_MAX.txt\n";
close(out);
$to_wait = "$study.annotate";
$wait = $wait_option;
$wait =~ s/JOB/$to_wait/;
$numq =`$stat | grep "^[0-9]" | wc -l`;
$numq = `$stat | grep "^[0-9]" | wc -l`;
$qneeded = $numq + 6;
until ($qneeded < $maxjobs){
    $x = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $x + 6;
    sleep(10);
}
`echo "perl $norm_script_dir/runall_filter_low_expressors.pl $to_filter $num_samples $cutoff_le $LOC" | $batchjobs $wait $jobname "$study.filter_low_expressors" -o $logdir/$study.filter_low_expressors.out -e $logdir/$study.filter_low_expressors.err`;
$date = `date`;
print LOG "$job_num. started \"$study.filter_low_expressors\"\t$date";
$job_num++;

#runall_sam2cov
if ($sam2cov eq "true"){
    $to_wait = "$study.make_final_samfile";
    $wait = $wait_option;
    $wait =~ s/JOB/$to_wait/;
    if ($other eq "true"){
	$c_option = "$submit $batchjobs $jobname $request $queue_15G";
        $new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_15G";
    }
    $numq = `$stat | grep "^[0-9]" | wc -l`;
    $qneeded = $numq + $num_samples;
    until ($qneeded < $maxjobs){
	$x = `$stat | grep "^[0-9]" | wc -l`;
	$qneeded = $x + $num_samples;
	sleep(10);
    }
    `echo "perl $norm_script_dir/runall_sam2cov.pl $sample_dir $LOC $fai $sam2cov_loc $aligner $c_option $new_queue" | $batchjobs $wait $jobname "$study.runall_sam2cov" -o $logdir/$study.runall_sam2cov.out -e $logdir/$study.runall_sam2cov.err`;
    $date = `date`;
    print LOG "$job_num. started \"$study.runall_sam2cov\"\t$date";
    $job_num++;

    sleep(10);
    $check = `$status | grep -C 1 -w $study.runall_sam2cov | egrep 'PEND|qw|hqw' | wc -l`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -C 1 -w $study.runall_sam2cov | egrep 'PEND|qw|hqw' | wc -l`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
    $check = `$status | grep -w $study.runall_sam2cov  | wc -l`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -w $study.runall_sam2cov  | wc -l`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
    $check = `$status | grep -w $study.sam2cov  | wc -l`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -w $study.sam2cov  | wc -l`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
}
#cleanup: delete intermediate sam
if ($delete_int_sam eq "true"){
    if ($sam2cov eq "true"){
	$to_wait = "$study.sam2cov";
    }
    else {
	$to_wait = "$study.filter_low_expressors";
    }
    $wait = $wait_option;
    $wait =~ s/JOB/$to_wait/;
    $numq =`$stat | grep "^[0-9]" | wc -l`;
    until ($numq < $maxjobs){
	$x = `$stat | grep "^[0-9]" | wc -l`;
	$numq = $x;
	sleep(10);
    }
    `echo "perl $norm_script_dir/cleanup.pl $sample_dir $LOC" | $batchjobs $wait $jobname "$study.cleanup" -o $logdir/$study.cleanup.out -e $logdir/$study.cleanup.err`;
    $date = `date`;
    print LOG "$job_num. started \"$study.cleanup\"\t$date";
    $job_num++;
}
#cleanup: compress 
if ($convert_sam2bam eq "true" | $gzip_cov eq "true"){
    $option = "-dont_cov -dont_bam";
    if ($convert_sam2bam eq "true"){
	$option =~ s/-dont_bam//g;
    }
    if ($gzip_cov eq 'true'){
	$option =~ s/-dont_cov//g;
    }
    if ($sam2cov eq "true"){
	$to_wait = "$study.sam2cov";
    }
    else {
        $to_wait = "$study.filter_low_expressors";
    }
    $wait = $wait_option;
    $wait =~ s/JOB/$to_wait/;
    if ($other eq "true"){
	$c_option = "$submit $batchjobs $jobname $request $queue_6G";
        $new_queue = "";
    }
    else{
	$new_queue = "-mem $queue_6G";
    }
    $numq =`$stat | grep "^[0-9]" | wc -l`;
    until ($numq < $maxjobs){
	$x = `$stat | grep "^[0-9]" | wc -l`;
	$numq = $x;
	sleep(10);
    }
    `echo "perl $norm_script_dir/runall_compress.pl $sample_dir $LOC $samfilename $fai $c_option $new_queue" | $batchjobs $wait $jobname "$study.compress" -o $logdir/$study.compress.out -e $logdir/$study.compress.err`;
    $date = `date`;
    print LOG "$job_num. started \"$study.sam2bam\"\t$date";
}
close(LOG);
#=cut
sub parse_config_file () {
    ($File, $Config) = @_;
    open(CONFIG, "$File") or die "ERROR: Config file not found : $File\n";
    while ($config_line = <CONFIG>) {
	chomp($config_line);
        $config_line =~ s/^\s*//;
        $config_line =~ s/\s*$//;
        if ( ($config_line !~ /^#/) && ($config_line ne "") ){
	    my ($Name, $Value) = split(/\s*=\s*/, $config_line);
	    if ($Value =~ /^"/){
		$Value =~ s/^"//;
		$Value =~ s/"$//;
	    }
	    $Config{$Name} = $Value;
	    $$Name = $Value;
	}
    }
}
