if(@ARGV < 4) {
    die "Usage: perl runall_sam2mappingstats.pl <sample dir> <loc> <sam file name> <total_num_reads?>

<sample dir> is a file with the names of the sample directories. 

             No options will be used if you give a file with 
             just the names of the sample directories.

             If you provide a file with 'sample dir \t total_num_reads',
             -numreads option will be used with the number provided.

<loc> is the directory with the sample directories
<sam file name> is the name of the sam file
<total_num_reads?> if you have the total_num_reads.txt file from runblast,
                   use \"true\". If not, use \"false\".

SAM file must use the IH or NH tags to indicate multi-mappers

";
}

use Cwd 'abs_path';
$path = abs_path($0);
$path =~ s/runall_//;
$sampledirs = $ARGV[0];
$LOC = $ARGV[1];
$sam_name = $ARGV[2];
$total_reads_file = $ARGV[3];
if ($total_reads_file eq "true"){
    $outfile = "$LOC/sampledir_totalreads.txt";
    if (-e $outfile){
	`rm $outfile`;
    }
    open(INFILE, $sampledirs);
    while($line = <INFILE>){
	chomp($line);
	$dir = $line;
	$total_file = "$LOC/$dir/total_num_reads.txt";
	$total_reads = `head -1 $total_file`;
	chomp($total_reads);
	$total_reads =~ s/total = //;
	$dir_reads = "$dir\t$total_reads\n";
	open(OUT, ">>$outfile");
	print OUT $dir_reads;
    }
    close(OUT);
    close(INFILE);
    $sampledirs = $outfile;
    
    open(INFILE, $sampledirs);
    while($line = <INFILE>){
	chomp($line);
	@fields = split(" ", $line);
	$size = @fields;
	$dir = $fields[0];
	$num_id = $fields[1];
	$id = $dir;
	$id =~ s/Sample_//;
	$shfile = "$LOC/$dir/a." . $id . "runsam2mappingstats.sh";
	open(OUTFILE, ">$shfile");
	if ($size eq "1"){
	    print OUTFILE "perl $path $LOC/$dir/$sam_name > $LOC/$dir/$id.mappingstats.txt\n";
	}
	if ($size eq "2"){
	    print OUTFILE "perl $path $LOC/$dir/$sam_name -numreads $num_id > $LOC/$dir/$id.mappingstats.txt\n";
	}
	close(OUTFILE);
	`bsub -q max_mem30 -o $LOC/$dir/$id.sam2mappingstats.out -e $LOC/$dir/$id.sam2mappingstats.err sh $shfile`;
    }
    close(INFILE);
}

if ($total_reads_file eq "false"){
    open(INFILE, $sampledirs);
    while($line = <INFILE>){
	chomp($line);
	$dir = $line;
	$id = $dir;
	$id =~ s/Sample_//;
	$id =~ s/\//_/g;
	$shfile = "$LOC/$dir/a." . $id . "runsam2mappingstats.sh";
	open(OUTFILE, ">$shfile");
	print OUTFILE "perl $path $LOC/$dir/$sam_name > $LOC/$dir/$id.mappingstats.txt\n";
	close(OUTFILE);
	`bsub -q max_mem30 -o $LOC/$dir/$id.sam2mappingstats.out -e $LOC/$dir/$id.sam2mappingstats.err sh $shfile`;
    }
    close(INFILE);
}
