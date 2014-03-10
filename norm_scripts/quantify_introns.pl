$|=1;
if(@ARGV<4) {
    die "Usage: quantify_introns.pl <introns file> <sam file> <output file> <output sam?> [options]

<introns file> has one line per intron, each line is in the format chr:start-end

<sam file> has must have mate pairs in consecutive rows

<output file> intronquants file

<output sam?> = true if you want it to output two sam files, one of things that map to introns 
                and one with things that do not.

option:

-depth <n> : by default, it will output 10 intronmappers

";
}
$i_intron = 10;
for($i=4; $i<@ARGV; $i++) {
    $arg_recognized = 'false';
    if($ARGV[$i] eq '-depth'){
	$i_intron = $ARGV[$i+1];
	$arg_recognized = 'true';
	$i++;
    }
    if($arg_recognized eq 'false') {
	die "arg \"$ARGV[$i]\" not recognized.\n";
    }
}

$intronsfile = $ARGV[0];
$samfile = $ARGV[1];
$outfile = $ARGV[2];
$intronoutfile = $samfile;
$intronoutfile =~ s/.sam$/_intronmappers.sam/;
$intergenicoutfile = $samfile;
$intergenicoutfile =~ s/.sam$/_intergenicmappers.sam/;
$outputsam = $ARGV[3];
if($outputsam eq "true") {
    for ($i=1; $i<=$i_intron; $i++){
	$intronoutfile[$i] = $intronoutfile;
	$intronoutfile[$i] =~ s/.sam$/.$i.sam/;
	open($OUTFILE[$i], ">$intronoutfile[$i]");
    }
    open(IGOUTFILE, ">$intergenicoutfile");
}

open(OUTFILE, ">$outfile");

open(INFILE, $intronsfile);

while($line = <INFILE>) {
    chomp($line);
    if($line =~ /([^:\t\s]+):(\d+)-(\d+)/) {
	$chr = $1;
	$start = $2;
	$end = $3;
	$intron = "$chr:$start-$end";
	if(defined $INTRON_hash{$intron}) {  # in case of duplicates
	    next;
	}
	$INTRON_hash{$intron}=0;
	$intron_cnt = @INTRONS;
	push(@INTRONS, $intron);
	$start_block = int($start / 1000);
	$end_block = int($end / 1000);
	for($i=$start_block; $i<=$end_block; $i++) {
	    push(@{$intron_overlaps_block{$chr}{$i}},$intron_cnt);  # all introns that overlap the ith span of 1K bases
	}
    } else {
	next;
    }
}
close(INFILE);
for($i=1;$i<=$i_intron;$i++){
    $outfile_cnt[$i]=0;
}
$outfile_cnt_ig=0;
open(INFILE, $samfile);
$CNT_OF_FRAGS_WHICH_HIT_INTRONS=0;
while ($line1 = <INFILE>) {
    $flag = 0;
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
    $a[0] =~ /(\d+)/;
    $seqnum1 = $1;
    $chr = $a[2];
    if($a[1] & 64) {
	$type1 = "a";
    } else {
	$type1 = "b";
	$reverse_only = "true";
    }
    if($reverse_only eq 'false') {
	$line2 = <INFILE>;
	chomp($line2);
	@b = split(/\t/,$line2);
	$b[0] =~ /(\d+)/;
	$seqnum2 = $1;
	if ($seqnum1 != $seqnum2) {
	    $len = -1 * (1 + length($line2));
	    seek(INFILE, $len, 1);
	    $forward_only = "true";
	} else {
	    if($b[1] & 128) {
		$type2 = "b";
	    } else {
		$forward_only = "true";
		$len = -1 * (1 + length($line2));
		seek(INFILE, $len, 1);
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
    if($start1 < $start2) {
	$merged_spans = &merge($spans1, $spans2);
    } else {
	$merged_spans = &merge($spans2, $spans1);
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
	    $NN = @{$intron_overlaps_block{$chr}{$i}};  # all introns that overlap the ith span of 1K bases
	    for($j=0; $j<$NN; $j++) {
		$current_intron = $INTRONS[$intron_overlaps_block{$chr}{$i}[$j]];
		$current_intron =~ /.*:(\d+)-(\d+)/;
		$start_e = $1;
		$end_e = $2;
		if($read_segment_end >= $start_e && $read_segment_start <= $end_e) {
		    if(!(defined $done{$current_intron})) {
			$INTRON_hash{$current_intron}++;
			if($flag == 1) {
			    $CNT_OF_FRAGS_WHICH_HIT_INTRONS++;
			}
			$flag++;
		    }
		    $done{$current_intron}=1;
		}
	    }
	}
    }
    $flagDist[$flag]++;
    if($flag > 0) {
	if($outputsam eq "true") {
	    for ($i=1; $i<$i_intron; $i++){
		if($flag == $i) {
		    $outfile_cnt[$i]++;
		    print {$OUTFILE[$i]} $line1;
		}
	    }
	    if($flag >= $i_intron) {
		$outfile_cnt[$i_intron]++;
		print {$OUTFILE[$i_intron]} $line1;
            }
	}
    } else {
	if($outputsam eq "true") {
	    $outfile_cnt_ig++;
	    print IGOUTFILE $line1;
	}
    }
}

for($i=0; $i<@flagDist; $i++) {
    print OUTFILE "$i\t$flagDist[$i]\n";
}
	
if($outputsam eq "true") {
    print IGOUTFILE "line count = $outfile_cnt_ig\n";
    for ($i=1; $i<=$i_intron; $i++){
	print {$OUTFILE[$i]} "line count = $outfile_cnt[$i]\n";
	close($OUTFILE[$i]);
    }
    close(INTRONOUTFILE);
    close(IGOUTFILE);
}

foreach $intron (sort {cmpChrs($a,$b)} keys %INTRON_hash) {
    print OUTFILE "$intron\t$INTRON_hash{$intron}\n";
}
close(OUTFILE);

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
