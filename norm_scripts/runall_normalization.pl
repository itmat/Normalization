#!/usr/bin/env perl
#use warnings;
use FindBin qw($Bin);
use lib ("$Bin/pm/lib/perl5");
use Net::OpenSSH;

my $USAGE =  "\nUsage: perl runall_normalization.pl --sample_dirs <file of sample_dirs> --loc <s> --unaligned <file of fa/fqfiles> --alignedfilename <s> --cfg <cfg file> [options]

where:
--sample_dirs <file of sample_dirs> : is a file of sample directories with alignment output without path
--loc <s> : full path of the directory with the sample directories
--unaligned <file of fa/fqfiles> : is a file with the full path of all input fa or fq files
--alignedfilename <s> : is the name of aligned sam/bam file (e.g. RUM.sam, RUM.bam, Aligned.out.sam, Aligned.out.bam) 
--cfg <cfg file> : is a cfg file for the study

OPTIONS:
     [pipeline options]
     By default, the pipeline will run through the steps in PART1 and pause (recommended).
     You will have a chance to check the following before resuming:
      (1) number of reads you will have after normalization
          - modify the list of sample directories accordingly.
      (2) percent high expressers
          - use -cutoff_highexp <n> option to set/change the highexpresser cutoff value.

     -part1_part2 : Use this option if you want to run steps in PART1 and PART2 without pausing.
     -part2 : Use this option to resume the pipeline at PART2. You may edit the <file of sample_dirs> file
               and/or change the highexpresser cutoff value.
     -alt_out <s> : Use this option to redirect the normalized data to an alternate output directory <s>
                    (Default: /path/to/studydir/NORMALIZED_DATA/)

     [resume options]
     You may not change the normalization parameters with resume option.
     -resume : Use this if you have a job that crashed or stopped. 
               Runs job that has already been initialized or partially run after the last completed step.
               It may repeat the last completed step.
     -resume_at \"<step>\" : Use this if you have a job that crashed or stopped.
                             This resumes at \"<step>\" step.
                             **make sure a full step name (found in log file) is given in quotes** 
                             (e.g. \"1   \"allsteps.get_total_num_reads\"\")

     [data type]
     -se : set this if the data are single end, 
           otherwise by default it will assume it's a paired end data
     -fa : set this if the unaligned files are in fasta format 
     -fq : set this if the unaligned files are in fastq format 
     -gz : set this if the unaligned files are compressed
     -sam : set this if the aligned files are in sam format
     -bam : set this if the aligned files are in bam format
    
     [normalization parameters]
     -cutoff_highexp <n> : is cutoff % value to identify highly expressed genes/exons/introns.
                           the script will consider genes/exons/introns with gene/exon/intronpercents greater than n(%) as high expressers,
                           report the list of highly expressed genes/exons and remove the reads that map to those genes/exons/introns.
                           (Default = 100; with the default cutoff, exons/genes/introns expressed >3% will be reported)

     -cutoff_lowexp <n> : is cutoff counts to identify low expressers in the final spreadsheets (exon, intron and junc).
                          the script will consider features with sum of counts for all samples less than <n> as low expressers
                          and remove them from all samples for the final spreadsheets.
                          (Default = 0; this will remove features with sum of counts = 0)

     [exon-intron-junction normalization only]

     -novel_off : set this if you DO NOT want to generate/use a study-specific master list of exons/introns
                  (By default, the pipeline will add inferred exons to the list of exons/introns)
     -min <n> : is minimum size of inferred exon for get_inferred_exons.pl script (Default = 10)
     -max <n> : is maximum size of inferred exon for get_inferred_exons.pl script (Default = 800)
     -depthExon <n> : the pipeline splits filtered sam files into 1,2,3...n exonmappers and downsamples each separately.
                   (Default = 20)
     -depthIntron <n> : the pipeline splits filtered sam files into 1,2,3...n intronmappers and downsamples each separately.
                   (Default = 10)
     -flanking_region <n> : is used for generating list of flanking regions.
                            by default, 5000 bp up/downstream of each gene will be considered a flanking region.
                            use this option to change the size <n>.
     -h : print usage 

";

if(@ARGV < 10) {
    die $USAGE;
}

my $required = 0;
my $unaligned = 0;
my $aligned = 0;
my $count_b = 0;
my $count_r = 0;
my $se = "";
my $unaligned_z = "";
my $min = 10;
my $max = 800;
my $cutoff_he = 100;
my $flanking = 5000;
my $filter_high_expressers = "false";
my $filter_gene = "false";
my $filter_gene2 = "false";
my $filter_eij = "false";
my $i_exon = 20;
my $i_intron = 10;
my $filter_low_expressers = "false";
my $novel = "true";
my $run_prepause = "true";
my $run_norm = "false";
my $shfile_name = "runall_normalization.sh";
my $resume = "false";
my $resume_at = "false";
my ($sample_dir, $LOC, $unaligned_file, $alignedfilename, $unaligned_type, $cfg_file, $cutoff_temp, $bam);
my ($name_to_check, $res_num, $last_step);
my $new_norm = "false";
my $b_option = "";

for(my $i=0; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-flanking_region'){
        $flanking = $ARGV[$i+1];
        $i++;
        $option_found = "true";
        if (($flanking !~ /(\d+$)/) || ($flanking < 0) ){
            die "-flanking_region <n> : <n> needs to be a number greater than 0\n";
        }
    }
    if ($ARGV[$i] eq '-part1_part2'){
	$option_found = "true";
	$run_prepause = "true";
	$run_norm = "true";
	$shfile_name = "runall_normalization_part1_part2.sh";
	$count_b++;
    }
    if ($ARGV[$i] eq '-resume'){
	$option_found = "true";
	$resume = "true";
	$count_r++;
    }
    if ($ARGV[$i] eq '-resume_at'){
	$option_found = "true";
	$resume = "true";
	$count_r++;
	$resume_at = "true";
	$last_step = $ARGV[$i+1];
	$i++;
    }
    if ($ARGV[$i] eq '-part2'){
	$option_found = "true";
	$run_prepause = "false";
	$run_norm = "true";
	$shfile_name = "runall_normalization_part2.sh";
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
	if ($unaligned_file =~ /^-/ | $unaligned_file eq ""){
	    die "\nplease provide <file of fa/fqfiles> for --unaligned\n";
	}
        $i++;
	$required++;
    }
    if ($ARGV[$i] eq '--alignedfilename'){
	$option_found = "true";
	$alignedfilename = $ARGV[$i+1];
	if ($alignedfilename =~ /^-/ | $alignedfilename eq ""){
	    die "\nplease provide the 'name of aligned file' for --alignedfilename\n";
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
    if ($ARGV[$i] eq '-sam'){
        $option_found = "true";
        $aligned++;
	$bam = "false";
    }
    if ($ARGV[$i] eq '-bam'){
        $option_found = "true";
        $aligned++;
	$bam = "true";
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
	$filter_high_expressers = "true";
        if ($cutoff_he !~ /(\d+$)/ ){
            die "-cutoff_highexp <n> : <n> needs to be a number\n";
        }
    }
    if ($ARGV[$i] eq '-depthExon'){
	$i_exon = $ARGV[$i+1];
	if ($i_exon !~ /(\d+$)/ ){
	    die "-depthExon <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-depthIntron'){
	$i_intron = $ARGV[$i+1];
	if ($i_intron !~ /(\d+$)/ ){
	    die "-depthIntron <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if($ARGV[$i] eq '-cutoff_lowexp') {
        $cutoff_temp = $ARGV[$i+1];
        $i++;
        $option_found = "true";
        $filter_low_expressers = "true";
        if ($cutoff_temp !~ /(\d+$)/ ){
            die "-cutoff_lowexp <n> : <n> needs to be a number\n";
        }
    }
    if($ARGV[$i] eq "-alt_out"){
        $option_found = "true";
        $i++;
        $new_norm = "true";
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if ($required ne '5'){
    die "please specify the required parameters: --sample_dirs, --loc, --unaligned, --alignedfilename and --cfg\n";
}
if ($unaligned ne '1'){
    die "you have to specify the type of your unaligned files: '-fa' or '-fq'\n"
}
if ($aligned ne '1'){
    die "you have to specify the type of your aligned files: '-sam' or '-bam'\n";
}
if ($count_r > 1){
    die "you can only set one of the following options: -resume, -resume_at \"<step>\"\n";
}
if ($count_b > 1){
    die "you can only set one of the following options: -part1_part2, -part2\n";
}

$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $normdir = $study_dir . "NORMALIZED_DATA";
my $study = $fields[@fields-2];
my $altstats = "";
my $dirs = `wc -l $sample_dir`;
my @a = split(" ", $dirs);
my $num_samples = $a[0];
my $cutoff_le = 0;
if ($filter_low_expressers eq "true"){
    $cutoff_le = $cutoff_temp;
}

if ($new_norm eq "true"){
    for(my $i=0; $i<@ARGV; $i++) {
        if ($ARGV[$i] eq "-alt_out"){
            $normdir = $ARGV[$i+1];
	    $altstats = "-alt_stats $normdir/STATS/";
	    unless (-d "$normdir/STATS/"){
		`mkdir -p $normdir/STATS/`;
	    }
        }
    }
}
#check for white spaces
my $to_trim = "false";
open(DIRS, $sample_dir);
while(my $id = <DIRS>){
    chomp($id);
    if (($id =~ /^\ /) || ($id =~ /\ $/)){
	$to_trim = "true";
    }
}
close(DIRS);

if ($to_trim eq "true"){
    my $trim = "$sample_dir.trim";
    open(TRIM, ">$trim");    
    open(DIRS, $sample_dir);
    while(my $id = <DIRS>){
	chomp($id);
	$id =~ s/^\s+|\s+$//g;
	print TRIM "$id\n";
    }
    close(DIRS);
    close(TRIM);
    $sample_dir = $trim;
}
my $resume_file = "$sample_dir.resume";

unless (-e $cfg_file){
    die "ERROR: cannot find file \"$cfg_file\". please provide a cfg file for the study\n";
}
my %Config;
&parse_config_file ($cfg_file,  \%Config);
my $compress_opt = "";
my $GNORM = "false";
my $EIJ = "false";
my $normcnt = 0;
my $samtools = $SAMTOOLS;
if ($bam eq "true"){
    $b_option = "-bam $samtools";
}
if ($GENE_NORM =~ /true/i){
    $GNORM = "true";
    $compress_opt .= " -gnorm";
    $normcnt++;
}
if ($EXON_INTRON_JUNCTION_NORM =~ /^true/i){
    $EIJ = "true";
    $compress_opt .= " -eij";
    $normcnt++;
}

if ($normcnt == 0){
    die "ERROR: Please select a type of Normalization you'd like to use (# 0. NORMALIZTION and DATA TYPE - [A] Normalization Type in your cfg file \"$cfg_file\")\n\n";
}
use Cwd 'abs_path';
my $norm_script_dir = abs_path($0);
$norm_script_dir =~ s/\/runall_normalization.pl//;
my $rl = `perl $norm_script_dir/get_readlength.pl $unaligned_file $unaligned_type $unaligned_z`;
chomp($rl);
my $read_length= $rl;

my $geneinfo = $GENE_INFO_FILE;
my $genome = $GENOME_FA;
my $fai = $GENOME_FAI;
my $pref = "false";
if ($rRNA_PREFILTERED =~ /^true/i){
    $pref = "true";
}
my $rRNA = $rRNA_FA;
my $use_chr_name = "";
my $chrnames = $CHRNAMES;
if (-e $chrnames){
    $use_chr_name = "-chromnames $CHRNAMES";
}
my $mito = $CHRM;
my $ensGene = $GENE_INFO_FILE;

my $strand_info = "";
my $data_stranded = "";
if ($STRANDED =~ /^true/i){
    $data_stranded = "-stranded";
    my $strand_flag = 0;
    if ($FWD =~ /^true/i){
        $strand_flag++;
        $strand_info = "-str_f";
    }
    if ($REV =~ /^true/i){
        $strand_flag++;
        $strand_info = "-str_r";
    }
    if ($strand_flag ne "1"){
        die "Please specify the read orientation. (# 0. NORMALIZTION and DATA TYPE - [B] Stranded Data in your cfg file \"$cfg_file\")\n\n";
    }
}

my $sam2cov = "false";
my $sam2cov_loc;
if ($SAM2COV =~ /^true/i){
    $sam2cov = "true";
    my $num_cov = 0;
    unless (-e $SAM2COV_LOC){
	die "You need to provide sam2cov location. (# 5. DATA VISUALIZATION in your cfg file \"$cfg_file\")\n";
    }
    $sam2cov_loc = $SAM2COV_LOC;
    if ($RUM =~ /^true/i){
	$aligner = "-rum";
	$num_cov++;
    }
    if ($STAR_GSNAP =~ /^true/i){
	$aligner = "-star";
	$num_cov++;
    }
    if ($num_cov ne '1'){
	die "Please specify which aligner was used. (# 5. DATA VISUALIZATION in your cfg file \"$cfg_file\")\n\n";
    }
}
my $delete_int_sam = "true";
my $convert_sam2bam = "false";
my $gzip_cov = "false";
if ($DELETE_INT_SAM ne ""){
    if ($DELETE_INT_SAM =~ /^true/i){
	$delete_int_sam = "true";
    }
    if ($DELETE_INT_SAM=~ /^false/i){
	$delete_int_sam = "false";
    }
}
if ($CONVERT_SAM2BAM ne ""){
    if ($CONVERT_SAM2BAM =~ /^true/i){
	$convert_sam2bam = "true";
    }
    if ($CONVERT_SAM2BAM =~ /^false/i){
	$convert_sam2bam= "false";
    }
}
unless (-e $samtools) {
    die "You need to provide samtools location. (# 3. FA and FAI - [3] samtools in your cfg file \"$cfg_file\")\n";
}

if ($GZIP_COV ne ""){
    if ($GZIP_COV =~ /^true/i){
        $gzip_cov = "true";
    }
    if ($GZIP_COV =~ /^false/i){
        $gzip_cov = "false";
    }
}

my $lsf = "false";
my $sge = "false";
my $other = "false";
my $num_cluster = 0;
my ($batchjobs,  $jobname, $status, $request, $queue_3G,  $queue_6G, $queue_10G, $queue_15G, $queue_30G, $queue_45G, $queue_60G, $submit, $c_option, $maxjobs);
if ($SGE_CLUSTER =~ /^true/i){
    $num_cluster++;
    if ($QUEUE_NAME_3G_sge eq "" | $QUEUE_NAME_6G_sge eq "" | $QUEUE_NAME_10G_sge eq "" |  $QUEUE_NAME_15G_sge eq "" | $QUEUE_NAME_30G_sge eq "" | $QUEUE_NAME_45G_sge eq "" | $QUEUE_NAME_60G_sge eq "" | $MAX_JOBS_sge eq "" | $REQUEST_RESOURCE_OPTION_sge eq ""){
        die "ERROR: please provide all required CLUSTER INFO for SGE_CLUSTER in the $cfg_file file\n";
    }
    else{
	$batchjobs = "qsub -cwd";
	$jobname = "-N";
	$status = "qstat -r";
	$request = $REQUEST_RESOURCE_OPTION_sge;
	$queue_3G = $QUEUE_NAME_3G_sge;
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
if ($LSF_CLUSTER =~ /^true/i){
    $num_cluster++;
    if ($QUEUE_NAME_3G_lsf eq "" | $QUEUE_NAME_6G_lsf eq "" | $QUEUE_NAME_10G_lsf eq "" |  $QUEUE_NAME_15G_lsf eq "" | $QUEUE_NAME_30G_lsf eq "" | $QUEUE_NAME_45G_lsf eq "" | $QUEUE_NAME_60G_lsf eq "" | $MAX_JOBS_lsf eq "" | $REQUEST_RESOURCE_OPTION_lsf eq ""){
        die "ERROR: please provide all required CLUSTER INFO for LSF_CLUSTER in the $cfg_file file\n";
    }
    else{
	$batchjobs = "bsub";
	$jobname = "-J";
	$status = "bjobs -w";
	$request = $REQUEST_RESOURCE_OPTION_lsf;
	$queue_3G = $QUEUE_NAME_3G_lsf;
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
if ($OTHER_CLUSTER =~ /^true/i){
    $num_cluster++;
    if ($SUBMIT_BATCH_JOBS eq "" | $JOB_NAME_OPTION eq "" | $CHECK_STATUS_FULLNAME eq "" | $REQUEST_RESOURCE_OPTION eq "" | $QUEUE_NAME_3G eq "" | $QUEUE_NAME_6G eq "" | $QUEUE_NAME_10G eq "" |  $QUEUE_NAME_15G eq "" | $QUEUE_NAME_30G eq "" | $QUEUE_NAME_45G eq "" | $QUEUE_NAME_60G eq "" | $MAX_JOBS eq ""){
	die "ERROR: please provide all required CLUSTER INFO for OTHER_CLUSTER in the $cfg_file file\n";
    }
    else {
	$batchjobs = $SUBMIT_BATCH_JOBS;
	$jobname = $JOB_NAME_OPTION;
	$status = $CHECK_STATUS_FULLNAME;
	$request = $REQUEST_RESOURCE_OPTION;
	$queue_3G = $QUEUE_NAME_3G;
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

#HEADNODE CHECK
my $hn_only = "false";
my $hn_option = "";
my $ssh;
unless ($HOST_NAME =~ /^$/){
    $hn_only = "true";
    $hn_option = "-headnode $HOST_NAME";
    $ssh = Net::OpenSSH->new($HOST_NAME,
				master_opts => [-o => "StrictHostKeyChecking=no", -o => "BatchMode=yes"]);
}
my $exon_list = "$LOC/master_list_of_exons.txt";
my $novel_list = "$LOC/master_list_of_exons.$study.txt";
my $gene_list = "$LOC/master_list_of_genes.txt";
my $list_for_intronquant = "$LOC/list_for_intronquants.$study.txt";
my $shdir = $study_dir . "shell_scripts";
my $logdir = $study_dir . "logs";
my $logfile = $logdir . "/$study.run_normalization.log";
unless (-d $shdir){
    `mkdir $shdir`;}
unless (-d $logdir){
    `mkdir $logdir`;}

my $cluster_max = "";
if ($maxjobs ne '200'){
    $cluster_max = "-max_jobs $maxjobs";
}

my @s = split(" ", $status);
my $stat = $s[0];

my $shfile = $shdir . "/" . $shfile_name;
my $input = `cat $shfile`;
my $list_for_genequant = $gene_list;
my $list_for_exonquant = $exon_list;
if ($novel eq "true"){
    $list_for_exonquant = $novel_list;
}
my $filter_highexp = "";
if ($filter_high_expressers eq "true"){
    $filter_highexp = "-filter_highexp";
    $filter_gene2 = "true";
}

my $UONLY = "";
#check UONLY
my $statsfile = "$study_dir/STATS/mappingstats_summary.txt";
if (-e $statsfile){
    my $maxline = `tail -2 $statsfile | head -1`;
    my @m = split(/\t/,$maxline);
    if (($m[5] == 0) && ($m[6] == 0)){
	$UONLY = "-u";
    }
}
open(LOG, ">>$logfile");
print LOG "\nPORT v0.8.4-beta\n";
my $default_input = $input;
#$default_input = `cat $shdir/runall_normalization.sh`;
$default_input =~ s/perl\ //g;
$default_input =~ s/runall_normalization.pl/run_normalization/g;
$default_input =~ s/\-fa\n//;
$default_input =~ s/\-fq\n//;
$default_input =~ s/\-sam //;
$default_input =~ s/\-bam //;
$default_input =~ s/\-gz//;
$default_input =~ s/\-se//;
print LOG "\n*************\n$default_input\n*************\n";

if (-e "$logdir/$study.runall_normalization.out"){
    `rm $logdir/$study.runall_normalization.out`;

}
if (-e "$logdir/$study.runall_normalization.err"){
    `rm $logdir/$study.runall_normalization.err`;
}
my $run_job = "true";
my $mem = "$request$queue_3G";
my $qlist = "$queue_3G,$queue_6G,$queue_10G,$queue_15G,$queue_30G,$queue_45G,$queue_60G";
if ($resume eq "true"){
    my ($name, $length, $get_name);
    if ($resume_at eq "false"){
	$last_step = `grep -A 1 "COMPLETED" $logfile | tail -1`;
	chomp($last_step);
	#repeat the last completed step if cannot find the name of failed step
	if ($last_step =~ /^$/){
	    $last_step = `grep -B 2 "COMPLETED" $logfile | tail -3 | head -1`;
	}
	#die if last completed step cannot be found
	if ($last_step =~ /^$/){
	    die "Cannot find the last completed step in your log file. Use -resume_at \"<step>\" option.\n\n";
	}
	$get_name = $last_step;
	$get_name =~ /\"(.*)\"/;
	$name = $1;
    }
    if ($resume_at eq "true"){
	$get_name = $last_step;
	my @b = split(" ", $get_name);
	$name = $b[@b-1];
    }
    # if resumed at runall_cat_genes_files (or runall_cat_genes_files_norm step), unless temp files exist,
    # go back one step and start from runall_sam2genes (or runall_sam2genes_2)
    my $cat_flag = 0;
    if ($name =~  /runall_cat_genes_files$/){
	my $TEflag = 0;
        my $err_name = "cat_genes.0.*.err";
        my $new_queue = "-mem $queue_3G";
        my $res = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
	my $rtmp = `wc -l $resume_file`;
	my ($res_cnt, $res_n) = split(" ", $rtmp);
	open(IN, $resume_file);
	while(my $line = <IN>){
	    chomp($line);
	    my @tcnt = glob("$LOC/$line/GNORM/*/*temp*");
	    if (@tcnt > 0){
		$TEflag++;
	    }
	}
	close(IN);
#	print "$TEflag\t$res_cnt\n";
	if ($TEflag ne $res_cnt){ #temp files don't exist
	    $cat_flag = 1;
	    my $tempname = $name;
	    $tempname =~ s/runall_cat_genes_files$/runall_sam2genes_gnorm/;
	    $name = $tempname;
	}
    }
    if ($name =~ /runall_cat_genes_files_norm$/){
	my $TEflag = 0;
        my $err_name = "cat_genes.1.*.err";
        my $new_queue = "-mem $queue_3G";
        my $res = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
        my $rtmp = `wc -l $resume_file`;
	my ($res_cnt, $res_n) =split(" ", $rtmp);
        open(IN, $resume_file);
        while(my $line = <IN>){
            chomp($line);
	    my @tcnt;
	    if ($STRANDED =~ /TRUE/i){
		@tcnt = glob("$normdir/GENE/FINAL_SAM/*sense/$line.*temp*");
	    }
	    else{
		@tcnt = glob("$normdir/GENE/FINAL_SAM/$line.*temp*");
	    }
	    if (@tcnt > 0){
		$TEflag++;
	    }
	}
	close(IN);
#	print "$TEflag\t$res_cnt\n";
	if ($TEflag ne $res_cnt){ #temp files don't exist
	    $cat_flag = 1;
	    my $tempname = $name;
	    $tempname =~ s/runall_cat_genes_files_norm$/runall_sam2genes_gnorm_2/;
	    $name = $tempname;
	}
    }
    # if resumed at runall_parseblastout, unless blastdb files exist,
    # go back one step and start from runall_runblast
    my $blast_flag = 0;
    if ($name =~  /runall_parseblastout$/){
        my $BDBflag = 0;
	my $err_name = "parseblastout.*.err";
	my $new_queue = "-mem $queue_3G";
	my $res = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
        my $rtmp = `wc -l $resume_file`;
        my ($res_cnt, $res_n) =split(" ", $rtmp);
        open(IN, $resume_file);
        while(my $line = <IN>){
            chomp($line);
            my @tcnt = glob("$LOC/$line/blastdb*");
            if (@tcnt > 0){
                $BDBflag++;
            }
        }
	close(IN);
#	print "$BDBflag\t$res_cnt\n";
        if ($BDBflag ne $res_cnt){ #database files don't exist
            $blast_flag = 1;
            my $tempname = $name;
            $tempname =~ s/runall_parseblastout$/runall_runblast/;
            $name = $tempname;
        }
    }
    my @a = split(/\./, $name);
    $name_to_check = $a[@a-1];
    my $get_num = $last_step;
    $get_num =~ /^(\d*)/;
    $res_num = $1;
    if ($res_num =~ /^$/){
	$res_num = 1;
	print LOG "\nJob number not provided. Setting it to 1.\n";
    }
    else{
	if (($cat_flag == 1) || ($blast_flag ==1)){
	    $res_num--;
	}
    }
    if ($cat_flag == 1){
	if ($name =~ /_2$/){
	    print LOG "\nCannot resume at runall_cat_genes_files_norm.\nResuming at the previous step...\n";
	}
	else{
	    print LOG "\nCannot resume at runall_cat_genes_files.\nResuming at the previous step...\n";
	}
    }
    if ($blast_flag == 1){
	print LOG "Cannot resume at runall_parseblastout.\nResuming at the previous step...\n";
    }
    $length = length($res_num) + length($name) + 3;
    print LOG "\nRESUME at $res_num \"$name\"\n==========";
    for (my $i=0; $i < $length; $i++){
	print LOG "=";
    }
    print LOG "\n";
    $run_job = "false";
}

if ($run_prepause eq "true"){
    $job_num = 1;
    if ($run_job eq "true"){
	print LOG "\nPreprocessing\n-------------\n";
    }
    #get_total_num_reads.pl
    $name_of_job = "$study.get_total_num_reads";
    if (($resume eq "true")&&($run_job eq "false")){
	if ($name_of_job =~ /.$name_to_check$/){
	    $run_job = "true";
	    $job_num = $res_num;
	}
    }
    if ($run_job eq "true"){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs,$jobname,$request,$queue_3G,$stat\\\"";
	}
	$new_queue = "-mem $queue_3G";
    
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
    
	$job = "echo \"perl $norm_script_dir/get_total_num_reads.pl $sample_dir $LOC $unaligned_file $unaligned_type $unaligned_z $c_option $new_queue $cluster_max $altstats $hn_option\" | $batchjobs $mem $jobname \"$study.get_total_num_reads\" -o $logdir/$study.get_total_num_reads.out -e $logdir/$study.get_total_num_reads.err";
	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }
    #runall_check_samformat
    $name_of_alljob = "$study.runall_check_samformat";
    if (($resume eq "true")&&($run_job eq "false")){
	if ($name_of_alljob =~ /.$name_to_check$/){
	    $run_job = "true";
	    $job_num = $res_num;
	}
    }
    if ($run_job eq "true"){
	$name_of_job = "$study.check_samformat";
	$err_name = "check_samformat.*.err";
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs,$jobname, $request, $queue_3G, $stat\\\"";
	}
	$new_queue = "-mem $queue_3G";
	
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/runall_check_samformat.pl $sample_dir $LOC $alignedfilename $se $c_option $new_queue $cluster_max $b_option $hn_option\" | $batchjobs $mem $jobname \"$study.runall_check_samformat\" -o $logdir/$study.runall_check_samformat.out -e $logdir/$study.runall_check_samformat.err";    
	if ($resume eq "false"){
	    &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	}
	else{
	    $resume = "false";
	    ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
	    $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
	}
	&check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }
    #sam2mappingstats.pl
    $name_of_alljob = "$study.runall_sam2mappingstats";
    if (($resume eq "true")&&($run_job eq "false")){
	if ($name_of_alljob =~ /.$name_to_check$/){
	    $run_job = "true";
	    $job_num = $res_num;
	}
    }
    if ($run_job eq "true"){
	$name_of_job = "$study.sam2mappingstats";
	$err_name = "sam2mappingstats.*.err";
	$total = "$study_dir/STATS/total_num_reads.txt";
	$sorted = `cut -f 2 $total | sort -n`;
	@a = split (/\n/, $sorted);
	$min_map = $a[0];
	$max_map = $a[@a-1];
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs,$jobname,$request,$queue_30G,$stat\\\"";
	}
	$new_queue = "-mem $queue_30G";
	if ($max_map > 150000000){
	    $new_queue = "-mem $queue_45G";
	    if ($max_map > 200000000){
		$new_queue = "-mem $queue_60G";
	    }
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/runall_sam2mappingstats.pl $sample_dir $LOC $alignedfilename true $c_option $new_queue $cluster_max $b_option $altstats $hn_option\" | $batchjobs $mem $jobname \"$study.runall_sam2mappingstats\" -o $logdir/$study.runall_sam2mappingstats.out -e $logdir/$study.runall_sam2mappingstats.err";
	if ($resume eq "false"){
	    &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	}
	else{
	    $resume = "false";
	    ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
	}
	&check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }
    #getstats.pl
    $name_of_job = "$study.getstats";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if ($run_job eq "true"){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	
	$job = "echo \"perl $norm_script_dir/getstats.pl $sample_dir $LOC $altstats -mito \\\"$mito\\\"\" | $batchjobs $mem $jobname \"$study.getstats\" -o $logdir/$study.getstats.out -e $logdir/$study.getstats.err";
    
	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }
    if ($run_job eq "true"){
	if (-e $statsfile){
	    my $maxline = `tail -2 $statsfile | head -1`;
	    my @m = split(/\t/,$maxline);
	    if (($m[5] == 0) && ($m[6] == 0)){
		$UONLY = "-u";
	    }
	}
    }
    if ($pref eq "true"){
	#skip blast
	$name_of_job = "$study.skip_blast";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_job =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if ($run_job eq "true"){
	    $err_name = "$name_of_job.err";
	    &clear_log($name_of_job, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }

	    $job = "echo \"perl $norm_script_dir/skip_blast.pl $sample_dir $LOC \"| $batchjobs $mem $jobname \"$study.skip_blast\" -o $logdir/$study.skip_blast.out -e $logdir/$study.skip_blast.err";

	    &onejob($job, $name_of_job, $job_num);
	    &check_exit_onejob($job, $name_of_job, $job_num);
	    &check_err ($name_of_job, $err_name, $job_num);
	    $job_num++;
	}
    }
    if ($pref eq "false"){
	#blast
	$name_of_alljob = "$study.runall_runblast";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if ($run_job eq "true"){
	    $name_of_job = "$study.runblast";
	    $err_name = "runblast.*.err";
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs,$jobname, $request, $queue_6G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_6G";
	    
	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/runall_runblast.pl $sample_dir $LOC $unaligned_file $norm_script_dir/ncbi-blast-2.2.30+ $rRNA $unaligned_type $unaligned_z $c_option $new_queue $cluster_max $hn_option\" | $batchjobs $mem $jobname \"$study.runall_runblast\" -o $logdir/$study.runall_runblast.out -e $logdir/$study.runall_runblast.err";
	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }
	    &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
	}
	#parseblast
        $name_of_alljob = "$study.runall_parseblastout";
        if (($resume eq "true")&&($run_job eq "false")){
            if ($name_of_alljob =~ /.$name_to_check$/){
                $run_job = "true";
                $job_num = $res_num;
            }
        }
        if ($run_job eq "true"){
            $name_of_job = "$study.parseblastout";
            $err_name = "parseblastout.*.err";

            if ($other eq "true"){
                $c_option = "$submit \\\"$batchjobs,$jobname, $request, $queue_6G, $stat\\\"";
            }
	    $new_queue = "-mem $queue_6G";
	    $total = "$study_dir/STATS/total_num_reads.txt";
	    $sorted = `cut -f 2 $total | sort -n`;
	    @a = split (/\n/, $sorted);
	    $min_map = $a[0];
	    $max_map = $a[@a-1];
            if ($min_map > 50000000){ #50,000,000
		$new_queue = "-mem $queue_30G";
                if ($min_map > 100000000){ #100,000,000
                    $new_queue = "-mem $queue_45G";
                }
                if ($min_map > 150000000){
                    $new_queue = "-mem $queue_60G";
                }
            }
	    while(qx{$stat | wc -l} > $maxjobs){
                sleep(10);
            }
            $job = "echo \"perl $norm_script_dir/runall_parseblastout.pl $sample_dir $LOC $c_option $new_queue $cluster_max $hn_option\" | $batchjobs $mem $jobname \"$study.runall_parseblastout\" -o $logdir/$study.runall_parseblastout.out -e $logdir/$study.runall_parseblastout.err";
            if ($resume eq "false"){
                &clear_log($name_of_alljob, $err_name);
                &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
            }
            else{
                $resume = "false";
                ####failedonly####
                if (-e "$logdir/$name_of_alljob.err"){
                    `rm $logdir/$name_of_alljob.err`;
                }
                if (-e "$logdir/$name_of_alljob.out"){
                    `rm $logdir/$name_of_alljob.out`;
                }
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
                $job =~ s/$sample_dir/$resume_file/;
                &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
                $job =~ s/$resume_file/$sample_dir/;
            }
            &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
            &check_err ($name_of_alljob, $err_name, $job_num);
            $job_num++;
	}
	#ribopercents
	$name_of_alljob = "$study.runall_getribopercents";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if ($run_job eq "true"){
	    $name_of_job = "$study.getribopercents";
	    $err_name = "$name_of_job.err";
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_3G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_3G";
	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/runall_get_ribo_percents.pl $sample_dir $LOC $altstats $c_option $new_queue $cluster_max $hn_option\" | $batchjobs $mem $jobname \"$study.runall_getribopercents\" -o $logdir/$study.runall_getribopercents.out -e $logdir/$study.runall_getribopercents.err";
	    &clear_log($name_of_alljob, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
	}
    }
    #check_fasta
    my $seqnum = `grep -c "^>" $genome`;
    my $falinecnt = `wc -l $genome`;
    my @lcfa =split(" ", $falinecnt);
    my $linenum_fa = $lcfa[0];
    #modify_to_onelinefa
    if (($seqnum * 2) ne $linenum_fa){
	$name_of_job = "$study.modify_to_onelinefa";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_job =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if ($run_job eq "true"){
            $err_name = "$name_of_job.err";
            &clear_log($name_of_job, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
            while(qx{$stat | wc -l} > $maxjobs){
                sleep(10);
            }
	    my $temp_genome = "$LOC/one-line.fa";
            $job = "echo \"perl $norm_script_dir/rum-2.0.5_05/bin/modify_fa_to_have_seq_on_one_line.pl $genome > $temp_genome && echo \"got here\"\"| $batchjobs $mem $jobname \"$name_of_job\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";

            &onejob($job, $name_of_job, $job_num);
	    &check_exit_onejob($job, $name_of_job, $job_num);
	    &check_err ($name_of_job, $err_name, $job_num);
            $job_num++;
	    $genome = $temp_genome;
        }
    }
    if ($run_job eq "true"){
	print LOG "\nNormalization\n-------------\n";
	$job_num = 1;
	if ($GNORM eq "true"){
	    print LOG "\n[Gene Normalization - PART1]\n\n";
	}
	elsif ($EIJ eq "true"){
	    print LOG "\n[Exon-Intron-Junction Normalization - PART1]\n\n";
	}
    }
    #filter_sam GNORM
    $name_of_alljob = "$study.runall_filtersam_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
	}
    }
    if (($run_job eq "true") && ($GNORM eq "true")){ #GNORM step
        $name_of_job = "$study.filtersam_gnorm";
        $err_name = "filtersam_gnorm.*.err";
        if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_3G, $stat\\\"";
	}
	$new_queue = "-mem $queue_3G";
	my $numr = `sort -nrk 1 $study_dir/STATS/ribo_percents.txt | head -1`;
	chomp($numr);
	my @xnumr = split(" " , $numr);
	my $maxribo = $xnumr[0];
	$maxribo =~ s/\,//g;
	if ($maxribo > 10000000){ #10,000,000
	    $new_queue = "-mem $queue_6G";
	    if ($maxribo > 20000000){ #20,000,000
		$new_queue = "-mem $queue_10G";
	    }
	    if ($maxribo > 30000000){ #30,000,000
		$new_queue = "-mem $queue_15G";
	    }
	    if ($maxribo > 50000000){ #50,000,000
		$new_queue = "-mem $queue_30G";
	    }
	}
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_filter_gnorm.pl $sample_dir $LOC $alignedfilename $se $c_option $new_queue $cluster_max $use_chr_name -mito \\\"$mito\\\" $UONLY $b_option $hn_option\" | $batchjobs $mem $jobname \"$study.runall_filtersam_gnorm\" -o $logdir/$study.runall_filtersam_gnorm.out -e $logdir/$study.runall_filtersam_gnorm.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }
    #runall_get_percent_numchr_gnorm
    $name_of_alljob = "$study.runall_get_percent_numchr_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true")&& ($GNORM eq "true")){
	$name_of_job = "$study.numchrcnt_gnorm";
	$err_name = "numchrcnt_gnorm.*.err";

        if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname,  $request, $queue_3G, $stat\\\"";
	}
	$new_queue = "-mem $queue_3G";
	while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
	$job = "echo \"perl $norm_script_dir/runall_get_percent_numchr.pl $sample_dir $LOC -GENE $c_option $new_queue $cluster_max $hn_option\" | $batchjobs $mem $jobname \"$study.runall_get_percent_numchr_gnorm\" -o $logdir/$study.runall_get_percent_numchr_gnorm.out -e $logdir/$study.runall_get_percent_numchr_gnorm.err";
	if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    #get_chr_stats_gnorm
    $name_of_job = "$study.get_chr_stats_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
	}
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
	$err_name = "$name_of_job.err";

        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
        while (qx{$status | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/get_chr_stats.pl $sample_dir $LOC -GENE $altstats\" | $batchjobs $mem $jobname \"$study.get_chr_stats_gnorm\" -o $logdir/$study.get_chr_stats_gnorm.out -e $logdir/$study.get_chr_stats_gnorm.err";
        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }

    #get_master_list_of_genes
    $name_of_job = "$study.get_master_list_of_genes";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/get_master_list_of_genes.pl $ensGene $LOC $data_stranded -readlength $read_length\" | $batchjobs $mem $jobname \"$study.get_master_list_of_genes\" -o $logdir/$study.get_master_list_of_genes.out -e $logdir/$study.get_master_list_of_genes.err";

        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }
    #runall_sam2genes_gnorm
    $name_of_alljob = "$study.runall_sam2genes_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $name_of_job = "$study.sam2genes_gnorm";
        $err_name = "sam2genes_gnorm_*.err";
	if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname,$request,$queue_3G, $stat\\\"";
        }
	$new_queue = "-mem $queue_3G";
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_sam2genes_gnorm.pl $sample_dir $LOC $ensGene $strand_info $se $c_option $new_queue $cluster_max $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_sam2genes_gnorm\" -o $logdir/$study.runall_sam2genes_gnorm.out -e $logdir/$study.runall_sam2genes_gnorm.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    #cat_genes_files
    $name_of_alljob = "$study.runall_cat_genes_files";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $name_of_job = "$study.cat_genes_files";
        $err_name = "cat_genes.0.*.err";
        if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname,$request,$queue_3G, $stat\\\"";
        }
	$new_queue = "-mem $queue_3G";

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
	$job = "echo \"perl $norm_script_dir/runall_cat_genes_files.pl $sample_dir $LOC $c_option $new_queue $cluster_max -i 0 $data_stranded $UONLY $hn_option\" | $batchjobs $mem $jobname \"$name_of_alljob\" -o $logdir/$name_of_alljob.out -e $logdir/$name_of_alljob.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
            &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
            if (-e "$logdir/$name_of_alljob.err"){
                `rm $logdir/$name_of_alljob.err`;
            }
            if (-e "$logdir/$name_of_alljob.out"){
                `rm $logdir/$name_of_alljob.out`;
            }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
            $job =~ s/$sample_dir/$resume_file/;
            &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
            $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    #runall_genefilter
    $name_of_alljob = "$study.runall_genefilter_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $name_of_job = "$study.genefilter_gnorm";
        $err_name = "genefilter.0.*.err";
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
        }
	$new_queue = "-mem $queue_15G";

	$total = "$study_dir/STATS/total_num_reads.txt";
        $sorted = `cut -f 2 $total | sort -n`;
        @a = split (/\n/, $sorted);
        $min_map = $a[0];
        $max_map = $a[@a-1];
        if ($max_map > 50000000){
            $new_queue = "-mem $queue_30G";
            if ($max_map > 100000000){
                $new_queue = "-mem $queue_45G";
            }
	    if ($max_map > 150000000){
		$new_queue = "-mem $queue_60G";
	    }
        }
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_genefilter.pl $sample_dir $LOC $se $c_option $cluster_max $new_queue $data_stranded -i 0 $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_genefilter_gnorm\" -o $logdir/$study.runall_genefilter_gnorm.out -e $logdir/$study.runall_genefilter_gnorm.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }
    #copy_lcfiles_gnorm
    $name_of_job = "$study.copy_lcfiles_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
	    $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
        if ($resume eq "true"){
            $resume = "false";
        }
        $job = "echo \"perl $norm_script_dir/copy_lcfiles.pl $sample_dir $LOC $data_stranded -gnorm $altstats\" | $batchjobs $mem $jobname \"$name_of_job\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";

        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }
    if ($STRANDED =~ /^true/i){
        #sense2antisense_gnorm
        $name_of_job = "$study.get_sense2antisense_stats_gnorm";
        if (($resume eq "true")&&($run_job eq "false")){
            if ($name_of_job =~ /.$name_to_check$/){
		$run_job = "true";
                $job_num = $res_num;
            }
        }
        if (($run_job eq "true") && ($GNORM eq "true")){
            $err_name = "$name_of_job.err";
            &clear_log($name_of_job, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
            while(qx{$stat | wc -l} > $maxjobs){
                sleep(10);
            }
            $job = "echo \"perl $norm_script_dir/get_sense2antisense_stats.pl $sample_dir $LOC -gnorm $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.get_sense2antisense_stats_gnorm\" -o $logdir/$study.get_sense2antisense_stats_gnorm.out -e $logdir/$study.get_sense2antisense_stats_gnorm.err";

            &onejob($job, $name_of_job, $job_num);
            &check_exit_onejob($job, $name_of_job, $job_num);
            &check_err ($name_of_job, $err_name, $job_num);
            $job_num++;
        }
    }

    #runall_quantifygenes_gnorm
    $name_of_alljob = "$study.runall_quantify_genes_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $name_of_job = "$study.quantifygenes.gnorm";
        $err_name = "quantifygenes.gnorm_*u.*.err";
	if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_10G, $stat\\\"";
        }
	$new_queue = "-mem $queue_10G";
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_quantify_genes_gnorm.pl $sample_dir $LOC $list_for_genequant $se $UONLY $c_option $cluster_max $new_queue $data_stranded $hn_option\" | $batchjobs $mem $jobname \"$study.runall_quantify_genes_gnorm\" -o $logdir/$study.runall_quantify_genes_gnorm.out -e $logdir/$study.runall_quantify_genes_gnorm.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob, $name_of_job,$job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    #get_percent_genemappers
    $name_of_job = "$study.get_percent_genemappers_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/get_percent_genemappers.pl $sample_dir $LOC $data_stranded $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.get_percent_genemappers_gnorm\" -o $logdir/$study.get_percent_genemappers_gnorm.out -e $logdir/$study.get_percent_genemappers_gnorm.err ";

        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }

    #get_high_genes
    $name_of_alljob = "$study.runall_get_high_genes";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $name_of_job = "$study.get_genepercents";
        $err_name = "get_genepercents.0.*.err";
	if ($filter_high_expressers eq "false" | $cutoff_he eq '100'){
            $cutoff_he = 3;
	}
        if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
        }
	$new_queue = "-mem $queue_6G";

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_get_high_genes.pl $sample_dir $LOC $cutoff_he $c_option $new_queue $cluster_max $data_stranded $se -i 0 $hn_option\" | $batchjobs $mem $jobname \"$study.runall_get_high_genes\" -o $logdir/$study.runall_get_high_genes.out -e $logdir/$study.runall_get_high_genes.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }
    if ($UONLY ne '-u'){
	#runall_get_genepercents nu
	$name_of_alljob = "$study.runall_get_genepercents";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if (($run_job eq "true") && ($GNORM eq "true")){
	    $name_of_job = "$study.get_genepercents";
	    $err_name = "get_genepercents.1.*.err";
	    if ($filter_high_expressers eq "false" | $cutoff_he eq '100'){
		$cutoff_he = 3;
	    }
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_6G";

	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/runall_get_genepercents.pl $sample_dir $LOC $c_option $new_queue $cluster_max $data_stranded $se -i 1 $hn_option\" | $batchjobs $mem $jobname \"$study.runall_get_genepercents\" -o $logdir/$study.runall_get_genepercents.out -e $logdir/$study.runall_get_genepercents.err";
	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }
	    &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
	}
    }
    if (($filter_high_expressers eq 'true') && ($GNORM eq "true")){
        #runall_filter_high_expressers_gnorm
	$name_of_alljob = "$study.runall_filter_high_expressers_gnorm";
        if (($resume eq "true")&&($run_job eq "false")){
            if ($name_of_alljob =~ /.$name_to_check$/){
                $run_job = "true";
                $job_num = $res_num;
            }
        }
        if ($run_job eq "true"){
	    $name_of_job = "$study.filter_high_expressers_gnorm";
            $err_name = "filter_high_expressers_gnorm.0.*.err";
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_3G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_3G";

            $job = "echo \"perl $norm_script_dir/runall_filter_high_expressers_gnorm.pl $sample_dir $LOC $list_for_genequant $data_stranded $se $c_option $cluster_max $new_queue -i 0 $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_filter_high_expressers_gnorm\" -o $logdir/$study.runall_filter_high_expressers_gnorm.out -e $logdir/$study.runall_filter_high_expressers_gnorm.err";
	    &clear_log($name_of_alljob, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
        }
	#runall_genefilter
	$name_of_alljob = "$study.runall_genefilter_gnorm2";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if (($run_job eq "true") && ($GNORM eq "true")){
	    $name_of_job = "$study.genefilter_gnorm2";
	    $err_name = "genefilter2.1.*.err";
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_15G";

	    $total = "$study_dir/STATS/total_num_reads.txt";
	    $sorted = `cut -f 2 $total | sort -n`;
	    @a = split (/\n/, $sorted);
	    $min_map = $a[0];
	    $max_map = $a[@a-1];
	    if ($max_map > 50000000){
		$new_queue = "-mem $queue_30G";
		if ($max_map > 100000000){
		    $new_queue = "-mem $queue_45G";
		}
		if ($max_map > 150000000){
		    $new_queue = "-mem $queue_60G";
		}
	    }
	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/runall_genefilter.pl $sample_dir $LOC $se -filter_highexp $c_option $cluster_max $new_queue $data_stranded $filter_highexp -i 1 $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_genefilter_gnorm2\" -o $logdir/$study.runall_genefilter_gnorm2.out -e $logdir/$study.runall_genefilter_gnorm2.err";
	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }
	    &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
	}
	#copy_lcfiles_gnorm2
	$name_of_job = "$study.copy_lcfiles_gnorm2";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_job =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if (($run_job eq "true") && ($GNORM eq "true")){
	    $err_name = "$name_of_job.err";
	    &clear_log($name_of_job, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
	    $job = "echo \"perl $norm_script_dir/copy_lcfiles.pl $sample_dir $LOC $data_stranded -gnorm $altstats\" | $batchjobs $mem $jobname \"$name_of_job\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";

	    &onejob($job, $name_of_job, $job_num);
	    &check_exit_onejob($job, $name_of_job, $job_num);
	    &check_err ($name_of_job, $err_name, $job_num);
	    $job_num++;
	}
        #runall_genefilter_highexp
        $name_of_alljob = "$study.runall_genefilter_highexp";
        if (($resume eq "true")&&($run_job eq "false")){
            if ($name_of_alljob =~ /.$name_to_check$/){
                $run_job = "true";
                $job_num = $res_num;
            }
        }
        if (($run_job eq "true") && ($GNORM eq "true")){
            $name_of_job = "$study.genefilter_highexp";
            $err_name = "genefilter_highexp*.0.*err";
            if ($other eq "true"){
                $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
            }
	    $new_queue = "-mem $queue_15G";

            while(qx{$stat | wc -l} > $maxjobs){
                sleep(10);
            }
            $job = "echo \"perl $norm_script_dir/runall_genefilter_highexp.pl $sample_dir $LOC $se $c_option $cluster_max $new_queue $data_stranded -i 0 $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_genefilter_highexp\" -o $logdir/$study.runall_genefilter_highexp.out -e $logdir/$study.runall_genefilter_highexp.err";
            if ($resume eq "false"){
                &clear_log($name_of_alljob, $err_name);
                &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
            }
            else{
                $resume = "false";
                ####failedonly####
                if (-e "$logdir/$name_of_alljob.err"){
                    `rm $logdir/$name_of_alljob.err`;
                }
                if (-e "$logdir/$name_of_alljob.out"){
                    `rm $logdir/$name_of_alljob.out`;
                }
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
                $job =~ s/$sample_dir/$resume_file/;
                &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
                $job =~ s/$resume_file/$sample_dir/;
            }
            &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
            &check_err ($name_of_alljob, $err_name, $job_num);
            $job_num++;
        }
    }
    #get_percent_high_expresser_gnorm
    $name_of_job = "$study.get_percent_high_expresser_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/get_percent_high_expresser_gnorm.pl $sample_dir $LOC $data_stranded $altstats\" | $batchjobs $mem $jobname \"$study.get_percent_high_expresser_gnorm\" -o $logdir/$study.get_percent_high_expresser_gnorm.out -e $logdir/$study.get_percent_high_expresser_gnorm.err";

        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }

    #predict_num_reads GNORM
    $name_of_job = "$study.predict_num_reads_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/predict_num_reads_gnorm.pl $sample_dir $LOC $se $data_stranded $filter_highexp $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.predict_num_reads_gnorm\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";

        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }

    if ($run_job eq "true") {
	if (($GNORM eq "true") && ($EIJ eq "true")){
	    $job_num = 1;
	    print LOG "\n[Exon-Intron-Junction Normalization - PART1]\n\n";
	}
    }
    #filter_sam EIJ
    $name_of_alljob = "$study.runall_filtersam";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){ #EIJ step
	$name_of_job = "$study.filtersam";
	$err_name = "filtersam.*.err";
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_3G, $stat\\\"";
	}
	$new_queue = "-mem $queue_3G";

        my $numr = `sort -nrk 1 $study_dir/STATS/ribo_percents.txt | head -1`;
        chomp($numr);
        my @xnumr = split(" " , $numr);
	my $maxribo = $xnumr[0];
	$maxribo =~ s/\,//g;
        if ($maxribo > 10000000){
            $new_queue = "-mem $queue_6G";
            if ($maxribo > 20000000){
		$new_queue = "-mem $queue_10G";
            }
            if ($maxribo > 30000000){ #30,000,000
                $new_queue = "-mem $queue_15G";
            }
	    if ($maxribo > 50000000){ #50,000,000
                $new_queue = "-mem $queue_30G";
            }
        }
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }

	$job = "echo \"perl $norm_script_dir/runall_filter.pl $sample_dir $LOC $alignedfilename $se $c_option $new_queue $cluster_max $use_chr_name -mito \\\"$mito\\\" $UONLY $b_option $hn_option\" | $batchjobs $mem $jobname \"$study.runall_filtersam\" -o $logdir/$study.runall_filtersam.out -e $logdir/$study.runall_filtersam.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
	&check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }

    #runall_get_percent_numchr
    $name_of_alljob = "$study.runall_get_percent_numchr";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true")&& ($EIJ eq "true")){
        $name_of_job = "$study.numchrcnt";
        $err_name = "numchrcnt.*.err";
	if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname,  $request, $queue_3G, $stat\\\"";
        }
	$new_queue = "-mem $queue_3G";

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_get_percent_numchr.pl $sample_dir $LOC -EIJ $c_option $new_queue $cluster_max $hn_option\" | $batchjobs $mem $jobname \"$study.runall_get_percent_numchr\" -o $logdir/$study.runall_get_percent_numchr.out -e $logdir/$study.runall_get_percent_numchr.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    #get_chr_stats
    $name_of_job = "$study.get_chr_stats";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
        $err_name = "$name_of_job.err";

        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
        while (qx{$status | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/get_chr_stats.pl $sample_dir $LOC -EIJ $altstats\" | $batchjobs $mem $jobname \"$study.get_chr_stats\" -o $logdir/$study.get_chr_stats.out -e $logdir/$study.get_chr_stats.err";
        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }

    #get_master_list_of_exons
    $name_of_job = "$study.get_master_list_of_exons";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/get_master_list_of_exons.pl $geneinfo $LOC $data_stranded -readlength $read_length\" | $batchjobs $mem $jobname \"$study.get_master_list_of_exons\" -o $logdir/$study.get_master_list_of_exons.out -e $logdir/$study.get_master_list_of_exons.err";

	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }
    #get_master_list_of_introns
    $name_of_job = "$study.get_master_list_of_introns";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/get_master_list_of_introns.pl $geneinfo $LOC $data_stranded\" | $batchjobs $mem $jobname \"$study.get_master_list_of_introns\" -o $logdir/$study.get_master_list_of_introns.out -e $logdir/$study.get_master_list_of_introns.err";

        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }
    #get_master_list_of_intergenic_regions
    $name_of_job = "$study.get_master_list_of_intergenic_regions";
    if (($resume eq "true")&&($run_job eq "false")){
	if ($name_of_job =~ /.$name_to_check$/){
	    $run_job = "true";
	    $job_num = $res_num;
	}
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/get_master_list_of_intergenic_regions.pl $geneinfo $LOC $data_stranded -FR $flanking -readlength $read_length\" | $batchjobs $mem $jobname \"$study.get_master_list_of_intergenic_regions\" -o $logdir/$study.get_master_list_of_intergenic_regions.out -e $logdir/$study.get_master_list_of_intergenic_regions.err";

	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }

    if (($novel eq "true") && ($EIJ eq "true")){
        #junctions
	$name_of_alljob = "$study.runall_sam2junctions_samfilename";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if ($run_job eq "true"){
	    $name_of_job = "$study.sam2junctions";
	    $err_name = "sam2junctions.1.*.err";
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_6G";

	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }	
	    $job = "echo \"perl $norm_script_dir/runall_sam2junctions.pl $sample_dir $LOC $geneinfo $genome -samfilename $alignedfilename $c_option $new_queue $cluster_max $b_option $hn_option\" | $batchjobs $mem $jobname \"$study.runall_sam2junctions_samfilename\" -o $logdir/$study.runall_sam2junctions_samfilename.out -e $logdir/$study.runall_sam2junctions_samfilename.err";
	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }
	    &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
	}

	#runall_get_inferred_exons 
	$name_of_alljob = "$study.runall_get_inferred_exons";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if ($run_job eq "true"){
	    $name_of_job = "$study.get_inferred_exons";
	    $err_name = "get_inferred_exons.*.err";
	    $min_option = "";
	    $max_option = "";
	    if ($min ne '10'){
		$min_option = "-min $min";
	    }
	    if ($max ne '800'){
		$max_option = "-max $max";
	    }
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname,$request,$queue_3G,$stat\\\"";
	    }
	    $new_queue = "-mem $queue_3G";

	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/runall_get_inferred_exons.pl $sample_dir $LOC $alignedfilename $min_option $max_option $c_option $new_queue $cluster_max $hn_option\" | $batchjobs $mem $jobname \"$study.runall_get_inferred_exons\" -o $logdir/$study.runall_get_inferred_exons.out -e $logdir/$study.runall_get_inferred_exons.err";
	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }
	    &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
	}
	#get_novel_exons
	$name_of_job = "$study.get_novel_exons";
	if (($resume eq "true") && ($run_job eq "false")){
	    if ($name_of_job =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if ($run_job eq "true"){
	    $err_name = "$name_of_job.err";
	    &clear_log($name_of_job, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
            while(qx{$stat | wc -l} > $maxjobs){
                sleep(10);
            }
	    $job = "echo \"perl $norm_script_dir/get_novel_exons.pl $sample_dir $LOC $geneinfo\" | $batchjobs $mem $jobname $name_of_job -e $logdir/$name_of_job.err -o $logdir/$name_of_job.out";
	    &onejob($job, $name_of_job, $job_num);
            &check_exit_onejob($job, $name_of_job, $job_num);
            &check_err ($name_of_job, $err_name, $job_num);
            $job_num++;
	}
        #get_novel_introns
        $name_of_job = "$study.runall_get_novel_introns";
        if (($resume eq "true")&&($run_job eq "false")){
            if ($name_of_job =~ /.$name_to_check$/){
                $run_job = "true";
                $job_num = $res_num;
            }
        }
        if ($run_job eq "true"){
            $err_name = "$name_of_job.err";
            &clear_log($name_of_job, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
            $job = "echo \"perl $norm_script_dir/runall_get_novel_introns.pl $sample_dir $LOC $alignedfilename $geneinfo\" | $batchjobs $mem $jobname \"$study.runall_get_novel_introns\" -o $logdir/$study.runall_get_novel_introns.out -e $logdir/$study.runall_get_novel_introns.err";
	    
	    &onejob($job, $name_of_job, $job_num);
	    &check_exit_onejob($job, $name_of_job, $job_num);
	    &check_err ($name_of_job, $err_name, $job_num);
	    $job_num++;
	}
    }
    #get_list_for_intronquants
    $name_of_job = "$study.get_list_for_intronquants";
    if (($resume eq "true")&&($run_job eq "false")){
	if ($name_of_job =~ /.$name_to_check$/){
	    $run_job = "true";
	    $job_num = $res_num;
	}
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	my $list_int_option = "";
	if ($novel eq "true"){
	    $list_int_option = "-novel";
	}
	$job = "echo \"perl $norm_script_dir/get_list_for_intronquants.pl $LOC $list_int_option\" | $batchjobs $mem $jobname \"$study.get_list_for_intronquants\" -o $logdir/$study.get_list_for_intronquants.out -e $logdir/$study.get_list_for_intronquants.err";

	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }

    #runall_quantify_exons_introns
    $name_of_alljob = "$study.runall_quantify_exons_introns";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$name_of_job = "$study.quantify_exons_introns";
	$err_name = "quantify_exons_introns_*u.*.err";
		
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	}
	$new_queue = "-mem $queue_6G";

	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/runall_quantify_exons_introns.pl $sample_dir $LOC $list_for_exonquant $list_for_intronquant $LOC/master_list_of_intergenic_regions.txt $strand_info $UONLY $c_option $new_queue $cluster_max $hn_option\" | $batchjobs $mem $jobname \"$study.runall_quantify_exons_introns\" -o $logdir/$study.runall_quantify_exons_introns.out -e $logdir/$study.runall_quantify_exons_introns.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
	&check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }
    
    #get_high_expressers 
    $name_of_alljob = "$study.runall_get_high_expressers";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$name_of_job = "$study.get_high_expresser";
	$err_name = "annotate.0.*.err";
	if ($cutoff_he eq '100'){
	    $cutoff_he = 3;
	}
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
	}
	$new_queue = "-mem $queue_15G";

	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/runall_get_high_expressers.pl $sample_dir $LOC $cutoff_he $geneinfo $list_for_exonquant $c_option $new_queue $cluster_max $data_stranded -i 0 $hn_option\" | $batchjobs $mem $jobname \"$study.runall_get_high_expressers\" -o $logdir/$study.runall_get_high_expressers.out -e $logdir/$study.runall_get_high_expressers.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
	    if ($err_name =~ /^annotate.0/){
		if (-e "$logdir/annotate.0.master_exon.err"){
		    `rm $logdir/annotate.0.master_exon.err`;
		}
		if (-e "$logdir/annotate.0.master_exon.out"){
		    `rm $logdir/annotate.0.master_exon.out`;
		}
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
	&check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }
    #runall_get_exon_intron_percents nu
    $name_of_alljob = "$study.runall_get_exon_intron_percents";
    if (($resume eq "true")&&($run_job eq "false")){
	if ($name_of_alljob =~ /.$name_to_check$/){
	    $run_job = "true";
	    $job_num = $res_num;
	}
    }
    if (($run_job eq "true") && ($EIJ eq "true") && ($UONLY ne '-u')){
	$name_of_job = "$study.get_exon_intron_percents";
	$err_name = "get_exon_intron_percents.0.*.err";
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	}
	$new_queue = "-mem $queue_6G";

	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/runall_get_exon_intron_percents.pl $sample_dir $LOC $c_option $new_queue $cluster_max $data_stranded -i 0 $hn_option\" | $batchjobs $mem $jobname \"$study.runall_get_exon_intron_percents\" -o $logdir/$study.runall_get_exon_intron_percents.out -e $logdir/$study.runall_get_exon_intron_percents.err";
	if ($resume eq "false"){
	    &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	}
	else{
	    $resume = "false";
	    ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
	    if ($err_name =~ /^annotate.0/){
		if (-e "$logdir/annotate.0.master_exon.err"){
		    `rm $logdir/annotate.0.master_exon.err`;
		}
		if (-e "$logdir/annotate.0.master_exon.out"){
		    `rm $logdir/annotate.0.master_exon.out`;
		}
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
	}
	&check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }
    
    # make_list_of_high_expressers
    $name_of_job = "$study.make_list_of_high_expressers";
    if (($resume eq "true")&&($run_job eq "false")){
	if ($name_of_job =~ /.$name_to_check$/){
	    $run_job = "true";
	    $job_num = $res_num;
	}
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}	
	$job = "echo \"perl $norm_script_dir/make_list_of_high_expressers.pl $sample_dir $LOC $list_for_exonquant $data_stranded\" | $batchjobs $mem $jobname \"$name_of_job\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";
	
	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }
    
    #get_percent_high_expresser
    $name_of_job = "$study.get_percent_high_expresser";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/get_percent_high_expresser.pl $sample_dir $LOC $list_for_exonquant $data_stranded $altstats\" | $batchjobs $mem $jobname \"$study.get_percent_high_expresser\" -o $logdir/$study.get_percent_high_expresser.out -e $logdir/$study.get_percent_high_expresser.err";

	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }
    
    #run_quantify_exons_introns_outputsam
    $name_of_alljob = "$study.runall_quantify_exons_introns_outputsam";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$name_of_job = "$study.quantify_exons_introns";
	$err_name = "quantify_exons_introns.outputsam.0.*.err";
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	}
	$new_queue = "-mem $queue_6G";

	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}

        $job = "echo \"perl $norm_script_dir/runall_quantify_exons_introns.pl $sample_dir $LOC $list_for_exonquant $list_for_intronquant $LOC/master_list_of_intergenic_regions.txt $strand_info $filter_highexp $c_option $new_queue $cluster_max -outputsam -depthE $i_exon -depthI $i_intron -i 0 $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_quantify_exons_introns_outputsam\" -o $logdir/$study.runall_quantify_exons_introns_outputsam.out -e $logdir/$study.runall_quantify_exons_introns_outputsam.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
	&check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }
    #copy_lcfiles_eij
    $name_of_job = "$study.copy_lcfiles_eij";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
        if ($resume eq "true"){
            $resume = "false";
        }
	$job = "echo \"perl $norm_script_dir/copy_lcfiles.pl $sample_dir $LOC $data_stranded -eij -depthExon $i_exon -depthIntron $i_intron $altstats\" | $batchjobs $mem $jobname \"$name_of_job\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";

        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }
    #exon2nonexon
    $name_of_job = "$study.get_exon2nonexon_stats";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}    
	$job = "echo \"perl $norm_script_dir/get_exon2nonexon_signal_stats.pl $sample_dir $LOC $data_stranded $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.get_exon2nonexon_stats\" -o $logdir/$study.get_exon2nonexon_stats.out -e $logdir/$study.get_exon2nonexon_stats.err";

	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }

    #1exonvsmultiexons
    $name_of_job = "$study.get_1exonvsmultiexons_stats";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/get_1exon_vs_multi_exon_stats.pl $sample_dir $LOC $data_stranded $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.get_1exonvsmultiexons_stats\" -o $logdir/$study.get_1exonvsmultiexons_stats.out -e $logdir/$study.get_1exonvsmultiexons_stats.err";

	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }
    if ($STRANDED =~ /^true/i){
	#sense2antisense
	$name_of_job = "$study.get_sense2antisense_stats";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_job =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if (($run_job eq "true") && ($EIJ eq "true")){
	    $err_name = "$name_of_job.err";
	    &clear_log($name_of_job, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/get_sense2antisense_stats.pl $sample_dir $LOC $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.get_sense2antisense_stats\" -o $logdir/$study.get_sense2antisense_stats.out -e $logdir/$study.get_sense2antisense_stats.err";
	    
	    &onejob($job, $name_of_job, $job_num);
	    &check_exit_onejob($job, $name_of_job, $job_num);
	    &check_err ($name_of_job, $err_name, $job_num);
	    $job_num++;
	}
    }
    #get_percent_intergenic
    $name_of_job = "$study.get_percent_intergenic";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/get_percent_intergenic.pl $sample_dir $LOC $data_stranded $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.get_percent_intergenic\" -o $logdir/$study.get_percent_intergenic.out -e $logdir/$study.get_percent_intergenic.err ";
	
	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }
    #get_percent_exon_inconsistent
    $name_of_job = "$study.get_percent_exon_inconsistent";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
	}
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/get_percent_exon_inconsistent.pl $sample_dir $LOC $data_stranded $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.get_percent_exon_inconsistent\" -o $logdir/$study.get_percent_exon_inconsistent.out -e $logdir/$study.get_percent_exon_inconsistent.err ";

        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }
    #get_breakdown
    $name_of_job = "$study.get_breakdown";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
        if ($resume eq "true"){
            $resume = "false";
        }
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/get_breakdown_eij.pl $sample_dir $LOC $data_stranded $UONLY $altstats\"| $batchjobs $mem $jobname \"$study.get_breakdown\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";
	&onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }

    #predict_num_reads EIJ
    $name_of_job = "$study.predict_num_reads";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/predict_num_reads.pl $sample_dir $LOC $filter_highexp -depthE $i_exon -depthI $i_intron $data_stranded $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.predict_num_reads\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";

	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }
    
    if ($run_job eq "true"){
	if (($run_prepause eq "true")&&($run_norm eq "false")){
	    print LOG "\n[PART1 complete] ";
	    print LOG "Check the following before proceeding:\n\n";

	    if ($GNORM eq "true"){
                $exp_num_reads = `grep -A 3 Expected $study_dir/STATS/GENE/expected_num_reads_gnorm.txt | grep -A 3 estimate`;
                chomp($exp_num_reads);
                print LOG "\n[Gene Normalization]\n";
                print LOG "(1) Number of reads\n";
                print LOG "$exp_num_reads\n";
                print LOG "See \"$study_dir/STATS/GENE/expected_num_reads_gnorm.txt\" \nand modify the list of sample directories (\"$sample_dir\") accordingly to get more reads.\n\n";
                print LOG "(2) High Expressers\n";
		my @highfiles = glob("$study_dir/STATS/GENE/percent_high_expresser_gene*txt");
		my $highcnt = 0;
		foreach my $highfile (@highfiles){
		    my $x = `head -1 $highfile | wc -w`;
		    chomp($x);
		    if ($x > 1){
			$highcnt++;
		    }
		}
		if ($highcnt eq 0){
		    if ($cutoff_he == 100){
			$cutoff_he = 3;
		    }
		    print LOG "PORT did not find any highly expressed genes ($cutoff_he% used as cutoff).\n\n";
		}
		else{
		    print LOG "See \"$study_dir/STATS/GENE/percent_high_expresser_gene*txt\" \nUse \"-cutoff_highexp <n>\" option to set/change the highexpresser cutoff value.\n(You may use -cutoff_highexp 100 to unfilter/keep the highexpressers.)\n\n";
		}
	    }
	    if ($EIJ eq "true"){
		$exp_num_reads = `grep -A 3 Expected $study_dir/STATS/EXON_INTRON_JUNCTION/expected_num_reads.txt | grep -A 3 estimate`;
		chomp($exp_num_reads);
		print LOG "\n[Exon-Intron-Junction Normalization]\n";
		print LOG "(1) Number of reads\n";
		print LOG "$exp_num_reads\n";
		print LOG "See \"$study_dir/STATS/EXON_INTRON_JUNCTION/expected_num_reads.txt\" \nand modify the list of sample directories (\"$sample_dir\") accordingly to get more reads.\n\n";
		print LOG "(2) High Expressers\n";
                my @highfiles = glob("$study_dir/STATS/EXON_INTRON_JUNCTION/percent_high_expresser_*txt");
		my $highcnt = 0;
		foreach my $highfile (@highfiles){
                    my $x = `head -1 $highfile | wc -w`;
                    chomp($x);
                    if ($x > 1){
			$highcnt++;
                    }
		}
		if ($highcnt eq 0){
		    if ($cutoff_he == 100){
			$cutoff_he = 3;
		    }
                    print LOG "PORT did not find any highly expressed exons/introns ($cutoff_he% used as cutoff).\n\n";
                }
		else{
		    print LOG "Check \"$study_dir/STATS/EXON_INTRON_JUNCTION/percent_high_expresser_*.txt\" \nUse \"-cutoff_highexp <n>\" option to set/change the highexpresser cutoff value.\n(You may use -cutoff_highexp 100 to unfilter/keep the highexpressers.)\n\n";
		}
	    }
=comment
	    $default_input = `cat $shdir/runall_normalization.sh`;
	    $default_input =~ s/perl\ //g;
	    $default_input =~ s/runall_normalization.pl/run_normalization/g;
	    $default_input =~ s/\-fa\n//;
	    $default_input =~ s/\-fq\n//;
	    $default_input =~ s/\-sam //;
	    $default_input =~ s/\-bam //;
	    $default_input =~ s/\-gz//;
	    $default_input =~ s/\-se//;
	    $default_input =~ s/\'-resume_at'\ .+\ //;
	    $default_input =~ s/\-resume//;
=cut
	    print LOG "*************\nUse \"-part2\" option to continue:\n(do not change options other than the ones listed above)\n";
	    #print LOG "e.g. $default_input -part2\n*************\n";
	}
    }

    if (($run_job eq "false") && ($run_norm eq "false") && ($resume eq "true")){
	print LOG "\nERROR: \"$study.$name_to_check\" step is not in [PART1].\n\tCannot resume at \"$study.$name_to_check\" step. Please check your pipeline option and -resume_at \"<step>\" option.\n\n";
    }
}
if ($run_norm eq "true"){
    if ($run_prepause eq "false"){
	$job_num = 1;
	if ($run_job eq "true"){
	    print LOG "\nNormalization (continued)\n-------------------------\n";
	}
    }
    if ($run_job eq "true"){
	$job_num = 1;
        if ($GNORM eq "true"){
            print LOG "\n[Gene Normalization - PART2]\n\n";
	}
        elsif ($EIJ eq "true"){
            print LOG "\n[Exon-Intron-Junction Normalization - PART2]\n\n";
        }
    }
    #check_fasta
    my $seqnum = `grep -c "^>" $genome`;
    my $falinecnt = `wc -l $genome`;
    my @lcfa =split(" ", $falinecnt);
    my $linenum_fa = $lcfa[0];
    my $temp_genome = "$LOC/one-line.fa";
    if (($seqnum * 2) ne $linenum_fa){
	unless (-e $temp_genome){
	    #modify_to_onelinefa2
	    $name_of_job = "$study.modify_to_onelinefa2";
	    if (($resume eq "true")&&($run_job eq "false")){
		if ($name_of_job =~ /.$name_to_check$/){
		    $run_job = "true";
		    $job_num = $res_num;
		}
	    }
	    if ($run_job eq "true"){
		$err_name = "$name_of_job.err";
		&clear_log($name_of_job, $err_name);
		if ($resume eq "true"){
		    $resume = "false";
		}	
		while(qx{$stat | wc -l} > $maxjobs){
		    sleep(10);
		}
		$job = "echo \"perl $norm_script_dir/rum-2.0.5_05/bin/modify_fa_to_have_seq_on_one_line.pl $genome > $temp_genome && echo \"got here\"\"| $batchjobs $mem $jobname \"$name_of_job\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";
		
		&onejob($job, $name_of_job, $job_num);
		&check_exit_onejob($job, $name_of_job, $job_num);
		&check_err ($name_of_job, $err_name, $job_num);
		$job_num++;
	    }
	}
	$genome = $temp_genome;
    }
    if ($run_prepause eq "false"){
        # when -cutoff_highexp is used along with -part2, compare the cutoff value against old cutoff
        # to determine if filter_high_expresser needs to be repeated
        if ($GNORM eq "true"){
            if ($filter_high_expressers eq 'true'){
		$filter_gene = "true";
		$filter_gene2 = "true";
                if (-e "$shdir/runall_normalization.sh"){
                    $command = `cat $shdir/runall_normalization.sh`;
                    if ($command =~ /highexp/){
                        $command =~ m/highexp\ (\d*)/;
                        $cutoff_old = $1;
                        if ($cutoff_he eq $cutoff_old){
                            $filter_gene = "false";
                        }
			else{
			    $filter_gene = "true";
			}
                    }
                }
            }
            if ($filter_gene eq 'true'){
		#get_high_genes_p2
		$name_of_alljob = "$study.runall_get_high_genes_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_alljob =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if ($run_job eq "true"){
		    $name_of_job = "$study.get_genepercents";
		    $err_name = "get_genepercents.1.*.err";
		    if ($other eq "true"){
			$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
		    }
		    $new_queue = "-mem $queue_6G";

		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }
		    $job = "echo \"perl $norm_script_dir/runall_get_high_genes.pl $sample_dir $LOC $cutoff_he $c_option $new_queue $cluster_max $data_stranded $se -i 1 $hn_option\" | $batchjobs $mem $jobname \"$study.runall_get_high_genes_p2\" -o $logdir/$study.runall_get_high_genes_p2.out -e $logdir/$study.runall_get_high_genes_p2.err";
		    if ($resume eq "false"){
			&clear_log($name_of_alljob, $err_name);
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    }
		    else{
			$resume = "false";
			####failedonly####
			if (-e "$logdir/$name_of_alljob.err"){
			    `rm $logdir/$name_of_alljob.err`;
			}
			if (-e "$logdir/$name_of_alljob.out"){
			    `rm $logdir/$name_of_alljob.out`;
			}
			$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
			$job =~ s/$new_queue/$r/;
			$job =~ s/$sample_dir/$resume_file/;
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
			$job =~ s/$resume_file/$sample_dir/;
		    }
		    &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    &check_err ($name_of_alljob, $err_name, $job_num);
		    $job_num++;
		}
		#runall_filter_high_expressers_gnorm_p2
		$name_of_alljob = "$study.runall_filter_high_expressers_gnorm_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_alljob =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if ($run_job eq "true"){
		    $name_of_job = "$study.filter_high_expressers_gnorm";
		    $err_name = "filter_high_expressers_gnorm.1.*.err";
		    if ($other eq "true"){
			$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_3G, $stat\\\"";
		    }
		    $new_queue = "-mem $queue_3G";

		    $job = "echo \"perl $norm_script_dir/runall_filter_high_expressers_gnorm.pl $sample_dir $LOC $list_for_genequant $data_stranded $se $c_option $cluster_max $new_queue -i 1 $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_filter_high_expressers_gnorm_p2\" -o $logdir/$study.runall_filter_high_expressers_gnorm_p2.out -e $logdir/$study.runall_filter_high_expressers_gnorm_p2.err";
		    &clear_log($name_of_alljob, $err_name);
		    if ($resume eq "true"){
			$resume = "false";
		    }
		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }
		    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
		    &check_err ($name_of_alljob, $err_name, $job_num);
		    $job_num++;
		}
                #runall_genefilter2
		$name_of_alljob = "$study.runall_genefilter_gnorm2_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_alljob =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if (($run_job eq "true") && ($GNORM eq "true")){
		    $name_of_job = "$study.genefilter_gnorm2";
		    $err_name = "genefilter2.2.*.err";
		    if ($other eq "true"){
			$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
		    }
		    $new_queue = "-mem $queue_15G";

		    $total = "$study_dir/STATS/total_num_reads.txt";
		    $sorted = `cut -f 2 $total | sort -n`;
		    @a = split (/\n/, $sorted);
		    $min_map = $a[0];
		    $max_map = $a[@a-1];
		    if ($max_map > 50000000){
			$new_queue = "-mem $queue_30G";
			if ($max_map > 100000000){
			    $new_queue = "-mem $queue_45G";
			}
			if ($max_map > 150000000){
			    $new_queue = "-mem $queue_60G";
			}
		    }
		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }
		    $job = "echo \"perl $norm_script_dir/runall_genefilter.pl $sample_dir $LOC $se -filter_highexp $c_option $cluster_max $new_queue $data_stranded -i 2 $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_genefilter_gnorm2_p2\" -o $logdir/$study.runall_genefilter_gnorm2_p2.out -e $logdir/$study.runall_genefilter_gnorm2_p2.err";
		    if ($resume eq "false"){
			&clear_log($name_of_alljob, $err_name);
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    }
		    else{
			$resume = "false";
			####failedonly####
			if (-e "$logdir/$name_of_alljob.err"){
			    `rm $logdir/$name_of_alljob.err`;
			}
			if (-e "$logdir/$name_of_alljob.out"){
			    `rm $logdir/$name_of_alljob.out`;
			}
			$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
			$job =~ s/$new_queue/$r/;
			$job =~ s/$sample_dir/$resume_file/;
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
			$job =~ s/$resume_file/$sample_dir/;
		    }
		    &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
		    &check_err ($name_of_alljob, $err_name, $job_num);
		    $job_num++;
		}
		#copy_lcfiles_gnorm2_p2
		$name_of_job = "$study.copy_lcfiles_gnorm2_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_job =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if (($run_job eq "true") && ($GNORM eq "true")){
		    $err_name = "$name_of_job.err";
		    &clear_log($name_of_job, $err_name);
		    if ($resume eq "true"){
			$resume = "false";
		    }
		    $job = "echo \"perl $norm_script_dir/copy_lcfiles.pl $sample_dir $LOC $data_stranded -gnorm $altstats\" | $batchjobs $mem $jobname \"$name_of_job\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";
		    
		    &onejob($job, $name_of_job, $job_num);
		    &check_exit_onejob($job, $name_of_job, $job_num);
		    &check_err ($name_of_job, $err_name, $job_num);
		    $job_num++;
		}
		#runall_genefilter_highexp_p2
		$name_of_alljob = "$study.runall_genefilter_highexp_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_alljob =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if (($run_job eq "true") && ($GNORM eq "true")){
		    $name_of_job = "$study.genefilter_highexp";
		    $err_name = "genefilter_highexp*.1.*err";
		    if ($other eq "true"){
			$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
		    }
		    $new_queue = "-mem $queue_15G";

		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }
		    $job = "echo \"perl $norm_script_dir/runall_genefilter_highexp.pl $sample_dir $LOC $se $c_option $cluster_max $new_queue $data_stranded -i 1 $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_genefilter_highexp_p2\" -o $logdir/$study.runall_genefilter_highexp_p2.out -e $logdir/$study.runall_genefilter_highexp_p2.err";
		    if ($resume eq "false"){
			&clear_log($name_of_alljob, $err_name);
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    }
		    else{
			$resume = "false";
			####failedonly####
			if (-e "$logdir/$name_of_alljob.err"){
			    `rm $logdir/$name_of_alljob.err`;
			}
			if (-e "$logdir/$name_of_alljob.out"){
			    `rm $logdir/$name_of_alljob.out`;
			}
			$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
			$job =~ s/$new_queue/$r/;
			$job =~ s/$sample_dir/$resume_file/;
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
			$job =~ s/$resume_file/$sample_dir/;
		    }
		    &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
		    &check_err ($name_of_alljob, $err_name, $job_num);
		    $job_num++;
		}
	    
		#get_percent_high_expresser_gnorm_p2
		$name_of_job = "$study.get_percent_high_expresser_gnorm_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_job =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if ($run_job eq "true"){
		    $err_name = "$name_of_job.err";
		    &clear_log($name_of_job, $err_name);
		    if ($resume eq "true"){
			$resume = "false";
		    }

		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }
		    $job = "echo \"perl $norm_script_dir/get_percent_high_expresser_gnorm.pl $sample_dir $LOC $data_stranded $altstats\" | $batchjobs $mem $jobname \"$study.get_percent_high_expresser_gnorm_p2\" -o $logdir/$study.get_percent_high_expresser_gnorm_p2.out -e $logdir/$study.get_percent_high_expresser_gnorm_p2.err";

		    &onejob($job, $name_of_job, $job_num);
		    &check_exit_onejob($job, $name_of_job, $job_num);
		    &check_err ($name_of_job, $err_name, $job_num);
		    $job_num++;
		}
		
                #predict_num_reads GNORM p2
		$name_of_job = "$study.predict_num_reads_gnorm_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_job =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if (($run_job eq "true") && ($GNORM eq "true")){
		    $err_name = "$study.predict_num_reads_gnorm_p2.err";
		    &clear_log($name_of_job, $err_name);
		    if ($resume eq "true"){
			$resume = "false";
		    }

		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }
		    $job = "echo \"perl $norm_script_dir/predict_num_reads_gnorm.pl $sample_dir $LOC $filter_highexp $data_stranded $se $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.predict_num_reads_gnorm_p2\" -o $logdir/$study.predict_num_reads_gnorm_p2.out -e $logdir/$study.predict_num_reads_gnorm_p2.err";
		    
		    &onejob($job, $name_of_job, $job_num);
		    &check_exit_onejob($job, $name_of_job, $job_num);
		    &check_err ($name_of_job, $err_name, $job_num);
		    $job_num++;
		}
	    }
	}
    }

    #runall_shuf_gnorm
    $name_of_alljob = "$study.runall_shuf_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $name_of_job = "$study.shuf_gnorm";
        $err_name = "run_shuf_gnorm*.err";
	&clear_log($name_of_alljob, $err_name);
        if ($resume eq "true"){
            $resume = "false";
        }
	if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_10G, $stat\\\"";
        }
	$new_queue = "-mem $queue_10G";

        @g = glob("$LOC/*/GNORM/*/*linecount*txt");
        if (@g ne '0'){
            $max_lc = `cut -f 2 $LOC/*/GNORM/*/*linecount*txt | sort -nr | head -1`;
            if ($max_lc > 40000000){
                $new_queue = "-mem $queue_30G";
                if ($max_lc > 100000000){
		    if ($max_lc <= 450000000){
			$new_queue = "-mem $queue_45G";
		    }
		    else{
			$new_queue = "-mem $queue_60G";
		    }
		}
            }
        }
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_shuf_gnorm.pl $sample_dir $LOC $se $c_option $new_queue $cluster_max $data_stranded $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_shuf_gnorm\" -o $logdir/$study.runall_shuf_gnorm.out -e $logdir/$study.runall_shuf_gnorm.err";
	&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }   
    #runall_shuf_gnorm_highexp
    if ($filter_high_expressers eq "true"){
	$name_of_alljob = "$study.runall_shuf_gnorm_highexp";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if (($run_job eq "true") && ($GNORM eq "true")){
	    $name_of_job = "$study.shuf_gnorm_highexp";
	    $err_name = "run_shuf_gnorm*highexp*.err";
	    &clear_log($name_of_alljob, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_6G";

	    @g = glob("$LOC/*/GNORM/*/*linecount*txt");
	    if (@g ne '0'){
		$max_lc = `cut -f 2 $LOC/*/GNORM/*/*linecount*txt | sort -nr | head -1`;
		if ($max_lc > 40000000){
		    $new_queue = "-mem $queue_10G";
		    if ($max_lc > 100000000){
			if ($max_lc <= 300000000){
			    $new_queue = "-mem $queue_30G";
			}
			elsif ($max_lc <= 450000000){
			    $new_queue = "-mem $queue_45G";
			}
			else{
			    $new_queue = "-mem $queue_60G";
			}
		    }
		}
	    }
	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/runall_shuf_gnorm_highexp.pl $sample_dir $LOC $se $c_option $new_queue $cluster_max $data_stranded $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_shuf_gnorm_highexp\" -o $logdir/$study.runall_shuf_gnorm_highexp.out -e $logdir/$study.runall_shuf_gnorm_highexp.err";
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
	}
    }

    #runall_cat_shuffiles_gnorm
    $name_of_alljob = "$study.runall_cat_shuffiles_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
	if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
	$name_of_job = "$study.cat_gnorm_Unique_NU";
        $err_name = "cat_gnorm_Unique_NU.*.err";
        if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname,$request,$queue_3G,$stat\\\"";
	}
	$new_queue = "-mem $queue_3G";

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_cat_gnorm_Unique_NU.pl $sample_dir $LOC $alignedfilename $data_stranded $c_option $new_queue $cluster_max $UONLY $b_option -normdir $normdir $filter_highexp $hn_option\" | $batchjobs $mem $jobname \"$study.runall_cat_shuffiles_gnorm\" -o $logdir/$study.runall_cat_shuffiles_gnorm.out -e $logdir/$study.runall_cat_shuffiles_gnorm.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
            &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
            if (-e "$logdir/$name_of_alljob.err"){
                `rm $logdir/$name_of_alljob.err`;
            }
            if (-e "$logdir/$name_of_alljob.out"){
                `rm $logdir/$name_of_alljob.out`;
            }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
            $job =~ s/$sample_dir/$resume_file/;
            &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
            $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    #runall_sam2genes_gnorm_2
    $name_of_alljob = "$study.runall_sam2genes_gnorm_2";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $name_of_job = "$study.sam2genes_gnorm";
        $err_name = "sam2genes_gnorm2.*.err";

	if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname,$request,$queue_3G,$stat\\\"";
        }
	$new_queue = "-mem $queue_3G";

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_sam2genes_gnorm.pl $sample_dir $LOC $ensGene $c_option $new_queue $cluster_max $strand_info $se -norm $normdir -samtools $samtools $hn_option\" | $batchjobs $mem $jobname \"$study.runall_sam2genes_gnorm_2\" -o $logdir/$study.runall_sam2genes_gnorm_2.out -e $logdir/$study.runall_sam2genes_gnorm_2.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
	&check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }

    #runall_cat_genes_files_norm
    $name_of_alljob = "$study.runall_cat_genes_files_norm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $name_of_job = "$study.cat_genes_files";
        $err_name = "cat_genes.1.*.err";
        if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname,$request,$queue_3G, $stat\\\"";
        }
	$new_queue = "-mem $queue_3G";

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_cat_genes_files.pl $sample_dir $LOC $c_option $new_queue $cluster_max -i 1 $data_stranded -norm $normdir $hn_option\" | $batchjobs $mem $jobname \"$name_of_alljob\" -o $logdir/$name_of_alljob.out -e $logdir/$name_of_alljob.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
            &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
            if (-e "$logdir/$name_of_alljob.err"){
                `rm $logdir/$name_of_alljob.err`;
            }
            if (-e "$logdir/$name_of_alljob.out"){
                `rm $logdir/$name_of_alljob.out`;
            }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
            $job =~ s/$sample_dir/$resume_file/;
            &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
            $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    if ($STRANDED =~ /^true/i){
	#runall_genefilter_norm
	$name_of_alljob = "$study.runall_genefilter_gnorm_norm";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if (($run_job eq "true") && ($GNORM eq "true")){
	    $name_of_job = "$study.genefilter_gnorm_norm";
	    $err_name = "genefilter.norm.*.err";
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_15G";

	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $total = "$study_dir/STATS/total_num_reads.txt";
	    $sorted = `cut -f 2 $total | sort -n`;
	    @a = split (/\n/, $sorted);
	    $min_map = $a[0];
	    $max_map = $a[@a-1];
	    if ($min_map > 50000000){
		$new_queue = "-mem $queue_30G";
		if ($min_map > 100000000){
		    $new_queue = "-mem $queue_45G";
		}
		if ($min_map > 150000000){
		    $new_queue = "-mem $queue_60G";
		}
	    }
	    $job = "echo \"perl $norm_script_dir/runall_genefilter.pl $sample_dir $LOC $se $c_option $cluster_max $new_queue $data_stranded -norm $normdir $hn_option\" | $batchjobs $mem $jobname \"$study.runall_genefilter_gnorm_norm\" -o $logdir/$study.runall_genefilter_gnorm_norm.out -e $logdir/$study.runall_genefilter_gnorm_norm.err";
	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }
	    &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
	}
    }

    #runall_quantifygenes_gnorm2
    $name_of_alljob = "$study.runall_quantify_genes_gnorm2";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $name_of_job = "$study.quantifygenes.gnorm2";
        $err_name = "quantifygenes.gnorm2*.err";
	if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_10G, $stat\\\"";
	}
	$new_queue = "-mem $queue_10G";

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_quantify_genes_gnorm.pl $sample_dir $LOC $list_for_genequant -norm $normdir $se $c_option $cluster_max $new_queue $data_stranded $hn_option\" | $batchjobs $mem $jobname \"$study.runall_quantify_genes_gnorm2\" -o $logdir/$study.runall_quantify_genes_gnorm2.out -e $logdir/$study.runall_quantify_genes_gnorm2.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob, $name_of_job,$job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    if ($STRANDED =~ /^true/i){
	#runall_unique_merge_gnorm
	$name_of_alljob = "$study.runall_unique_merge_gnorm";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if (($run_job eq "true") && ($GNORM eq "true")){
	    $name_of_job = "$study.unique_merge_gnorm";
	    $err_name = "unique_merge_gnorm.*.err";

	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_15G";


	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    
	    $job = "echo \"perl $norm_script_dir/runall_unique_merge_gnorm.pl $sample_dir $LOC $se $c_option $cluster_max $new_queue -normdir $normdir $hn_option\" | $batchjobs $mem $jobname \"$name_of_alljob\" -o $logdir/$name_of_alljob.out -e $logdir/$name_of_alljob.err";

	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }
	    &check_exit_alljob($job, $name_of_alljob, $name_of_job,$job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
	}
    }

    #runall_sam2junctions_gnorm
    $name_of_alljob = "$study.runall_sam2junctions_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
	$name_of_job = "$study.sam2junctions_gnorm";
        $err_name = "sam2junctions_gnorm.*.err";
	if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
        }
	$new_queue = "-mem $queue_6G";

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_sam2junctions.pl $sample_dir $LOC $ensGene $genome -gnorm $c_option $new_queue $cluster_max $data_stranded -normdir $normdir $hn_option\" | $batchjobs $mem $jobname \"$study.runall_sam2junctions_gnorm\" -o $logdir/$study.runall_sam2junctions_gnorm.out -e $logdir/$study.runall_sam2junctions_gnorm.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    #quants2spreadsheet_gnorm
    $name_of_job = "$study.quants2spreadsheet_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
	
	my $mem_quants = $mem;
	if ($num_samples > 200){
	    $mem_quants = "$request$queue_10G";
	}
        $job = "echo \"perl $norm_script_dir/quants2spreadsheet_min_max.pl $sample_dir $LOC genequants $filter_highexp $data_stranded -normdir $normdir\" | $batchjobs $mem_quants $jobname \"$study.quants2spreadsheet_gnorm\" -o $logdir/$study.quants2spreadsheet_gnorm.out -e $logdir/$study.quants2spreadsheet_gnorm.err";
	
        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }

    #filter_low_expressers
    $name_of_job = "$study.filter_low_expressers_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}

        $to_filter = "$normdir/GENE/to_filter.txt";
        open(OUT, ">$to_filter");
	if ($STRANDED =~ /^true/i){
	    print OUT "master_list_of_gene_counts_MIN.sense.$study.txt\nmaster_list_of_gene_counts_MIN.antisense.$study.txt\nmaster_list_of_gene_counts_MAX.sense.$study.txt\nmaster_list_of_gene_counts_MAX.antisense.$study.txt\n";
	}
	else{
	    print OUT "master_list_of_gene_counts_MIN.$study.txt\nmaster_list_of_gene_counts_MAX.$study.txt\n";
	}
	close(OUT);
	while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_filter_low_expressers_gnorm.pl $to_filter $num_samples $cutoff_le $normdir\" | $batchjobs $mem $jobname \"$study.filter_low_expressers_gnorm\" -o $logdir/$study.filter_low_expressers_gnorm.out -e $logdir/$study.filter_low_expressers_gnorm.err";

        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }
    if ($run_job eq "true"){
	if (($GNORM eq "true") && ($EIJ eq "true")){
	    $job_num = 1;
	    print LOG "\n[Exon-Intron-Junction Normalization - PART2]\n\n";
	}
    }
    if ($run_prepause eq "false"){
	# when -cutoff_highexp is used along with -part2, compare the cutoff value against old cutoff 
	# to determine if filter_high_expresser and/or quantify_exons need to be repeated
	if ($EIJ eq "true"){
	    if ($filter_high_expressers eq 'true'){
		$filter_eij = "true";
		if (-e "$shdir/runall_normalization.sh"){
		    $command = `cat $shdir/runall_normalization.sh`;
		    if ($command =~ /highexp/){
			$command =~ m/highexp\ (\d*)/;
			$cutoff_old = $1;
			if ($cutoff_he eq $cutoff_old){
			    $filter_eij = "false";
			}
			else{
			    $filter_eij = "true";
			}
		    }	    
		}
	    }
	    if ($filter_eij eq "true"){
		#get_high_expressers 
		$name_of_alljob = "$study.runall_get_high_expressers_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_alljob =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if ($run_job eq "true"){
		    $name_of_job = "$study.get_high_expresser";
		    $err_name = "annotate.1.*.err";
		    if ($other eq "true"){
			$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
		    }
		    $new_queue = "-mem $queue_15G";
		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }

		    $job = "echo \"perl $norm_script_dir/runall_get_high_expressers.pl $sample_dir $LOC $cutoff_he $geneinfo $list_for_exonquant $c_option $new_queue $cluster_max $data_stranded -i 1 -part2 $hn_option\" | $batchjobs $mem $jobname \"$study.runall_get_high_expressers_p2\" -o $logdir/$study.runall_get_high_expressers_p2.out -e $logdir/$study.runall_get_high_expressers_p2.err";
		    if ($resume eq "false"){
			&clear_log($name_of_alljob, $err_name);
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    }
		    else{
			$resume = "false";
			####failedonly####
			if (-e "$logdir/$name_of_alljob.err"){
			    `rm $logdir/$name_of_alljob.err`;
			}
			if (-e "$logdir/$name_of_alljob.out"){
			    `rm $logdir/$name_of_alljob.out`;
			}
			if ($err_name =~ /^annotate.1/){
			    if (-e "$logdir/annotate.1.master_exon.err"){
				`rm $logdir/annotate.1.master_exon.err`;
			    }
			    if (-e "$logdir/annotate.1.master_exon.out"){
				`rm $logdir/annotate.1.master_exon.out`;
			    }
			}
			$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
			$job =~ s/$new_queue/$r/;
			$job =~ s/$sample_dir/$resume_file/;
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
			$job =~ s/$resume_file/$sample_dir/;
		    }
		    &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    &check_err ($name_of_alljob, $err_name, $job_num);
		    $job_num++;
		}
=comment
		#runall_get_exon_intron_percents nu p2
		$name_of_alljob = "$study.runall_get_exon_intron_percents_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_alljob =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if (($run_job eq "true") && ($EIJ eq "true") && ($UONLY ne '-u')){
		    $name_of_job = "$study.get_exon_intron_percents";
		    $err_name = "get_exon_intron_percents.1.*.err";
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
		    $job = "echo \"perl $norm_script_dir/runall_get_exon_intron_percents.pl $sample_dir $LOC $c_option $new_queue $cluster_max $data_stranded -i 1\" | $batchjobs $mem $jobname \"$study.runall_get_exon_intron_percents_p2\" -o $logdir/$study.runall_get_exon_intron_percents_p2.out -e $logdir/$study.runall_get_exon_intron_percents_p2.err";
		    if ($resume eq "false"){
			&clear_log($name_of_alljob, $err_name);
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    }
		    else{
			$resume = "false";
			####failedonly####
			if (-e "$logdir/$name_of_alljob.err"){
			    `rm $logdir/$name_of_alljob.err`;
			}
			if (-e "$logdir/$name_of_alljob.out"){
			    `rm $logdir/$name_of_alljob.out`;
			}
			if ($err_name =~ /^annotate.0/){
			    if (-e "$logdir/annotate.0.master_exon.err"){
				`rm $logdir/annotate.0.master_exon.err`;
			    }
			    if (-e "$logdir/annotate.0.master_exon.out"){
				`rm $logdir/annotate.0.master_exon.out`;
			    }
			}
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
			$job =~ s/$sample_dir/$resume_file/;
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
			$job =~ s/$resume_file/$sample_dir/;
		    }
		    &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    &check_err ($name_of_alljob, $err_name, $job_num);
		    $job_num++;
		}
