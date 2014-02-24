$| = 1;

if(@ARGV<5) {
    die "Usage: quantify_exons.pl <exons file> <sam file> <output file> <exon sam out> <intron sam out> [options]

<exons file> has one line per exon, each line is in the format chr:start-end

<sam file> has must have mate pairs in consecutive rows

<output file> is tab delimited with two columns:   [feature]   [count]

This script reports fragments per feature by default.  If you want reads
per feature use the -rpf option.

NOTE 1: Neither the exons file or the sam file need to be sorted.

NOTE 2: If the data are paired end, then the rows for the two alignments
are should be consecutive.  It doesn't matter which is first as long as
they are consecutive.  If one of the pair does not map, a null record
should still exist in the sam file.

NOTE 3: In the sam file, the id for a forward and reverse read should be
the same, or at most differ by non-numeric characters, or by having /1
versus /2 on the end.

Note 4: In the sam file the bitflag must properly determine whether a read
is the forward or reverse read of a read pair.

Note 5: If the sam file is sorted without keeping the forward and reverse
records consecutive (e.g. tophat output, or anything sorted with samtools),
then -rpf mode must be used.  Unfortunately if the file is sorted that way,
it is not reversible.

Options:

-no-HI-tags : To have HI tags means that each read has an HI and IH (or NH)
tag that indicates the number of locations a read maps to.  IH (or NH) is
the total number and HI is a counter.  If the HI and HI tags are not used,
it is hard to figure out which are the multi-mappers.  The program will
take a first pass over the sam file to determine this.  If SAM is big this
will eat a lot of RAM.

-treat-primary-as-unique : This means only multi-mapper alignments that are
indicated by the bitflag to be not primary are treated as a non-unique mapper.
By default all multi-mappers are treated as non-unique mappers regardless of
whether they are not primary, or not.  

-treat-HI:i:1-as-unique : This assumes you are using the HI tags and HI:i:1
is to be treated as a unique alignment.  Do this only if HI:I:1 is somehow
blessed as the primary and most likely alignment.

-rpf : Report reads per feature instead of fragments per feature.  If the
sam file is sorted by location, without keeping forward and reverse reads
consecutive, then you should use this option or you could get weird results.

-NU-only

";
}

$exonsfile = $ARGV[0];
$samfile = $ARGV[1];
$outfile = $ARGV[2];
$exon_sam_outfile = $ARGV[3];
$intron_sam_outfile = $ARGV[4];
if($exon_sam_outfile ne "none") {
    open(EXONSAMOUT, ">$exon_sam_outfile");
}
if($intron_sam_outfile ne "none") {
    open(INTRONSAMOUT, ">$intron_sam_outfile");
}
if($exon_sam_outfile ne "none") {
    $exon_sam_outfile1 = $exon_sam_outfile;
    $exon_sam_outfile1 =~ s/.sam$/.1.sam/;
    open(OUTFILE1, ">$exon_sam_outfile1");
    
    $exon_sam_outfile2 = $exon_sam_outfile;
    $exon_sam_outfile2 =~ s/.sam$/.2.sam/;
    open(OUTFILE2, ">$exon_sam_outfile2");
    
    $exon_sam_outfile3 = $exon_sam_outfile;
    $exon_sam_outfile3 =~ s/.sam$/.3.sam/;
    open(OUTFILE3, ">$exon_sam_outfile3");
    
    $exon_sam_outfile4 = $exon_sam_outfile;
    $exon_sam_outfile4 =~ s/.sam$/.4.sam/;
    open(OUTFILE4, ">$exon_sam_outfile4");
    
    $exon_sam_outfile5 = $exon_sam_outfile;
    $exon_sam_outfile5 =~ s/.sam$/.5.sam/;
    open(OUTFILE5, ">$exon_sam_outfile5");

    $exon_sam_outfile6 = $exon_sam_outfile;
    $exon_sam_outfile6 =~ s/.sam$/.6.sam/;
    open(OUTFILE6, ">$exon_sam_outfile6");

    $exon_sam_outfile7 = $exon_sam_outfile;
    $exon_sam_outfile7 =~ s/.sam$/.7.sam/;
    open(OUTFILE7, ">$exon_sam_outfile7");

    $exon_sam_outfile8 = $exon_sam_outfile;
    $exon_sam_outfile8 =~ s/.sam$/.8.sam/;
    open(OUTFILE8, ">$exon_sam_outfile8");

    $exon_sam_outfile9 = $exon_sam_outfile;
    $exon_sam_outfile9 =~ s/.sam$/.9.sam/;
    open(OUTFILE9, ">$exon_sam_outfile9");

    $exon_sam_outfile10 = $exon_sam_outfile;
    $exon_sam_outfile10 =~ s/.sam$/.10.sam/;
    open(OUTFILE10, ">$exon_sam_outfile10");

    $exon_sam_outfile11 = $exon_sam_outfile;
    $exon_sam_outfile11 =~ s/.sam$/.11.sam/;
    open(OUTFILE11, ">$exon_sam_outfile11");

    $exon_sam_outfile12 = $exon_sam_outfile;
    $exon_sam_outfile12 =~ s/.sam$/.12.sam/;
    open(OUTFILE12, ">$exon_sam_outfile12");

    $exon_sam_outfile13 = $exon_sam_outfile;
    $exon_sam_outfile13 =~ s/.sam$/.13.sam/;
    open(OUTFILE13, ">$exon_sam_outfile13");

    $exon_sam_outfile14 = $exon_sam_outfile;
    $exon_sam_outfile14 =~ s/.sam$/.14.sam/;
    open(OUTFILE14, ">$exon_sam_outfile14");

    $exon_sam_outfile15 = $exon_sam_outfile;
    $exon_sam_outfile15 =~ s/.sam$/.15.sam/;
    open(OUTFILE15, ">$exon_sam_outfile15");

    $exon_sam_outfile16 = $exon_sam_outfile;
    $exon_sam_outfile16 =~ s/.sam$/.16.sam/;
    open(OUTFILE16, ">$exon_sam_outfile16");

    $exon_sam_outfile17 = $exon_sam_outfile;
    $exon_sam_outfile17 =~ s/.sam$/.17.sam/;
    open(OUTFILE17, ">$exon_sam_outfile17");

    $exon_sam_outfile18 = $exon_sam_outfile;
    $exon_sam_outfile18 =~ s/.sam$/.18.sam/;
    open(OUTFILE18, ">$exon_sam_outfile18");

    $exon_sam_outfile19 = $exon_sam_outfile;
    $exon_sam_outfile19 =~ s/.sam$/.19.sam/;
    open(OUTFILE19, ">$exon_sam_outfile19");

    $exon_sam_outfile20 = $exon_sam_outfile;
    $exon_sam_outfile20 =~ s/.sam$/.20.sam/;
    open(OUTFILE20, ">$exon_sam_outfile20");
}

