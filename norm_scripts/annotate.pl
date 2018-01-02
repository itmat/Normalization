use warnings;
use strict; 

if(@ARGV<3) { 
    die "usage: annotate.pl <annotation file> <features file> <outputfile> [option]

the <annotation file> should be downloaded from UCSC known-gene track including
at minimum the following suffixes: name (this should correspond to your main identifier, typically some kind of transcript id), chrom, exonStarts, exonEnds, geneSymbol.

Each of the above suffixes should not appear in more than one column header.

the <features file> should have features formatted as:
chr:start-end
where start and end are positive integers
chr is the name of the chromosome (or contig), names cannot have colon, semi-colon, comma or whitespace.

option:
-readlength <n> : use this option if -readlength option was used for generating master list of exons.
-exon
-intron

";
}

my $annotation_file = $ARGV[0];
my $features_file = $ARGV[1];
my $output_file = $ARGV[2];

my $readlength = 0;
my $eflag = "false";
my $iflag = "false";
for(my $i=3; $i<@ARGV; $i++) {
    my $opt_rec = "false";
    if ($ARGV[$i] eq '-readlength'){
	$readlength = $ARGV[$i+1];
	$i++;
	$opt_rec = "true";
    }
    if ($ARGV[$i] eq '-exon'){
	$eflag = "true";
	$opt_rec = "true";
    }
    if ($ARGV[$i] eq '-intron'){
	$iflag = "true";
	$opt_rec = "true";
    }
    if ($opt_rec eq "false"){
	die "option $ARGV[$i] is not recognized\n";
    }
}

open(INFILE, $annotation_file) or die "file '$annotation_file' cannot open for reading.\n";
open(OUT, ">$output_file") or die "cannot open $output_file\n";
my $line = <INFILE>;
chomp($line);
my @ANNOTHEADER = split(/\t/,$line);

my ($exonstartscol, $exonendscol, $genesymbolcol, $chromcol, $namecol);

for(my $i=0; $i<@ANNOTHEADER; $i++) {
  if($ANNOTHEADER[$i] =~ /exonStarts$/) {
    $exonstartscol = $i;
  }
  if($ANNOTHEADER[$i] =~ /exonEnds$/) {
    $exonendscol = $i;
  }
  if($ANNOTHEADER[$i] =~ /name$/) {
    $namecol = $i;
  }
  if($ANNOTHEADER[$i] =~ /chrom$/) {
    $chromcol = $i;
  }
  if($ANNOTHEADER[$i] =~ /geneSymbol$/) {
    $genesymbolcol = $i;
  }
}

if (!defined($namecol) || !defined($chromcol) || !defined($exonstartscol) || !defined($exonendscol) || !defined($genesymbolcol)) { 
  die "Your header must contain columns with the following suffixes: name, chrom, starts, ends\n";
}

