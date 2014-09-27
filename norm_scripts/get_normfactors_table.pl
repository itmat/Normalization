#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "\nUsage: perl get_normfactors_table.pl <sample_dirs> <loc>

<sample dirs> is a file with the names of the sample directories (without path)
<loc> is the location where the sample directories are

";

if (@ARGV < 2){
    die $USAGE;
}

my $dirs = $ARGV[0];
my $LOC = $ARGV[1];
$LOC =~ s/\/$//;
my @fields = split("/", $LOC);
my $last_dir = $fields[@fields-1];
my $study_dir = $LOC;
$study_dir =~ s/$last_dir//;
my $eij = "false";
my $gnorm = "false";

my $out_eij = "$study_dir/STATS/exon-intron-junction_normalization_factors.txt";
my $out_gnorm = "$study_dir/STATS/gene_normalization_factors.txt";

if (-d "$study_dir/STATS/EXON_INTRON_JUNCTION"){
    $eij = "true";
}
if (-d "$study_dir/STATS/GENE"){
    $gnorm = "true";
}
my ($total, $chrM, $NU, $ribo, $exonicU, $exonicNU, $oneexonmappersU, $oneexonmappersNU, $intergenicU, $intergenicNU, $geneU, $geneNU);
my ($total_num, $chrM_num, $chrM_num_m, $NU_num, $NU_num_m, $ribo_num, $exonic_u,  $exonic_nu, $one_u, $one_nu, $intergenic_u, $intergenic_nu, $gene_u, $gene_nu);

