#!/usr/bin/env perl
use strict;
use warnings;
if (@ARGV < 2){
    die "usage: perl unique_merge_gnorm.pl <sample id> <loc> [options]

where:
<sample id> is sample id (directory name)
<loc> is the path to the sample directories

option:
  -normdir <s>

  -u  :  set this if you want to return only unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

  -nu :  set this if you want to return only non-unique mappers, otherwise by default
         it will return both unique and non-unique mappers.

  -se : set this for single end data

";
}

my $pe = "true";
my $NU = "true";
my $U = "true";
my $numargs = 0;
my $normdir = "";
my $ncnt = 0;
for(my$i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$numargs++;
	$option_found = "true";
    }
    if($ARGV[$i] eq '-normdir') {
        $option_found = "true";
	$normdir = $ARGV[$i+1];
	$i++;
	$ncnt++;
    }
    if($ARGV[$i] eq '-se'){
	$pe = "false";
	$option_found = "true";
    }
    if($ARGV[$i] eq '-u') {
	$NU = "false";
	$numargs++;
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
my $norm_dir = "$normdir/GENE/FINAL_SAM/";
my $norm_merged_dir = $norm_dir . "/merged";
unless (-d $norm_merged_dir){
    `mkdir $norm_merged_dir`;
}
my $id = $ARGV[0];
my ($genefile, $genefile_a);
my $outfile = "$norm_merged_dir/$id.merged.sam";
open(OUTFILE, ">$outfile");
if ($numargs eq '0'){    
    $genefile = "$norm_dir/sense/$id.gene.norm.sam";
    $genefile_a = "$norm_dir/antisense/$id.gene.norm.sam";
}
elsif ($U eq "true"){
    $genefile = "$norm_dir/sense/$id.gene.norm_u.sam";
    $genefile_a = "$norm_dir/antisense/$id.gene.norm_u.sam";
}
elsif ($NU eq "true"){
    $genefile = "$norm_dir/sense/$id.gene.norm_nu.sam";
    $genefile_a = "$norm_dir/antisense/$id.gene.norm_nu.sam";
}
#identify common string and get chr names
my $common_str = "";
my @NAME;
my %CHR = ();
open(GENE, $genefile) or die "Cannot open $genefile\n";
while (<GENE>){
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
close(GENE);

my $last_1000 = `tail -1000 $genefile_a`;
my @tail = split(/\n/, $last_1000);
for my $seq (@tail){
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
# genefile sense
open(GENE, $genefile) or die "Cannot open $genefile\n";
while(my $line = <GENE>){
    chomp($line);
    if ($line =~ /^@/){
	next;
    }
    if ($pe eq "false"){
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
	$READ_HASH{$chr}{$for_hash} = 1;
	print OUTFILE "$line\n"; 
    }
    if ($pe eq "true"){
	my $line_r = <GENE>;
	chomp($line_r);
	my @a = split (/\t/, $line);
	my @r = split(/\t/, $line_r);
	my $readname = $a[0];
	my $readname_r = $r[0];
	$readname =~ s/[^A-Za-z0-9 ]//g;
	$readname =~ s/$common_str//;
	$readname_r =~ s/[^A-Za-z0-9 ]//g;
	$readname_r =~ s/$common_str//;
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
	my ($HI_tag_r, $IH_tag_r);
	if ($line_r =~ /(N|I)H:i:(\d+)/){
	    $line_r =~ /(N|I)H:i:(\d+)/;
	    $IH_tag_r = $2;
	}
	if ($line_r =~ /HI:i:(\d+)/){
	    $line_r =~ /HI:i:(\d+)/;
	    $HI_tag_r = $1;
	}
	my $for_hash = "$readname:$IH_tag:$HI_tag";
	my $for_hash_r = "$readname_r:$IH_tag_r:$HI_tag_r";
	if ($for_hash ne $for_hash_r){
	    die "fwd and rev reads need to be in adjacent lines\n\n";
	}
	$READ_HASH{$chr}{$for_hash} = 1;
	print OUTFILE "$line\n$line_r\n";
    }
}
close(GENE);
#antisense file
open(GENE_A, $genefile_a) or die "Cannot open $genefile_a\n";
while(my $line = <GENE_A>){
    chomp($line);
    if ($line =~ /^@/){
	next;
    }
    if ($pe eq "false"){
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
	}
    }
    if ($pe eq "true"){
	my $line_r = <GENE_A>;
	chomp($line_r);
	my @a = split (/\t/, $line);
	my @a_r = split (/\t/, $line_r);
	my $readname = $a[0];
	my $readname_r = $a_r[0];
	$readname =~ s/[^A-Za-z0-9 ]//g;
	$readname =~ s/$common_str//;
	$readname_r =~ s/[^A-Za-z0-9 ]//g;
	$readname_r =~ s/$common_str//;
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
	my ($HI_tag_r, $IH_tag_r);
	if ($line_r =~ /(N|I)H:i:(\d+)/){
	    $line_r =~ /(N|I)H:i:(\d+)/;
	    $IH_tag_r = $2;
	}
	if ($line_r =~ /HI:i:(\d+)/){
	    $line_r =~ /HI:i:(\d+)/;
	    $HI_tag_r = $1;
	}
	my $for_hash = "$readname:$IH_tag:$HI_tag";
	my $for_hash_r = "$readname_r:$IH_tag_r:$HI_tag_r";
	if ($for_hash ne $for_hash_r){
	    die "fwd and rev reads need to be in adjacent lines\n\n";
	}
	if (exists $READ_HASH{$chr}{$for_hash}){
	    next;
	}
	else{
	    print OUTFILE "$line\n$line_r\n";
	}
    }
    
}
close(GENE_A);
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
