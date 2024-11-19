#!/usr/bin/env perl
use warnings;
use strict;

my $USAGE = "perl copy_lcfiles.pl <output directory> <input directories>

where:
<output dir>: line count directory to create
<input directories>: path to the directories with filtered files in them

options:
-stranded: set this for stranded data
-eij: default - both
-gnorm: default - both
-depthExon <n> : default 20
-depthIntron <n> : default 10
-alt_stats <s> 

";

if (@ARGV<2){
    die $USAGE;
}
my $stranded = "false";
my $eij = "true";
my $gnorm = "true";
my $cnt = 0;
my $i_exon = 20;
my $i_intron = 10;
my $lcdir = $ARGV[0];

my @dirs;
for(my $i=1;$i<@ARGV;$i++){
    my $option_found = "false";
    if ($ARGV[$i] eq '-stranded'){
        $option_found = "true";
        $stranded = "true";
    }
    if ($ARGV[$i] eq '-eij'){
        $option_found = "true";
        $gnorm = "false";
        $cnt++;
    }
    if ($ARGV[$i] eq '-gnorm'){
        $option_found = "true";
        $eij = "false";
        $cnt++;
    }
    if ($ARGV[$i] eq '-depthExon'){
        $i_exon = $ARGV[$i+1];
        $i++;
        $option_found = "true";
    }
    if ($ARGV[$i] eq '-depthIntron'){
        $i_intron = $ARGV[$i+1];
        $i++;
        $option_found = "true";
    }
    if ($ARGV[$i] !~ /^-/) {
        push(@dirs, $ARGV[$i]);
        $option_found = "true";
    }
    if($option_found eq "false") {
        die "option \"$ARGV[$i]\" was not recognized.\n";
    }
}

unless (-d $lcdir){
    `mkdir -p $lcdir`;
}

if ($gnorm eq "true"){
    my ($gene_u, $gene_nu, $gene_u_a, $gene_nu_a);
    if ($stranded eq "false"){
        $gene_u = "$lcdir/gene.unique.lc.txt";
        $gene_nu = "$lcdir/gene.nu.lc.txt";
        if (-e $gene_u){
            `rm $gene_u`;
        }
        if (-e $gene_nu){
            `rm $gene_nu`;
        }
        for my $dir (@dirs) {
            if (-d "$dir/GNORM/Unique/"){
                my $x = `find $dir/GNORM/Unique/ -name "*filtered_u.genes*linecount*" | xargs cat >> $gene_u`;
            }
            if (-d "$dir/GNORM/NU/"){
                my $x = `find $dir/GNORM/NU/ -name "*filtered_nu.genes*linecount*" | xargs cat >> $gene_nu`;
            }
        }
    }
    if ($stranded eq "true"){
        $gene_u = "$lcdir/gene.unique.sense.lc.txt";
        $gene_nu = "$lcdir/gene.nu.sense.lc.txt";
        $gene_u_a = "$lcdir/gene.unique.antisense.lc.txt";
        $gene_nu_a = "$lcdir/gene.nu.antisense.lc.txt";
        if (-e $gene_u){
            `rm $gene_u`;
        }
        if (-e $gene_nu){
            `rm $gene_nu`;
        }
        if (-e $gene_u_a){
            `rm $gene_u_a`;
        }
        if (-e $gene_nu_a){
            `rm $gene_nu_a`;
        }
        for my $dir (@dirs) {
            if (-d "$dir/GNORM/Unique/"){
                my $x = `find $dir/GNORM/Unique/ -name "*filtered_u.genes*.sense.linecount*" | xargs cat >> $gene_u`;
            }
            my $y = `find $dir/GNORM/Unique/ -name "*filtered_u.genes*.antisense.linecount*" | xargs cat >> $gene_u_a`;
            if (-d "$dir/GNORM/NU/"){
                my $x = `find $dir/GNORM/NU/ -name "*filtered_nu.genes*.sense.linecount*" | xargs cat >> $gene_nu`;
                my $y = `find $dir/GNORM/NU/ -name "*filtered_nu.genes*.antisense.linecount*" | xargs cat >> $gene_nu_a`;
            }
        }
    }
}