$secondary_as_non_unique = "false";
$noHItags = "false";
$HI1_as_unique = "false";
$rpf = 'false';
$nuonly = 'false';
for($i=5; $i<@ARGV; $i++) {
    $arg_recognized = 'false';
    if($ARGV[$i] eq '-treat-primary-as-unique') {
	$secondary_as_non_unique = "true";
	$arg_recognized = 'true';
    }
    if($ARGV[$i] eq '-treat-HI:i:1-as-unique') {
	$HI1_as_unique = "true";
	$arg_recognized = 'true';
    }
    if($ARGV[$i] eq '-no-HI-tags') {
	$noHItags = "true";
	$arg_recognized = 'true';
    }
    if($ARGV[$i] eq '-rpf') {
	$rpf = 'true';
	$arg_recognized = 'true';
    }
    if($ARGV[$i] eq '-NU-only') {
	$nuonly = 'true';
	$arg_recognized = 'true';
    }
    if($arg_recognized eq 'false') {
	die "arg \"$ARGV[$i]\" not recognized.\n";
    }
}

open(INFILE, $exonsfile);
while($line = <INFILE>) {
    chomp($line);
    if($line =~ /([^:\t\s]+):(\d+)-(\d+)/) {
	$chr = $1;
	$start = $2;
	$end = $3;
	$exon = "$chr:$start-$end";
	if(defined $EXON_counts_unique{$exon}) {
	    next;
	}
	if(defined $EXON_counts_nu{$exon}) {
	    next;
	}
	$EXON_counts_unique{$exon}=0;
	$EXON_counts_nu{$exon}=0;
	$exon_cnt = @EXONS;
	push(@EXONS, $exon);
	$start_block = int($start / 1000);
	$end_block = int($end / 1000);
	for($i=$start_block; $i<=$end_block; $i++) {
	    push(@{$exon_overlaps_block{$chr}{$i}},$exon_cnt);  # all exons that overlap the ith span of 1K bases
	}
    } else {
	next;
    }
}
close(INFILE);

if($noHItags eq 'true' && $secondary_as_non_unique eq 'false') {
    open(INFILE, $samfile);
    while ($line = <INFILE>) {
	@a = split(/\t/,$line);
	$a[0] =~ s!/1$!!;
	$a[0] =~ s!/2$!!;
	$a[0] =~ s/[^\d]//g;
	if($a[1] & 64) {
	    $id = $a[0] . "a";
	} else {
	    $id = $a[0] . "b";
	}
	if(defined $UNIQUE{$id}) {
	    $UNIQUE{$id} = "false";
	} else {
	    $UNIQUE{$id} = "true";
	}
    }
    close(INFILE);
}

