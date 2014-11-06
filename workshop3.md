# RNA-Seq Workshop

> November 6, 2014

### Link to GitHub repository:
https://github.com/itmat/Normalization

---

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

    cp /opt/rna_seq/data/sample1_*.fq $HOME/workshop/reads/sample1/ 
    cp /opt/rna_seq/data/sample2_*.fq $HOME/workshop/reads/sample2/ 
    cp /opt/rna_seq/data/sample3_*.fq $HOME/workshop/reads/sample3/ 
    cp /opt/rna_seq/data/sample4_*.fq $HOME/workshop/reads/sample4/ 


### 1. STAR

    bsub -Is bash
    module load STAR-2.3.0e  

---

    cd $HOME/workshop
    cat > $HOME/workshop/sample_dirs.txt
    sample1
    sample2
    sample3
    sample4
    CTRL-D

---

    perl /opt/rna_seq/scripts/runstar_workshop.pl $HOME/workshop/sample_dirs.txt \
    $HOME/workshop/reads/ /opt/rna_seq/data/star_chr1and2andM/

---

    bjobs -w
    ls -ltr $HOME/workshop/logs/
    more $HOME/workshop/shell_scripts/sample1.runstar.sh

### 2. PORT

    cd $HOME/workshop
    tree
    ls $HOME/workshop/reads/*/*forward.fq > $HOME/workshop/unaligned.txt 
    more /opt/rna_seq/scripts/workshop.cfg

####*[PART1]*

    run_normalization --sample_dirs $HOME/workshop/sample_dirs.txt --loc $HOME/workshop/reads/ \
    --unaligned $HOME/workshop/unaligned.txt --samfilename Aligned.out.sam \
    --cfg /opt/rna_seq/scripts/workshop.cfg -fq -depthExon 3 -depthIntron 3

---

    bjobs -w
    ls -ltr $HOME/workshop/logs/
    tail -f $HOME/workshop/logs/workshop.run_normalization.log
    less -S $HOME/workshop/STATS/GENE/expected_num_reads_gnorm.txt
    less -S $HOME/workshop/STATS/EXON_INTRON_JUNCTION/expected_num_reads.txt
    more $HOME/workshop/STATS/*/percent_high_expresser_*.txt

####*[PART2]*

    run_normalization --sample_dirs $HOME/workshop/sample_dirs.txt --loc $HOME/workshop/reads/ \
    --unaligned $HOME/workshop/unaligned.txt --samfilename Aligned.out.sam \
    --cfg /opt/rna_seq/scripts/workshop.cfg -fq -depthExon 3 -depthIntron 3 -part2 -cutoff_highexp 5

---

    bjobs -w
    ls -ltr $HOME/workshop/logs/
    tail -f $HOME/workshop/logs/workshop.run_normalization.log
    cd $HOME/workshop/
    tree -d

---

###3. Data Visualization 

<a href="http://genome.ucsc.edu/index.html" target="_blank">UCSC Genome Browser</a>

    http://itmat.data.s3.amazonaws.com/workshop/mm9/sample1.junctions_hq.bb
    http://itmat.data.s3.amazonaws.com/workshop/mm9/sample1.Unique.bw
    http://itmat.data.s3.amazonaws.com/workshop/mm9/sample2.junctions_hq.bb
    http://itmat.data.s3.amazonaws.com/workshop/mm9/sample2.Unique.bw
    http://itmat.data.s3.amazonaws.com/workshop/mm9/sample3.junctions_hq.bb
    http://itmat.data.s3.amazonaws.com/workshop/mm9/sample3.Unique.bw
    http://itmat.data.s3.amazonaws.com/workshop/mm9/sample4.junctions_hq.bb
    http://itmat.data.s3.amazonaws.com/workshop/mm9/sample4.Unique.bw

    chr2:12,219,870-12,235,708

    color=255,0,0
    itemRgb=on

<a href="http://genome.ucsc.edu/cgi-bin/hgTracks?hgS_doOtherUser=submit&hgS_otherUserName=ITMAT&hgS_otherUserSessionName=hide_all&knownGene=pack&singleSearch=knownGene&position=chr2:12219870-12235708 &hubUrl=http://itmat.data.s3.amazonaws.com/workshop/all_samples.txt" target="_blank">UCSC Track Hubs</a>


###4. Differential Expression Analysis

    cd $HOME
    mkdir $HOME/differential_expression
    cd $HOME/differential_expression
    R

**In R:**

    d = read.csv("/opt/rna_seq/data/control_vs_treatment.csv",header=T,row.names=1)
    head(d)

---    

    png("eucl_dist.png")
    trans = t(d)
    hc <- hclust(dist(trans))
    plot(hc,  main="Euclidian distance", xlab = "")
    dev.off() 

---

    png("corr_dist.png")
    dd <- as.dist((1 - cor(d))/2)
    plot(hclust(dd), main=sprintf("sum of dist. %f, Correlation Distance", sum(dd)),ylim =   400)
    dev.off()

---

    data=d
    p_val = as.data.frame(c(rep(NA,dim(data)[1])))
    colnames(p_val) = "P_VAL"

    for (i in 1:dim(data)[1]) {
      p_val_cur <- tryCatch(
        wilcox.test(as.matrix(data[i,1:4]),as.matrix(data[i,5:8]),alternative="two.sided",exact=TRUE)$p.value, error=function(x) 1 )
      p_val$P_VAL[i]=p_val_cur
    }

---

    FDR <- as.data.frame(p.adjust(p_val$P_VAL, method="BH"))
    colnames(FDR) = "FDR"
    out_table = cbind(data,p_val,FDR)

    out_table_sorted = out_table[order(out_table$FDR),]

    write.csv(out_table_sorted, file="wilcox_BH_treatment_vs_ctrl.csv")

---