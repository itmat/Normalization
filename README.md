# PORT
## RNA-Seq Normalization & Quantification
**PORT** offers two types of normalization: __GENE Normalization__ and __EXON-INTRON-JUNCTION Normalization__.

============================================================================================================================================================

### 0. Setting Up

#####A. Clone the repository
    
    git clone https://github.com/itmat/Normalization.git

#####B. Input Directory Structure
- Give `STUDY` directory a unique name.
- Make sure the unaligned reads and alignment outputs(SAM files) are in each sample directory inside the `READS` folder.
- All alignment files (SAM files) MUST have the same name.
- SAM files should have unique read ids.

<pre>
STUDY
└── READS
    ├── Sample_1
    │   ├── Unaligned reads
    │   └── Aligned.sam
    ├── Sample_2
    │   ├── Unaligned reads
    │   └── Aligned.sam
    ├── Sample_3
    │   ├── Unaligned reads
    │   └── Aligned.sam
    └── Sample_4
        ├── Unaligned reads
        └── Aligned.sam

</pre>

#####C. Configuration File
Get the `template.cfg` file from `Normalization/` and modify as you need. Follow the instructions in the config file. You can choose GENE Normalization, EXON_INTRON_JUNCTION Normalization or Both methods.

#####D. File of Sample Directories and Unaligned Reads
###### i. File of Sample Directories
Create a file &lt;sample dirs> with the names of the sample directories (without path, sorted by condition).

       e.g. the <sample dirs> file should look like this:
            Sample_1
            Sample_2
            Sample_3
            Sample_4

###### ii. File of Unaligned Reads (Forward only)
Create a file &lt;file of input forward fa/fq files> with full path of input forward fa or forward fq files.

       e.g. the <file of input forward fa/fq files> file should look like this:
            path/to/Sample_1.fwd.fq/fa
            path/to/Sample_2.fwd.fq/fa
            path/to/Sample_3.fwd.fq/fa
            path/to/Sample_4.fwd.fq/fa

#####E. Install [sam2cov](https://github.com/khayer/sam2cov/)
This is an optional step. You can use sam2cov to create coverage files and upload them to a Genome Browser. Currently, sam2cov only supports reads aligned with RUM or STAR. __Please make sure you have the lastest version of sam2cov__.

     git clone https://github.com/khayer/sam2cov.git
     cd sam2cov
     make

#####F. Index
Get the gene information file and genome sequence one-line fasta file. 
###### i. mm9, hg19, and dm3
The following files are available for download: 

     http://itmat.indexes.s3.amazonaws.com/mm9_ucsc_gene_info.txt
     http://itmat.indexes.s3.amazonaws.com/mm9_genome_one-line-seqs.fa
     http://itmat.indexes.s3.amazonaws.com/hg19_ucsc_gene_info.txt
     http://itmat.indexes.s3.amazonaws.com/hg19_genome_one-line-seqs.fa
     http://itmat.indexes.s3.amazonaws.com/dm3_refseq_gene_info.txt
     http://itmat.indexes.s3.amazonaws.com/dm3_genome_one-line-seqs.fa

