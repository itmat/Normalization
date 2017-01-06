#!/usr/bin/env perl
use strict;
use warnings;
if (@ARGV < 2){
    die "usage: perl unique_merge_samfiles.pl <sample id> <loc> [options]

where:
<sample id> is sample id (directory name)
<loc> is the path to the sample directories

option: 
  -normdir <s>

  -stranded : set this if your data are strand-specific.

  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.
";
}


my $NU = "true";
my $U = "true";
my $numargs = 0;
my $stranded = "false";
my $normdir = "";
my $ncnt = 0;
for(my$i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-normdir'){
	$option_found = "true";
	$normdir = $ARGV[$i+1];
	$i++;
	$ncnt++;
    }
    if($ARGV[$i] eq '-u') {
	$NU = "false";
	$numargs++;
	$option_found = "true";
    }
    if ($ARGV[$i] eq '-stranded'){
	$stranded = "true";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}
if($numargs > 1) {
    die "you cannot specify both -u and -nu, it will output both unique
and non-unique by default so if that's what you want don't use either arg
-u or -nu.
";
}

if ($ncnt ne '1'){
    die "please specify -normdir path\n";
}
my $LOC = $ARGV[1];
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $loc_study = $LOC;
$loc_study =~ s/$last_dir//;
my $norm_dir = "$normdir/EXON_INTRON_JUNCTION/FINAL_SAM/";
my $norm_exon_dir = $norm_dir . "/exonmappers";
my $norm_intron_dir = $norm_dir . "/intronmappers";
my $norm_ig_dir = $norm_dir . "/intergenicmappers";
my $norm_und_dir = $norm_dir . "/exon_inconsistent";
my $norm_merged_dir = $norm_dir . "/merged";
unless (-d $norm_merged_dir){
    `mkdir $norm_merged_dir`;
}
my ($norm_exon_dir_a,  $norm_intron_dir_a);
if ($stranded eq "true"){
    $norm_exon_dir = $norm_dir . "/exonmappers/sense";
    $norm_exon_dir_a = $norm_dir . "/exonmappers/antisense";
    $norm_intron_dir = $norm_dir . "/intronmappers/sense";
    $norm_intron_dir_a = $norm_dir . "/intronmappers/antisense";
}

my $id = $ARGV[0];
my ($exonfile, $exonfile_a, $intronfile, $intronfile_a, $igfile, $undfile);
my $outfile = "$norm_merged_dir/$id.merged.sam";
open(OUTFILE, ">$outfile");
if ($numargs eq '0'){    
    $exonfile = "$norm_exon_dir/$id.exonmappers.norm.sam";
    $intronfile = "$norm_intron_dir/$id.intronmappers.norm.sam";
    $igfile = "$norm_ig_dir/$id.intergenicmappers.norm.sam";
    $undfile = "$norm_und_dir/$id.exon_inconsistent_reads.norm.sam";
    if ($stranded eq "true"){
	$exonfile_a = "$norm_exon_dir_a/$id.exonmappers.norm.sam";
	$intronfile_a = "$norm_intron_dir_a/$id.intronmappers.norm.sam";
    }
}
elsif ($U eq "true"){
    $exonfile = "$norm_exon_dir/$id.exonmappers.norm.sam";
    $intronfile = "$norm_intron_dir/$id.intronmappers.norm.sam";
    $igfile = "$norm_ig_dir/$id.intergenicmappers.norm.sam";
    $undfile = "$norm_und_dir/$id.exon_inconsistent_reads.norm.sam";
    if ($stranded eq "true"){
	$exonfile_a = "$norm_exon_dir_a/$id.exonmappers.norm.sam";
	$intronfile_a = "$norm_intron_dir_a/$id.intronmappers.norm.sam";
    }
}
elsif ($NU eq "true"){
    $exonfile = "$norm_exon_dir/$id.exonmappers.norm.sam";
    $intronfile = "$norm_intron_dir/$id.intronmappers.norm.sam";
    $igfile = "$norm_ig_dir/$id.intergenicmappers.norm.sam";
    $undfile = "$norm_und_dir/$id.exon_inconsistent_reads.norm.sam";
    if ($stranded eq "true"){
	$exonfile_a = "$norm_exon_dir_a/$id.exonmappers.norm.sam";
	$intronfile_a = "$norm_intron_dir_a/$id.intronmappers.norm.sam";
    }
}
#identify common string and get chr names
my $common_str = "";
my @NAME;
my %CHR = ();
open(EX, $exonfile) or die "Cannot open $exonfile\n";
while (<EX>){
    if (1..1000){
	if ($_ =~ /^@/){
	    next;
	}
	my @a = split (/\t/, $_);
	my $seqname = $a[0];
	$seqname =~ s/[^A-Za-z0-9 ]//g;
	push(@NAME, $seqname);
    }
}
close(EX);