if ($gnorm eq "true"){
    open(OUT, ">$out_gnorm");
    print OUT "sample\t";
    if (-e "$study_dir/STATS/mappingstats_summary.txt"){
        print OUT "totalnumreads\t%chrM\t%NU\t";
        $total = "true";
        $chrM = "true";
        $NU = "true";
    }
    if (-e "$study_dir/STATS/ribo_percents.txt"){
        print OUT "%ribo\t";
        $ribo = "true";
    }
    if (-e "$study_dir/STATS/GENE/percent_genemappers_Unique.txt"){
	print OUT "%geneU\t";
	$geneU = "true";
    }
    if (-e "$study_dir/STATS/GENE/percent_genemappers_NU.txt"){
	print OUT "%geneNU\t";
	$geneNU = "true";
    }
    print OUT "\n";
    open(IN, $dirs);
    while (my $line = <IN>){
        chomp($line);
        #totalnumreads
	if ($total eq "true"){
	    $total_num = `cut -f 1,2 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
            chomp($total_num);
            $total_num =~ s/$line//g;
	    $total_num =~ s/^\s*(.*?)\s*$/$1/;
            $total_num =~ s/\,//g;
        }
	#chrM
	if ($chrM eq "true"){
            $chrM_num = `cut -f 1,5 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
            chomp($chrM_num);
            $chrM_num =~ s/$line//g;
            $chrM_num =~ s/^\s*(.*?)\s*$/$1/;
            $chrM_num =~ m/\((.*)\%\)/;
            $chrM_num_m = $1;
        }
        #NU
        if ($NU eq "true"){
            $NU_num = `cut -f 1,8 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
            chomp($NU_num);
            $NU_num =~ s/$line//g;
            $NU_num =~ s/^\s*(.*?)\s*$/$1/;
            $NU_num =~ m/\((.*)\%\)/;
            $NU_num_m = $1;
        }
        #ribo
        if ($ribo eq "true"){
	    $ribo_num = `cut -f 3,4 $study_dir/STATS/ribo_percents.txt | grep -w $line`;
            chomp($ribo_num);
            $ribo_num =~ s/$line//g;
            $ribo_num =~ s/^\s*(.*?)\s*$/$1/;
            $ribo_num = $ribo_num * 100;
	}

        #gene u
        if ($geneU eq "true"){
            $gene_u = `grep -w $line $study_dir/STATS/GENE/percent_genemappers_Unique.txt`;
            chomp($gene_u);
            $gene_u =~ s/$line//g;
            $gene_u =~ s/^\s*(.*?)\s*$/$1/;
        }
        #gene nu
        if ($geneNU eq "true"){
            $gene_nu = `grep -w $line $study_dir/STATS/GENE/percent_genemappers_NU.txt`;
            chomp($gene_nu);
            $gene_nu =~ s/$line//g;
            $gene_nu =~ s/^\s*(.*?)\s*$/$1/;
        }
        print OUT "$line\t$total_num\t$chrM_num_m\t$NU_num_m\t$ribo_num\t$gene_u\t$gene_nu\n";
    }
    close(OUT);
    close(IN);
}	
if ($eij eq "true"){
    open(OUT, ">$out_eij");
    print OUT "sample\t";

    if (-e "$study_dir/STATS/mappingstats_summary.txt"){
	print OUT "totalnumreads\t%chrM\t%NU\t";
	$total = "true";
	$chrM = "true";
	$NU = "true";
    }
    if (-e "$study_dir/STATS/ribo_percents.txt"){
	print OUT "%ribo\t";
	$ribo = "true";
    }
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique.txt"){
	print OUT "%exonicU\t";
	$exonicU = "true";
    }    
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU.txt"){
        print OUT "%exonicNU\t";
	$exonicNU = "true";
    }
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique.txt"){
	print OUT "%1exonmappersU\t";
	$oneexonmappersU = "true";
    }
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU.txt"){
	print OUT "%1exonmappersNU\t";
	$oneexonmappersNU = "true";
    }
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/percent_intergenic_Unique.txt"){
	print OUT "%intergenicU\t";
	$intergenicU = "true";
    }    
    if (-e "$study_dir/STATS/EXON_INTRON_JUNCTION/percent_intergenic_NU.txt"){
        print OUT "%intergenicNU\t";
	$intergenicNU = "true";
    }
    print OUT "\n";
    open(IN, $dirs);
    while (my $line = <IN>){
	chomp($line);
	#totalnumreads
	if ($total eq "true"){
	    $total_num = `cut -f 1,2 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
	    chomp($total_num);
	    $total_num =~ s/$line//g;
	    $total_num =~ s/^\s*(.*?)\s*$/$1/;
	    $total_num =~ s/\,//g;
	}
	#chrM
	if ($chrM eq "true"){
	    $chrM_num = `cut -f 1,5 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
	    chomp($chrM_num);
	    $chrM_num =~ s/$line//g;
	    $chrM_num =~ s/^\s*(.*?)\s*$/$1/;
	    $chrM_num =~ m/\((.*)\%\)/;
	    $chrM_num_m = $1;
	}
	#NU
	if ($NU eq "true"){
	    $NU_num = `cut -f 1,8 $study_dir/STATS/mappingstats_summary.txt | grep -w $line`;
	    chomp($NU_num);
	    $NU_num =~ s/$line//g;
	    $NU_num =~ s/^\s*(.*?)\s*$/$1/;
	    $NU_num =~ m/\((.*)\%\)/;
	    $NU_num_m = $1;
	}
	#ribo
	if ($ribo eq "true"){
	    $ribo_num = `cut -f 3,4 $study_dir/STATS/ribo_percents.txt | grep -w $line`; 
	    chomp($ribo_num);
	    $ribo_num =~ s/$line//g;
	    $ribo_num =~ s/^\s*(.*?)\s*$/$1/;
	    $ribo_num = $ribo_num * 100;
	}

	#exonic u
	if ($exonicU eq "true"){
	    $exonic_u = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_Unique.txt`;
	    chomp($exonic_u);
	    $exonic_u =~ s/$line//g;
	    $exonic_u =~ s/^\s*(.*?)\s*$/$1/;
	}
	#exonic nu
	if ($exonicNU eq "true"){
	    $exonic_nu = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/exon2nonexon_signal_stats_NU.txt`;
	    chomp($exonic_nu);
	    $exonic_nu =~ s/$line//g;
	    $exonic_nu =~ s/^\s*(.*?)\s*$/$1/;
	}
	#one-vs-multi u
	if ($oneexonmappersU eq "true"){
	    $one_u = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_Unique.txt`;
	    chomp($one_u);
	    $one_u =~ s/$line//g;
	    $one_u =~ s/^\s*(.*?)\s*$/$1/;
	}
	#one-vs-multi nu
	if ($oneexonmappersNU eq "true"){
	    $one_nu = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/1exon_vs_multi_exon_stats_NU.txt`;
	    chomp($one_nu);
	    $one_nu =~ s/$line//g;
	    $one_nu =~ s/^\s*(.*?)\s*$/$1/;
	}
	#intergenic u
	if ($intergenicU eq "true"){
	    $intergenic_u = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/percent_intergenic_Unique.txt`;
	    chomp($intergenic_u);
	    $intergenic_u =~ s/$line//g;
	    $intergenic_u =~ s/^\s*(.*?)\s*$/$1/;
	}
	#intergenic nu
	if ($intergenicNU eq "true"){
	    $intergenic_nu = `grep -w $line $study_dir/STATS/EXON_INTRON_JUNCTION/percent_intergenic_NU.txt`;
	    chomp($intergenic_nu);
	    $intergenic_nu =~ s/$line//g;
	    $intergenic_nu =~ s/^\s*(.*?)\s*$/$1/;
	}
	print OUT "$line\t$total_num\t$chrM_num_m\t$NU_num_m\t$ribo_num\t$exonic_u\t$exonic_nu\t$one_u\t$one_nu\t$intergenic_u\t$intergenic_nu\n";
    }
    close(OUT);
    close(IN);
}

print "got here\n";
