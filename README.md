# nimnexus: command-line tools for processing ChIP-nexus data

+ trim: Filter, trim and rename sequences in the fastq according to the used barcodes
+ dedup: De-duplicate PCR duplicates from a sorted BAM file

## Installation

Download the binary from releases.

## Commands
### Trim

```shell
$ nimnexus trim --help
nimnexus version:0.1.0

Trim the fastq reads

    Usage: nimnexus trim [options] <barcode>

Arguments:

   <barcode>    Barcode sequences (comma-separated) that follow random barcode

Options:

  -t --trim <int>           Pre-trim all reads by this length before processing [default: 0]
  -k --keep <int>           Minimum number of bases required after barcode to keep read [default: 18]
  -r --randombarcode <int>  Number of bases at the start of each read used for random barcode [default: 5]

Example:
  zcat input.fastq.gz | nimnexus trim -t 1 CTGA,TGAC,GACT,ACTG | gzip -c > output.fastq.gz

  # Using pigz to (de-)compress in parallel
  pigz -cd input.fastq.gz | nimnexus trim -t 1 CTGA,TGAC,GACT,ACTG | pigz -c > output.fastq.gz
```


Example:
```
zcat tests/data/mesc_pbx_raw_sample.fastq.gz | ./nimnexus trim -t 1 CTGA,TGAC,GACT,ACTG  > /tmp/output.fastq
```

### Dedup

```shell
$ nimnexus dedup --help
nimnexus version:0.1.0

Remove duplicate reads from the sorted bam file

    Usage: nimnexus dedup [options] <BAM>

Arguments:

   <BAM>    sorted BAM file

Options:

  -t --threads <int>       number of BAM decompression threads [default: 2]

Example:
  nimnexus dedup -t 10 file.bam | samtools view -b > file.dedup.bam
```

Note: `nimnexus dup` writes the output in the SAM format to stdout. Hence `samtools view -b` is used to convert SAM->BAM.