=cut
		# make_list_of_high_expressers
		$name_of_job = "$study.make_list_of_high_expressers_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_job =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if ($run_job eq "true"){
		    $err_name = "$name_of_job.err";
		    if ($resume eq "true"){
			$resume = "false";
		    }

		    &clear_log($name_of_job, $err_name);
		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }
		    $job = "echo \"perl $norm_script_dir/make_list_of_high_expressers.pl $sample_dir $LOC $list_for_exonquant $data_stranded\" | $batchjobs $mem $jobname \"$name_of_job\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";

		    &onejob($job, $name_of_job, $job_num);
		    &check_exit_onejob($job, $name_of_job, $job_num);
		    &check_err ($name_of_job, $err_name, $job_num);
		    $job_num++;
		}

		#get_percent_high_expresser
		$name_of_job = "$study.get_percent_high_expresser_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_job =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if ($run_job eq "true"){
		    $err_name = "$name_of_job.err";
		    &clear_log($name_of_job, $err_name);
		    if ($resume eq "true"){
			$resume = "false";
		    }

		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }
		    $job = "echo \"perl $norm_script_dir/get_percent_high_expresser.pl $sample_dir $LOC $list_for_exonquant $data_stranded $altstats\" | $batchjobs $mem $jobname \"$study.get_percent_high_expresser_2\" -o $logdir/$study.get_percent_high_expresser_p2.out -e $logdir/$study.get_percent_high_expresser_p2.err";
		    
		    &onejob($job, $name_of_job, $job_num);
		    &check_exit_onejob($job, $name_of_job, $job_num);
		    &check_err ($name_of_job, $err_name, $job_num);
		    $job_num++;
		}

		#run_quantify_exons_introns_outputsam_p2
		$name_of_alljob = "$study.runall_quantify_exons_introns_outputsam_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_alljob =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if ($run_job eq "true"){
		    $name_of_job = "$study.quantify_exons_introns";
		    $err_name = "quantify_exons_introns.outputsam.1.*.err";
		    if ($other eq "true"){
			$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
		    }
		    $new_queue = "-mem $queue_6G";

		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }

		    $job = "echo \"perl $norm_script_dir/runall_quantify_exons_introns.pl $sample_dir $LOC $list_for_exonquant $list_for_intronquant $LOC/master_list_of_intergenic_regions.txt $strand_info $filter_highexp $c_option $new_queue $cluster_max -outputsam -depthE $i_exon -depthI $i_intron -i 1 $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_quantify_exons_introns_outputsam_p2\" -o $logdir/$study.runall_quantify_exons_introns_outputsam_p2.out -e $logdir/$study.runall_quantify_exons_introns_outputsam_p2.err";
		    if ($resume eq "false"){
			&clear_log($name_of_alljob, $err_name);
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    }
		    else{
			$resume = "false";
			####failedonly####
			if (-e "$logdir/$name_of_alljob.err"){
			    `rm $logdir/$name_of_alljob.err`;
			}
			if (-e "$logdir/$name_of_alljob.out"){
			    `rm $logdir/$name_of_alljob.out`;
			}
			$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
			$job =~ s/$new_queue/$r/;
			$job =~ s/$sample_dir/$resume_file/;
			&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
			$job =~ s/$resume_file/$sample_dir/;
		    }
		    &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		    &check_err ($name_of_alljob, $err_name, $job_num);
		    $job_num++;
		}
		#copy_lcfiles_eij p2
		$name_of_job = "$study.copy_lcfiles_eij_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_job =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if (($run_job eq "true") && ($EIJ eq "true")){
		    $err_name = "$name_of_job.err";
		    &clear_log($name_of_job, $err_name);
		    if ($resume eq "true"){
			$resume = "false";
		    }
		    $job = "echo \"perl $norm_script_dir/copy_lcfiles.pl $sample_dir $LOC $data_stranded -eij -depthExon $i_exon -depthIntron $i_intron $altstats\" | $batchjobs $mem $jobname \"$name_of_job\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";

		    &onejob($job, $name_of_job, $job_num);
		    &check_exit_onejob($job, $name_of_job, $job_num);
		    &check_err ($name_of_job, $err_name, $job_num);
		    $job_num++;
		}