$CNT_OF_FRAGS_WHICH_HIT_EXONS=0;
$Flag = 0;
$outfile1_cnt=0;
$outfile2_cnt=0;
$outfile3_cnt=0;
$outfile4_cnt=0;
$outfile5_cnt=0;
$outfile6_cnt=0;
$outfile7_cnt=0;
$outfile8_cnt=0;
$outfile9_cnt=0;
$outfile10_cnt=0;
$outfile11_cnt=0;
$outfile12_cnt=0;
$outfile13_cnt=0;
$outfile14_cnt=0;
$outfile15_cnt=0;
$outfile16_cnt=0;
$outfile17_cnt=0;
$outfile18_cnt=0;
$outfile19_cnt=0;
$outfile20_cnt=0;
open(INFILE, $samfile);
while ($line1 = <INFILE>) {
    chomp($line1);
    $Flag = 0;
    $seqnum1 = "";
    $seqnum2 = "";
    @a = split(/\t/,$line1);
    if(@a < 10) {
	next;
    }
    $reverse_only = "false";
    $forward_only = "false";
    if ($line1 eq '') {
	last;
    }
    @a = split(/\t/,$line1);
    $a[0] =~ s!/1$!!;
    $a[0] =~ s!/2$!!;
    $a[0] =~ s/[^\d]//g;
    $seqnum1 = $a[0];
    $chr = $a[2];
    if($rpf eq 'true') {
	$forward_only = 'true';
	$reverse_only = 'false';
    } else {
	$line2 = <INFILE>;
	chomp($line2);
	@b = split(/\t/,$line2);
	$b[0] =~ s!/1$!!;
	$b[0] =~ s!/2$!!;
	$b[0] =~ s/[^\d]//g;
	$seqnum2 = $b[0];
	if ($seqnum1 != $seqnum2) {
	    $len = -1 * (1 + length($line2));
	    seek(INFILE, $len, 1);
	    if($a[1] & 64) {
		$forward_only = "true";
		$reverse_only = "false";
	    } else {
		$forward_only = "false";
		$reverse_only = "true";
	    }
	} else {
	    if(($a[1] & 64 && $b[1] & 128) || ($a[1] & 128 && $b[1] & 64)) {
		$forward_only = "false";
		$reverse_only = "false";
	    } else {
		$len = -1 * (1 + length($line2));
		seek(INFILE, $len, 1);
		if($a[1] & 64) {
		    $forward_only = "true";
		    $reverse_only = "false";
		} else {
		    $forward_only = "false";
		    $reverse_only = "true";
		}
	    }
	}
    }
    if($forward_only eq 'false' && $reverse_only eq 'false') {
	if($a[5] eq '*' && $b[5] eq '*') {
	    next;
	}
    }
    if($forward_only eq 'false' && $reverse_only eq 'false') {
	if($a[5] eq '*' && $b[5] ne '*') {
	    $reverse_only = 'true';
	}
    }
    if($forward_only eq 'false' && $reverse_only eq 'false') {
	if($b[5] eq '*' && $a[5] ne '*') {
	    $forward_only = 'true';
	}
    }

    $unique = "true";
    if($noHItags eq "false") {
	if($line1 =~ /IH:i:(\d+)/) {
	    $n = $1;
	    if($n > 1) {
		$unique = "false";
	    }
	    if($n == 1 && $HI1_as_unique eq 'true') {
		$unique = "true";
	    }
	} elsif ($line1 =~ /NH:i:(\d+)/) {
	    $n = $1;
	    if($n > 1) {
		$unique = "false";
	    }
	    if($n == 1 && $HI1_as_unique eq 'true') {
		$unique = "true";
	    }
	}
	if($line2 =~ /IH:i:(\d+)/) {
	    $n = $1;
	    if($n > 1) {
		$unique = "false";
	    }
	    if($n == 1 && $HI1_as_unique eq 'true') {
		$unique = "true";
	    }
	} elsif($line2 =~ /IH:i:(\d+)/) {
	    $n = $1;
	    if($n > 1) {
		$unique = "false";
	    }
	    if($n == 1 && $HI1_as_unique eq 'true') {
		$unique = "true";
	    }
	}
    } else {
	$unique = "true";
	if($forward_only eq 'true') {
	    $id = $seqnum1 . "a";
	    $unique = $UNIQUE{$id};
	}
	if($reverse_only eq 'true') {
	    $id = $seqnum1 . "b";
	    $unique = $UNIQUE{$id};
	}
	if($reverse_only eq 'false' && $forward_only eq 'false') {
	    $ida = $seqnum1 . "a";
	    $idb = $seqnum1 . "b";
	    if($UNIQUE{$ida} eq "false" || $UNIQUE{$idb} eq "false") {
		$unique = "false";
	    }
	}
    }

    if($secondary_as_non_unique eq "true") {
	if($a[1] & 256) {
	    $unique = "false";
	} else {
	    $unique = "true";
	}
    }

    if($nuonly eq 'true' && $unique eq 'false') {
	$unique = "true";
    }

    $cigar1 = &removeDs($a[5]);
    $cigar2 = &removeDs($b[5]);
    $spans1 = &cigar2spans($cigar1, $a[3]);
    $spans2 = &cigar2spans($cigar2, $b[3]);
    $spans1 =~ /^(\d+)/;
    $start1 = $1;
    $spans1 =~ /(\d+)$/;
    $end1 = $1;
    $spans2 =~ /^(\d+)/;
    $start2 = $1;
    $spans2 =~ /(\d+)$/;
    $end2 = $1;
    if($forward_only eq 'false' && $reverse_only eq 'false' && ($end1 < $start2 || $start1 > $end2)) {
	# this is the hard case
	undef %EXON_candidate_hash1;
	undef %EXON_candidate_hash2;
	undef %done;
	if($start1 > $start2) {
	    $temp = $spans1;
	    $spans1 = $spans2;
	    $spans2 = $temp;
	}
	@S = split(/, /, $spans1);
	$span1 = $S[@S-1];
	for($s=0; $s<@S; $s++) {
	    $S[$s] =~ /(\d+)-(\d+)/;
	    $read_segment_start = $1;
	    $read_segment_end = $2;
	    $read_segment_start_block = int($read_segment_start / 1000);
	    $read_segment_end_block = int($read_segment_end / 1000);
	    for($i=$read_segment_start_block; $i<= $read_segment_end_block; $i++) {
		$NN = @{$exon_overlaps_block{$chr}{$i}};  # all exons that overlap the ith span of 1K bases
		for($j=0; $j<$NN; $j++) {
		    $current_exon = $EXONS[$exon_overlaps_block{$chr}{$i}[$j]];
		    $current_exon =~ /.*:(\d+)-(\d+)/;
		    $start_e = $1;
		    $end_e = $2;
		    if(((($s==0) && ($read_segment_start >= $start_e)) || (($s>0) && ($read_segment_start == $start_e)))
		       && ((($s==(@S-1)) && ($read_segment_end <= $end_e)) || (($s<(@S-1)) && ($read_segment_end == $end_e)))) {
			if($s==(@S-1)) {
			    $EXON_candidate_hash1{$current_exon}=1;
			} else {
			    if(!(defined $done{$current_exon})) {
				if($unique eq 'true') {
				    $EXON_counts_unique{$current_exon}++;
				    $Flag++;
				    if($Flag == 1) {
					$CNT_OF_FRAGS_WHICH_HIT_EXONS++;
				    }
				} else {
				    $EXON_counts_nu{$current_exon}++;
				}
			    }
			    $done{$current_exon}=1;
    			}
		    }
		}
	    }
	}
	@S = split(/, /, $spans2);
	$span2 = $S[0];
	for($s=0; $s<@S; $s++) {
	    $S[$s] =~ /(\d+)-(\d+)/;
	    $read_segment_start = $1;
	    $read_segment_end = $2;
	    $read_segment_start_block = int($read_segment_start / 1000);
	    $read_segment_end_block = int($read_segment_end / 1000);
	    for($i=$read_segment_start_block; $i<= $read_segment_end_block; $i++) {
		$NN = @{$exon_overlaps_block{$chr}{$i}};  # all exons that overlap the ith span of 1K bases
		for($j=0; $j<$NN; $j++) {
		    $current_exon = $EXONS[$exon_overlaps_block{$chr}{$i}[$j]];
		    $current_exon =~ /.*:(\d+)-(\d+)/;
		    $start_e = $1;
		    $end_e = $2;
		    if(((($s==0) && ($read_segment_start >= $start_e)) || (($s>0) && ($read_segment_start == $start_e)))
		       && ((($s==(@S-1)) && ($read_segment_end <= $end_e)) || (($s<(@S-1)) && ($read_segment_end == $end_e)))) {
			if($s==0) {
			    $EXON_candidate_hash2{$current_exon}=1;
			} else {
			    if(!(defined $done{$current_exon})) {
				if($unique eq 'true') {
				    $EXON_counts_unique{$current_exon}++;
				    $Flag++;
				    if($Flag == 1) {
					$CNT_OF_FRAGS_WHICH_HIT_EXONS++;
				    }
				} else {
				    $EXON_counts_nu{$current_exon}++;
				}
			    }
			    $done{$current_exon}=1;
    			}
		    }
		}
	    }
	}
	$span1 =~ /\d+-(\d+)$/;
	$span1_end = $1;
	$span2 =~ /^(\d+)-\d+$/;
	$span2_start = $1;
	# EXON_candidate_hash1 holds exons that overlap the final segment of the upstream read and are consistent with it
	# EXON_candidate_hash2 holds exons that overlap the first segment of the downstream read and are consistent with it
	foreach $exon (keys %EXON_candidate_hash1) { # upstream read overlaps the exon and is consistent with it.
	    if(defined $EXON_candidate_hash2{$exon}) { # downstream read overlaps the exon too,
		                                       # and is consistent with it.
		if(!(defined $done{$exon})) {
		    if($unique eq 'true') {
			$EXON_counts_unique{$exon}++;
			$Flag++;
			if($Flag == 1) {
			    $CNT_OF_FRAGS_WHICH_HIT_EXONS++;
			}
		    } else {
			$EXON_counts_nu{$exon}++;
		    }
		}
		$done{$exon}=1;
	    }
	}
	foreach $exon (keys %EXON_candidate_hash1) { # now check for upstream things where downstream read doesn't
	                                             # overlap so can't be inconsistent
	    $exon =~ /.*:\d+-(\d+)/;
	    $exon_end = $1;
	    if($span2_start > $exon_end) { # downstream read doesn't overlap the exon, so can't
                                           # be inconsistent with it.
		if(!(defined $done{$exon})) {
		    if($unique eq 'true') {
			$EXON_counts_unique{$exon}++;
			$Flag++;
			if($Flag == 1) {
			    $CNT_OF_FRAGS_WHICH_HIT_EXONS++;
			}
		    } else {
			$EXON_counts_nu{$exon}++;
		    }
		}
		$done{$exon}=1;
	    }
	}
	foreach $exon (keys %EXON_candidate_hash2) { # and conversely...
	    $exon =~ /.*:(\d+)-\d+/;
	    $exon_start = $1;
	    if($span1_end < $exon_start) { # downstream read doesn't overlap the exon, so can't
                                           # be inconsistent with it.
		if(!(defined $done{$exon})) {
		    if($unique eq 'true') {
			$EXON_counts_unique{$exon}++;
			$Flag++;
			if($Flag == 1) {
			    $CNT_OF_FRAGS_WHICH_HIT_EXONS++;
			}
		    } else {
			$EXON_counts_nu{$exon}++;
		    }
		}
		$done{$exon}=1;
	    }
	}
    } else {
	if($forward_only eq 'false' && $reverse_only eq 'false' && $end1 >= $start2 && $start1 <= $end2){
	    if($start1 < $start2) {
		$merged_spans = &merge($spans1, $spans2);
	    } else {
		$merged_spans = &merge($spans2, $spans1);
	    }
	}
	if($forward_only eq 'true' && $reverse_only eq 'false') {
	    $merged_spans = $spans1;
	}
	if($forward_only eq 'false' && $reverse_only eq 'true') {
	    $merged_spans = $spans2;
	}
	@S = split(/, /, $merged_spans);
	undef %done;
	for($s=0; $s<@S; $s++) {
	    $S[$s] =~ /(\d+)-(\d+)/;
	    $read_segment_start = $1;
	    $read_segment_end = $2;
	    $read_segment_start_block = int($read_segment_start / 1000);
	    $read_segment_end_block = int($read_segment_end / 1000);
	    for($i=$read_segment_start_block; $i<= $read_segment_end_block; $i++) {
		$NN = @{$exon_overlaps_block{$chr}{$i}};  # all exons that overlap the ith span of 1K bases
		for($j=0; $j<$NN; $j++) {
		    $current_exon = $EXONS[$exon_overlaps_block{$chr}{$i}[$j]];
		    $current_exon =~ /.*:(\d+)-(\d+)/;
		    $start_e = $1;
		    $end_e = $2;
		    if(((($s==0) && ($read_segment_start >= $start_e)) || (($s>0) && ($read_segment_start == $start_e)))
		       && ((($s==(@S-1)) && ($read_segment_end <= $end_e)) || (($s<(@S-1)) && ($read_segment_end == $end_e)))) {
			if(!(defined $done{$current_exon})) {
			    if($unique eq 'true') {
				$EXON_counts_unique{$current_exon}++;
				$Flag++;
				if($Flag == 1) {
				    $CNT_OF_FRAGS_WHICH_HIT_EXONS++;
				}
			    } else {
				$EXON_counts_nu{$current_exon}++;
			    }
			}
			$done{$current_exon}=1;
		    }
		}
	    }
	}
    }
    if($Flag >= 1) {
	if($exon_sam_outfile ne "none") {
	    if($forward_only eq 'true' && $reverse_only eq 'false') {
		print EXONSAMOUT "$line1\n";
	    }
	    if($forward_only eq 'false' && $reverse_only eq 'true') {
		print EXONSAMOUT "$line2\n";
	    }
	    if($forward_only eq 'false' && $reverse_only eq 'false') {
		print EXONSAMOUT "$line1\n";
		print EXONSAMOUT "$line2\n";
	    }	    
	    if($Flag == 1) {
		$outfile1_cnt++;
		print OUTFILE1 "$line1\n";
	    }
	    if($Flag == 2) {
		$outfile2_cnt++;
		print OUTFILE2 "$line1\n";
	    }
	    if($Flag == 3) {
		$outfile3_cnt++;
		print OUTFILE3 "$line1\n";
	    }
	    if($Flag == 4) {
		$outfile4_cnt++;
		print OUTFILE4 "$line1\n";
	    }
	    if($Flag == 5) {	
		$outfile5_cnt++;
		print OUTFILE5 "$line1\n";
	    }
	    if($Flag == 6) {
                $outfile6_cnt++;
                print OUTFILE6 "$line1\n";
            }
	    if($Flag == 7) {
                $outfile7_cnt++;
                print OUTFILE7 "$line1\n";
            }
	    if($Flag == 8) {
                $outfile8_cnt++;
                print OUTFILE8 "$line1\n";
	    }
            if($Flag == 9) {
                $outfile9_cnt++;
                print OUTFILE9 "$line1\n";
            }
	    if($Flag == 10) {
                $outfile10_cnt++;
                print OUTFILE10 "$line1\n";
            }
            if($Flag == 11) {
                $outfile11_cnt++;
                print OUTFILE11 "$line1\n";
            }
            if($Flag == 12) {
                $outfile12_cnt++;
                print OUTFILE12 "$line1\n";
            }
            if($Flag == 13) {
                $outfile13_cnt++;
                print OUTFILE13 "$line1\n";
            }
	    if($Flag == 14) {
		$outfile14_cnt++;
		print OUTFILE14 "$line1\n";
	    }
	    if($Flag == 15) {
		$outfile15_cnt++;
		print OUTFILE15 "$line1\n";
	    }
	    if($Flag == 16) {
		$outfile16_cnt++;
		print OUTFILE16 "$line1\n";
	    }
	    if($Flag == 17) {
		$outfile17_cnt++;
		print OUTFILE17 "$line1\n";
	    }
	    if($Flag == 18) {
		$outfile18_cnt++;
		print OUTFILE18 "$line1\n";
	    }
	    if($Flag == 19) {
		$outfile19_cnt++;
		print OUTFILE19 "$line1\n";
	    }
	    if($Flag >= 20) {
		$outfile20_cnt++;
		print OUTFILE20 "$line1\n";
            }
	}
    } else {
	if($exon_sam_outfile ne "none") {
	    if($forward_only eq 'true' && $reverse_only eq 'false') {
		print INTRONSAMOUT "$line1\n";
	    }
	    if($forward_only eq 'false' && $reverse_only eq 'true') {
		print INTRONSAMOUT "$line2\n";
	    }
	    if($forward_only eq 'false' && $reverse_only eq 'false') {
		print INTRONSAMOUT "$line1\n";
		print INTRONSAMOUT "$line2\n";
	    }	    
	}
    }
    $FLAG_DIST[$Flag]++;
}
print OUTFILE1 "line count = $outfile1_cnt\n";
print OUTFILE2 "line count = $outfile2_cnt\n";
print OUTFILE3 "line count = $outfile3_cnt\n";
print OUTFILE4 "line count = $outfile4_cnt\n";
print OUTFILE5 "line count = $outfile5_cnt\n";
print OUTFILE6 "line count = $outfile6_cnt\n";
print OUTFILE7 "line count = $outfile7_cnt\n";
print OUTFILE8 "line count = $outfile8_cnt\n";
print OUTFILE9 "line count = $outfile9_cnt\n";
print OUTFILE10 "line count = $outfile10_cnt\n";
print OUTFILE11 "line count = $outfile11_cnt\n";
print OUTFILE12 "line count = $outfile12_cnt\n";
print OUTFILE13 "line count = $outfile13_cnt\n";
print OUTFILE14 "line count = $outfile14_cnt\n";
print OUTFILE15 "line count = $outfile15_cnt\n";
print OUTFILE16 "line count = $outfile16_cnt\n";
print OUTFILE17 "line count = $outfile17_cnt\n";
print OUTFILE18 "line count = $outfile18_cnt\n";
print OUTFILE19 "line count = $outfile19_cnt\n";
print OUTFILE20 "line count = $outfile20_cnt\n";
close(OUTFILE1);
close(OUTFILE2);
close(OUTFILE3);
close(OUTFILE4);
close(OUTFILE5);
close(OUTFILE6);
close(OUTFILE7);
close(OUTFILE8);
close(OUTFILE9);
close(OUTFILE10);
close(OUTFILE11);
close(OUTFILE12);
close(OUTFILE13);
close(OUTFILE14);
close(OUTFILE15);
close(OUTFILE16);
close(OUTFILE17);
close(OUTFILE18);
close(OUTFILE19);
close(OUTFILE20);

