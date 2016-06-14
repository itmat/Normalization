#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "perl sam2genes.pl <samfile> <ensGene file> <outfile>

<samfile> input samfile (full path)
<ensGene file> ensGenes file (full path)
<outfile> output file (full path)

options:
 -str_f : if forward read is in the same orientation as the transcripts/genes.
 -str_r : if reverse read is in the same orientation as the transcripts/genes.
 -se : set this if the data are single end, otherwise by default it will assume it's a paired end data.
";

if (@ARGV < 3){
    die $USAGE;
}

my $FWD = "false";
my $REV = "false";
my $pe = "true";
my $numargs = 0;
my $stranded = "false";
for(my $i=3; $i<@ARGV; $i++) {
    my $option_found = "false";
    if($ARGV[$i] eq '-str_f') {
	$FWD = "true";
	$stranded = "true";
	$numargs++;
	$option_found = "true";
    }
    if($ARGV[$i] eq '-str_r') {
	$REV = "true";
	$stranded = "true";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-se'){
	$pe = "false";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($stranded eq "true"){
    if($numargs ne '1') {
	die "You can only use one of the options \"-str_f\" or \"-str_r\".\n";
    }
}


my $samfile = $ARGV[0];
my $ens_file = $ARGV[1];
my $outfile = $ARGV[2];
my (%txHASH, %exSTARTS, %exENDS, %geneHASH, %geneSYMBOL, %geneSTR, %done);

open(ENS, $ens_file) or die "cannot find file \"$ens_file\"\n";
my $header = <ENS>;
chomp($header);
my @ENSHEADER = split(/\t/, $header);
my ($txnamecol, $txchrcol, $txstartcol, $txendcol, $exstartscol, $exendscol, $genenamecol, $genesymbolcol, $strandcol);
for(my $i=0; $i<@ENSHEADER; $i++){
    if ($ENSHEADER[$i] =~ /strand$/){
	$strandcol = $i;
    }
    if ($ENSHEADER[$i] =~ /name$/){
	$txnamecol = $i;
    }
    if ($ENSHEADER[$i] =~ /chrom$/){
	$txchrcol = $i;
    }
    if ($ENSHEADER[$i] =~ /txStart$/){
	$txstartcol = $i;
    }
    if ($ENSHEADER[$i] =~ /txEnd$/){
	$txendcol = $i;
    }
    if ($ENSHEADER[$i] =~ /exonStarts$/){
        $exstartscol = $i;
    }
    if ($ENSHEADER[$i] =~ /exonEnds$/){
        $exendscol = $i;
    }
    if ($ENSHEADER[$i] =~ /name2$/){
        $genenamecol = $i;
    }
    if ($ENSHEADER[$i] =~ /ensemblToGeneName.value$/){
	$genesymbolcol = $i;
    }
}

if (!defined($txnamecol) || !defined($txchrcol) || !defined($txstartcol) || !defined($txendcol) || !defined($exstartscol) || !defined($exendscol) || !defined($genenamecol) || !defined($genesymbolcol) || !defined($strandcol)){
    die "Your header must contain columns with the following suffixes: name, chrom, strand, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value\n";
}

while(my $line = <ENS>){
    chomp($line);
    my @a = split(/\t/, $line);
    my $tx_id = $a[$txnamecol];
    my $tx_chr = $a[$txchrcol];
    my $tx_start_loc = $a[$txstartcol] + 1;
    my $tx_end_loc = $a[$txendcol];
    my $tx_exonStarts = $a[$exstartscol];
    my $tx_exonEnds = $a[$exendscol];
    my $gene_id = $a[$genenamecol];
    my $gene_symbol = $a[$genesymbolcol];
    my $tx_strand = $a[$strandcol];
    #index by chr and first 1-3 digits of txStart and txEnd
    my $index_st = int($tx_start_loc/1000000);
    my $index_end = int($tx_end_loc/1000000);
    for (my $index = $index_st; $index <= $index_end; $index++){
	push (@{$txHASH{$tx_chr}[$index]}, $tx_id);
    }
    #exStarts and exEnds into HASH
    my @tx_starts = split(",", $tx_exonStarts);
    for (my $i = 0; $i<@tx_starts; $i++){
	$tx_starts[$i] = $tx_starts[$i] + 1;
    }
    my @tx_ends = split(",", $tx_exonEnds);
    $exSTARTS{$tx_id} = \@tx_starts;
    $exENDS{$tx_id} = \@tx_ends;
    #genehash with tx_id as key
    $geneHASH{$tx_id} = $gene_id;
    $geneSYMBOL{$gene_id} = $gene_symbol;
    $geneSTR{$gene_id} = $tx_strand;
}
close(ENS);

open(SAM, $samfile) or die "cannot find file \"$samfile\"\n";
open(OUT, ">$outfile");
print OUT "readID\ttranscriptIDs\tgeneIDs\tgeneSymbols\t(N|I)H-HI\n";
while(my $line = <SAM>){
    chomp($line);
    if ($line =~ /^@/){
	next;
    }
    my $hi_tag = 0;
    my $ih_tag = 0;
    if ($line =~ /HI:i:(\d+)/){
	$line =~ /HI:i:(\d+)/;
	$hi_tag = $1;
    }
    if ($line =~ /(N|I)H:i:(\d+)/){
	$line =~ /(N|I)H:i:(\d+)/;
	$ih_tag = $2;
    }
    my $ih_hi = "$ih_tag:$hi_tag";
    my @readStarts = ();
    my @readEnds = ();
    my @txIDs = ();
    my @a = split(/\t/, $line);
    my $read_id = $a[0];
    my $flag = $a[1];
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
    undef %done;
    for(my $i=0;$i<@b;$i++){
        $b[$i] =~ /(\d+)-(\d+)/;
        my $read_segment_start = $1;
        my $read_segment_end = $2;
        my $read_segment_start_block = int($read_segment_start / 1000000);
        my $read_segment_end_block = int($read_segment_end / 1000000);
        for(my $index=$read_segment_start_block; $index<= $read_segment_end_block; $index++) {
	    if (exists $txHASH{$chr}[$index]){
		my $hashsize = @{$txHASH{$chr}[$index]};
		for (my $j=0; $j<$hashsize; $j++){
		    my $tx_id = $txHASH{$chr}[$index][$j];
		    unless ($flag & 4){
			my $check = &checkCompatibility($chr, $exSTARTS{$tx_id}, $exENDS{$tx_id}, $chr, \@readStarts, \@readEnds);
			if (!(defined $done{$tx_id})){
			    if ($check eq "1"){
				push(@txIDs, $tx_id);
			    }
			}
			$done{$tx_id}=1;
		    }
		}
	    }
	}
    }
    my @uniquetxIDs = &uniq(@txIDs);
    my @geneIDs = ();
    my $txID_list = "";
    for(my $i=0; $i<@uniquetxIDs; $i++){
	$txID_list = $txID_list . "$uniquetxIDs[$i],";
	push (@geneIDs, $geneHASH{$uniquetxIDs[$i]});
    }
    my @unique_gene_ids = &uniq(@geneIDs);
    my $array_size = @unique_gene_ids;
    my $geneID_list = "";
    my $symbol_list = "";
    if ($stranded eq "true"){
	my $read_strand = "";
	#paired end
	if ($pe eq "true"){
	    if ($FWD eq "true"){
		if ($flag & 64){ #forward read
		    if ($flag & 16){ 
			$read_strand = "-";
		    }
		    elsif ($flag & 32){
			$read_strand = "+";
		    }
		    if ($array_size == 1){
			if ($read_strand eq $geneSTR{$unique_gene_ids[0]}){
			    $geneID_list = "$unique_gene_ids[0]";
			    $symbol_list = $geneSYMBOL{$unique_gene_ids[0]};
			}
			else{
			    $geneID_list = "ANTI:$unique_gene_ids[0]";
			    $symbol_list = "ANTI:$geneSYMBOL{$unique_gene_ids[0]}";
			}
		    }
		    elsif ($array_size > 1){
			for(my $i=0; $i<$array_size;$i++){
			    if ($read_strand eq $geneSTR{$unique_gene_ids[$i]}){
				$geneID_list = $geneID_list . "$unique_gene_ids[$i],";
				$symbol_list = $symbol_list . "$geneSYMBOL{$unique_gene_ids[$i]},";
			    }
			    else{
				$geneID_list = $geneID_list . "ANTI:$unique_gene_ids[$i],";
				$symbol_list = $symbol_list . "ANTI:$geneSYMBOL{$unique_gene_ids[$i]},";
			    }
			}
		    }
		}
		else{
		    if ($array_size == 1){
			$geneID_list = "$unique_gene_ids[0]";
			$symbol_list = $geneSYMBOL{$unique_gene_ids[0]};
		    }
		    elsif ($array_size > 1){
			for(my $i=0; $i<$array_size;$i++){
			    $geneID_list = $geneID_list . "$unique_gene_ids[$i],";
			    $symbol_list = $symbol_list . "$geneSYMBOL{$unique_gene_ids[$i]},";
			}
		    }
		}
	    }
	    if ($REV eq "true"){
		if ($flag & 128){ #revese read
		    if ($flag & 16){
			$read_strand = "-";
		    }
		    elsif ($flag & 32){
			$read_strand = "+";
		    }
		    if ($array_size == 1){
			if ($read_strand eq $geneSTR{$unique_gene_ids[0]}){
			    $geneID_list = "$unique_gene_ids[0]";
			    $symbol_list = $geneSYMBOL{$unique_gene_ids[0]};
			}
			else{
                            $geneID_list = "ANTI:$unique_gene_ids[0]";
			    $symbol_list = "ANTI:$geneSYMBOL{$unique_gene_ids[0]}";
			}
		    }
		    elsif ($array_size > 1){
			for(my $i=0; $i<$array_size;$i++){
			    if ($read_strand eq $geneSTR{$unique_gene_ids[$i]}){
				$geneID_list = $geneID_list . "$unique_gene_ids[$i],";
				$symbol_list = $symbol_list . "$geneSYMBOL{$unique_gene_ids[$i]},";
			    }
                            else{
                                $geneID_list = $geneID_list . "ANTI:$unique_gene_ids[$i],";
                                $symbol_list = $symbol_list . "ANTI:$geneSYMBOL{$unique_gene_ids[$i]},";
                            }
			}
		    }
		}
		else{
		    if ($array_size == 1){
			$geneID_list = "$unique_gene_ids[0]";
			$symbol_list = $geneSYMBOL{$unique_gene_ids[0]};
		    }
		    elsif ($array_size > 1){
			for(my $i=0; $i<$array_size;$i++){
			    $geneID_list = $geneID_list . "$unique_gene_ids[$i],";
			    $symbol_list = $symbol_list . "$geneSYMBOL{$unique_gene_ids[$i]},";
			}
		    }
		}
	    }
	}
	#single end
	if ($pe eq "false"){
	    if ($FWD eq "true"){
		if ($flag & 16){
		    $read_strand = "-";
		}
		else{
		    $read_strand = "+";
		}
	    }
	    if ($REV eq "true"){
		if ($flag & 16){
		    $read_strand = "+";
		}
		else{
		    $read_strand = "-";
		}
	    }
	    if ($array_size == 1){
		if ($read_strand eq $geneSTR{$unique_gene_ids[0]}){
		    $geneID_list = "$unique_gene_ids[0]";
		    $symbol_list = $geneSYMBOL{$unique_gene_ids[0]};
		}
		else{
		    $geneID_list = "ANTI:$unique_gene_ids[0]";
		    $symbol_list = "ANTI:$geneSYMBOL{$unique_gene_ids[0]}";
		}
	    }
	    elsif ($array_size > 1){
		for(my $i=0; $i<$array_size;$i++){
		    if ($read_strand eq $geneSTR{$unique_gene_ids[$i]}){
			$geneID_list = $geneID_list . "$unique_gene_ids[$i],";
			$symbol_list = $symbol_list . "$geneSYMBOL{$unique_gene_ids[$i]},";
		    }
		    else{
			$geneID_list = $geneID_list . "ANTI:$unique_gene_ids[$i],";
			$symbol_list = $symbol_list . "ANTI:$geneSYMBOL{$unique_gene_ids[$i]},";
		    }
		}
	    }
	}
    }
    if ($stranded eq "false"){
	if ($array_size == 1){
	    $geneID_list = $unique_gene_ids[0];
	    $symbol_list = $geneSYMBOL{$unique_gene_ids[0]};
	}
	elsif ($array_size > 1){
	    for(my $i=0; $i<$array_size;$i++){
		$geneID_list = $geneID_list . "$unique_gene_ids[$i],";
		$symbol_list = $symbol_list . "$geneSYMBOL{$unique_gene_ids[$i]},";
	    }
	}
    }
    print OUT "$read_id\t$txID_list\t$geneID_list\t$symbol_list\t$ih_hi\n";
}
close(SAM);
close(OUT);
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

# The *Starts and *Ends variables are references to arrays of starts and ends
# for one transcript and one read respectively. 
# Coordinates are assumed to be 1-based/right closed.
sub checkCompatibility {
  my ($txChr, $txStarts, $txEnds, $readChr, $readStarts, $readEnds) = @_;
  my $singleSegment  = scalar(@{$readStarts})==1 ? 1: 0;
  my $singleExon = scalar(@{$txStarts})==1 ? 1 : 0;

  # Check whether read overlaps transcript
  if ($txChr ne $readChr || $readEnds->[scalar(@{$readEnds})-1]<$txStarts->[0] || $readStarts->[0]>$txEnds->[scalar(@{$txEnds})-1]) {
#    print STDERR  "Read does not overlap transcript\n";
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
#      print STDERR  "Read stradles transcript\n";
      return(0);
    }
    elsif ($singleExon) {
#      print STDERR "Transcript has one exon but read has more than one segment\n";
      return(0);
    }
    else {
      my $readJunctions = &getJunctions($readStarts, $readEnds);
      my $txJunctions = &getJunctions($txStarts, $txEnds);
      my ($intronStarts, $intronEnds) = &getIntrons($txStarts, $txEnds);
      my $intron = &overlaps($readStarts, $readEnds, $intronStarts, $intronEnds );
      my $compatible = &compareJunctions($txJunctions, $readJunctions);
      if (!$intron && $compatible) {
#	print STDERR "Read is compatible with transcript\n";
	return(1);
      }
      else{
#	print STDERR "Read overlaps intron(s) or is incompatible with junctions\n";
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
#      print STDERR "Read is compatible with transcript\n";
      return(1);
    }
    else{
#      print STDERR "Read overlaps intron(s) or is incompatible with junctions\n";
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