=comment
		#exon2nonexon
		$name_of_job = "$study.get_exon2nonexon_stats_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_job =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if ($run_job eq "true"){
		    $err_name = "$name_of_job.err";
		    &clear_log($name_of_job, $err_name);
		    if ($resume eq "true"){
			$resume = "false";
		    }

		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }    
		    $job = "echo \"perl $norm_script_dir/get_exon2nonexon_signal_stats.pl $sample_dir $LOC $data_stranded $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.get_exon2nonexon_stats_p2\" -o $logdir/$study.get_exon2nonexon_stats_p2.out -e $logdir/$study.get_exon2nonexon_stats_p2.err";
		    &onejob($job, $name_of_job, $job_num);
		    &check_exit_onejob($job, $name_of_job, $job_num);
		    &check_err ($name_of_job, $err_name, $job_num);
		    $job_num++;
		}
		#1exonvsmultiexons
		$name_of_job = "$study.get_1exonvsmultiexons_stats_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_job =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if ($run_job eq "true"){
		    $err_name = "$name_of_job.err";
		    &clear_log($name_of_job, $err_name);
		    if ($resume eq "true"){
			$resume = "false";
		    }

		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }
		    $job = "echo \"perl $norm_script_dir/get_1exon_vs_multi_exon_stats.pl $sample_dir $LOC $data_stranded $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.get_1exonvsmultiexons_stats_p2\" -o $logdir/$study.get_1exonvsmultiexons_stats_p2.out -e $logdir/$study.get_1exonvsmultiexons_stats_p2.err";
		    
		    &onejob($job, $name_of_job, $job_num);
		    &check_exit_onejob($job, $name_of_job, $job_num);
		    &check_err ($name_of_job, $err_name, $job_num);
		    $job_num++;
		}
		if ($STRANDED =~ /^true/i){
		    #sense2antisense_p2
		    $name_of_job = "$study.get_sense2antisense_stats_p2";
		    if (($resume eq "true")&&($run_job eq "false")){
			if ($name_of_job =~ /.$name_to_check$/){
			    $run_job = "true";
			    $job_num = $res_num;
			}
		    }
		    if (($run_job eq "true") && ($EIJ eq "true")){
			$err_name = "$name_of_job.err";
			&clear_log($name_of_job, $err_name);
			if ($resume eq "true"){
			    $resume = "false";
			}

			while(qx{$stat | wc -l} > $maxjobs){
			    sleep(10);
			}
			$job = "echo \"perl $norm_script_dir/get_sense2antisense_stats.pl $sample_dir $LOC $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.get_sense2antisense_stats_p2\" -o $logdir/$study.get_sense2antisense_stats_p2.out -e $logdir/$study.get_sense2antisense_stats_p2.err";

			&onejob($job, $name_of_job, $job_num);
			&check_exit_onejob($job, $name_of_job, $job_num);
			&check_err ($name_of_job, $err_name, $job_num);
			$job_num++;
		    }
		}
