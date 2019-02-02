## Testing nimnexus

### Trimming


```
export URL=...  # setup base url path
```
Get the data

```bash
cd data
wget $URL/for_ziga/sandbox/mesc_pbx_nexus_2_S3_R1_001.fastq.gz
wget $URL/for_ziga/sandbox/mesc_pbx_preprocessed.fastq.gz 
```

Trim the fastq (5-10min):
```bash
time pigz -cd  mesc_pbx_nexus_2_S3_R1_001.fastq.gz | nimnexus trim CTGA,TGAC,GACT,ACTG | pigz -c > mesc_pbx_nexus_2_S3_R1_001.trimmed.fas
# Output
# 
# Removed 21470893/92202987 of reads
# pigz -cd mesc_pbx_nexus_2_S3_R1_001.fastq.gz  82.07s user 32.77s system 41% cpu 4:39.94 total
# nimnexus trim CTGA,TGAC,GACT,ACTG  185.55s user 92.27s system 99% cpu 4:39.95 total
# pigz -c > mesc_pbx_nexus_2_S3_R1_001.trimmed.fastq.gz  1015.83s user 114.28s system 403% cpu 4:40.08 total
```

Compare the results

```
zdiff mesc_pbx_nexus_2_S3_R1_001.trimmed.fastq.gz mesc_pbx_preprocessed.fastq.gz | head
```

### De-duplication

Get files
```
wget $URL/MESC_TFs/raw_bam/mesc_oct4_nexus_1_id2226.bam
wget $URL/MESC_TFs/deduplicated_bam/mesc_oct4_nexus_1_id2226_filtered.bam
```

Run de-duplication. Use 10 threads. Takes ca 3 min.

```
$ time ../nimnexus dedup -t 10 data/mesc_oct4_nexus_1_id2226.bam | samtools view -b > data/mesc_oct4_nexus_1_id2226.dedup.bam
nimnexus version:0.1.0

Removed 3673272/34612851 of reads
../nimnexus dedup -t 10 data/mesc_oct4_nexus_1_id2226.bam  238.84s user 4.73s system 109% cpu 3:41.71 total
samtools view -b > data/mesc_oct4_nexus_1_id2226.dedup.bam  207.13s user 5.09s system 95% cpu 3:41.75 total
```

Compare the resulting bam file

```
diff <(samtools view mesc_oct4_nexus_1_id2226_filtered.bam | awk '{ print $3,$4 }' ) <(samtools view mesc_oct4_nexus_1_id2226.dedup.bam | awk '{ print $3,$4}' ) | head
```

This considers the genomic position to test for difference.

Example difference:

Original
```
$ samtools view mesc_oct4_nexus_1_id2226.bam | grep 4785602 | grep chr1 | head
GTAGT_GACT      0       chr1    4785602 255     35M     *       0       0       GGTTGGCCAGGCTCACTCTCGGCAAGGACCGCAGC     FFFFFFFFFFFFFF<FFFFFFFFFFFFFFFFFFFF     XA:i:0  MD:Z:35 NM:i:0
GTAGT_GACT      0       chr1    4785602 255     40M     *       0       0       GGTTGGCCAGGCTCACTCTCGGCAAGGACCGCAGCAGGTT        FFFFFFFFFFFFFFFFFFFF<FFFBFFFFFFFFFFFFFFB        XA:i:1  MD:Z:39C0       NM:i:1
```

nimnexus
```
$ samtools view mesc_oct4_nexus_1_id2226.dedup.bam | grep 4785602 | grep chr1 | head
GTAGT_GACT      0       chr1    4785602 255     35M     *       0       0       GGTTGGCCAGGCTCACTCTCGGCAAGGACCGCAGC     FFFFFFFFFFFFFF<FFFFFFFFFFFFFFFFFFFF     XA:i:0  MD:Z:35 NM:i:0
```


R-script:

```
$ samtools view mesc_oct4_nexus_1_id2226_filtered.bam | grep 4785602 | grep chr1 | head
*       0       chr1    4785602 255     35M     *       0       0       GGTTGGCCAGGCTCACTCTCGGCAAGGACCGCAGC     FFFFFFFFFFFFFF<FFFFFFFFFFFFFFFFFFFF
*       0       chr1    4785602 255     40M     *       0       0       GGTTGGCCAGGCTCACTCTCGGCAAGGACCGCAGCAGGTT        FFFFFFFFFFFFFFFFFFFF<FFFBFFFFFFFFFFFFFFB
```