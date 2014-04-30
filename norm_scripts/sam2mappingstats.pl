#!/usr/bin/env perl

if(@ARGV < 2) {
    die "Usage: perl sam2mappingstats.pl <sam file> <outfilename> [options]

samfile : SAM file must use the IH or NH tags to indicate multi-mappers
outfilename : name of the output txt file

options: -numreads <n>  :  This is the total number of reads.
                                - This cannot usually be inferred from the SAM file

         -covU <f>  :  <f> is the coverage unique mappers bed file with zero-based half-open coordinates.
                       Use this option to report the number and percent of bases mapped.

         -covNU <f>    <f> is the coverage non-unique mappers bed file with zero-based half-open coordinates.
                       Use this option to report the number and percent of bases mapped.

         -species <s>  : <s> is hg18, hg19, mm9 or mm10, susscr3.  Use this if -cov is specified.

";
}

$sam_in = $ARGV[0];
$outfile = $ARGV[1];
$cov = "";
$num_ids = 0;
for($i=2; $i<@ARGV; $i++) {
     $argument_recognized = 0;
    if($ARGV[$i] eq '-numreads') {
	$num_ids = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($ARGV[$i] eq '-covU') {
	$covU = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($ARGV[$i] eq '-covNU') {
	$covNU = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($ARGV[$i] eq '-species') {
	$species = $ARGV[$i+1];
	$i++;
	$argument_recognized = 1;
    }
    if($argument_recognized == 0) {
	die "ERROR: command line arugument '$ARGV[$i]' not recognized.\n";
    }
}
if($covU =~ /\S/ && !($species =~ /\S/)) {
    die "Error: if you specify a coverage plot with -covU, you also must specify the species.\n";
}
if($covNU =~ /\S/ && !($species =~ /\S/)) {
    die "Error: if you specify a coverage plot with -covNU, you also must specify the species.\n";
}

$genome_size = 0;
if($species eq 'susscr3') {
    $genome_size = 2808525991;
}
if($species eq 'mm9') {
    $genome_size = 2725765481;
}
if($species eq 'mm10') {
    $genome_size = 2730871774;
}
if($species eq 'hg18') {
    $genome_size = 3096521113;
}
if($species eq 'hg19') {
    $genome_size = 3101804741;
}
if($covU =~ /\S/) {
    $bases_covered_U = 0;
    open(INFILE, $covU);
    $linecnt = 0;
    while($line = <INFILE>) {
	$linecnt++;
	if($linecnt % 1000000 == 0) {
	    $date = `date`;
	    print "processed $linecnt lines of '$covU'\t$date";
	}
	if($line =~ /track/) {
	    next;
	}
	chomp($line);
	@a = split(/\t/,$line);
	$bases_covered_U = $bases_covered_U + $a[2] - $a[1];
    }
    close(INFILE);
}
if($covNU =~ /\S/) {
    $bases_covered_NU = 0;
    open(INFILE, $covNU);
    $linecnt = 0;
    while($line = <INFILE>) {
	$linecnt++;
	if($linecnt % 1000000 == 0) {
	    $date = `date`;
	    print "processed $linecnt lines of '$covNU'\t$date";
	}
	if($line =~ /track/) {
	    next;
	}
	chomp($line);
	@a = split(/\t/,$line);
	$bases_covered_NU = $bases_covered_NU + $a[2] - $a[1];
    }
    close(INFILE);
}

open(SAM, $sam_in) or die "cannot find file \"$sam_in\"\n";
while (<SAM>){
    if (1..1000){
	if ($_ =~ /^@/){
	    next;
	}
	@a = split (/\t/, $_);
	$seqname = $a[0];
	$seqname =~ s/[^A-Za-z0-9 ]//g;
	push(@NAME, $seqname);
	$length = length $seqname;
    }
}
close(SAM);
$common_str = "";

@tail = &last_x_lines($sam_in, 1000);
for $seq (@tail){
    @a = split (/\t/, $seq);
    $seqname = $a[0];
    $seqname =~ s/[^A-Za-z0-9 ]//g;
    push(@NAME, $seqname);
}
$common_str = &LCP(@NAME);

open(INFILE, $sam_in);
$linecnt = 0;
$num_OL = 0;
$num_NOL = 0;
while($line = <INFILE>) {
    $linecnt++;
    if($linecnt % 1000000 == 0) {
	$date = `date`;
	print "processed $linecnt lines\t$date";
    }
    chomp($line);
    if($line =~ /^@/) {
	next;
    }
    @a = split(/\t/,$line);
    $seqname = $a[0];
    $seqname =~ s/[^A-Za-z0-9 ]//g;
    $seqname =~ s/$common_str//g;
    if($a[5] eq '*' || $a[5] eq '.') {
	next;
    }
    $n = 0;
    if($line =~ /IH:i:(\d+)/) {
	$n = $1;
    }
    if($line =~ /NH:i:(\d+)/) {
	$n = $1;
    }
    if($n == 0) {
	$num_alignments = 1;
    } else {
	$num_alignments = $n;
    }
    if($num_alignments == 1) {
	if(!(defined $U{$seqname})) {
	    $CHR_U{$a[2]}++;
	}
	if ($a[1] & 1){
	    if($a[1] & 2**6) {
		if($U{$seqname}+0==0) {
		    $U{$seqname} = 1;   # 1 means forward found only so far
		}
		if($U{$seqname}+0==2) { # 2 means reverse found only so far
		    $U{$seqname} = 3;   # 3 means both forward and reverse found
		}
		if($line =~ /XO:A:T/) {
		    $num_OL++;
		}
		if($line =~ /XO:A:F/) {
		    $num_NOL++;
		}
	    } else {
		if($U{$seqname}+0==0) {
		    $U{$seqname} = 2;   # 2 means reverse found only so far
		}
		if($U{$seqname}+0==1) { # 1 means forward found only so far
		    $U{$seqname} = 3;   # 3 means both forward and reverse found
		}
	    }
	}
	else {
	    $U{$seqname} = 1;
	}
    } 
    else {
	if ($a[1] & 1){
	    if($a[1] & 2**6) {
		if($NU{$seqname}+0==0) {
		    $NU{$seqname} = 1;   # 1 means forward found only so far
		}
		if($NU{$seqname}+0==2) { # 2 means reverse found only so far
		    $NU{$seqname} = 3;   # 3 means both forward and reverse found
		}
		$CHR_NU{$a[2]}++;
	    } else {
		if($NU{$seqname}+0==0) {
		    $NU{$seqname} = 2;   # 2 means reverse found only so far
		}
		if($NU{$seqname}+0==1) { # 1 means forward found only so far
		    $NU{$seqname} = 3;   # 3 means both forward and reverse found
		}
	    }
	}
	else {
	    $NU{$seqname} = 1;
	}
    }
    $numLocs{$n}++;
}

$bothmappedU = 0;
$forwardonlyU = 0;
$reverseonlyU = 0;
$linecnt = 0;
$Nids = 0;
foreach  $key (keys  %U) {
    $Nids++;
    $linecnt++;
    if($linecnt % 1000000 == 0) {
	$date = `date`;
	print "processed $linecnt U IDs\t$date";
    }
    if($U{$key}+0==1) {
	$forwardonlyU++;
    }
    if($U{$key}+0==2) {
	$reverseonlyU++;
    }
    if($U{$key}+0==3) {
	$bothmappedU++;
    }
}
$linecnt = 0;
foreach $key (keys %NU) {
    $Nids++;
    $linecnt++;
    if($linecnt % 1000000 == 0) {
	$date = `date`;
	print "processed $linecnt NU IDs\t$date";
    }
    if($NU{$key}+0==1) {
	$forwardonlyNU++;
    }
    if($NU{$key}+0==2) {
	$reverseonlyNU++;
    }
    if($NU{$key}+0==3) {
	$bothmappedNU++;
    }
}

if($num_ids == 0) {
    $num_ids = $Nids;
}

$num_ids_formatted = format_large_int($num_ids);
$bothmappedU_formatted = format_large_int($bothmappedU);
$bothmappedU_percent = int($bothmappedU / $num_ids * 1000) / 10;
$forwardonlyU_formatted = format_large_int($forwardonlyU);
$reverseonlyU_formatted = format_large_int($reverseonlyU);
$forwardU_total = $bothmappedU + $forwardonlyU;
$reverseU_total = $bothmappedU + $reverseonlyU;
$forwardU_total_formatted = format_large_int($forwardU_total);
$reverseU_total_formatted = format_large_int($reverseU_total);
$forwardU_total_percent = int($forwardU_total / $num_ids * 1000) / 10;
$reverseU_total_percent = int($reverseU_total / $num_ids * 1000) / 10;
$atleastoneforwardorreverse = $bothmappedU + $forwardonlyU + $reverseonlyU;
$atleastoneforwardorreverse_formatted = format_large_int($atleastoneforwardorreverse);
$atleastoneforwardorreverse_percent = int($atleastoneforwardorreverse / $num_ids * 1000) / 10;

$forwardonlyNU_formatted = format_large_int($forwardonlyNU);
$reverseonlyNU_formatted = format_large_int($reverseonlyNU);
$forwardonlyNU_percent = int($forwardonlyNU / $num_ids * 1000) / 10;
$reverseonlyNU_percent = int($reverseonlyNU / $num_ids * 1000) / 10;
$bothmappedNU_formatted = format_large_int($bothmappedNU);
$bothmappedNU_percent = int($bothmappedNU / $num_ids * 1000) / 10;
$atleastoneforwardorreverseNU = $bothmappedNU + $forwardonlyNU + $reverseonlyNU;
$atleastoneforwardorreverseNU_formatted = format_large_int($atleastoneforwardorreverseNU);
$atleastoneforwardorreverseNU_percent = int($atleastoneforwardorreverseNU / $num_ids * 1000) / 10;

$total_forward = $bothmappedU + $forwardonlyU + $bothmappedNU + $forwardonlyNU;
$total_forward_formatted = format_large_int($total_forward);
$total_forward_percent = int($total_forward / $num_ids * 1000) / 10;
$total_reverse = $bothmappedU + $reverseonlyU + $bothmappedNU + $reverseonlyNU;
$total_reverse_formatted = format_large_int($total_reverse);
$total_reverse_percent = int($total_reverse / $num_ids * 1000) / 10;
$total_consistent = $bothmappedU + $bothmappedNU;
$total_consistent_formatted = format_large_int($total_consistent);
$total_consistent_percent = int($total_consistent / $num_ids * 1000) / 10;
$total = $bothmappedU + $forwardonlyU + $reverseonlyU + $bothmappedNU + $forwardonlyNU + $reverseonlyNU;
$total_formatted = format_large_int($total);
$total_percent = int($total / $num_ids * 1000) / 10;

$num_OL_formatted = format_large_int($num_OL);
$num_NOL_formatted = format_large_int($num_NOL);

open(OUT, ">$outfile");
print OUT "Number of read pairs: $num_ids_formatted

UNIQUE MAPPERS
--------------
Both forward and reverse mapped consistently: $bothmappedU_formatted ($bothmappedU_percent%)
";
if($num_OL > 0) {
    print OUT "   - do overlap: $num_OL_formatted
   - don't overlap: $num_NOL_formatted
"
}
print OUT "Number of forward mapped only: $forwardonlyU_formatted
Number of reverse mapped only: $reverseonlyU_formatted
Number of forward total: $forwardU_total_formatted ($forwardU_total_percent%)
Number of reverse total: $reverseU_total_formatted ($reverseU_total_percent%)
At least one of forward or reverse mapped: $atleastoneforwardorreverse_formatted ($atleastoneforwardorreverse_percent%)

NON-UNIQUE MAPPERS
------------------
Total number forward only ambiguous: $forwardonlyNU_formatted ($forwardonlyNU_percent%)
Total number reverse only ambiguous: $reverseonlyNU_formatted ($reverseonlyNU_percent%)
Total number consistent ambiguous: $bothmappedNU_formatted ($bothmappedNU_percent%)
At least one of forward or reverse mapped: $atleastoneforwardorreverseNU_formatted ($atleastoneforwardorreverseNU_percent%)

TOTAL
-----
Total number forward: $total_forward_formatted ($total_forward_percent%)
Total number reverse: $total_reverse_formatted ($total_reverse_percent%)
Total number consistent: $total_consistent_formatted ($total_consistent_percent%)
At least one of forward or reverse mapped: $total_formatted ($total_percent%)

";

if($covU =~ /\S/ || $covNU =~ /\S/) {
    $genome_size_formatted = format_large_int($genome_size);
    print OUT "genome size: $genome_size_formatted\n"
}
if($covU =~ /\S/) {
    $coverageU_formatted = format_large_int($bases_covered_U);
    $coverageU_percent = int($bases_covered_U / $genome_size * 1000) / 10;
    print OUT "number of bases covered by unique mappers: $coverageU_formatted ($coverageU_percent%)\n";
}
if($covNU =~ /\S/) {
    $coverageNU_formatted = format_large_int($bases_covered_NU);
    $coverageNU_percent = int($bases_covered_NU / $genome_size * 1000) / 10;
    print OUT "number of bases covered by non-unique mappers: $coverageNU_formatted ($coverageNU_percent%)\n\n";
}

print OUT "Uniquely mapping reads per chromosome
-------------------------------------
chr\tnum\t%ofU\t%allMapped\t%ofAll
";

foreach $chr (sort {cmpChrs($a,$b)} keys %CHR_U) {
    $pall = int($CHR_U{$chr} / $num_ids * 1000) / 10;
    $pU = int($CHR_U{$chr} / $atleastoneforwardorreverse * 1000) / 10;
    $ptm = int($CHR_U{$chr} / $total * 1000) / 10;
    print OUT "$chr\t$CHR_U{$chr}\t$pU\t$ptm\t$pall\n";
}
print OUT "\nNon-Uniquely mapping reads per chromosome\n-----------------------------------------\n";
print OUT "chr\tnum\t%ofNU\t%allMapped\t%ofAll\n";
foreach $chr (sort {cmpChrs($a,$b)} keys %CHR_NU) {
    $totalNU = $bothmappedNU + $forwardonlyNU + $reverseonlyNU;
    $pall = int($CHR_NU{$chr} / $num_ids * 1000) / 10;
    $pNU = int($CHR_NU{$chr} / $totalNU * 1000) / 10;
    $ptm = int($CHR_U{$chr} / $total * 1000) / 10;
    print OUT "$chr\t$CHR_NU{$chr}\t$pNU\t$ptm\t$pall\n";
}
print OUT "
Num. Locations      Num. Reads
------------------------------
";
foreach $n (sort {$a<=>$b} keys %numLocs) {
    print OUT "$n\t$numLocs{$n}\n";
}

sub last_x_lines {
    my ($filename, $lineswanted) = @_;
    my ($line, $filesize, $seekpos, $numread, @lines);

    open F, $filename or die "Can't read $filename: $!\n";

    $filesize = -s $filename;
    $seekpos = 50 * $lineswanted;
    $numread = 0;

    while ($numread < $lineswanted) {
        @lines = ();
        $numread = 0;
        seek(F, $filesize - $seekpos, 0);
        <F> if $seekpos < $filesize; # Discard probably fragmentary line
        while (defined($line = <F>)) {
            push @lines, $line;
            shift @lines if ++$numread > $lineswanted;
        }
        if ($numread < $lineswanted) {
            # We didn't get enough lines. Double the amount of space to read from next time.
            if ($seekpos >= $filesize) {
                die "There aren't even $lineswanted lines in $filename - I got $numread\n";
            }
            $seekpos *= 2;
            $seekpos = $filesize if $seekpos >= $filesize;
        }
    }
    close F;
    return @lines;
}

sub LCP {
    return '' unless @_;
    return $_[0] if @_ == 1;
     $i          = 0;
     $first      = shift;
     $min_length = length($first);
    foreach (@_) {
        $min_length = length($_) if length($_) < $min_length;
    }
  INDEX: foreach  $ch ( split //, $first ) {
      last INDEX unless $i < $min_length;
      foreach  $string (@_) {
	  last INDEX if substr($string, $i, 1) ne $ch;
      }
  }
    continue { $i++ }
    return substr $first, 0, $i;
}

sub format_large_int () {
    ($int) = @_;
    @a = split(//,"$int");
    $j=0;
    $newint = "";
    $n = @a;
    for($i=$n-1;$i>=0;$i--) {
	$j++;
	$newint = $a[$i] . $newint;
	if($j % 3 == 0) {
	    $newint = "," . $newint;
	}
    }
    $newint =~ s/^,//;
    return $newint;
}

sub cmpChrs () {
    $a2_c = lc($b);
    $b2_c = lc($a);
    if($a2_c =~ /^\d+$/ && !($b2_c =~ /^\d+$/)) {
        return 1;
    }
    if($b2_c =~ /^\d+$/ && !($a2_c =~ /^\d+$/)) {
        return -1;
    }
    if($a2_c =~ /^[ivxym]+$/ && !($b2_c =~ /^[ivxym]+$/)) {
        return 1;
    }
    if($b2_c =~ /^[ivxym]+$/ && !($a2_c =~ /^[ivxym]+$/)) {
        return -1;
    }
    if($a2_c eq 'm' && ($b2_c eq 'y' || $b2_c eq 'x')) {
        return -1;
    }
    if($b2_c eq 'm' && ($a2_c eq 'y' || $a2_c eq 'x')) {
        return 1;
    }
    if($a2_c =~ /^[ivx]+$/ && $b2_c =~ /^[ivx]+$/) {
        $a2_c = "chr" . $a2_c;
        $b2_c = "chr" . $b2_c;
    }
    if($a2_c =~ /$b2_c/) {
	return -1;
    }
    if($b2_c =~ /$a2_c/) {
	return 1;
    }
    # dealing with roman numerals starts here
    if($a2_c =~ /chr([ivx]+)/ && $b2_c =~ /chr([ivx]+)/) {
	$a2_c =~ /chr([ivx]+)/;
	$a2_roman = $1;
	$b2_c =~ /chr([ivx]+)/;
	$b2_roman = $1;
	$a2_arabic = arabic($a2_roman);
    	$b2_arabic = arabic($b2_roman);
	if($a2_arabic > $b2_arabic) {
	    return -1;
	} 
	if($a2_arabic < $b2_arabic) {
	    return 1;
	}
	if($a2_arabic == $b2_arabic) {
	    $tempa = $a2_c;
	    $tempb = $b2_c;
	    $tempa =~ s/chr([ivx]+)//;
	    $tempb =~ s/chr([ivx]+)//;
	    undef %temphash;
	    $temphash{$tempa}=1;
	    $temphash{$tempb}=1;
	    foreach $tempkey (sort {cmpChrs($a,$b)} keys %temphash) {
		if($tempkey eq $tempa) {
		    return 1;
		} else {
		    return -1;
		}
	    }
	}
    }
    if($b2_c =~ /chr([ivx]+)/ && !($a2_c =~ /chr([a-z]+)/) && !($a2_c =~ /chr(\d+)/)) {
	return -1;
    }
    if($a2_c =~ /chr([ivx]+)/ && !($b2_c =~ /chr([a-z]+)/) && !($b2_c =~ /chr(\d+)/)) {
	return 1;
    }

    # roman numerals ends here
    if($a2_c =~ /chr(\d+)$/ && $b2_c =~ /chr.*_/) {
        return 1;
    }
    if($b2_c =~ /chr(\d+)$/ && $a2_c =~ /chr.*_/) {
        return -1;
    }
    if($a2_c =~ /chr([a-z])$/ && $b2_c =~ /chr.*_/) {
        return 1;
    }
    if($b2_c =~ /chr([a-z])$/ && $a2_c =~ /chr.*_/) {
        return -1;
    }
    if($a2_c =~ /chr(\d+)/) {
        $numa = $1;
        if($b2_c =~ /chr(\d+)/) {
            $numb = $1;
            if($numa < $numb) {return 1;}
	    if($numa > $numb) {return -1;}
	    if($numa == $numb) {
		$tempa = $a2_c;
		$tempb = $b2_c;
		$tempa =~ s/chr\d+//;
		$tempb =~ s/chr\d+//;
		undef %temphash;
		$temphash{$tempa}=1;
		$temphash{$tempb}=1;
		foreach $tempkey (sort {cmpChrs($a,$b)} keys %temphash) {
		    if($tempkey eq $tempa) {
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
    if($a2_c =~ /chrx(.*)/ && ($b2_c =~ /chr(y|m)$1/)) {
	return 1;
    }
    if($b2_c =~ /chrx(.*)/ && ($a2_c =~ /chr(y|m)$1/)) {
	return -1;
    }
    if($a2_c =~ /chry(.*)/ && ($b2_c =~ /chrm$1/)) {
	return 1;
    }
    if($b2_c =~ /chry(.*)/ && ($a2_c =~ /chrm$1/)) {
	return -1;
    }
    if($a2_c =~ /chr\d/ && !($b2_c =~ /chr[^\d]/)) {
	return 1;
    }
    if($b2_c =~ /chr\d/ && !($a2_c =~ /chr[^\d]/)) {
	return -1;
    }
    if($a2_c =~ /chr[^xy\d]/ && (($b2_c =~ /chrx/) || ($b2_c =~ /chry/))) {
        return -1;
    }
    if($b2_c =~ /chr[^xy\d]/ && (($a2_c =~ /chrx/) || ($a2_c =~ /chry/))) {
        return 1;
    }
    if($a2_c =~ /chr(\d+)/ && !($b2_c =~ /chr(\d+)/)) {
        return 1;
    }
    if($b2_c =~ /chr(\d+)/ && !($a2_c =~ /chr(\d+)/)) {
        return -1;
    }
    if($a2_c =~ /chr([a-z])/ && !($b2_c =~ /chr(\d+)/) && !($b2_c =~ /chr[a-z]+/)) {
        return 1;
    }
    if($b2_c =~ /chr([a-z])/ && !($a2_c =~ /chr(\d+)/) && !($a2_c =~ /chr[a-z]+/)) {
        return -1;
    }
    if($a2_c =~ /chr([a-z]+)/) {
        $letter_a = $1;
        if($b2_c =~ /chr([a-z]+)/) {
            $letter_b = $1;
            if($letter_a lt $letter_b) {return 1;}
	    if($letter_a gt $letter_b) {return -1;}
        } else {
            return -1;
        }
    }
    $flag_c = 0;
    while($flag_c == 0) {
        $flag_c = 1;
        if($a2_c =~ /^([^\d]*)(\d+)/) {
            $stem1_c = $1;
            $num1_c = $2;
            if($b2_c =~ /^([^\d]*)(\d+)/) {
                $stem2_c = $1;
                $num2_c = $2;
                if($stem1_c eq $stem2_c && $num1_c < $num2_c) {
                    return 1;
                }
                if($stem1_c eq $stem2_c && $num1_c > $num2_c) {
                    return -1;
                }
                if($stem1_c eq $stem2_c && $num1_c == $num2_c) {
                    $a2_c =~ s/^$stem1_c$num1_c//;
                    $b2_c =~ s/^$stem2_c$num2_c//;
                    $flag_c = 0;
                }
            }
        }
    }
    if($a2_c le $b2_c) {
	return 1;
    }
    if($b2_c le $a2_c) {
	return -1;
    }


    return 1;
}


sub clean () {
    ($infilename, $outfilename) = @_;
    open(INFILE, $infilename);
    open(OUTFILE, ">>$outfilename");
    while($line = <INFILE>) {
	$flag = 0;
	chomp($line);
	@a = split(/\t/,$line);
	$strand = $a[4];
	$chr = $a[1];
	@b2 = split(/, /,$a[2]);
	$a[3] =~ s/://g;
	$seq_temp = $a[3];
	$seq_temp =~ s/\+//g;
	if(length($seq_temp) < $match_length_cutoff) {
	    next;
	}
	for($i=0; $i<@b2; $i++) {
	    @c2 = split(/-/,$b2[$i]);
	    if($c2[1] < $c2[0]) {
		$flag = 1;
	    }
	}
        if(defined $CHR2SEQ{$chr} && !(defined $samheader{$chr})) {
	    $CS = $chrsize{$chr};
	    $samheader{$chr} = "\@SQ\tSN:$chr\tLN:$CS\n";
	}
	if(defined $CHR2SEQ{$chr} && $flag == 0) {
	    if($line =~ /[^\t]\+[^\t]/) {   # insertions will break things, have to fix this, for now not just cleaning these lines
		@LINE = split(/\t/,$line);
		print OUTFILE "$LINE[0]\t$LINE[1]\t$LINE[2]\t$LINE[4]\t$LINE[3]\n";
	    } else {
		@b = split(/, /, $a[2]);
		$SEQ = "";
		for($i=0; $i<@b; $i++) {
 		    @c = split(/-/,$b[$i]);
		    $len = $c[1] - $c[0] + 1;
		    $start = $c[0] - 1;
		    $SEQ = $SEQ . substr($CHR2SEQ{$chr}, $start, $len);
		}
		&trimleft($SEQ, $a[3], $a[2]) =~ /(.*)\t(.*)/;
		$spans = $1;
		$seq = $2;
		$length1 = length($seq);
		$length2 = length($SEQ);
		for($i=0; $i<$length2 - $length1; $i++) {
		    $SEQ =~ s/^.//;
		}
		$seq =~ s/://g;
		&trimright($SEQ, $seq, $spans) =~ /(.*)\t(.*)/;
		$spans = $1;
		$seq = $2;
		$seq = addJunctionsToSeq($seq, $spans);

		# should fix the following so it doesn't repeat the operation unnecessarily
		# while processing the RUM_NU file
		$seq_temp = $seq;
		$seq_temp =~ s/://g;
		$seq_temp =~ s/\+//g;
		if(length($seq_temp) >= $match_length_cutoff) {
		    if($countmismatches eq "true") {
			$num_mismatches = &countmismatches($SEQ, $seq);
			print OUTFILE "$a[0]\t$chr\t$spans\t$strand\t$seq\t$num_mismatches\n";
		    } else {
			print OUTFILE "$a[0]\t$chr\t$spans\t$strand\t$seq\n";
		    }
		}
	    }
	}
    }
    close(INFILE);
    close(OUTFILE);
}

sub removefirst () {
    ($n_1,  $spans_1,  $seq_1) = @_;
    $seq_1 =~ s/://g;
    @a_1 = split(/, /, $spans_1);
    $length_1 = 0;
    @b_1 = split(/-/,$a_1[0]);
    $length_1 = $b_1[1] - $b_1[0] + 1;
    if($length_1 <= $n_1) {
	$m_1 = $n_1 - $length_1;
	$spans2_1 = $spans_1;
	$spans2_1 =~ s/^\d+-\d+, //;
	for($j_1=0; $j_1<$length_1; $j_1++) {
	    $seq_1 =~ s/^.//;
	}
	$return = removefirst($m_1, $spans2_1, $seq_1);
	return $return;
    } else {
	for($j_1=0; $j_1<$n_1; $j_1++) {
	    $seq_1 =~ s/^.//;
	}
	$spans_1 =~ /^(\d+)-/;
	$start_1 = $1 + $n_1;
	$spans_1 =~ s/^(\d+)-/$start_1-/;
	return $spans_1 . "\t" . $seq_1;
    }
}

sub removelast () {
    ($n_1,  $spans_1,  $seq_1) = @_;
    $seq_1 =~ s/://g;
    @a_1 = split(/, /, $spans_1);
    @b_1 = split(/-/,$a_1[@a_1-1]);
    $length_1 = $b_1[1] - $b_1[0] + 1;
    if($length_1 <= $n_1) {
	$m_1 = $n_1 - $length_1;
	$spans2_1 = $spans_1;
	$spans2_1 =~ s/, \d+-\d+$//;
	for($j_1=0; $j_1<$length_1; $j_1++) {
	    $seq_1 =~ s/.$//;
	}
	$return = removelast($m_1, $spans2_1, $seq_1);
	return $return;
    } else {
	for($j_1=0; $j_1<$n_1; $j_1++) {
	    $seq_1 =~ s/.$//;
	}
	$spans_1 =~ /-(\d+)$/;
	$end_1 = $1 - $n_1;
	$spans_1 =~ s/-(\d+)$/-$end_1/;
	return $spans_1 . "\t" . $seq_1;
    }
}

sub trimleft () {
    ($seq1_2,  $seq2_2,  $spans_2) = @_;
    # seq2_2 is the one that gets modified and returned

    $seq1_2 =~ s/://g;
    $seq1_2 =~ /^(.)(.)/;
    $genomebase_2[0] = $1;
    $genomebase_2[1] = $2;
    $seq2_2 =~ s/://g;
    $seq2_2 =~ /^(.)(.)/;
    $readbase_2[0] = $1;
    $readbase_2[1] = $2;
    $mismatch_count_2 = 0;
    for($j_2=0; $j_2<2; $j_2++) {
	if($genomebase_2[$j_2] eq $readbase_2[$j_2]) {
	    $equal_2[$j_2] = 1;
	} else {
	    $equal_2[$j_2] = 0;
	    $mismatch_count_2++;
	}
    }
    if($mismatch_count_2 == 0) {
	return $spans_2 . "\t" . $seq2_2;
    }
    if($mismatch_count_2 == 1 && $equal_2[0] == 0) {
	&removefirst(1, $spans_2, $seq2_2) =~ /^(.*)\t(.*)/;
	$spans_new_2 = $1;
	$seq2_new_2 = $2;
	$seq1_2 =~ s/^.//;
	$return = &trimleft($seq1_2, $seq2_new_2, $spans_new_2);
	return $return;
    }
    if($equal_2[1] == 0 || $mismatch_count_2 == 2) {
	&removefirst(2, $spans_2, $seq2_2) =~ /^(.*)\t(.*)/;
	$spans_new_2 = $1;
	$seq2_new_2 = $2;
	$seq1_2 =~ s/^..//;
	$return = &trimleft($seq1_2, $seq2_new_2, $spans_new_2);
	return $return;
    }
}

sub trimright () {
    ($seq1_2, $seq2_2, $spans_2) = @_;
    # seq2_2 is the one that gets modified and returned

    $seq1_2 =~ s/://g;
    $seq1_2 =~ /(.)(.)$/;
    $genomebase_2[0] = $2;
    $genomebase_2[1] = $1;
    $seq2_2 =~ s/://g;
    $seq2_2 =~ /(.)(.)$/;
    $readbase_2[0] = $2;
    $readbase_2[1] = $1;
    $mismatch_count_2 = 0;

    for($j_2=0; $j_2<2; $j_2++) {
	if($genomebase_2[$j_2] eq $readbase_2[$j_2]) {
	    $equal_2[$j_2] = 1;
	} else {
	    $equal_2[$j_2] = 0;
	    $mismatch_count_2++;
	}
    }
    if($mismatch_count_2 == 0) {
	return $spans_2 . "\t" . $seq2_2;
    }
    if($mismatch_count_2 == 1 && $equal_2[0] == 0) {
	&removelast(1, $spans_2, $seq2_2) =~ /(.*)\t(.*)$/;
	$spans_new_2 = $1;
	$seq2_new_2 = $2;
	$seq1_2 =~ s/.$//;
	$return = &trimright($seq1_2, $seq2_new_2, $spans_new_2);
	return $return;
    }
    if($equal_2[1] == 0 || $mismatch_count_2 == 2) {
	&removelast(2, $spans_2, $seq2_2) =~ /(.*)\t(.*)$/;
	$spans_new_2 = $1;
	$seq2_new_2 = $2;
	$seq1_2 =~ s/..$//;
	$return = &trimright($seq1_2, $seq2_new_2, $spans_new_2);
	return $return;
    }
}

sub addJunctionsToSeq () {
    ($seq_in,  $spans_in) = @_;
    @s1 = split(//,$seq_in);
    @b1 = split(/, /,$spans_in);
    $seq_out = "";
    $place = 0;
    for($j1=0; $j1<@b1; $j1++) {
	@c1 = split(/-/,$b1[$j1]);
	$len1 = $c1[1] - $c1[0] + 1;
	if($seq_out =~ /\S/) {
	    $seq_out = $seq_out . ":";
	}
	for($k1=0; $k1<$len1; $k1++) {
	    $seq_out = $seq_out . $s1[$place];
	    $place++;
	}
    }
    return $seq_out;
}

sub countmismatches () {
    ($seq1m,  $seq2m) = @_;
    # seq2m is the "read"

    $seq1m =~ s/://g;
    $seq2m =~ s/://g;
    $seq2m =~ s/\+[^+]\+//g;

    @C1 = split(//,$seq1m);
    @C2 = split(//,$seq2m);
    $NUM=0;
    for($k=0; $k<@C1; $k++) {
	if($C1[$k] ne $C2[$k]) {
	    $NUM++;
	}
    }
    return $NUM;
}

sub isroman($) {
    $arg = shift;
    $arg ne '' and
	$arg =~ /^(?: M{0,3})
                (?: D?C{0,3} | C[DM])
                (?: L?X{0,3} | X[LC])
                (?: V?I{0,3} | I[VX])$/ix;
}

sub arabic($) {
     $arg = shift;
     %roman2arabic = qw(I 1 V 5 X 10 L 50 C 100 D 500 M 1000);
     %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
     @figure = reverse sort keys %roman_digit;
     $roman_digit{$_} = [split(//, $roman_digit{$_}, 2)] foreach @figure;
     isroman $arg or return undef;
     ($last_digit) = 1000;
     $arabic=0;
     ($arabic);
     foreach (split(//, uc $arg)) {
	 ($digit) = $roman2arabic{$_};
	 $arabic -= 2 * $last_digit if $last_digit < $digit;
	 $arabic += ($last_digit = $digit);
     }
     $arabic;
}

sub Roman($) {
    $arg = shift;
    %roman2arabic = qw(I 1 V 5 X 10 L 50 C 100 D 500 M 1000);
    %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
    @figure = reverse sort keys %roman_digit;
    $roman_digit{$_} = [split(//, $roman_digit{$_}, 2)] foreach @figure;
    0 < $arg and $arg < 4000 or return undef;
    $roman="";
    ($x, $roman);
    foreach (@figure) {
        ($digit,  $i,  $v) = (int($arg / $_), @{$roman_digit{$_}});
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

sub roman($) {
    lc Roman shift;
}