my $last_1000 = `tail -1000 $intronfile`;
my @tail = split(/\n/, $last_1000);
for my $seq (@tail){
    if ($seq !~ /^@/){
	my @a = split (/\t/, $seq);
	my $seqname = $a[0];
	$seqname =~ s/[^A-Za-z0-9 ]//g;
	push(@NAME, $seqname);
    }
}
open(IG, $igfile) or die "Cannot open $igfile\n";
while (<IG>){
    if (1..1000){
	if ($_ =~ /^@/){
	    next;
	}
	my @a = split (/\t/, $_);
	my $seqname = $a[0];
	$seqname =~ s/[^A-Za-z0-9 ]//g;
	push(@NAME, $seqname);
    }
}
close(IG);

my $last_1000_und = `tail -1000 $undfile`;
my @tail_und = split(/\n/, $last_1000_und);
for my $seq (@tail_und){
    if ($seq !~ /^@/){
	my @a = split (/\t/, $seq);
	my $seqname = $a[0];
	$seqname =~ s/[^A-Za-z0-9 ]//g;
	push(@NAME, $seqname);
    }
}

$common_str = &LCP(@NAME);
my %READ_HASH;
# READ IN FILES
# exonmapper file
open(EX, $exonfile) or die "Cannot open $exonfile\n";
while(my $line = <EX>){
    chomp($line);
    if ($line =~ /^@/){
	next;
    }
    my @a = split (/\t/, $line);
    my $readname = $a[0];
    $readname =~ s/[^A-Za-z0-9 ]//g;
    $readname =~ s/$common_str//;
    my $chr = $a[2];
    my ($HI_tag, $IH_tag);
    if ($line =~ /(N|I)H:i:(\d+)/){
	$line =~ /(N|I)H:i:(\d+)/;
	$IH_tag = $2;
    }
    if ($line =~ /HI:i:(\d+)/){
	$line =~ /HI:i:(\d+)/;
	$HI_tag = $1;
    }
    my $for_hash = "$readname:$IH_tag:$HI_tag";
    
    if (exists $READ_HASH{$chr}{$for_hash}){
	next;
    }
    else{
	print OUTFILE "$line\n"; 
	$READ_HASH{$chr}{$for_hash} = 1;
    }
}
close(EX);
if ($stranded eq "true"){
    # exonmapper file
    open(EX_A, $exonfile_a) or die "Cannot open $exonfile_a\n";
    while(my $line = <EX_A>){
	chomp($line);
	if ($line =~ /^@/){
	    next;
	}
	my @a = split (/\t/, $line);
	my $readname = $a[0];
	$readname =~ s/[^A-Za-z0-9 ]//g;
	$readname =~ s/$common_str//;
	my $chr = $a[2];
	my ($HI_tag, $IH_tag);
	if ($line =~ /(N|I)H:i:(\d+)/){
	    $line =~ /(N|I)H:i:(\d+)/;
	    $IH_tag = $2;
	}
	if ($line =~ /HI:i:(\d+)/){
	    $line =~ /HI:i:(\d+)/;
	    $HI_tag = $1;
	    }
	my $for_hash = "$readname:$IH_tag:$HI_tag";
	if (exists $READ_HASH{$chr}{$for_hash}){
	    next;
	}
	else{
	    print OUTFILE "$line\n";
	    $READ_HASH{$chr}{$for_hash} = 1;
	}
    }
    close(EX_A);
}
# intronmapper file
open(INT, $intronfile) or die "Cannot open $intronfile\n";
while(my $line = <INT>){
    chomp($line);
    if ($line =~ /^@/){
	next;
    }
    my @a = split (/\t/, $line);
    my $readname = $a[0];
    $readname =~ s/[^A-Za-z0-9 ]//g;
    $readname =~ s/$common_str//;
    my $chr = $a[2];
    my ($HI_tag, $IH_tag);
    if ($line =~ /(N|I)H:i:(\d+)/){
	$line =~ /(N|I)H:i:(\d+)/;
	$IH_tag = $2;
    }
    if ($line =~ /HI:i:(\d+)/){
	$line =~ /HI:i:(\d+)/;
	$HI_tag = $1;
    }
    my $for_hash = "$readname:$IH_tag:$HI_tag";
    
    if (exists $READ_HASH{$chr}{$for_hash}){
	next;
    }
    else{
	print OUTFILE "$line\n";
	$READ_HASH{$chr}{$for_hash} = 1;
    }
}
close(INT);
if ($stranded eq "true"){
    open(INT_A, $intronfile_a) or die "Cannot open $intronfile_a\n";
    while(my $line = <INT_A>){
	chomp($line);
	if ($line =~ /^@/){
	    next;
	}
	my @a = split (/\t/, $line);
	my $readname = $a[0];
	$readname =~ s/[^A-Za-z0-9 ]//g;
	$readname =~ s/$common_str//;
	my $chr = $a[2];
	my ($HI_tag, $IH_tag);
	if ($line =~ /(N|I)H:i:(\d+)/){
	    $line =~ /(N|I)H:i:(\d+)/;
	    $IH_tag = $2;
	}
	if ($line =~ /HI:i:(\d+)/){
	    $line =~ /HI:i:(\d+)/;
	    $HI_tag = $1;
	}
	my $for_hash = "$readname:$IH_tag:$HI_tag";
	
	if (exists $READ_HASH{$chr}{$for_hash}){
	    next;
	}
	else{
	    print OUTFILE "$line\n";
	    $READ_HASH{$chr}{$for_hash} = 1;
	}
    }
    close(INT_A);
}
#intergenic file
open(IG, $igfile) or die "Cannot open $igfile\n";
while(my $line = <IG>){
    chomp($line);
    if ($line =~ /^@/){
	next;
    }
    my @a = split (/\t/, $line);
    my $readname = $a[0];
    $readname =~ s/[^A-Za-z0-9 ]//g;
    $readname =~ s/$common_str//;
    my $chr = $a[2];
    my ($HI_tag, $IH_tag);
    if ($line =~ /(N|I)H:i:(\d+)/){
	$line =~ /(N|I)H:i:(\d+)/;
	$IH_tag = $2;
    }
    if ($line =~ /HI:i:(\d+)/){
	$line =~ /HI:i:(\d+)/;
	$HI_tag = $1;
    }
    my $for_hash = "$readname:$IH_tag:$HI_tag";
    
    if (exists $READ_HASH{$chr}{$for_hash}){
	next;
    }
    else{
	print OUTFILE "$line\n";
	$READ_HASH{$chr}{$for_hash} = 1;
    }
}
close(IG);
#exon_inconsistent 
open(UND, $undfile) or die "Cannot open $undfile\n";
while(my $line = <UND>){
    chomp($line);
    if ($line =~ /^@/){
	next;
    }
    my @a = split (/\t/, $line);
    my $readname = $a[0];
    $readname =~ s/[^A-Za-z0-9 ]//g;
    $readname =~ s/$common_str//;
    my $chr = $a[2];
    my ($HI_tag, $IH_tag);
    if ($line =~ /(N|I)H:i:(\d+)/){
	$line =~ /(N|I)H:i:(\d+)/;
	$IH_tag = $2;
    }
    if ($line =~ /HI:i:(\d+)/){
	$line =~ /HI:i:(\d+)/;
	$HI_tag = $1;
    }
    my $for_hash = "$readname:$IH_tag:$HI_tag";
    
    if (exists $READ_HASH{$chr}{$for_hash}){
	next;
    }
    else{
	print OUTFILE "$line\n";
	$READ_HASH{$chr}{$for_hash} = 1;
    }
}
close(UND);
close(OUTFILE);


print "got here\n";

sub LCP {
    return '' unless @_;
    return $_[0] if @_ == 1;
    my $i          = 0;
    my $first      = shift;
    my $min_length = length($first);
    foreach (@_) {
        $min_length = length($_) if length($_) < $min_length;
    }
  INDEX: foreach  my $ch ( split //, $first ) {
      last INDEX unless $i < $min_length;
      foreach  my $string (@_) {
	  last INDEX if substr($string, $i, 1) ne $ch;
      }
  }
    continue { $i++ }
    return substr $first, 0, $i;
}
