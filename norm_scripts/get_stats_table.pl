$sorted_list = $ARGV[0];
$new_table = $ARGV[1];

print "sample\ttotalnumreads\t%ribo\t%chrM\t%NU\t%1exonmappersU\t%1exonmappersNU\t%exonicU\t%exonicNU\t%intergenicU\t%intergenicNU\n";
open(IN, $sorted_list);
while ($line = <IN>){
    chomp($line);
    #totalnumreads
    $total = `cut -f 1,2 mappingstats_summary.txt | grep $line`;
    chomp($total);
    $total =~ s/$line//g;
    $total =~ s/^\s*(.*?)\s*$/$1/;
    $total =~ s/\,//g;

    #ribo
    $ribo = `cut -f 3,4 ribo_percents.txt | grep $line`; 
    chomp($ribo);
    $ribo =~ s/$line//g;
    $ribo =~ s/^\s*(.*?)\s*$/$1/;
    $ribo = $ribo * 100;

    #chrM
    $chrM = `cut -f 1,5 mappingstats_summary.txt | grep $line`;
    chomp($chrM);
    $chrM =~ s/$line//g;
    $chrM =~ s/^\s*(.*?)\s*$/$1/;
    $chrM =~ m/\((.*)\%\)/;
    $chrM_m = $1;
    
    #NU
    $NU = `cut -f 1,8 mappingstats_summary.txt | grep $line`;
    chomp($NU);
    $NU =~ s/$line//g;
    $NU =~ s/^\s*(.*?)\s*$/$1/;
    $NU =~ m/\((.*)\%\)/;
    $NU_m = $1;

    #one-vs-multi u
    $one_u = `grep $line 1exon_vs_multi_exon_stats_Unique.txt`;
    chomp($one_u);
    $one_u =~ s/$line//g;
    $one_u =~ s/^\s*(.*?)\s*$/$1/;

    #one-vs-multi nu
    $one_nu = `grep $line 1exon_vs_multi_exon_stats_NU.txt`;
    chomp($one_nu);
    $one_nu =~ s/$line//g;
    $one_nu =~ s/^\s*(.*?)\s*$/$1/;
    
    #exonic u
    $exonic_u = `grep $line exon2nonexon_signal_stats_Unique.txt`;
    chomp($exonic_u);
    $exonic_u =~ s/$line//g;
    $exonic_u =~ s/^\s*(.*?)\s*$/$1/;

    #exonic nu
    $exonic_nu = `grep $line exon2nonexon_signal_stats_NU.txt`;
    chomp($exonic_nu);
    $exonic_nu =~ s/$line//g;
    $exonic_nu =~ s/^\s*(.*?)\s*$/$1/;

    #intergenic u
    $intergenic_u = `grep $line percent_intergenic_Unique.txt`;
    chomp($intergenic_u);
    $intergenic_u =~ s/$line//g;
    $intergenic_u =~ s/^\s*(.*?)\s*$/$1/;

    #intergenic nu
    $intergenic_nu = `grep $line percent_intergenic_NU.txt`;
    chomp($intergenic_nu);
    $intergenic_nu =~ s/$line//g;
    $intergenic_nu =~ s/^\s*(.*?)\s*$/$1/;

    print "$line\t$total\t$ribo\t$chrM_m\t$NU_m\t$one_u\t$one_nu\t$exonic_u\t$exonic_nu\t$intergenic_u\t$intergenic_nu\n";
       
}
