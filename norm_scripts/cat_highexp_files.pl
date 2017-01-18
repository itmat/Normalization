#!/usr/bin/env perl
use warnings;
use strict;

if(@ARGV<2) {
    die "usage: perl cat_highexp_files.pl <sample id> <loc> [option]

where:
<sample id> 
<loc> is the path to the sample directories

option:
 -stranded: set this if your data are strand-specific.

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
for(my$i=2; $i<@ARGV; $i++) {
    my $option_found = "false";
    if($ARGV[$i] eq '-stranded') {
	$option_found = "true";
	$stranded = "true";
    }
    if($ARGV[$i] eq '-nu') {
	$U = "false";
	$numargs++;
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


my $LOC = $ARGV[1];
my $samfilename = $ARGV[2];
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $loc_study = $LOC;
$loc_study =~ s/$last_dir//;

my %READ_HASH;
my (%HIGHE, %HIGHI, %HIGHE_A, %HIGHI_A);
my $hEx = "$LOC/high_expressers_exon.txt";
my $hInt = "$LOC/high_expressers_intron.txt";
my ($hEx_a, $hInt_a);
if ($stranded eq "true"){
    $hEx = "$LOC/high_expressers_exon_sense.txt";
    $hInt = "$LOC/high_expressers_intron_sense.txt";
    $hEx_a = "$LOC/high_expressers_exon_antisense.txt";
    $hInt_a = "$LOC/high_expressers_intron_antisense.txt";
}
open(IN, $hEx) or die "cannot open $hEx\n";
while(my $line = <IN>){
    chomp($line);
    $line =~ s/:/./;
    $HIGHE{$line}=1;
}
close(IN);
open(IN2, $hInt) or die "cannot open $hInt\n";
while(my $line = <IN2>){
    chomp($line);
    $line =~ s/:/./;
    $HIGHI{$line}=1;
}
close(IN2);
if ($stranded eq "true"){
    open(IN, $hEx_a) or die "cannot open $hEx_a\n";
    while(my $line = <IN>){
	chomp($line);
	$line =~ s/:/./;
	$HIGHE_A{$line}=1;
    }
    close(IN);
    open(IN2, $hInt_a) or die "cannot open $hInt_a\n";
    while(my $line = <IN2>){
	chomp($line);
	$line =~ s/:/./;
	$HIGHI_A{$line}=1;
    }
    close(IN2);
}
my $cntE = keys %HIGHE;
my $cntI = keys %HIGHI;
my $cntEA = keys %HIGHE_A;
my $cntIA = keys %HIGHI_A;
my $id = $ARGV[0];
chomp($id);
if ($U eq "true"){
    my ($outEx, $outInt, $dir, $outEx_a, $outInt_a, $dir_a);
    if ($stranded eq "false"){
	$outEx = "$LOC/$id/EIJ/Unique/$id.filtered_u_exonmappers.highexp_shuf_norm.sam.gz";
	$outInt = "$LOC/$id/EIJ/Unique/$id.filtered_u_intronmappers.highexp_shuf_norm.sam.gz";
	$dir = "$LOC/$id/EIJ/Unique";
	if (-e $outEx){
	    `rm $outEx`;
	}
	if (-e $outInt){
	    `rm $outInt`;
	}
    }
    if ($stranded eq "true"){
	$outEx = "$LOC/$id/EIJ/Unique/sense/$id.filtered_u_exonmappers.highexp_shuf_norm.sam.gz";
        $outInt = "$LOC/$id/EIJ/Unique/sense/$id.filtered_u_intronmappers.highexp_shuf_norm.sam.gz";
        $dir = "$LOC/$id/EIJ/Unique/sense/";
	$outEx_a = "$LOC/$id/EIJ/Unique/antisense/$id.filtered_u_exonmappers.highexp_shuf_norm.sam.gz";
        $outInt_a = "$LOC/$id/EIJ/Unique/antisense/$id.filtered_u_intronmappers.highexp_shuf_norm.sam.gz";
        $dir_a = "$LOC/$id/EIJ/Unique/antisense/";
	if (-e $outEx){
            `rm $outEx`;
	}
	if (-e $outInt){
	    `rm $outInt`;
	}
	if (-e $outEx_a){
            `rm $outEx_a`;
	}
	if (-e $outInt_a){
	    `rm $outInt_a`;
	}

    }
    if ($cntE > 0){
	open(my $OUT, "| /bin/gzip -c >$outEx") or die;
	%READ_HASH=();
	foreach my $exon (keys %HIGHE){
	    my @ex = glob("$dir/*exonmappers*$exon.highexp.sam.gz");
	    if (@ex > 0){
		foreach my $file (@ex){
		    my $pipecmd = "zcat $file";
		    open(FILE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
		    while(my $line = <FILE>){
			chomp($line);
			if ($line =~ /^@/){
			    next;
			}
			my @a = split (/\t/, $line);
			my $readname = $a[0];
			$readname =~ s/[^A-Za-z0-9 ]//g;
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
			    print $OUT "$line\n";
			    $READ_HASH{$chr}{$for_hash} = 1;
			}
		    }
		    close(FILE);
		}
	    }
	}
	close($OUT);
    }
    if ($cntI > 0){
	open(my $OUT, "| /bin/gzip -c >$outInt") or die;
	%READ_HASH=();
        foreach my $intron (keys %HIGHI){
            my @int = glob("$dir/*intronmappers*$intron.highexp.sam.gz");
	    if (@int > 0){
		foreach my $file (@int){
		    my $pipecmd = "zcat $file";
		    open(FILE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
		    while(my $line = <FILE>){
			chomp($line);
			if ($line =~ /^@/){
			    next;
			}
			my @a = split (/\t/, $line);
			my $readname = $a[0];
			$readname =~ s/[^A-Za-z0-9 ]//g;
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
			    print $OUT "$line\n";
			    $READ_HASH{$chr}{$for_hash} = 1;
			}
		    }
		    close(FILE);
		}
	    }
	}
	close($OUT);
    }
    if ($stranded eq "true"){
	if ($cntEA > 0){
	    open(my $OUT, "| /bin/gzip -c >$outEx_a") or die;
	    %READ_HASH=();
	    foreach my $exon (keys %HIGHE_A){
		my @ex = glob("$dir_a/*exonmappers*$exon.highexp.sam.gz");
		if (@ex > 0){
		    foreach my $file (@ex){
			my $pipecmd = "zcat $file";
			open(FILE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
			while(my $line = <FILE>){
			    chomp($line);
			    if ($line =~ /^@/){
				next;
			    }
			    my @a = split (/\t/, $line);
			    my $readname = $a[0];
			    $readname =~ s/[^A-Za-z0-9 ]//g;
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
				print $OUT "$line\n";
				$READ_HASH{$chr}{$for_hash} = 1;
			    }
			}
			close(FILE);
		    }
		}
	    }
	    close($OUT);
	}
	if ($cntIA > 0){
	    open(my $OUT, "| /bin/gzip -c >$outInt_a") or die;
	    %READ_HASH=();
	    foreach my $intron (keys %HIGHI_A){
		my @int = glob("$dir_a/*intronmappers*$intron.highexp.sam.gz");
		if (@int > 0){
		    foreach my $file (@int){
			my $pipecmd = "zcat $file";
			open(FILE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
			while(my $line = <FILE>){
			    chomp($line);
			    if ($line =~ /^@/){
				next;
			    }
			    my @a = split (/\t/, $line);
			    my $readname = $a[0];
			    $readname =~ s/[^A-Za-z0-9 ]//g;
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
				print $OUT "$line\n";
				$READ_HASH{$chr}{$for_hash} = 1;
			    }
			}
			close(FILE);
		    }
		}
	    }
	    close($OUT);
	}
    }
}
if ($NU eq "true"){
    my ($outEx, $outInt, $dir, $outEx_a, $outInt_a, $dir_a);
    if ($stranded eq "false"){
	$outEx = "$LOC/$id/EIJ/NU/$id.filtered_nu_exonmappers.highexp_shuf_norm.sam.gz";
	$outInt = "$LOC/$id/EIJ/NU/$id.filtered_nu_intronmappers.highexp_shuf_norm.sam.gz";
        $dir = "$LOC/$id/EIJ/NU";
	if (-e $outEx){
	    `rm $outEx`;
	}
	if (-e $outInt){
	    `rm $outInt`;
	}
    }
    if ($stranded eq "true"){
        $outEx = "$LOC/$id/EIJ/NU/sense/$id.filtered_nu_exonmappers.highexp_shuf_norm.sam.gz";
        $outInt = "$LOC/$id/EIJ/NU/sense/$id.filtered_nu_intronmappers.highexp_shuf_norm.sam.gz";
        $dir = "$LOC/$id/EIJ/NU/sense/";
        $outEx_a = "$LOC/$id/EIJ/NU/antisense/$id.filtered_nu_exonmappers.highexp_shuf_norm.sam.gz";
        $outInt_a = "$LOC/$id/EIJ/NU/antisense/$id.filtered_nu_intronmappers.highexp_shuf_norm.sam.gz";
        $dir_a = "$LOC/$id/EIJ/NU/antisense/";
	if (-e $outEx){
            `rm $outEx`;
	}
	if (-e $outInt){
	    `rm $outInt`;
	}
	if (-e $outEx_a){
            `rm $outEx_a`;
	}
	if (-e $outInt_a){
	    `rm $outInt_a`;
	}
    }
    if ($cntE > 0){
	open(my $OUT, "| /bin/gzip -c >$outEx") or die;
	%READ_HASH=();
        foreach my $exon (keys %HIGHE){
            my @ex = glob("$dir/*exonmappers*$exon.highexp.sam.gz");
	    if (@ex > 0){
		foreach my $file (@ex){
                    my $pipecmd = "zcat $file";
                    open(FILE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
		    while(my $line = <FILE>){
			chomp($line);
			if ($line =~ /^@/){
			    next;
			}
			my @a = split (/\t/, $line);
			my $readname = $a[0];
			$readname =~ s/[^A-Za-z0-9 ]//g;
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
			    print $OUT "$line\n";
			    $READ_HASH{$chr}{$for_hash} = 1;
			}
		    }
		    close(FILE);
		}
	    }
	}
	close($OUT);
    }
    if ($cntI > 0){
	open(my $OUT, "| /bin/gzip -c >$outInt") or die;
	%READ_HASH=();
        foreach my $intron (keys %HIGHI){
            my @int = glob("$dir/*intronmappers*$intron.highexp.sam.gz");
	    if (@int > 0){
		foreach my $file (@int){
                    my $pipecmd = "zcat $file";
                    open(FILE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
		    while(my $line = <FILE>){
			chomp($line);
			if ($line =~ /^@/){
			    next;
			}
			my @a = split (/\t/, $line);
			my $readname = $a[0];
			$readname =~ s/[^A-Za-z0-9 ]//g;
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
			    print $OUT "$line\n";
			    $READ_HASH{$chr}{$for_hash} = 1;
			}
		    }
		    close(FILE);
		}
	    }
	}
	close($OUT);
    }
    if ($stranded eq "true"){
	if ($cntEA > 0){
	    open(my $OUT, "| /bin/gzip -c >$outEx_a") or die;
	    %READ_HASH=();
	    foreach my $exon (keys %HIGHE_A){
		my @ex = glob("$dir_a/*exonmappers*$exon.highexp.sam.gz");
		if (@ex > 0){
		    foreach my $file (@ex){
			my $pipecmd = "zcat $file";
			open(FILE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
			while(my $line = <FILE>){
			    chomp($line);
			    if ($line =~ /^@/){
				next;
			    }
			    my @a = split (/\t/, $line);
			    my $readname = $a[0];
			    $readname =~ s/[^A-Za-z0-9 ]//g;
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
				print $OUT "$line\n";
				$READ_HASH{$chr}{$for_hash} = 1;
			    }
			}
			close(FILE);
		    }
		}
	    }
	    close($OUT);
	}
	if ($cntIA > 0){
	    open(my $OUT, "| /bin/gzip -c >$outInt_a") or die;
	    %READ_HASH=();
	    foreach my $intron (keys %HIGHI_A){
		my @int = glob("$dir_a/*intronmappers*$intron.highexp.sam.gz");
		if (@int > 0){
		    foreach my $file (@int){
			my $pipecmd = "zcat $file";
			open(FILE, '-|', $pipecmd) or die "Opening pipe [$pipecmd]: $!\n+";
			while(my $line = <FILE>){
			    chomp($line);
			    if ($line =~ /^@/){
				next;
			    }
			    my @a = split (/\t/, $line);
			    my $readname = $a[0];
			    $readname =~ s/[^A-Za-z0-9 ]//g;
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
				print $OUT "$line\n";
				$READ_HASH{$chr}{$for_hash} = 1;
			    }
			}
			close(FILE);
		    }
		}
	    }
	    close($OUT);
	}
    }
}
print "got here\n";
