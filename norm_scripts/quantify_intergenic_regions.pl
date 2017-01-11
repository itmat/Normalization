#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "perl quanitfy_intergenic_regions.pl <samfile> <intergenic regions file> <loc>

<samfile> input samfile (full path)
<intergenic regions file> master list of intergenic regions (full path) 

* note : this script assumes the input samfile is single end data.

options:
 -outputsam : set this if you want to output the sam files 
 -depth <n> : by default, it will output 2 intergenic regions mapper
 -h : prints usage.

";

if (@ARGV < 2){
    die $USAGE;
}
my $numargs = 0;
my $i_ig = 2;
my $print = "false";

for(my $i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-h'){
	die $USAGE;
    }
    if ($ARGV[$i] eq '-outputsam'){
	$option_found = "true";
	$print = "true";
    }
    if ($ARGV[$i] eq '-depth'){
	$i_ig = $ARGV[$i+1];
	if ($i_ig !~ /(\d+$)/ ){
	    die "-depth <n> : <n> needs to be a number\n";
	}
	$i++;
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

my $samfile = $ARGV[0];
my @fields = split("/", $samfile);
my $samname = $fields[@fields-1];

my $directory = $samfile;
$directory =~ s/$samname$//g;
my $igquants = $directory . "/$samname";
$igquants =~ s/.sam.gz$/.intergenicquants/;
$igquants =~ s/.sam$/.intergenicquants/;
my $linecountfile = "$directory/intergenic.linecounts.txt";
my $ig_sam_out = $samfile;
$ig_sam_out =~ s/.sam.gz$/_intergenic_regionmappers.sam.gz/g;
$ig_sam_out =~ s/.sam$/_intergenic_regionmappers.sam.gz/g;
my (@ig_sam_outfile, @OUTFILE_IG);
my $total_lc = 0;

my $max_ig = 2;
unless ($i_ig eq $max_ig){
    $max_ig = $i_ig;
}
my $IGSAMOUT;
if ($print eq "true"){
    open($IGSAMOUT, "| /bin/gzip -c > $ig_sam_out") or die "error starting gzip $!";
    open(LC, ">$linecountfile");
    for (my $i=1; $i<=$max_ig;$i++){
        $ig_sam_outfile[$i] = $ig_sam_out;
        $ig_sam_outfile[$i] =~ s/.sam.gz$/.$i.sam.gz/;
        open($OUTFILE_IG[$i], "| /bin/gzip -c >$ig_sam_outfile[$i]") or die "error starting gzip $!";
    }
}

my (%igHASH, %igSTART, %igEND, %igSTR, %ig_uniqueCOUNT, %ig_nuCOUNT, %doneIG);
my %ML_IG;
# master list of intergenic
my $igfile = $ARGV[1];
open(IGS, $igfile) or die "cannot find '$igfile'\n";
while(my $line = <IGS>){
    chomp($line);
    my @a = split(/\t/, $line);
    my $line1 = $a[0];
    my ($chr, $start, $end);
    if ($line1 =~ /([^:\t\s]+):(\d+)-(\d+)/){
	$chr = $1;
	$start = $2;
	$end = $3;
    }
    my $igreg = "$chr:$start-$end";
    if ($line1 =~ /\.[1]$/){
	$igreg = $igreg . ".1";
    }
    my $index_st = int($start/1000);
    my $index_end = int($end/1000);
    for (my $index = $index_st; $index <= $index_end; $index++){
	push (@{$igHASH{$chr}[$index]}, $igreg);
    }
    my @igStArray = ();
    my @igEndArray = ();
    $ML_IG{$igreg} = 1;
    push (@igStArray, $start);
    push (@igEndArray, $end);
    $igSTART{$igreg} = \@igStArray;
    $igEND{$igreg} = \@igEndArray;
    $ig_uniqueCOUNT{$igreg} = 0;
    $ig_nuCOUNT{$igreg} = 0;
}

my $CNT_OF_FRAGS_WHICH_HIT_IGS = 0;

my @IG_FLAG_DIST;
my @ig_outfile_cnt;

for (my $i=0;$i<=$max_ig;$i++){
    $ig_outfile_cnt[$i] = 0;
    $IG_FLAG_DIST[$i] = 0;
}
if ($samfile =~ /.gz$/){
    my $pipecmd = "zcat $samfile";
    open(SAM, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
}
else{
    open(SAM, $samfile) or die "cannot open $samfile\n";
}
while(my $line = <SAM>){
    chomp($line);
    if ($line =~ /^@/){
	next;
    }
    $total_lc++;
    my $igFlag = 0;

    my $print_ig = "true";
    my $UNIQUE = "false";
    my $NU = "false";
    my $tag = 0;
    if ($line =~ /(N|I)H:i:(\d+)/){
	$line =~ /(N|I)H:i:(\d+)/;
	$tag = $2;
    }
    if ($tag == 1){
	$UNIQUE = "true";
    }
    else {
	$NU = "true";
    }
    my @readStarts = ();
    my @readEnds = ();
    my @a = split(/\t/, $line);
    my $read_id = $a[0];
    my $bitflag = $a[1];
    my $chr = $a[2];
    my $readSt = $a[3];
    my $cigar = $a[5];
    while ($cigar =~ /(\d+)M(\d+)D(\d+)M/){
	my $N = $1+$2+$3;
	my $str = $1 . "M" . $2 . "D" . $3 . "M";
	my $new_str = $N . "M";
	$cigar =~ s/$str/$new_str/;
    }
    my $spans = &cigar2spans($readSt, $cigar);
#    print "===============\n$read_id\t"; #debug
    my %EXONS = (); #debug
    my %A_EXONS = (); #debug
    my %INTRONS = (); #debug
    my %A_INTRONS = (); #debug
    my %IGS = (); #debug
#    print "$spans\n"; #debug
    my @b = split (",", $spans);
    for (my $i=0; $i<@b; $i++){
	my @c = split("-", $b[$i]);
	my $read_st = $c[0];
	$read_st =~ s/^\s*(.*?)\s*$/$1/;
	my $read_end = $c[1];
	$read_end =~ s/^\s*(.*?)\s*$/$1/;
	push (@readStarts, $read_st);
	push (@readEnds, $read_end);
    }
    undef %doneIG;
    for(my $i=0;$i<@b;$i++){
	#check one span at a time
	my @readStarts_span = ();
	my @readEnds_span = ();
	my @c = split("-", $b[$i]);
	my $read_st = $c[0];
        $read_st =~ s/^\s*(.*?)\s*$/$1/;
	my $read_end = $c[1];
        $read_end =~ s/^\s*(.*?)\s*$/$1/;
        push (@readStarts_span, $read_st);
        push (@readEnds_span, $read_end);

	$b[$i] =~ /(\d+)-(\d+)/;
	my $read_segment_start = $1;
	my $read_segment_end = $2;
	my $read_segment_start_block = int($read_segment_start / 1000);
	my $read_segment_end_block = int($read_segment_end / 1000);
	#print "\n$b[$i]\n------\n";
	my %temp_AE = ();
	for(my $index=$read_segment_start_block; $index<= $read_segment_end_block; $index++) {
	    # check if read span maps to intergenic region
	    if (exists $igHASH{$chr}[$index]){
		my $hashsize = @{$igHASH{$chr}[$index]};
		for (my $j=0; $j<$hashsize; $j++){
		    my $ig = $igHASH{$chr}[$index][$j];
		    my $check = &compareSegments_overlap($chr, $chr, $igSTART{$ig}->[0], $igEND{$ig}->[0], \@readStarts, \@readEnds);
		    if ($check eq "1"){
			if (!(defined $doneIG{$ig})){                            
			    #$IGS{$ig} = 1; #debug
			    $igFlag++;
			    #$ig_mapper++;
			    if($igFlag == 1) {
				$CNT_OF_FRAGS_WHICH_HIT_IGS++;
			    }
			    if ($UNIQUE eq "true"){
				$ig_uniqueCOUNT{$ig}++;
			    }
			    elsif ($NU eq "true"){
				$ig_nuCOUNT{$ig}++;
			    }
			}
			$doneIG{$ig}=1;
		    }
		}
	    }
	}
    }
    # START PRINTING : READ LEVEL NOW
    #ig
    if (($print eq "true") && ($print_ig eq "true")){
        if ($igFlag >= 1){
            print $IGSAMOUT "$line\n";
            for (my $i=1; $i<$max_ig;$i++){
                if ($igFlag == $i){
		    $ig_outfile_cnt[$i]++;
                    print {$OUTFILE_IG[$i]} "$line\n";
                }
            }
            if ($igFlag >= $max_ig){
		$ig_outfile_cnt[$max_ig]++;
                print {$OUTFILE_IG[$max_ig]} "$line\n";
            }
        }
    }
    if ($igFlag > $max_ig){
	$igFlag = $max_ig;
    }
    $IG_FLAG_DIST[$igFlag]++;
=debug
    foreach my $int (sort keys %INTRONS){
	print "INTRON:$int; ";
    }
    print"\n";
=cut
}
close(SAM);

if ($print eq "true"){
    for (my $i=1;$i<=$max_ig;$i++){
        print LC "$ig_sam_outfile[$i]\t$ig_outfile_cnt[$i]\n";
        print {$OUTFILE_IG[$i]} "line count = $ig_outfile_cnt[$i]\n";
        close($OUTFILE_IG[$i]);
    }
}
#intergenicregionquants
open(OUT, ">$igquants");
print OUT "total number of reads which incremented at least one intergenic region: $CNT_OF_FRAGS_WHICH_HIT_IGS\n";
print OUT "feature\tmin\tmax\n";
print OUT "num intergenic regions dist:\n";
for(my $i=0; $i<=$max_ig; $i++) {
    print OUT "$i\t$IG_FLAG_DIST[$i]\n";
}
foreach my $ig (sort {&cmpChrs($a,$b)} keys %ML_IG){
    my $maxcount = $ig_uniqueCOUNT{$ig} + $ig_nuCOUNT{$ig};
    print OUT "$ig\t$ig_uniqueCOUNT{$ig}\t$maxcount\n";
}
close(OUT);

if ($print eq "true"){
    close(LC);
    close($IGSAMOUT);
}
print "got here\n";

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}
sub cigar2spans {
    my ($start, $matchstring) = @_;
    my $spans = "";
    my $current_loc = $start;
    if($matchstring =~ /^(\d+)S/) {
        $matchstring =~ s/^(\d+)S//;
    }
    if($matchstring =~ /(\d+)S$/) {
        $matchstring =~ s/(\d+)S$//;
    }
    $matchstring =~ s/(\d+)I//g;
    while($matchstring =~ /(\d+)M(\d+)M/) {
        my $n1 = $1;
        my $n2 = $2;
        my $n = $n1 + $n2;
        my $str1 = $n1 . "M" . $n2 . "M";
        my $str2 = $n . "M";
        $matchstring =~ s/$str1/$str2/;
    }
    while($matchstring =~ /(\d+)N(\d+)D/) {
        my $n1 = $1;
	my $n2 = $2;
        my $n = $n1 + $n2;
        my $str1 = $n1 . "N" . $n2 . "D";
        my $str2 = $n . "N";
        $matchstring =~ s/$str1/$str2/;
    }
    while($matchstring =~ /(\d+)D(\d+)N/) {
        my $n1 = $1;
        my $n2 = $2;
        my $n = $n1 + $n2;
        my $str1 = $n1 . "D" . $n2 . "N";
        my $str2 = $n . "N";
        $matchstring =~ s/$str1/$str2/;
    }
    if($matchstring =~ /D/) {
        while ($matchstring =~ /(\d+)M(\d+)D(\d+)M/){
	    my $l1 = $1;
	    my $l2 = $2;
	    my $l3 = $3;
	    my $L = $1 + $2 + $3;
	    $L = $L . "M";
	    $matchstring =~ s/\d+M\d+D\d+M/$L/;
	}
    }
    while($matchstring =~ /(\d+)M(\d+)M/) {
        my $n1 = $1;
        my $n2 = $2;
        my $n = $n1 + $n2;
        my $str1 = $n1 . "M" . $n2 . "M";
        my $str2 = $n . "M";
        $matchstring =~ s/$str1/$str2/;
    }
    while($matchstring =~ /^(\d+)([^\d])/) {
        my $num = $1;
        my $type = $2;
        if($type eq 'M') {
            my $E = $current_loc + $num - 1;
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
        for(my $i=0; $i<@b-1; $i++) {
            my @c1 = split(/-/, $b[$i]);
            my @c2 = split(/-/, $b[$i+1]);
            if($c1[1] + 1 >= $c2[0]) {
                my $str = "-$c1[1], $c2[0]";
                $spans =~ s/$str//;
            }
        }
    }
    return $spans;
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
            foreach my $tempkey (sort {&cmpChrs($a,$b)} keys %temphash) {
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
                foreach my $tempkey (sort {&cmpChrs($a,$b)} keys %temphash) {
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
sub arabic($) {
    my $arg = shift;
    my %roman2arabic = qw(I 1 V 5 X 10 L 50 C 100 D 500 M 1000);
    my %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
    my  @figure = reverse sort keys %roman_digit;
    $roman_digit{$_} = [split(//, $roman_digit{$_}, 2)] foreach @figure;
    isroman($arg) or return undef;
    my ($last_digit) = 1000;
    my $arabic=0;
    foreach (split(//, uc $arg)) {
	my ($digit) = $roman2arabic{$_};
	$arabic -= 2 * $last_digit if $last_digit < $digit;
	$arabic += ($last_digit = $digit);
    }
    $arabic;
}
sub isroman($) {
    my $arg = shift;
    return $arg ne '' and
	$arg =~ /^(?: M{0,3})
                 (?: D?C{0,3} | C[DM])
                 (?: L?X{0,3} | X[LC])
                 (?: V?I{0,3} | I[VX])$/ix;
}


# The *Starts and *Ends variables are references to arrays of starts and ends
# for one transcript and one read respectively. 
# Coordinates are assumed to be 1-based/right closed.
sub checkCompatibility {
    my ($txChr, $txStarts, $txEnds, $readChr, $readStarts, $readEnds) = @_;
    my $singleSegment  = scalar(@{$readStarts})==1 ? 1: 0;
    my $singleExon = scalar(@{$txStarts})==1 ? 1 : 0;
    # Check whether read overlaps transcript
    if ($txChr ne $readChr || $readEnds->[scalar(@{$readEnds})-1]<$txStarts->[0] || $readStarts->[0]>$txEnds->[scalar(@{$txEnds})-1]) {
	#print STDERR  "Read does not overlap transcript\n";
	return(0);
    }
  
    # Check whether read stradles transcript
    elsif (!$singleSegment) {
	my $stradle;
	for (my $i=0; $i<scalar(@{$readStarts})-1; $i++) {
	    if ($readEnds->[$i]<$txStarts->[0] && $readStarts->[$i+1]>$txEnds->[scalar(@{$txEnds})-1]) {
		$stradle = 1;
		last;
	    }
	}
	if ($stradle) {
	    #print STDERR  "Read stradles transcript\n";
	    return(0);
	}
	elsif ($singleExon) {
	    my $compatible;
	    $compatible = &compareSegments2($txStarts->[0], $txEnds->[0], $readStarts, $readEnds);
	    if ($compatible){
		return(1);
	    }
	    else{
		#print STDERR "HERE\n";
		return(0);
	    }
	}
	else {
	    my $readJunctions = &getJunctions($readStarts, $readEnds);
	    my $txJunctions = &getJunctions($txStarts, $txEnds);
	    my ($intronStarts, $intronEnds) = &getIntrons($txStarts, $txEnds);
	    my $intron = &overlaps($readStarts, $readEnds, $intronStarts, $intronEnds );
	    my $compatible = &compareJunctions($txJunctions, $readJunctions);
	    if (!$intron && $compatible) {
		#print STDERR "Read is compatible with transcript\n";
		return(1);
	    }
	    else{
		#print STDERR "Read overlaps intron(s) or is incompatible with junctions\n";
		return(0);
	    }
	}
    }
    else {
	my $intron = 0;
	if (!$singleExon) {
	    my ($intronStarts, $intronEnds) = &getIntrons($txStarts, $txEnds);
	    $intron = &overlaps($readStarts, $readEnds, $intronStarts, $intronEnds ); 
	}
	my $compatible = &compareSegments($txStarts, $txEnds, $readStarts->[0], $readEnds->[0]);
	if (!$intron && $compatible) {
	    #print STDERR "Read is compatible with transcript\n";
	    return(1);
	}
	else{
	    #print STDERR "Read overlaps intron(s) or is incompatible with junctions\n";
	    return(0);
	}
    }
}

sub getJunctions {
  my ($starts, $ends) = @_;
  my $junctions = "s: $ends->[0], e: $starts->[1]";
  for (my $i=1; $i<@{$ends}-1; $i++) {
    $junctions .= ", s: $ends->[$i], e: $starts->[$i+1]";
  }
  return($junctions);
}

sub getIntrons {
  my ($txStarts, $txEnds) = @_;
  my ($intronStarts, $intronEnds);
  for (my $i=0; $i<@{$txStarts}-1; $i++) {
    push(@{$intronStarts}, $txEnds->[$i]+1);
    push(@{$intronEnds}, $txStarts->[$i+1]-1);
  }
  return($intronStarts, $intronEnds);
}

sub overlaps {
  my ($starts1, $ends1, $starts2, $ends2) = @_;
  my $overlap = 0;

  if (!($ends1->[@{$ends1}-1]<$starts2->[0]) && !($ends2->[@{$ends2}-1]<$starts1->[0])) {
    for (my $i=0; $i<@{$starts1}; $i++) {
      for (my $j=0; $j<@{$starts2}; $j++) {
	if ($starts1->[$i]<$ends2->[$j] && $starts2->[$j]<$ends1->[$i]) {
	  $overlap =  1;
	  last;
	}
      }
    }
  }
  return($overlap);
}

sub compareJunctions {
  my ($txJunctions, $readJunctions) = @_;
  my $compatible = 0; 
  if (index($txJunctions, $readJunctions)!=-1) {
    $compatible = 1;
  } 
  return($compatible);
}

sub compareSegments {
  my ($txStarts, $txEnds, $readStart, $readEnd) = @_;
  my $compatible = 0;
  for (my $i=0; $i<scalar(@{$txStarts}); $i++) {
    if ($readStart>=$txStarts->[$i] && $readEnd<=$txEnds->[$i] ) {
      $compatible = 1;
      last;
    }
  }
  return($compatible);
}

sub compareSegments2 { #1exon case
    my ($exonStart, $exonEnd, $readStarts, $readEnds) = @_;
    my $compatible = 0;
    for (my $i=0; $i<scalar(@{$readStarts});$i++){
	if (((($i==0) && ($readStarts->[$i] >= $exonStart)) || (($i>0) && ($readStarts->[$i] == $exonStart))) && ((($i==scalar(@{$readStarts}-1)) && ($readEnds->[$i] <= $exonEnd)) || (($i<scalar(@{$readStarts}-1)) && ($readEnds->[$i] == $exonEnd)))){
	    $compatible = 1;
	}
    }
    return($compatible);
}

# The *Starts and *Ends variables are references to arrays of starts and ends
sub compareSegments_overlap {
    my ($exonChr, $readChr, $exonStart, $exonEnd, $readStarts, $readEnds) = @_;
    my $compatible = 0;
    if ($exonChr eq $readChr){
	for (my $i=0; $i<scalar(@{$readStarts});$i++){
	    if (($readEnds->[$i] >= $exonStart) && ($readStarts->[$i] <= $exonEnd)){ # if read overlaps exon
		$compatible = 1;
	    }
	}
    }
    return($compatible);
}
