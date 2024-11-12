-----------------

# PORT 
## Pipeline Of RNA-Seq Transformations
**#RNA-Seq** **#Normalization** **#Quantification**<br><br>

-----------------

### About PORT
PORT is a resampling based read-level normalization and quantification pipeline for RNA-Seq differential expression analysis and it offers two types of normalization: __GENE Normalization__ and __EXON-INTRON-JUNCTION Normalization__.

-----------------

### Running PORT
Please see the [PORT wiki](https://github.com/itmat/normalization/wiki) for usage, input/output files and an explanation of the pipeline.<br>
>PORT is designed to be run on a compute cluster. It has been tested on SGE and LSF.

-----------------

### Notes on the fixes contained in temp_fix_for_blast_job_queuing branch

We have encountered a few bugs in PORT that require substantial investigation and/or refactoring of significant portions of PORT code. While this work is under way, we have applied several hotfixes to PORT that should avoid these errors and allow PORT to complete its execution. Here we discuss these bugs and the fixes we've applied in further detail below.

#### Changes to runblast.pl script

The main orchestration script for the BLAST step (runall_runblast.pl) executes one BLAST script (runblast.pl) per sample. The BLAST scripts orchestrate the calls to the NCBI BLAST blastn executable. Each BLAST script needs to submit about 100-200 blastn jobs:

```
    runall_runblast.pl
      • runblast.pl for sample 1
          - blastn query 1 on sample 1
          - blastn query 2 on sample 1
             ...

      • runblast.pl for sample 2
          - blastn query 1 on sample 2
          - blastn query 2 on sample 2
             ...

         ...
      • runblast.pl for sample N
          - blastn query 1 on sample N
          - blastn query 2 on sample N
```

The problem arises because each BLAST script checks for the number of jobs in the queue before submitting a blastn job. If the number of jobs in the queue is lower than the user specified queue size, the BLAST script will submit an additional blastn job, otherwise it will wait for 10 seconds before inquiring the state of the queue again. Several problems arise here:
1. If the user specified queue size is smaller than the sample size N, the queue will be completely filled with BLAST scripts and there will be no room for blastn jobs. This leads to a deadlock in which each BLAST script waits for a free slot in the queue which never opens.
2. If the queue size is big enough to accommodate all BLAST scripts, but is not much bigger, then the execution time for the BLAST step might be very long since there are only few slots in the queue which can be used for blastn jobs.
3. If the queue is full, BLAST script waits 10 seconds before querying the state of the queue again. If the sample size is large, this can lead to 20-30 queries per second on average. On certain schedulers (AWS Batch), to resolve each query, multiple API calls need to be made. This can lead to over 100 API calls per second on average. Since the average number is large, there is a chance that at some point the number of API calls per second goes over the scheduler system limit which will raise an error and stop execution of PORT. Note that this situation appears even when jitter and exponential backoff are implemented.

The approach taken here for dealing with these issues is to simply remove the checks in BLAST scripts. Then, each BLAST script quickly puts all blastn jobs in the queue and then exits. The underlying assumption is that the scheduling system can handle large number of jobs in the queue (20,000 or more).


#### Changes to run_shuf.pl script

The run_shuf.pl script is responsible for randomly sampling (without replacement) a desired number of reads from a file containing a list of reads. While the broader causes underlying this bug are still under investigation, there are circumstances where this script attempts to sample more reads than are present in the read file. This causes the script to fail with the following errors:

```
Use of uninitialized value $num in substitution (s///) at norm_scripts/run_shuf.pl line 30.
Use of uninitialized value $num in scalar chomp at norm_scripts/run_shuf.pl line 31.
Use of uninitialized value $num in hash element at norm_scripts/run_shuf.pl line 32.
```

These errors are caused when the $num variable attempts to access an element of the @shuffled array that is out of bounds. The desired number of reads is specified by the script's 3rd command line argument, and this value is internally stored in the $min_num variable. The total number of reads in the input file is specified by the script's 2nd command line argument, and this value is internally stored in the $line_count variable. The @shuffled array contains one index for each read in the input file and its size is instantiated using the $line_count variable.

Calls to the run_shuf.pl script are constructed by the runall_shuf.pl script. So under certain circumstances, this script is assembling these problematic run_shuf.pl commands where the 3rd argument (desired number of reads) is greater than the 2nd argument (total number of reads / line count of input file). The line counts for each file are calculated in another part of the pipeline. So it's unclear if the error occurs within the runall_shuf.pl script, or in a part of the pipeline upstream of this script that calculates its input information.

While we search for the cause of this bug, we have applied a fix to the run_shuf.pl script that will prevent it from throwing this error. Briefly, the script sets the number of desired reads ($min_num) equal to the total number of reads ($line_count), if the desired number of reads is greater than the total number of reads.

-----------------