my $SYMBOL;
my (%GS, %GE, %CHR);
my $feature_overlaps_block;
while($line = <INFILE>) {
  chomp($line);
  my @a = split(/\t/, $line);
  my $chr = $a[$chromcol];
  my $exonSt = $a[$exonstartscol];
  my $exonEnd = $a[$exonendscol];
  my $symbol = $a[$genesymbolcol];
  $exonSt =~ s/\s*,\s*$//;
  $exonSt =~ s/^\s*,\s*//;
  $exonEnd =~ s/\s*,\s*$//;
  $exonEnd =~ s/^\s*,\s*//;
  my @S = split(/,/,$exonSt);
  my @E = split(/,/,$exonEnd);
  my $N = @S;
  my $gstart = $S[0] - (2 * $readlength);
  my $gend = $E[@E-1] - (2 * $readlength);
  $CHR{$symbol} = $chr;
  if (exists $GS{$symbol}){
      my $olds = $GS{$symbol};
      my $olde = $GE{$symbol};
      if ($gstart < $olds){
	  $GS{$symbol} = $gstart;
      }
      if ($gend > $olde){
	  $GE{$symbol} = $gend;
      }
  }
  else{
      $GS{$symbol} = $gstart;
      $GE{$symbol} = $gend;
  }
  if ($eflag eq 'true'){
      for(my $e=0; $e<$N; $e++) {
	  if ($e == 0){
	      $S[$e] = $S[$e] - (2 * $readlength);
	  }
	  if ($e == $N-1){
	      $E[$e] = $E[$e] + (2 * $readlength);
	  }
	  if ($S[$e] < 0){
	      $S[$e] = 0;
	  }
	  $S[$e]++;
	  my $exon = "$chr:$S[$e]-$E[$e]";
	  push(@{$SYMBOL->{$exon}}, $symbol);
      }
  }
  if ($iflag eq 'true'){
      for(my $e=0; $e<$N-1; $e++) {
	  $E[$e]++;
	  my $intron = "$chr:$E[$e]-$S[$e+1]";
	  push(@{$SYMBOL->{$intron}}, $symbol);
      }
  }
  for(my $i=0; $i<@S; $i++) {
    my $start0 = $S[$i] + 1;
    my $end0 = $E[$i];
    my $chr = $a[$chromcol];
    my $base = $chr . ":" . $start0 . "-" . $end0;  
    for(my $i1=0; $i1<2; $i1++) {
      for(my $i2=0; $i2<2; $i2++) {
	my $start = $start0 + $i1;
	my $end = $end0 + $i2;
	my $exon = $chr . ":" . $start . "-" . $end;
	my $exonS = $chr . ":" . $start;
	my $exonE = $chr . ":" . $end;
	push(@{$SYMBOL->{$exon}}, $a[$genesymbolcol]);
	push(@{$SYMBOL->{$exonS}}, $a[$genesymbolcol]);
	push(@{$SYMBOL->{$exonE}}, $a[$genesymbolcol]);
	my $start_block = int($start / 1000);
	my $end_block = int($end / 1000);
	for(my $j=$start_block; $j<=$end_block; $j++) {
	  push(@{$feature_overlaps_block->{$chr}->{$j}},$exon);  # all exons that overlap the jth span of 1K bases
	}
      }
    }
  }
  for(my $i=0; $i<@S-1; $i++) {
    my $start0 = $E[$i]+1;
    my $end0 = $S[$i+1];
    my $chr = $a[$chromcol];
    my $base = $chr . ":" . $start0 . "-" . $end0; 
    for(my $i1=0; $i1<2; $i1++) {
      for(my $i2=0; $i2<2; $i2++) {
	my $start = $start0 + $i1;
	my $end = $end0 + $i2;
	my $intron = $chr . ":" . $start . "-" . $end;
	my $intronS = $chr . ":" . $start;
	my $intronE = $chr . ":" . $end;
	push(@{$SYMBOL->{$intron}}, $a[$genesymbolcol]);
	push(@{$SYMBOL->{$intronS}}, $a[$genesymbolcol]);
	push(@{$SYMBOL->{$intronE}}, $a[$genesymbolcol]);
	my $start_block = int($start / 1000);
	my $end_block = int($end / 1000);
	for(my $j=$start_block; $j<=$end_block; $j++) {
	  push(@{$feature_overlaps_block->{$chr}->{$j}},$intron);  # all introns that overlap the jth span of 1K bases
	}
      }
    }
  }
}
close(INFILE);
foreach my $gs (keys %GS){
    my $gene = "$CHR{$gs}:$GS{$gs}-$GE{$gs}";
    push(@{$SYMBOL->{$gene}}, $gs);
}
open(INFILE, $features_file) or die "file '$features_file' cannot open for reading.\n";
my $header = <INFILE>;
chomp($header);
print OUT "$header\tgeneSymbol\n";
while($line = <INFILE>) {
  chomp($line);
  if(!($line =~ /[^\s:,;]+:\d+-\d+/)) {
    next;
  }
  $line =~ /([^\s:,;]+:\d+-\d+)/;
  my  $feature = $1;
  my  $featureS = $feature;
  $featureS =~ s/:\d+-/:/;
  my $featureE = $feature;
  $featureE =~ s/-\d+$//;
  print OUT "$line"; 
  if(defined $SYMBOL->{$feature}) {
      my @unique = &uniq(@{$SYMBOL->{$feature}});
#      print OUT "\tANOT:" . join(',', @unique);
      print OUT "\t" . join(',', @unique);
      print OUT "\n";
      next;
  } 
  elsif(defined $SYMBOL->{$featureS}) {
      my @unique = &uniq(@{$SYMBOL->{$featureS}});
#      print OUT "\tANOT_S:" . join(',', @unique);
      print OUT "\t" . join(',', @unique);
      print OUT "\n";
      next;
  } 
  elsif(defined $SYMBOL->{$featureE}) {
      my @unique = &uniq(@{$SYMBOL->{$featureE}});
#      print OUT "\tANOT_E:" . join(',', @unique);
      print OUT "\t" . join(',', @unique);
      print OUT "\n";
      next;
  } 
  else {
      $feature =~ /(.*):(\d+)-(\d+)$/;
      my $feature_chr = $1;
      $featureS = $2;
      $featureE = $3;
      my $start_block = int($featureS / 1000);
      my $end_block = int($featureE / 1000);
      my $min = 100000000;
      my $flag = 0;
      my ($annotS, $annotN, $annotD) = ('', '', '');
      my $inside = "false";
      for(my $j=$start_block; $j<=$end_block; $j++) {
	  my $NN = defined($feature_overlaps_block->{$feature_chr}->{$j}) ? @{$feature_overlaps_block->{$feature_chr}->{$j}} : 0;
	  for(my $k=0; $k<$NN; $k++) {
	      my $feature_o = $feature_overlaps_block->{$feature_chr}->{$j}->[$k];
	      $feature_o =~ /.*:(\d+)-(\d+)$/;
	      my $start_o = $1;
	      my $end_o = $2;
	      # if completely inside exon
	      if (($featureS >= $start_o) && ($featureE <= $end_o) && ($featureE >= $start_o) && ($featureS <= $end_o)){
		  my @unique = &uniq(@{$SYMBOL->{$feature_o}});
		  $annotS = join (',', @unique);
		  $inside = "true";
	      }
	  }
      }
      if ($inside eq "true"){
#	  print OUT "\tINSIDE:$annotS\n";
	  print OUT "\t$annotS\n";
	  next;
      }
      else{
	  my @to_printf;
	  my @to_printl;
	  for(my $j=$start_block; $j<=$end_block; $j++) {
	      my $NN = defined($feature_overlaps_block->{$feature_chr}->{$j}) ? @{$feature_overlaps_block->{$feature_chr}->{$j}} : 0;
	      for(my $k=0; $k<$NN; $k++) {
		  my $feature_o = $feature_overlaps_block->{$feature_chr}->{$j}->[$k];
		  $feature_o =~ /.*:(\d+)-(\d+)$/;
		  my $start_o = $1;
		  my $end_o = $2;
		  if(abs($featureS - $start_o) < $min) {
		      $min = abs($featureS - $start_o);
		      my @unique = &uniq(@{$SYMBOL->{$feature_o}});
                      if ($min <= 100000){
                          foreach my $sym (@unique){
                              push (@to_printf, $sym);
                          }
		      }
		      else{
                          foreach my $sym (@unique){
                              push (@to_printl, $sym);
                          }
                      }
		  }
		  if(abs($featureE - $start_o) < $min) {
		      $min = abs($featureE - $start_o);
		      my @unique = &uniq(@{$SYMBOL->{$feature_o}});
                      if ($min <= 100000){
                          foreach my $sym (@unique){
                              push (@to_printf, $sym);
                          }
		      }
		      else{
                          foreach my $sym (@unique){
                              push (@to_printl, $sym);
                          }
                      }
		  }
		  if(abs($featureS - $end_o) < $min) {
		      my @unique = &uniq(@{$SYMBOL->{$feature_o}});
		      $min = abs($featureS - $end_o);
                      if ($min <= 100000){
                          foreach my $sym (@unique){
                              push (@to_printf, $sym);
                          }
		      }
		      else{
                          foreach my $sym (@unique){
                              push (@to_printl, $sym);
                          }
                      }
		  }
		  if(abs($featureE - $end_o) < $min) {
		      $min = abs($featureE - $end_o);
		      my @unique = &uniq(@{$SYMBOL->{$feature_o}});
		      if ($min <= 100000){
			  foreach my $sym (@unique){
			      push (@to_printf, $sym);
			  }
		      }
		      else{
                          foreach my $sym (@unique){
                              push (@to_printl, $sym);
                          }
		      }
		  }
	      }
	  }
	  my @uniquef = &uniq(@to_printf);
	  $annotS =  join(',', @uniquef);
	  my @uniquel = &uniq(@to_printl);
	  if (@uniquel > 0){
	      if (@uniquef > 0){
		  $annotS .= ",$min bases from" . join(',',@uniquel);
	      }
	      else{
		  $annotS .= "$min bases from" . join(',',@uniquel);
	      }
	  }
	  print OUT "\t$annotS\n";
	  next;
      }
  }
}
print "got here\n";
sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}