open(OUTFILE, ">$outfile");
print OUTFILE "total number of reads-pairs which incremented at least one exon: $CNT_OF_FRAGS_WHICH_HIT_EXONS\n";
print OUTFILE "feature\tmin\tmax\n";
print OUTFILE "num exons dist:\n";
for($i=0; $i<@FLAG_DIST; $i++) {
    print OUTFILE "$i\t$FLAG_DIST[$i]\n";
}
foreach $exon (sort {cmpChrs($a,$b)} keys %EXON_counts_unique) {
    $M = $EXON_counts_unique{$exon} + $EXON_counts_nu{$exon};
    print OUTFILE "$exon\t$EXON_counts_unique{$exon}\t$M\n";
}
close(OUTFILE);
if($exon_sam_outfile ne "none") {
    close(EXONSAMOUT);
}
if($intron_sam_outfile ne "none") {
    close(INTRONSAMOUT);
}

sub cigar2spans {
    ($matchstring, $start) = @_;
    $spans = "";
    $current_loc = $start;
    while($matchstring =~ /^(\d+)([^\d])/) {
	$num = $1;
	$type = $2;
	if($type eq 'M') {
	    $E = $current_loc + $num - 1;
	    if($spans =~ /\S/) {
		$spans = $spans . ", " .  $current_loc . "-" . $E;
	    } else {
		$spans = $current_loc . "-" . $E;
	    }
	    $current_loc = $E;
	}
	if($type eq 'D' || $type eq 'N') {
	    $current_loc = $current_loc + $num + 1;
	}
	if($type eq 'I') {
	    $current_loc++;
	}
	$matchstring =~ s/^\d+[^\d]//;
    }
    my $spans2 = "";
    while($spans2 ne $spans) {
	$spans2 = $spans;
	my @b = split(/, /, $spans);
	for($i=0; $i<@b-1; $i++) {
	    @c1 = split(/-/, $b[$i]);
	    @c2 = split(/-/, $b[$i+1]);
	    if($c1[1] + 1 >= $c2[0]) {
		$str = "-$c1[1], $c2[0]";
		$spans =~ s/$str//;
	    }
	}
    }
    return $spans;
}

