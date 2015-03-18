#!/usr/bin/env perl
use strict;
use warnings;

my $USAGE = "\nUsage: perl resolve_multimappers_gnorm.pl <sam2genes output> <output file> [options]

<sam2gene output> output file from sam2gene.pl script
<output file> name of output file (e.g. path/to/sampledirectory/sampleid.filtered.sam)

option:

  -se :  set this if the data are single end, otherwise by default it will assume it's a paired end data.

\n";

if (@ARGV<2){
    die $USAGE;
}

my $pe = "true";
for(my $i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if ($ARGV[$i] eq '-se'){
	$pe = "false";
	$option_found = "true";
    }
    if($option_found eq "false") {
	die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

my $input = $ARGV[0];
my $outfile = $ARGV[1];

my (%Unique, %NU);
my %CNT;
my %IH;#debug
open(IN, $input) or die "cannot find file \"$input\"\n";
my $header = <IN>;
while(my $forward = <IN>){
    if ($pe eq "true"){
	chomp($forward);
	my ($readid, $hi);
	#forward read
	my @f = split(/\t/, $forward);
	my $read_id_f = $f[0];
	my $gene_ids_f = $f[2];
	my $gene_syms_f = $f[3];
	my $ih_hi_f = $f[4];
	$ih_hi_f =~ /(\d*)\:(\d*)/;
	my $ih_f = $1;
	my $hi_f = $2;
	$IH{$read_id_f} = $ih_f;
	#reverse read
	my $reverse = <IN>;
	my @r = split(/\t/, $reverse);
	my $read_id_r = $r[0];
	my $gene_ids_r = $r[2];
	my $gene_syms_r = $r[3];
	my $ih_hi_r = $r[4];
	$ih_hi_r =~ /(\d*)\:(\d*)/;
	my $ih_r = $1;
	my $hi_r = $2;
	if (($read_id_f eq $read_id_r) && ($hi_f eq $hi_r)){
	    $readid = $read_id_f;
	    $hi = $hi_f;
	}
	else{
	    die "ERROR: $input file is not in the correct format.\n";
	}
	# make sure both reads map to at least one gene. 
	if (($gene_ids_f =~ /^$/) || ($gene_ids_r =~ /^$/)){
	    next;
	}
	my @bf = split(",", $gene_ids_f);
	my @br = split(",", $gene_ids_r);
	if ((@bf == 1) && (@br == 1)){ #single gene id
	    if ($gene_ids_f eq $gene_ids_r){ 
		if ($gene_ids_f =~ /ANTI/){ #skip if antisense
		    next;
		}
		if (exists $Unique{$readid}){
		    unless (defined $CNT{$readid}){
			push(@{$NU{$readid}}, $Unique{$readid}[0]);
			$CNT{$readid}++; 
		    }
		    push(@{$NU{$readid}},$hi);
		    $CNT{$readid}++; 
		}
		else{
		    push(@{$Unique{$readid}},$hi);
		}
	    }
	}
	else{ #multiple gene ids
	    my $check = 0;
	    for(my $i=0;$i<@bf;$i++){
		for (my $k=0; $k<@br; $k++){
		    if ($bf[$i] eq $br[$k]){
			if ($bf[$i] !~ /ANTI/){
			    $check++;
			}
		    }
		}
	    }
	    if ($check == 1){ #read pair map to single gene id
		if (exists $Unique{$readid}){
                    unless (defined $CNT{$readid}){                    
			push(@{$NU{$readid}}, $Unique{$readid}[0]);
			$CNT{$readid}++;
		    }
                    push(@{$NU{$readid}},$hi);
		    $CNT{$readid}++;
                }
		else{
                    push(@{$Unique{$readid}},$hi);
                }
	    }
	    elsif ($check > 1){ #read pair map to multiple gene ids
		push(@{$NU{$readid}},$hi);
		$CNT{$readid}++;
	    }
	}
    }
    if ($pe eq "false"){ #single read
	chomp($forward);
	my @a = split(/\t/, $forward);
	my $readid = $a[0];
	my $gene_ids = $a[2];
	my $gene_syms = $a[3];
	my $ih_hi = $a[4];
        $ih_hi =~ /(\d*)\:(\d*)/;
        my $ih_tag = $1;
	my $hi = $2;
	if ($gene_ids =~ /^$/){
	    next;
	}
	my @b = split(",", $gene_ids);
	if (@b == 1){ #single gene id
	    if ($gene_ids =~ /ANTI/){ #skip if antisense
		next;
	    }
	    if (exists $Unique{$readid}){
		unless (defined $CNT{$readid}){
		    push(@{$NU{$readid}}, $Unique{$readid}[0]);
		    $CNT{$readid}++;
		}
		push(@{$NU{$readid}},$hi);
		$CNT{$readid}++;
	    }
	    else{
		push(@{$Unique{$readid}},$hi);
	    }
	}
	else{ #multiple gene ids
	    my $check = 0;
	    for(my $i=0;$i<@b;$i++){
		if ($b[$i] !~ /ANTI/){
		    $check++;
		}
	    }
	    if ($check == 1){ #alignment map to single gene id
		if (exists $Unique{$readid}){
		    unless (defined $CNT{$readid}){
			push(@{$NU{$readid}}, $Unique{$readid}[0]);
			$CNT{$readid}++;
		    }
		    push(@{$NU{$readid}},$hi);
		    $CNT{$readid}++;
		}
		else{
		    push(@{$Unique{$readid}},$hi);
		}
	    }
	    elsif ($check > 1){ #alignment map to multiple gene ids
		push(@{$NU{$readid}},$hi);
		$CNT{$readid}++;
	    }
	}
    }
}
close(IN);

foreach my $read (keys %Unique){
    if (exists $NU{$read}){
	delete $Unique{$read};
    }
}

=comment #debug
my $temp_u = "temp_u.txt";
open(U, ">$temp_u");
foreach my $read (keys %Unique){
    print U "$read\t$Unique{$read}[0]\n";
}

my $temp_nu = "temp_nu.txt";
open(NU, ">$temp_nu");
foreach my $read (keys %NU){
    my $size = @{$NU{$read}};
    print NU "$read\t";
    for (my $i=0;$i<$size;$i++){
	print NU "$NU{$read}[$i]\t";
    }
    print NU "count:$CNT{$read}\n";
}

foreach my $read (keys %NU){
    my $ih = $IH{$read};
    my $cnt = $CNT{$read};
    if ($ih ne $cnt ){
	print "$read\n";
    }
}
=cut 

my @a = split(/\//, $outfile);
my $filename = $a[@a-1];
my $dir = $outfile;
$dir =~ s/$filename$//;
$dir .= "GNORM/";
my $out_u = "$dir/Unique/$filename";
$out_u =~ s/.sam$/_u.sam/;
my $out_nu = "$dir/NU/$filename";
$out_nu =~ s/.sam$/_nu.sam/;

my $in_unique_file = "$dir/$filename";
$in_unique_file =~ s/.sam$/_u.sam/;
my $in_nu_file = "$dir/$filename";
$in_nu_file =~ s/.sam$/_nu.sam/;

unless (-e "$dir/Unique"){
    my $x = `mkdir $dir/Unique`;
}

unless (-e "$dir/NU"){
    my $x = `mkdir $dir/NU`;
}

my $x = `cat $in_unique_file > $out_u`;
open(UNIQUE, ">>$out_u") or die "cannot find file '$out_u'\n";
open(NU, ">$out_nu");
open(IN, $in_nu_file) or die "cannot find file '$in_nu_file'\n";
while(my $line = <IN>){
    chomp($line);
    if ($line =~ /^@/){
	next;
    }
    my @a = split(/\t/, $line);
    my $readid = $a[0];
    my $hi_tag = 0;
    if ($line =~ /HI:i:(\d+)/){
	$line =~ /HI:i:(\d+)/;
	$hi_tag = $1;
    }
    my $original_hi = "HI:i:$hi_tag";
    my $ih_tag = 0;
    my $i_or_h = "";
    if ($line =~ /(N|I)H:i:(\d+)/){
        $line =~ /(N|I)H:i:(\d+)/;
        $i_or_h = $1;
        $ih_tag = $2;
    }
    my $original_ih = "$i_or_h" . "H:i:$ih_tag";
    my $new_ih = "$i_or_h" . "H:i:1";
    if (exists $Unique{$readid}){
	if ($hi_tag eq $Unique{$readid}[0]){ #fix tag to unique and print to unique file
	    $line =~ s/$original_ih/$new_ih/;
	    $line =~ s/$original_hi/HI:i:1/;
	    print UNIQUE "$line\n";
	}
    }
    elsif (exists $NU{$readid}){
	for(my $i=0;$i<$CNT{$readid};$i++){
	    if ($hi_tag eq $NU{$readid}[$i]){
		print NU "$line\n";
	    }
	}
    }
    else{
	print NU "$line\n";
    }
}
close(IN);
close(UNIQUE);
close(NU);
print "got here\n";