###### ii. other organisms
Follow the instructions [here](https://github.com/itmat/rum/wiki/Creating-indexes) to create indexes.

#####G. Ensembl Genes
Get Ensembl Genes file. 
###### i. mm9, hg19 and dm3
Tables are available for mm9, hg19 and dm3:

    /path/to/Normalization/norm_scripts/mm9_ensGenes.txt
    /path/to/Normalization/norm_scripts/hg19_ensGenes.txt
    /path/to/Normalization/norm_scripts/dm3_ensGenes.txt

###### ii. other organisms
You can get the table from UCSC table browser. Your header must contain columns with the following suffixes: name, chrom, txStart, txEnd, exonStarts, exonEnds, name2, ensemblToGeneName.value.

#####I. Annotation File
###### i. mm9 and hg19
Tables are available for mm9 and hg19:

    /path/to/Normalization/norm_scripts/ucsc_known_mm9
    /path/to/Normalization/norm_scripts/ucsc_known_hg19

###### ii. other organisms
This file should be downloaded from UCSC known-gene track including at minimum the following suffixes: name (this should correspond to your main identifier, typically some kind of transcript id), chrom, exonStarts, exonEnd, geneSymbol, and description.

#####I. Output Directory Structure
You will find all log files and shell scripts in `STUDY/logs` and `STUDY/shell_scripts` directory, respectively. Once you complete the normalization pipeline, your directory structure will look like this if you run both Gene and Exon-Intron-Junction Normliazation (before the Clean Up step):
<pre>
STUDY
│── READS
│   ├── Sample_1
│   │   ├── EIJ
│   │   │   ├── NU
│   │   │   └── Unique
│   │   └── GNORM
│   │       ├── NU
│   │       └── Unique
│   ├── Sample_2
│   │   ├── EIJ
│   │   │   ├── NU
│   │   │   └── Unique
│   │   └── GNORM
│   │       ├── NU
│   │       └── Unique
│   ├── Sample_3
│   │   ├── EIJ
│   │   │   ├── NU
│   │   │   └── Unique
│   │   └── GNORM
│   │       ├── NU
│   │       └── Unique
│   └── Sample_4
│       ├── EIJ
│       │   ├── NU
│       │   └── Unique
│       └── GNORM
│           ├── NU
│           └── Unique
│
├── STATS
│   ├── EXON_INTRON_JUNCTION
│   └── GENE
│
│── NORMALIZED_DATA
│   ├── EXON_INTRON_JUNCTION
│   │   ├── COV
│   │   │   └── MERGED
│   │   ├── exonmappers
│   │   │   ├── MERGED
│   │   │   ├── NU
│   │   │   └── Unique
│   │   ├── FINAL_SAM
│   │   │   └── MERGED
│   │   ├── JUNCTIONS
│   │   ├── notexonmappers
│   │   │   ├── MERGED
│   │   │   ├── NU
│   │   │   └── Unique
│   │   └── SPREADSHEETS
│   └── GENE
│       ├── COV
│       │   └── MERGED
│       ├── FINAL_SAM
│       │   ├── MERGED
│       │   ├── NU
│       │   └── Unique
│       ├── JUNCTIONS
│       └── SPREADSHEETS
│
│── logs
│
└── shell_scripts
</pre>

========================================================================================================

### 1. RUN_NORMALIZATION

This runs the Normalization pipeline. <br> 
You can also run it step by step using the scripts documented in [#2. NORMALIZATION STEPS](https://github.com/itmat/Normalization/blob/master/documentation.md#2-normalization-steps).

    run_normalization --sample_dirs <file of sample_dirs> --loc <s> \
    --unaligned <file of fa/fqfiles> --samfilename <s> --cfg <cfg file> [options]

* --sample_dirs &lt;file of sample dirs> : a file with the names of the sample directories
* --loc &lt;s> : full path of the directory with the sample directories (`READS`)
* --unaligned &lt;file of fa/fqfiles> : file of fa/fqfiles
* --samfilename &lt;s> : the name of sam file (e.g. RUM.sam, Aligned.out.sam)
* --cfg <cfg file> : configuration file for the study
* option : <br>
     **[pipeline options]**<br>
     **By default**, the pipeline will run through the steps in [PART1](https://github.com/itmat/Normalization/blob/master/documentation.md#part1---both-gene-and-exon-intron-junction-normalization) and pause (recommended). You will have a chance to check the expected number of reads after normalization and the list of percent high expressors before resuming.<br>
     **-part1_part2** : Use this option if you want to run steps in PART1 and PART2 without pausing. <br>
     **-part2** : Use this option to resume the pipeline at [PART2](https://github.com/itmat/Normalization/blob/master/documentation.md#part2). You may edit the &lt;file of sample dirs> file and/or change the highexpressor cutoff value.<br>

      **[resume options]**<br>
      You may not change the normalization parameters with resume option.<br>
      **-resume** : Use this if you have a job that crashed or stopped. This runs job that has already been initialized or partially run after the last completed step. It may repeat the last completed step if necessary.<br>
      **-resume_at "&lt;step>"** : Use this if you have a job that crashed or stopped. This resumes job at "&lt;step>". **make sure full step name (found in log file) is given in quotes.**<br>(e.g. "1   "STUDY.get_total_num_reads"")<br>

     **[data type]**<br>
     **-se** : set this if the data is single end, otherwise by default it will assume it's a paired end data<br>
     **-fa** : set this if the unaligned files are in fasta format<br>
     **-fq** : set this if the unaligned files are in fastq format<br>
     **-gz** : set this if the unaligned files are compressed<br>

     **[normalization parameters]**<br>
     **-cutoff_highexp &lt;n>** : <br>is cutoff % value to identify highly expressed genes/exons.<br>
                           the script will consider genes/exons with gene/exonpercents greater than n(%) as high expressors,
                           remove them from the list of genes/exons and remove the reads that map to those genes/exons.<br>
                           (Default = 100; with the default cutoff, exons expressed >5% will be reported, but will not remove any exons from the list)<br>
     **-cutoff_lowexp &lt;n>** : <br>is cutoff counts to identify low expressors in the final spreadsheets (exon, intron and junc).<br>
                          the script will remove features with sum of counts less than <n> from all samples.<br>
                          (Default = 0; with the default cutoff, features with sum of counts = 0 will be removed from all samples)<br>

     **[exon-intron-junction normalization only]**<br>
     **-novel_off** : set this if you DO NOT want to generate/use a study-specific master list of exons<br> (By default, the pipeline will add inferred exons to the list of exons) <br>
     **-min &lt;n>** : is minimum size of inferred exon for get_novel_exons.pl script (Default = 10)<br>
     **-max &lt;n>** : is maximum size of inferred exon for get_novel_exons.pl script (Default = 1200)<br>
     **-depthE &lt;n>** : the pipeline splits filtered sam files into 1,2,3...n exonmappers and downsamples each separately.<br>
                   (Default = 20)<br>
     **-depthI &lt;n>** : the pipeline splits filtered sam files into 1,2,3...n intronmappers and downsamples each separately.<br>
                   (Default = 10)<br>
     **-h** : print usage


This creates `runall_normalization.sh` file in `STUDY/shell_scripts` directory and runs the entire normalization pipeline. In addition to the STDOUT and STDERR files in `STUDY/logs`, this will create a log file called **`STUDY/logs/$study.run_normalization.log`**, which you can use to check the status.