sub merge () {
    ($aspans2, $bspans2) = @_;
    undef @astarts2;
    undef @aends2;
    undef @bstarts2;
    undef @bends2;
    @a = split(/, /, $aspans2);
    for ($i=0; $i<@a; $i++) {
	@b = split(/-/,$a[$i]);
	$astarts2[$i] = $b[0];
	$aends2[$i] = $b[1];
    }
    @a = split(/, /, $bspans2);
    for ($i=0; $i<@a; $i++) {
	@b = split(/-/,$a[$i]);
	$bstarts2[$i] = $b[0];
	$bends2[$i] = $b[1];
    }
    if ($aends2[@aends2-1] + 1 < $bstarts2[0]) {
	$merged_spans = $aspans2 . ", " . $bspans2;
    }
    if ($aends2[@aends2-1] + 1 == $bstarts2[0]) {
	$aspans2 =~ s/-\d+$//;
	$bspans2 =~ s/^\d+-//;
	$merged_spans = $aspans2 . "-" . $bspans2;
    }
    if ($aends2[@aends2-1] + 1 > $bstarts2[0]) {
	$merged_spans = $aspans2;
	for ($i=0; $i<@bstarts2; $i++) {
	    if ($aends2[@aends2-1] >= $bstarts2[$i] && ($aends2[@aends2-1] <= $bstarts2[$i+1] || $i == @bstarts2-1)) {
		$merged_spans =~ s/-\d+$//;
		$merged_spans = $merged_spans . "-" . $bends2[$i];
		for ($j=$i+1; $j<@bstarts2; $j++) {
		    $merged_spans = $merged_spans . ", $bstarts2[$j]-$bends2[$j]";
		}
	    }
	}
    }
    return $merged_spans;
}