=cut
		#predict_num_reads EIJ p2
		$name_of_job = "$study.predict_num_reads_p2";
		if (($resume eq "true")&&($run_job eq "false")){
		    if ($name_of_job =~ /.$name_to_check$/){
			$run_job = "true";
			$job_num = $res_num;
		    }
		}
		if ($run_job eq "true"){
		    $err_name = "$name_of_job.err";
		    &clear_log($name_of_job, $err_name);
		    if ($resume eq "true"){
			$resume = "false";
		    }
		    while(qx{$stat | wc -l} > $maxjobs){
			sleep(10);
		    }
		    $job = "echo \"perl $norm_script_dir/predict_num_reads.pl $sample_dir $LOC $filter_highexp -depthE $i_exon -depthI $i_intron $data_stranded $UONLY $altstats\" | $batchjobs $mem $jobname \"$study.predict_num_reads_p2\" -o $logdir/$name_of_job.out -e $logdir/$name_of_job.err";

		    &onejob($job, $name_of_job, $job_num);
		    &check_exit_onejob($job, $name_of_job, $job_num);
		    &check_err ($name_of_job, $err_name, $job_num);
		    $job_num++;
		}

	    }
	}
    }
    #runall_shuf
    $name_of_alljob = "$study.runall_shuf";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$name_of_job = "$study.shuf";
	$err_name = "shuf.*.err";
	&clear_log($name_of_alljob, $err_name);
        if ($resume eq "true"){
            $resume = "false";
        }
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	}
	$new_queue = "-mem $queue_6G";

	my $linecounts = "$LOC/*/EIJ/Unique/linecounts.txt";
	if ($STRANDED =~ /^true/i){
	    $linecounts = "$LOC/*/EIJ/Unique/sense/linecounts.txt";
	}
	@g = glob("$linecounts");
	if (@g ne '0'){
	    $max_lc = `cut -f 2 $linecounts | sort -nr | head -1`;
	    if ($max_lc > 30000000){
		$new_queue = "-mem $queue_30G";
                if ($max_lc > 100000000){
		    if ($max_lc <= 450000000){
			$new_queue = "-mem $queue_45G";
		    }
		    else{
			$new_queue = "-mem $queue_60G";
		    }
		}
	    }
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/runall_shuf.pl $sample_dir $LOC $c_option $new_queue $cluster_max -depthE $i_exon -depthI $i_intron $data_stranded $UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_shuf\" -o $logdir/$study.runall_shuf.out -e $logdir/$study.runall_shuf.err";

	&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }
    if ($filter_high_expressers eq "true"){
	#runall_shuf_highexp
	$name_of_alljob = "$study.runall_shuf_highexp";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if (($run_job eq "true") && ($EIJ eq "true")){
	    $name_of_job = "$study.shuf_highexp";
	    $err_name = "run_shuf_highexp*.err";
	    &clear_log($name_of_alljob, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_6G";

	    my $linecounts = "$LOC/*/EIJ/Unique/linecounts.txt";
	    if ($STRANDED =~ /^true/i){
		$linecounts = "$LOC/*/EIJ/Unique/sense/linecounts.txt";
	    }
	    @g = glob("$linecounts");
	    if (@g ne '0'){
		$max_lc = `cut -f 2 $linecounts | sort -nr | head -1`;
		if ($max_lc > 45000000){
		    $new_queue = "-mem $queue_10G";
		    if ($max_lc > 100000000){
			if ($max_lc <= 300000000){
			    $new_queue = "-mem $queue_30G";
			}
			elsif ($max_lc <= 450000000){
			    $new_queue = "-mem $queue_45G";
			}
			else{
			    $new_queue = "-mem $queue_60G";
			}
		    }
		}
	    }
	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/runall_shuf_highexp.pl $sample_dir $LOC $c_option $new_queue $cluster_max -depthExon $i_exon -depthIntron $i_intron $altstats $data_stranded \$UONLY $hn_option\" | $batchjobs $mem $jobname \"$study.runall_shuf_highexp\" -o $logdir/$study.runall_shuf_highexp.out -e $logdir/$study.runall_shuf_highexp.err";
	    
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
	    $job_num++;
	}
	#cat highexp files
	$name_of_alljob = "$study.runall_cat_highexp_files";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if (($run_job eq "true") && ($EIJ eq "true")){
	    $name_of_job = "$study.cat_highexp_files";
	    $err_name = "cat_highexp_files.*.err";
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname,$request,$queue_6G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_6G";
	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/runall_cat_highexp_files.pl $sample_dir $LOC $c_option $new_queue $cluster_max $data_stranded \$UONLY $hn_option\" | $batchjobs $mem $jobname \"$name_of_alljob\" -o $logdir/$name_of_alljob.out -e $logdir/$name_of_alljob.err";
	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }
            &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
            &check_err ($name_of_alljob, $err_name, $job_num);
            $job_num++;
	}
    }
    #cat_shuffiles
    $name_of_alljob = "$study.runall_cat_shuffiles";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
        $name_of_job = "$study.cat_shuffiles";
	$err_name = "cat_shuffiles.*.err";
        if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname,$request,$queue_3G, $stat\\\"";
        }
	$new_queue = "-mem $queue_3G";

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
	$job = "echo \"perl $norm_script_dir/runall_cat_shuffiles.pl $sample_dir $LOC $data_stranded $c_option $new_queue $cluster_max $UONLY -normdir $normdir $hn_option\" | $batchjobs $mem $jobname \"$study.runall_cat_shuffiles\" -o $logdir/$study.runall_cat_shuffiles.out -e $logdir/$study.runall_cat_shuffiles.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
            &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
            if (-e "$logdir/$name_of_alljob.err"){
                `rm $logdir/$name_of_alljob.err`;
            }
            if (-e "$logdir/$name_of_alljob.out"){
                `rm $logdir/$name_of_alljob.out`;
            }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
            $job =~ s/$sample_dir/$resume_file/;
            &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
            $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    #runall_unique_merge_samfiles
    $name_of_alljob = "$study.runall_unique_merge_samfiles";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }

    if (($run_job eq "true") && ($EIJ eq "true")){
	$name_of_job = "$study.unique_merge_samfiles";
	$err_name = "unique_merge_samfiles.*.err";

	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
	}
	$new_queue = "-mem $queue_15G";

        my $linecounts = "$study_dir/STATS/lineCounts/exon.unique.lc.1.txt";
	if ($STRANDED =~ /^true/i){
            $linecounts = "$study_dir/STATS/lineCounts/exon.unique.sense.lc.1.txt";
        }
        @g = glob("$linecounts");
        if (@g ne '0'){
            $max_lc = `cut -f 2 $linecounts | sort | head -1`;
            if ($max_lc > 30000000){
                $new_queue = "-mem $queue_30G";
                if (100000000 < $max_lc){
                    if ($max_lc <= 450000000){
                        $new_queue = "-mem $queue_45G";
                    }
                    else{
                        $new_queue = "-mem $queue_60G";
                    }
                }
            }
        }
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}

	$job = "echo \"perl $norm_script_dir/runall_unique_merge_samfiles.pl $sample_dir $LOC $data_stranded $c_option $cluster_max $new_queue $UONLY -normdir $normdir $hn_option\" | $batchjobs $mem $jobname \"$name_of_alljob\" -o $logdir/$name_of_alljob.out -e $logdir/$name_of_alljob.err";
	if ($resume eq "false"){
	    &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	}
	else{
            $resume = "false";
                ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
	}
        &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }

    #runall_sam2junctions
    $name_of_alljob = "$study.runall_sam2junctions";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$name_of_job = "$study.sam2junctions";
	$err_name = "sam2junctions.0.*.err";
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	}
	$new_queue = "-mem $queue_6G";

	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}    
	$job = "echo \"perl $norm_script_dir/runall_sam2junctions.pl $sample_dir $LOC $geneinfo $genome $c_option $new_queue $cluster_max -normdir $normdir $hn_option\" | $batchjobs $mem $jobname \"$study.runall_sam2junctions\" -o $logdir/$study.runall_sam2junctions.out -e $logdir/$study.runall_sam2junctions.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
	&check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }

    #runall_quantify_exons_introns_norm
    $name_of_alljob = "$study.runall_quantify_exons_introns_norm";
    if (($resume eq "true")&&($run_job eq "false")){
	if ($name_of_alljob =~ /.$name_to_check$/){
	    $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
        $name_of_job = "$study.quantify_exons_introns";
        $err_name = "quantify_exons_introns.2.*.err";
        
	if ($other eq "true"){
            $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
        }
	$new_queue = "-mem $queue_6G";

        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/runall_quantify_exons_introns.pl $sample_dir $LOC $list_for_exonquant $list_for_intronquant $LOC/master_list_of_intergenic_regions.txt $strand_info -norm $normdir $c_option $new_queue $cluster_max $hn_option\" | $batchjobs $mem $jobname \"$study.runall_quantify_exons_introns_norm\" -o $logdir/$study.runall_quantify_exons_introns_norm.out -e $logdir/$study.runall_quantify_exons_introns_norm.err";
        if ($resume eq "false"){
            &clear_log($name_of_alljob, $err_name);
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        }
        else{
            $resume = "false";
            ####failedonly####
	    if (-e "$logdir/$name_of_alljob.err"){
		`rm $logdir/$name_of_alljob.err`;
	    }
	    if (-e "$logdir/$name_of_alljob.out"){
		`rm $logdir/$name_of_alljob.out`;
	    }
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	    &runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    $job =~ s/$resume_file/$sample_dir/;
        }
        &check_exit_alljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
        &check_err ($name_of_alljob, $err_name, $job_num);
        $job_num++;
    }
    #make_final_spreadsheets
    $name_of_alljob = "$study.make_final_spreadsheets";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$name_of_job = "$study.final_spreadsheet";
	$err_name = "*2spreadsheet*.err";
	&clear_log($name_of_alljob, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs,$jobname, $request, $queue_6G, $queue_10G, $stat\\\"";
	}
	$new_queue = "-mem $queue_10G";

	if ($num_samples > 100){
	    $new_queue = "-mem $queue_30G";
	}
	if ($num_samples > 500){
	    $new_queue = "-mem $queue_60G";
	}
	my $novelei = "";
	if ($novel eq "true"){
	    $novelei = "-novel";
	}
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/make_final_spreadsheets.pl $sample_dir $LOC $novelei $c_option $new_queue $filter_highexp $data_stranded $UONLY -normdir $normdir $hn_option\" | $batchjobs $mem $jobname \"$study.make_final_spreadsheets\" -o $logdir/$study.make_final_spreadsheets.out -e $logdir/$study.make_final_spreadsheets.err";

	&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }
    #run_annotate
    $name_of_alljob = "$study.run_annotate";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$name_of_job = "$study.annotate";
	$err_name = "annotate.*.txt.err";
	&clear_log($name_of_alljob, $err_name);
	if ($resume eq "true"){
            $resume = "false";
        }
	$to_annotate = "$normdir/EXON_INTRON_JUNCTION/to_annotate.txt";
	open(OUT, ">$to_annotate");
	if ($STRANDED =~ /^true/i){
	    if ($UONLY eq "-u"){
		print OUT "master_list_of_exon_counts_MIN.sense.$study.txt\nmaster_list_of_exon_counts_MIN.antisense.$study.txt\nmaster_list_of_intron_counts_MIN.sense.$study.txt\nmaster_list_of_intron_counts_MIN.antisense.$study.txt\nmaster_list_of_junction_counts_MIN.$study.txt\n";
	    }
	    else{
		print OUT "master_list_of_exon_counts_MIN.sense.$study.txt\nmaster_list_of_exon_counts_MIN.antisense.$study.txt\nmaster_list_of_exon_counts_MAX.sense.$study.txt\nmaster_list_of_exon_counts_MAX.antisense.$study.txt\nmaster_list_of_intron_counts_MIN.sense.$study.txt\nmaster_list_of_intron_counts_MIN.antisense.$study.txt\nmaster_list_of_intron_counts_MAX.sense.$study.txt\nmaster_list_of_intron_counts_MAX.antisense.$study.txt\nmaster_list_of_junction_counts_MIN.$study.txt\nmaster_list_of_junction_counts_MAX.$study.txt\n";
	    }
	}
	else{
	    if ($UONLY eq '-u'){
		print OUT "master_list_of_exon_counts_MIN.$study.txt\nmaster_list_of_intron_counts_MIN.$study.txt\nmaster_list_of_junction_counts_MIN.$study.txt\n";
	    }
	    else{
		print OUT "master_list_of_exon_counts_MIN.$study.txt\nmaster_list_of_exon_counts_MAX.$study.txt\nmaster_list_of_intron_counts_MIN.$study.txt\nmaster_list_of_intron_counts_MAX.$study.txt\nmaster_list_of_junction_counts_MIN.$study.txt\nmaster_list_of_junction_counts_MAX.$study.txt\n";
	    }
	}
	close(OUT);
	if ($other eq "true"){
	    $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
	}
	$new_queue = "-mem $queue_15G";

	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/run_annotate.pl $to_annotate $geneinfo $LOC $c_option $new_queue $cluster_max -normdir $normdir $hn_option\" | $batchjobs $mem $jobname \"$study.run_annotate\" -o $logdir/$study.run_annotate.out -e $logdir/$study.run_annotate.err";
    
	&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	&check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	&check_err ($name_of_alljob, $err_name, $job_num);
	$job_num++;
    }
    #filter_low_expressers
    $name_of_job = "$study.filter_low_expressers";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$err_name = "$name_of_job.err";
	&clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
	$to_filter = "$normdir/EXON_INTRON_JUNCTION/to_filter.txt";
	open(OUT, ">$to_filter");
        if ($STRANDED =~ /^true/i){
	    if ($UONLY eq '-u'){
		print OUT "annotated_master_list_of_exon_counts_MIN.sense.$study.txt\nannotated_master_list_of_exon_counts_MIN.antisense.$study.txt\nannotated_master_list_of_intron_counts_MIN.sense.$study.txt\nannotated_master_list_of_intron_counts_MIN.antisense.$study.txt\nannotated_master_list_of_junction_counts_MIN.$study.txt\nmaster_list_of_intergenic_counts_MIN.$study.txt\n";
	    }
	    else{
		print OUT "annotated_master_list_of_exon_counts_MIN.sense.$study.txt\nannotated_master_list_of_exon_counts_MIN.antisense.$study.txt\nannotated_master_list_of_exon_counts_MAX.sense.$study.txt\nannotated_master_list_of_exon_counts_MAX.antisense.$study.txt\nannotated_master_list_of_intron_counts_MIN.sense.$study.txt\nannotated_master_list_of_intron_counts_MIN.antisense.$study.txt\nannotated_master_list_of_intron_counts_MAX.sense.$study.txt\nannotated_master_list_of_intron_counts_MAX.antisense.$study.txt\nannotated_master_list_of_junction_counts_MIN.$study.txt\nannotated_master_list_of_junction_counts_MAX.$study.txt\nmaster_list_of_intergenic_counts_MIN.$study.txt\nmaster_list_of_intergenic_counts_MAX.$study.txt\n";
	    }
        }
	else{
	    if ($UONLY eq '-u'){
		print OUT "annotated_master_list_of_exon_counts_MIN.$study.txt\nannotated_master_list_of_intron_counts_MIN.$study.txt\nannotated_master_list_of_junction_counts_MIN.$study.txt\nmaster_list_of_intergenic_counts_MIN.$study.txt\n";
	    }
	    else{
		print OUT "annotated_master_list_of_exon_counts_MIN.$study.txt\nannotated_master_list_of_exon_counts_MAX.$study.txt\nannotated_master_list_of_intron_counts_MIN.$study.txt\nannotated_master_list_of_intron_counts_MAX.$study.txt\nannotated_master_list_of_junction_counts_MIN.$study.txt\nannotated_master_list_of_junction_counts_MAX.$study.txt\nmaster_list_of_intergenic_counts_MIN.$study.txt\nmaster_list_of_intergenic_counts_MAX.$study.txt\n";
	    }
	}
	close(OUT);
	while(qx{$stat | wc -l} > $maxjobs){
	    sleep(10);
	}
	$job = "echo \"perl $norm_script_dir/runall_filter_low_expressers.pl $to_filter $num_samples $cutoff_le $normdir\" | $batchjobs $mem $jobname \"$study.filter_low_expressers\" -o $logdir/$study.filter_low_expressers.out -e $logdir/$study.filter_low_expressers.err";

	&onejob($job, $name_of_job, $job_num);
	&check_exit_onejob($job, $name_of_job, $job_num);
	&check_err ($name_of_job, $err_name, $job_num);
	$job_num++;
    }

    if ($run_job eq "true"){
	print LOG "\nPostprocessing\n--------------\n";
	$job_num = 1;
    }
    #get_normfactors_table
    $name_of_job = "$study.get_normfactors_table";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if ($run_job eq "true") {
        $err_name = "$name_of_job.err";
        &clear_log($name_of_job, $err_name);
	if ($resume eq "true"){
	    $resume = "false";
	}
        while(qx{$stat | wc -l} > $maxjobs){
            sleep(10);
        }
        $job = "echo \"perl $norm_script_dir/get_normfactors_table.pl $sample_dir $LOC $data_stranded $altstats -mito \\\"$mito\\\"\" | $batchjobs $mem $jobname \"$study.get_normfactors_table\" -o $logdir/$study.get_normfactors_table.out -e $logdir/$study.get_normfactors_table.err";

        &onejob($job, $name_of_job, $job_num);
        &check_exit_onejob($job, $name_of_job, $job_num);
        &check_err ($name_of_job, $err_name, $job_num);
        $job_num++;
    }
    #runall_sam2cov_gnorm
    $name_of_alljob = "$study.runall_sam2cov_gnorm";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($GNORM eq "true")){
        $name_of_job = "$study.sam2cov_gnorm";
        $err_name = "sam2cov_gnorm.*.err";
	if ($sam2cov eq "true"){
            if ($other eq "true"){
                $c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
            }
	    $new_queue = "-mem $queue_15G";

            while(qx{$stat | wc -l} > $maxjobs){
                sleep(10);
            }
            $job = "echo \"perl $norm_script_dir/runall_sam2cov_gnorm.pl $sample_dir $LOC $fai $sam2cov_loc $aligner $c_option $new_queue $cluster_max $se $strand_info -normdir $normdir $hn_option\" | $batchjobs $mem $jobname \"$study.runall_sam2cov_gnorm\" -o $logdir/$study.runall_sam2cov_gnorm.out -e $logdir/$study.runall_sam2cov_gnorm.err";
	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }
	    &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);
            $job_num++;
        }
    }
    #runall_sam2cov
    $name_of_alljob = "$study.runall_sam2cov";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_alljob =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if (($run_job eq "true") && ($EIJ eq "true")){
	$name_of_job = "$study.sam2cov";
	$err_name = "sam2cov.*.err";
	if ($sam2cov eq "true"){
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_15G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_15G";

	    while(qx{$stat | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/runall_sam2cov.pl $sample_dir $LOC $fai $sam2cov_loc $aligner $c_option $new_queue $cluster_max $strand_info -normdir $normdir $hn_option\" | $batchjobs $mem $jobname \"$study.runall_sam2cov\" -o $logdir/$study.runall_sam2cov.out -e $logdir/$study.runall_sam2cov.err";
	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }
	    &check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
	    &check_err ($name_of_alljob, $err_name, $job_num);	
	    $job_num++;
	}
    }
    #cleanup: delete intermediate sam
    $name_of_job = "$study.cleanup";
    if (($resume eq "true")&&($run_job eq "false")){
        if ($name_of_job =~ /.$name_to_check$/){
            $run_job = "true";
            $job_num = $res_num;
        }
    }
    if ($run_job eq "true"){
	$err_name = "$name_of_job.err";
	if ($delete_int_sam eq "true"){
	    &clear_log($name_of_job, $err_name);
	    if ($resume eq "true"){
		$resume = "false";
	    }
	    while (qx{$status | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/cleanup.pl $sample_dir $LOC $unaligned_type $unaligned_z -normdir $normdir\" | $batchjobs $mem $jobname \"$study.cleanup\" -o $logdir/$study.cleanup.out -e $logdir/$study.cleanup.err";
	    
	    &onejob($job, $name_of_job, $job_num);
	    &check_exit_onejob($job, $name_of_job, $job_num);
	    &check_err ($name_of_job, $err_name, $job_num);
	    $job_num++;
	}
    }
    #cleanup: compress 
    if ($convert_sam2bam eq "true" || $gzip_cov eq "true"){
	my $samtoolcmd = "";
	if ($convert_sam2bam eq "true"){
	    $samtoolcmd = "-samtools $samtools";
	}
	my $bamcmd = "";
	if ($bam eq "true"){
	    $bamcmd = "-bam";
	}
	$name_of_alljob = "$study.runall_compress";
	if (($resume eq "true")&&($run_job eq "false")){
	    if ($name_of_alljob =~ /.$name_to_check$/){
		$run_job = "true";
		$job_num = $res_num;
	    }
	}
	if ($run_job eq "true"){
	    $name_of_job = "$study.compress";
	    $err_name = "sam2bam.*.err";
	    
	    $option = "-dont_cov -dont_bam";
	    if ($convert_sam2bam eq "true"){
		$option =~ s/-dont_bam//g;
	    }
	    if ($gzip_cov eq 'true'){
		$option =~ s/-dont_cov//g;
	    }
	    if ($other eq "true"){
		$c_option = "$submit \\\"$batchjobs, $jobname, $request, $queue_6G, $stat\\\"";
	    }
	    $new_queue = "-mem $queue_6G";

	    while (qx{$status | wc -l} > $maxjobs){
		sleep(10);
	    }
	    $job = "echo \"perl $norm_script_dir/runall_compress.pl $sample_dir $LOC $alignedfilename $fai $bamcmd $c_option $new_queue $option $cluster_max $samtoolcmd $compress_opt -normdir $normdir $hn_option\" | $batchjobs $mem $jobname \"$study.runall_compress\" -o $logdir/$study.runall_compress.out -e $logdir/$study.runall_compress.err ";
	    if ($resume eq "false"){
		&clear_log($name_of_alljob, $err_name);
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
	    }
	    else{
		$resume = "false";
		####failedonly####
		if (-e "$logdir/$name_of_alljob.err"){
		    `rm $logdir/$name_of_alljob.err`;
		}
		if (-e "$logdir/$name_of_alljob.out"){
		    `rm $logdir/$name_of_alljob.out`;
		}
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
		&runalljob($job, $name_of_alljob, $name_of_job, $job_num, $err_name);
		$job =~ s/$resume_file/$sample_dir/;
	    }	    
	    if ($convert_sam2bam eq "true"){
		&check_exit_alljob($job, $name_of_alljob,$name_of_job, $job_num, $err_name);
		&check_err ($name_of_alljob, $err_name, $job_num);
	    }
	    else{
		$err_name = "$name_of_alljob.err";
		&check_exit_onejob($job, $name_of_alljob, $job_num);
		&check_err ($name_of_alljob, $err_name, $job_num);
	    }
		
	    if (-e "$logdir/$study.sam2bam.log"){
		print LOG "\t* please check the sam2bam logfile $logdir/$study.sam2bam.log\n";
	    }
	}
    }
    if ($run_job eq "true"){
	print LOG "\n* Normalization completed successfully.\n\n";
    }
    if (($run_job eq "false") && ($resume eq "true")){
	if ($run_prepause eq "false"){
	    print LOG "\nERROR: \"$study.$name_to_check\" step is not in [PART2].\n\tCannot resume at \"$study.$name_to_check\" step. Please check your pipeline option and -resume_at \"<step>\" option.\n\n";
	}
	if ($run_prepause eq "true"){
	    print LOG "\nERROR: \"$last_step\" is not in [PART1] or [PART2].\n\tPlease check -resume_at \"<step>\" option.\n\n";
	}
    }
}
close(LOG);

sub parse_config_file () {
    my ($File, $Config) = @_;
    open(CONFIG, "$File") or die "ERROR: Config file not found : $File\n";
    while (my $config_line = <CONFIG>) {
	chomp($config_line);
        $config_line =~ s/^\s*//;
        $config_line =~ s/\s*$//;
        if (($config_line !~ /^#/) && ($config_line ne "") ){
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
    if ($hn_only eq "true"){
	$ssh->system($job) or
	    die "remote command failed: " . $ssh->error;
	#ssh($HOST_NAME, $job);
    }
    else{
	`$job`;
    }
    my $date = `date`;
    print LOG "$job_num  \"$name_of_job\"\n\tSTARTED: $date";

    sleep(10);
    my $check = `$status | grep -wc "$name_of_job"`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -wc "$name_of_job"`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
}

sub runalljob{
    my ($job, $name_of_alljob, $name_of_job, $job_num, $err_name) =@_;
    my $out_name = $err_name;
    $out_name =~ s/err$/out/g;
    if ($hn_only eq "true"){
        $ssh->system($job) or
            die "remote command failed: " . $ssh->error;
#	ssh($HOST_NAME,$job);
    }
    else{
        `$job`;
    }
    my $date = `date`;
    print LOG "$job_num  \"$name_of_alljob\"\n\tSTARTED: $date";

    sleep(10);
    my $check = `$status | grep -C 1 -w "$name_of_alljob" | egrep -c 'PEND|qw|hqw'`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -C 1 -w "$name_of_alljob" | egrep -c 'PEND|qw|hqw'`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
    $check = `$status | grep -wc "$name_of_alljob"`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -wc "$name_of_alljob"`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
    $check = `$status | grep -wc "$name_of_job"`;
    chomp($check);
    until ($check eq '0'){
	$check = `$status | grep -wc "$name_of_job"`;
	sleep(10);
	chomp($check);
    }
    sleep(10);
}
    
sub check_exit_onejob {
    my ($job, $name_of_job, $job_num) = @_;
    my $outfile = "$logdir/$name_of_job.out";
    until (-e $outfile){
	sleep(10);
    }
    my $check_out = `grep "got here" $outfile | grep -vc echo`;
    chomp($check_out);
    if ($check_out eq '0'){
	if (-e "$logdir/$name_of_job.err"){
	    `rm $logdir/$name_of_job.err`;
	}
	if (-e "$logdir/$name_of_job.out"){
	    `rm $logdir/$name_of_job.out`;
	}
	my $jobnum_rep = "\t**Job exited before completing\n\tretrying...";
	&onejob($job, $name_of_job, $jobnum_rep);
    }
}

sub check_exit_alljob{
    my ($job, $name_of_alljob, $name_of_job, $job_num, $err_name) = @_;
    my $outfile_all = "$logdir/$name_of_alljob.out";
    while (qx{ls $outfile_all | wc -l} < 1){
	sleep(10);
    }
    my $out_name = $err_name;
    $out_name =~ s/err$/out/g;
    my $check_out_all = `grep "got here" $outfile_all | grep -vc echo`;
    chomp($check_out_all);
    if ($check_out_all eq '0'){
	if (-e "$logdir/$name_of_alljob.err"){
	    `rm $logdir/$name_of_alljob.err`;
	}
	if (-e "$logdir/$name_of_alljob.out"){
	    `rm $logdir/$name_of_alljob.out`;
	}
	if ($err_name =~ /^annotate/){
	    if ($err_name =~ /^annotate.0/){
		if (-e "$logdir/annotate.0.master_exon.err"){
                    `rm $logdir/annotate.0.master_exon.err`;
		}
		if (-e "$logdir/annotate.0.master_exon.out"){
		    `rm $logdir/annotate.0.master_exon.out`;
		}
	    }
	    if ($err_name =~ /^annotate.1/){
		if (-e "$logdir/annotate.1.master_exon.err"){
		    `rm $logdir/annotate.1.master_exon.err`;
		}
		if (-e "$logdir/annotate.1.master_exon.out"){
		    `rm $logdir/annotate.1.master_exon.out`;
		}
	    }
	}
	unless ($name_of_alljob =~ /runall_shuf/){
            $r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
            $job =~ s/$new_queue/$r/;
	    $job =~ s/$sample_dir/$resume_file/;
	}
	my $jobnum_rep = "\t**Job exited before completing\n\tretrying...";
        &runalljob($job, $name_of_alljob, $name_of_job, $jobnum_rep, $err_name);
    }
    else{
	my $out_name = $err_name;
	$out_name =~ s/err$/out/g;
	my $wc_out = `ls $logdir/$out_name | wc -l`;
	my $check_out = `grep "got here" $logdir/$out_name | grep -vc echo`;
	if (qx{grep -c "SAM header" $logdir/$err_name} > 0){
	    `sed -i '/SAM header/d' $logdir/$err_name`;
	}
	if (qx{grep -c "sam_header_read" $logdir/$err_name} > 0){
	    `sed -i '/sam_header_read/d' $logdir/$err_name`;
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
	    if ($err_name =~ /^annotate/){
		if ($err_name =~ /^annotate.0/){
		    if (-e "$logdir/annotate.0.master_exon.err"){
			`rm $logdir/annotate.0.master_exon.err`;
		    }
		    if (-e "$logdir/annotate.0.master_exon.out"){
			`rm $logdir/annotate.0.master_exon.out`;
		    }
		}
		if ($err_name =~ /^annotate.1/){
		    if (-e "$logdir/annotate.1.master_exon.err"){
			`rm $logdir/annotate.1.master_exon.err`;
		    }
		    if (-e "$logdir/annotate.1.master_exon.out"){
			`rm $logdir/annotate.1.master_exon.out`;
		    }
		}
	    }
	    unless ($name_of_alljob =~ /runall_shuf/){
		$r = `perl $norm_script_dir/restart_failedjobs_only.pl $sample_dir $LOC \"$err_name\" \"$new_queue\" -qlist \"$qlist\"`;
		$job =~ s/$new_queue/$r/;
		$job =~ s/$sample_dir/$resume_file/;
	    }
	    my $jobnum_rep = "\t**Job exited before completing\n\tretrying...";
	    &runalljob($job, $name_of_alljob, $name_of_job, $jobnum_rep, $err_name);
	}
    }
}

sub check_err {
    my ($name_of_job, $err_name, $job_num) = @_;
    my $out_name = $err_name;
    $out_name =~ s/err$/out/g;
    my $outfile = "$logdir/$name_of_job.out";
    my $check_out = `grep "got here" $outfile | grep -vc echo`;
    chomp($check_out);
    my $file_count = 1;
    my $finish_count = $check_out;
    #runall
    if ($out_name ne "$name_of_job.out"){ 
	my $out_count = `ls $logdir/$out_name | wc -l`;
	chomp($out_count);
	my $check_out_count = `grep "got here" $logdir/$out_name | grep -vc echo`;
	chomp($check_out_count);
	$file_count = $out_count + 1;
	$finish_count = $check_out_count + $check_out;
    }
    if ($file_count ne $finish_count){
	my $date = `date`;
	print LOG "***Job killed:\tjob exited before completing\t$date\n";
	die "\nERROR: \"$job_num\t\"$name_of_job\" exited before completing\n";
    }
    else{
	my $wc_err = `wc -l $logdir/$name_of_job.err`;
	my @wc = split(/\n/, $wc_err);
	my $last_wc = $wc[@wc-1];
	my @w = split(" ", $last_wc);
	my $wc_num = $w[0];
	my $err = `cat $logdir/$name_of_job.err`;
	if ($wc_num ne '0'){
	    print LOG "***Job killed:\nstderr: $logdir/$name_of_job.err\n";
	    die "\nERROR: \"$job_num $name_of_job\"\n$err\nstderr: $logdir/$name_of_job.err";
	}
	else{
	    if ("$name_of_job.err" ne "$err_name"){
		my $wc_err_sample = `wc -l $logdir/$err_name`;
		my @wc = split(/\n/, $wc_err_sample);
		my $sum = 0;
		my $log = `cat $logdir/$err_name`;
		for(my $i=0;$i<@wc;$i++){
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
		    my $date =`date`;
		    print LOG "\tCOMPLETED: $date";
		}
	    }
	    else{
		my $date =`date`;
		print LOG "\tCOMPLETED: $date";
	    }
	}
    }
}

sub only_err{
    my ($name_of_job, $err_name, $job_num) = @_;
    my $wc_err = `wc -l $logdir/$name_of_job.err`;
    my @wc = split(" ", $wc_err);
    my $wc_num = $wc[0];
    my $err = `cat $logdir/$name_of_job.err`;
    if ($wc_num ne '0'){
	print LOG "***Job killed:\nstderr: $logdir/$name_of_job.err\n";
	die "\nERROR: \"$job_num $name_of_job\"\n$err\nstderr: $logdir/$name_of_job.err";
    }
    else{
	if ("$name_of_job.err" ne "$err_name"){
	    my $wc_err_sample = `wc -l $logdir/$err_name`;
	    @wc = split(/\n/, $wc_err_sample);
	    my $sum = 0;
	    my $log = `cat $logdir/$err_name`;
	    for(my $i=0;$i<@wc;$i++){
		my $last_wc = $wc[@wc-1-$i];
		my @w = split(" ", $last_wc);
		$wc_num = $w[0];
		$sum = $sum + $wc_num;
	    }
	    if ($sum ne '0'){
		print LOG "***Job Killed:\nstderr: $logdir/$err_name\n";
		die "\nERROR: \"$job_num $name_of_job\"\n$log\nstderr: $logdir/$err_name";
	    }
	    else{
		my $date =`date`;
		print LOG "\tCOMPLETED: $date";
	    }
	}
	else{
	    my $date =`date`;
	    print LOG "\tCOMPLETED: $date";
	}
    }
}

sub clear_log{
    my ($name_of_job, $err_name) = @_;
    my $out_name = $err_name;
    $out_name =~ s/err$/out/g;
    my @g = glob("$logdir/$out_name*");
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

