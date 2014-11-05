# RNA-Seq Workshop

> November 6, 2014

### Link to GitHub repository:
https://github.com/itmat/Normalization

### 0. Set up

    ssh pennkey@demohpc.pmacs.upenn.edu

---
    
    mkdir $HOME/workshop
    cd $HOME/workshop

---

    mkdir -p $HOME/workshop/reads/sample1 
    mkdir -p $HOME/workshop/reads/sample2 
    mkdir -p $HOME/workshop/reads/sample3 
    mkdir -p $HOME/workshop/reads/sample4

---

    cp /path/to/workshopdata/sample1_*.fq $HOME/workshop/reads/sample1/ 
    cp /path/to/workshopdata/sample2_*.fq $HOME/workshop/reads/sample2/ 
    cp /path/to/workshopdata/sample3_*.fq $HOME/workshop/reads/sample3/ 
    cp /path/to/workshopdata/sample4_*.fq $HOME/workshop/reads/sample4/ 

---

### 1. STAR

    bsub -Is bash
    module load STAR-2.3.0e  

---

    cat > $HOME/workshop/sample_dirs.txt
    sample1
    sample2
    sample3
    sample4 

---

    perl /path/to/workshop_scripts/runstar_workshop.pl $HOME/workshop/sample_dirs.txt $HOME/workshop/reads/ /path/to/star_chr1and2andM/ 

---

    more $HOME/workshop/shell_scripts/sample1.runstar.sh

### 2. PORT


    ls $HOME/workshop/reads/*/*forward.fq > $HOME/workshop/unaligned.txt 

---

####*[PART1]*

    run_normalization --sample_dirs $HOME/reads/sample_dirs.txt --loc $HOME/workshop/reads/ --unaligned $HOME/workshop/unaligned.txt --samfilename Aligned.out.sam --cfg /path/to/workshop_scripts/workshop.cfg -fq -depthExon 3 -depthIntron 3 

---

    more $HOME/workshop/logs/workshop.run_normalization.log
    less -S $HOME/workshop/STATS/GENE/expected_num_reads_gnorm.txt
    less -S $HOME/workshop/STATS/EXON_INTRON_JUNCTION/expected_num_reads.txt
    more $HOM$/workshop/STATS/*/percent_high_expresser_*.txt

####*[PART2]*

    run_normalization --sample_dirs $HOME/reads/sample_dirs.txt --loc $HOME/workshop/reads/ --unaligned $HOME/workshop/unaligned.txt --samfilename Aligned.out.sam --cfg /path/to/workshop_scripts/workshop.cfg -fq -depthExon 3 -depthIntron 3 -part2 -cutoff_highexp 5

---

    more $HOME/workshop/logs/workshop.run_normalization.log

---

###3. Data Visualization 

    wget http://itmat.data.s3.amazonaws.com/workshop/workshop_bw_bb.tar.gz

---

[Genome browser link](http://genome.ucsc.edu/cgi-bin/hgTracks?hgS_doOtherUser=submit&hgS_otherUserName=ITMAT&hgS_otherUserSessionName=hide_all&knownGene=pack&singleSearch=knownGene&position=chr2:12219870-12235708 &hubUrl=http://itmat.data.s3.amazonaws.com/workshop/all_samples.txt)
 