if ($eij eq "true"){
    my (@ex_u_lc, @ex_nu_lc, @ex_u_a_lc, @ex_nu_a_lc);
    my (@int_u_lc, @int_nu_lc, @int_u_a_lc, @int_nu_a_lc);
    my $ig_u = "$lcdir/intergenic.unique.lc.txt";
    my $ig_nu = "$lcdir/intergenic.nu.lc.txt";
    my $e_inc_u = "$lcdir/exon_inconsist.unique.lc.txt";
    my $e_inc_nu = "$lcdir/exon_inconsist.nu.lc.txt";
    if (-e "$ig_u"){
        `rm $ig_u`;
    }
    if (-e "$ig_nu"){
        `rm $ig_nu`;
    }
    if (-e "$e_inc_u"){
        `rm $e_inc_u`;
    }
    if (-e "$e_inc_nu"){
        `rm $e_inc_nu`;
    }
    if ($stranded eq "false"){
        #exonmappers
        my $ex_u = "$lcdir/exon.unique.lc.txt";
        my $ex_nu = "$lcdir/exon.nu.lc.txt";
        my $int_u = "$lcdir/intron.unique.lc.txt";
        my $int_nu = "$lcdir/intron.nu.lc.txt";
        for (my $i=1; $i<=$i_exon;$i++){
            $ex_u_lc[$i] = $ex_u;
            $ex_u_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$ex_u_lc[$i]"){
                `rm $ex_u_lc[$i]`;
            }
            $ex_nu_lc[$i] = $ex_nu;
            $ex_nu_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$ex_nu_lc[$i]"){
                `rm $ex_nu_lc[$i]`;
            }
            for my $dir (@dirs) {
                if (-d "$dir/EIJ/Unique/"){
                    my $x = `find $dir/EIJ/Unique/ -name "*linecount*" | xargs cat | grep "exonmappers.$i.sam" >> $ex_u_lc[$i]`;
                }
                if (-d "$dir/EIJ/NU/"){
                    my $x = `find $dir/EIJ/NU/ -name "*linecount*" | xargs cat | grep "exonmappers.$i.sam" >> $ex_nu_lc[$i]`;
                }
            }
        }
        #intronmappers
        for (my $i=1; $i<=$i_intron;$i++){
            $int_u_lc[$i] = $int_u;
            $int_u_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$int_u_lc[$i]"){
                `rm $int_u_lc[$i]`;
            }            
            $int_nu_lc[$i] = $int_nu;
            $int_nu_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$int_nu_lc[$i]"){
                `rm $int_nu_lc[$i]`;
            }
            for my $dir (@dirs) {
                if (-d "$dir/EIJ/Unique/"){
                    my $x = `find $dir/EIJ/Unique/ -name "*linecount*" |  xargs cat | grep "intronmappers.$i.sam" >> $int_u_lc[$i]`;
                }
                if (-d "$dir/EIJ/NU/"){
                    my $x = `find $dir/EIJ/NU/ -name "*linecount*" |  xargs cat | grep "intronmappers.$i.sam" >> $int_nu_lc[$i]`;
                }
            }
        }
        #intergenic and exon-inconsist 
        for my $dir (@dirs) {
            if (-d "$dir/EIJ/Unique/"){
                my $x = `find $dir/EIJ/Unique/ -name "*linecount*" | xargs cat | grep "intergenicmappers.sam" >> $ig_u`;
                my $y = `find $dir/EIJ/Unique/ -name "*linecount*" | xargs cat | grep "exon_inconsistent_reads.sam" >> $e_inc_u`;
            }
            if (-d "$dir/EIJ/NU/"){
                my $x = `find $dir/EIJ/NU/ -name "*linecount*" | xargs cat | grep "intergenicmappers.sam" >> $ig_nu`;
                my $y = `find $dir/EIJ/NU/ -name "*linecount*" | xargs cat | grep "exon_inconsistent_reads.sam" >> $e_inc_nu`;
            }
        }
    }
    if ($stranded eq "true"){
        my $ex_u = "$lcdir/exon.unique.sense.lc.txt";
        my $ex_nu = "$lcdir/exon.nu.sense.lc.txt";
        my $int_u = "$lcdir/intron.unique.sense.lc.txt";
        my $int_nu = "$lcdir/intron.nu.sense.lc.txt";
        my $ex_u_a = "$lcdir/exon.unique.antisense.lc.txt";
        my $ex_nu_a = "$lcdir/exon.nu.antisense.lc.txt";
        my $int_u_a = "$lcdir/intron.unique.antisense.lc.txt";
        my $int_nu_a = "$lcdir/intron.nu.antisense.lc.txt";
        #exonmappers
        for (my $i=1; $i<=$i_exon;$i++){
            $ex_u_lc[$i] = $ex_u;
            $ex_u_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$ex_u_lc[$i]"){
                `rm $ex_u_lc[$i]`;
            }
            $ex_u_a_lc[$i] = $ex_u_a;
            $ex_u_a_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$ex_u_a_lc[$i]"){
                `rm $ex_u_a_lc[$i]`;
            }
            $ex_nu_lc[$i] = $ex_nu;
            $ex_nu_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$ex_nu_lc[$i]"){
                `rm $ex_nu_lc[$i]`;
            }
            $ex_nu_a_lc[$i] = $ex_nu_a;
            $ex_nu_a_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$ex_nu_a_lc[$i]"){
                `rm $ex_nu_a_lc[$i]`;
            }
            for my $dir (@dirs) {
                if (-d "$dir/EIJ/Unique/"){
                    my $x = `find $dir/EIJ/Unique/sense/ -name "linecount*" | xargs cat | grep "exonmappers.$i.sam" >> $ex_u_lc[$i]`;
                    my $y = `find $dir/EIJ/Unique/antisense/ -name "*linecount*" | xargs cat | grep "exonmappers.$i.sam" >> $ex_u_a_lc[$i]`;
                }
                if (-d "$dir/EIJ/NU/"){
                    my $x = `find $dir/EIJ/NU/sense/ -name "*linecount*" | xargs cat | grep "exonmappers.$i.sam" >> $ex_nu_lc[$i]`;
                    my $y = `find $dir/EIJ/NU/antisense/ -name "*linecount*" | xargs cat | grep "exonmappers.$i.sam" >> $ex_nu_a_lc[$i]`;
                }
            }
        }
        #intronmappers
        for (my $i=1; $i<=$i_intron;$i++){
            $int_u_lc[$i] = $int_u;
            $int_u_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$int_u_lc[$i]"){
                `rm $int_u_lc[$i]`;
            }
            $int_u_a_lc[$i] = $int_u_a;
            $int_u_a_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$int_u_a_lc[$i]"){
                `rm $int_u_a_lc[$i]`;
            }
            $int_nu_lc[$i] = $int_nu;
            $int_nu_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$int_nu_lc[$i]"){
                `rm $int_nu_lc[$i]`;
            }
            $int_nu_a_lc[$i] = $int_nu_a;
            $int_nu_a_lc[$i] =~ s/.txt$/.$i.txt/;
            if (-e "$int_nu_a_lc[$i]"){
                `rm $int_nu_a_lc[$i]`;
            }
            for my $dir (@dirs) {
                if (-d "$dir/EIJ/Unique/"){
                    my $x = `find $dir/EIJ/Unique/sense/ -name "*linecount*" |  xargs cat | grep "intronmappers.$i.sam" >> $int_u_lc[$i]`;
                    my $y = `find $dir/EIJ/Unique/antisense/ -name "*linecount*" |  xargs cat | grep "intronmappers.$i.sam" >> $int_u_a_lc[$i]`;
                }
                if (-d "$dir/EIJ/NU/"){
                    my $x = `find $dir/EIJ/NU/sense/ -name "*linecount*" |  xargs cat | grep "intronmappers.$i.sam" >> $int_nu_lc[$i]`;
                    my $y = `find $dir/EIJ/NU/antisense/ -name "*linecount*" |  xargs cat | grep "intronmappers.$i.sam" >> $int_nu_a_lc[$i]`;
                }
            }
        }
        #intergenic and exon-inconsist
        for my $dir (@dirs) {
            if (-d "$dir/EIJ/Unique/sense/"){
                my $x = `find $dir/EIJ/Unique/sense/ -name "*linecount*" | xargs cat | grep "intergenicmappers.sam" >> $ig_u`;
                my $y = `find $dir/EIJ/Unique/sense/ -name "*linecount*" | xargs cat | grep "exon_inconsistent_reads.sam" >> $e_inc_u`;
            }
            if (-d "$dir/EIJ/NU/"){
                my $x = `find $dir/EIJ/NU/sense/ -name "*linecount*" | xargs cat | grep "intergenicmappers.sam" >> $ig_nu`;
                my $y = `find $dir/EIJ/NU/sense/ -name "*linecount*" | xargs cat | grep "exon_inconsistent_reads.sam" >> $e_inc_nu`;
            }
        }
    }
}