sub removeDs () {
    my ($cigar) = @_;
    $cigar =~ s/D/M/g;
    while($cigar =~ /(\d+)M(\d+)M/) {
	$n1 = $1;
	$n2 = $2;
	$s1 = $n1+$n2;
	$s0 = $n1 . "M" . $n2 . "M";
	$s1 = $s1 . "M";
	$cigar =~ s/$s0/$s1/;
    }
    return $cigar;
}

sub roman($) {
    return lc(Roman(shift()));
}

sub isroman($) {
    my $arg = shift;
    return $arg ne '' and
        $arg =~ /^(?: M{0,3})
                 (?: D?C{0,3} | C[DM])
                 (?: L?X{0,3} | X[LC])
                 (?: V?I{0,3} | I[VX])$/ix;
}


sub arabic($) {
    my $arg = shift;
    my %roman2arabic = qw(I 1 V 5 X 10 L 50 C 100 D 500 M 1000);
    my %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
    my  @figure = reverse sort keys %roman_digit;
    $roman_digit{$_} = [split(//, $roman_digit{$_}, 2)] foreach @figure;
    isroman $arg or return undef;
    my ($last_digit) = 1000;
    my $arabic=0;
    foreach (split(//, uc $arg)) {
        my ($digit) = $roman2arabic{$_};
        $arabic -= 2 * $last_digit if $last_digit < $digit;
        $arabic += ($last_digit = $digit);
    }
    $arabic;
}

sub Roman($) {
    my $arg = shift;
    my %roman2arabic = qw(I 1 V 5 X 10 L 50 C 100 D 500 M 1000);
    my %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
    my @figure = reverse sort keys %roman_digit;
    $roman_digit{$_} = [split(//, $roman_digit{$_}, 2)] foreach @figure;
    0 < $arg and $arg < 4000 or return undef;
    my $roman = "";
    my $x;
    foreach (@figure) {
        my ($digit, $i, $v) = (int($arg / $_), @{$roman_digit{$_}});
        if (1 <= $digit and $digit <= 3) {
            $roman .= $i x $digit;
        } elsif ($digit == 4) {
            $roman .= "$i$v";
        } elsif ($digit == 5) {
            $roman .= $v;
        } elsif (6 <= $digit and $digit <= 8) {
            $roman .= $v . $i x ($digit - 5);
        } elsif ($digit == 9) {
            $roman .= "$i$x";
        }
        $arg -= $digit * $_;
        $x = $i;
    }
    $roman;
}

sub num_digits {
    my ($n) = (@_);
    my $size = 0;

    do {
        $size++;
        $n = int($n / 10);
    } while ($n);
    return $size;
}

sub cmpChrs ($$) {
    my $a2_c = lc($_[1]);
    my $b2_c = lc($_[0]);
    if($a2_c eq 'finished1234') {
	return 1;
    }
    if($b2_c eq 'finished1234') {
	return -1;
    }
    if ($a2_c =~ /^\d+$/ && !($b2_c =~ /^\d+$/)) {
        return 1;
    }
    if ($b2_c =~ /^\d+$/ && !($a2_c =~ /^\d+$/)) {
        return -1;
    }
    if ($a2_c =~ /^[ivxym]+$/ && !($b2_c =~ /^[ivxym]+$/)) {
        return 1;
    }
    if ($b2_c =~ /^[ivxym]+$/ && !($a2_c =~ /^[ivxym]+$/)) {
        return -1;
    }
    if ($a2_c eq 'm' && ($b2_c eq 'y' || $b2_c eq 'x')) {
        return -1;
    }
    if ($b2_c eq 'm' && ($a2_c eq 'y' || $a2_c eq 'x')) {
        return 1;
    }
    if ($a2_c =~ /^[ivx]+$/ && $b2_c =~ /^[ivx]+$/) {
        $a2_c = "chr" . $a2_c;
        $b2_c = "chr" . $b2_c;
    }
    if ($a2_c =~ /$b2_c/) {
	return -1;
    }
    if ($b2_c =~ /$a2_c/) {
	return 1;
    }
    # dealing with roman numerals starts here
    if ($a2_c =~ /chr([ivx]+)/ && $b2_c =~ /chr([ivx]+)/) {
	$a2_c =~ /chr([ivx]+)/;
	my $a2_roman = $1;
	$b2_c =~ /chr([ivx]+)/;
	my $b2_roman = $1;
	my $a2_arabic = arabic($a2_roman);
    	my $b2_arabic = arabic($b2_roman);
	if ($a2_arabic > $b2_arabic) {
	    return -1;
	} 
	if ($a2_arabic < $b2_arabic) {
	    return 1;
	}
	if ($a2_arabic == $b2_arabic) {
            my $tempa = $a2_c;
	    my $tempb = $b2_c;
	    $tempa =~ s/chr([ivx]+)//;
	    $tempb =~ s/chr([ivx]+)//;
            my %temphash;
	    $temphash{$tempa}=1;
	    $temphash{$tempb}=1;
	    foreach my $tempkey (sort {cmpChrs($a,$b)} keys %temphash) {
		if ($tempkey eq $tempa) {
		    return 1;
		} else {
		    return -1;
		}
	    }
	}
    }
    if ($b2_c =~ /chr([ivx]+)/ && !($a2_c =~ /chr([a-z]+)/) && !($a2_c =~ /chr(\d+)/)) {
	return -1;
    }
    if ($a2_c =~ /chr([ivx]+)/ && !($b2_c =~ /chr([a-z]+)/) && !($b2_c =~ /chr(\d+)/)) {
	return 1;
    }

    if ($b2_c =~ /m$/ && $a2_c =~ /vi+/) {
	return 1;
    }
    if ($a2_c =~ /m$/ && $b2_c =~ /vi+/) {
	return -1;
    }

    # roman numerals ends here
    if ($a2_c =~ /chr(\d+)$/ && $b2_c =~ /chr.*_/) {
        return 1;
    }
    if ($b2_c =~ /chr(\d+)$/ && $a2_c =~ /chr.*_/) {
        return -1;
    }
    if ($a2_c =~ /chr([a-z])$/ && $b2_c =~ /chr.*_/) {
        return 1;
    }
    if ($b2_c =~ /chr([a-z])$/ && $a2_c =~ /chr.*_/) {
        return -1;
    }
    if ($a2_c =~ /chr(\d+)/) {
        my $numa = $1;
        if ($b2_c =~ /chr(\d+)/) {
            my $numb = $1;
            if ($numa < $numb) {
                return 1;
            }
	    if ($numa > $numb) {
                return -1;
            }
	    if ($numa == $numb) {
		my $tempa = $a2_c;
		my $tempb = $b2_c;
		$tempa =~ s/chr\d+//;
		$tempb =~ s/chr\d+//;
		my %temphash;
		$temphash{$tempa}=1;
		$temphash{$tempb}=1;
		foreach my $tempkey (sort {cmpChrs($a,$b)} keys %temphash) {
		    if ($tempkey eq $tempa) {
			return 1;
		    } else {
			return -1;
		    }
		}
	    }
        } else {
            return 1;
        }
    }
    if ($a2_c =~ /chrx(.*)/ && ($b2_c =~ /chr(y|m)$1/)) {
	return 1;
    }
    if ($b2_c =~ /chrx(.*)/ && ($a2_c =~ /chr(y|m)$1/)) {
	return -1;
    }
    if ($a2_c =~ /chry(.*)/ && ($b2_c =~ /chrm$1/)) {
	return 1;
    }
    if ($b2_c =~ /chry(.*)/ && ($a2_c =~ /chrm$1/)) {
	return -1;
    }
    if ($a2_c =~ /chr\d/ && !($b2_c =~ /chr[^\d]/)) {
	return 1;
    }
    if ($b2_c =~ /chr\d/ && !($a2_c =~ /chr[^\d]/)) {
	return -1;
    }
    if ($a2_c =~ /chr[^xy\d]/ && (($b2_c =~ /chrx/) || ($b2_c =~ /chry/))) {
        return -1;
    }
    if ($b2_c =~ /chr[^xy\d]/ && (($a2_c =~ /chrx/) || ($a2_c =~ /chry/))) {
        return 1;
    }
    if ($a2_c =~ /chr(\d+)/ && !($b2_c =~ /chr(\d+)/)) {
        return 1;
    }
    if ($b2_c =~ /chr(\d+)/ && !($a2_c =~ /chr(\d+)/)) {
        return -1;
    }
    if ($a2_c =~ /chr([a-z])/ && !($b2_c =~ /chr(\d+)/) && !($b2_c =~ /chr[a-z]+/)) {
        return 1;
    }
    if ($b2_c =~ /chr([a-z])/ && !($a2_c =~ /chr(\d+)/) && !($a2_c =~ /chr[a-z]+/)) {
        return -1;
    }
    if ($a2_c =~ /chr([a-z]+)/) {
        my $letter_a = $1;
        if ($b2_c =~ /chr([a-z]+)/) {
            my $letter_b = $1;
            if ($letter_a lt $letter_b) {
                return 1;
            }
	    if ($letter_a gt $letter_b) {
                return -1;
            }
        } else {
            return -1;
        }
    }
    my $flag_c = 0;
    while ($flag_c == 0) {
        $flag_c = 1;
        if ($a2_c =~ /^([^\d]*)(\d+)/) {
            my $stem1_c = $1;
            my $num1_c = $2;
            if ($b2_c =~ /^([^\d]*)(\d+)/) {
                my $stem2_c = $1;
                my $num2_c = $2;
                if ($stem1_c eq $stem2_c && $num1_c < $num2_c) {
                    return 1;
                }
                if ($stem1_c eq $stem2_c && $num1_c > $num2_c) {
                    return -1;
                }
                if ($stem1_c eq $stem2_c && $num1_c == $num2_c) {
                    $a2_c =~ s/^$stem1_c$num1_c//;
                    $b2_c =~ s/^$stem2_c$num2_c//;
                    $flag_c = 0;
                }
            }
        }
    }
    if ($a2_c le $b2_c) {
	return 1;
    }
    if ($b2_c le $a2_c) {
	return -1;
    }


    return 1;
}

sub by_location ($$) {
    my ($c, $d) = @_;
    my $c_chr = $c->{chr} || "";
    my $d_chr = $d->{chr} || "";

    ($c_chr ne $d_chr ? cmpChrs($c_chr, $d_chr) : 0) ||
    ($c->{start}  || 0) <=> ($d->{start}  || 0) ||
    ($c->{end}    || 0) <=> ($d->{end}    || 0) ||
    ($c->{entry} || 0) cmp ($d->{entry} || 0);
}
