import docopt
import hts
import strutils, sequtils
import tables


proc bam_dedup*() =
  let doc = format("""
Remove duplicate reads from the sorted bam file

    Usage: nimnexus dedup [options] <BAM>

Arguments:

   <BAM>    sorted BAM file

Options:

  -t --threads <int>       number of BAM decompression threads [default: 2]

Example:
  nimnexus dedup -t 10 file.bam > file.dedup.bam
    """)
  let args = docopt(doc)

  var
    bam:Bam
    obam:Bam
    threads = parse_int($args["--threads"])

  open(bam, $args["<BAM>"], threads=threads)
  open(obam, "-", threads=threads, mode="wBAM")
  obam.write_header(bam.hdr)

  var
    positions = newTable[string, int](initialSize=16384)
    i = 0
    prev_chr = ""
    prev_pos = 0
    
  for aln in bam:
    if aln.chrom != prev_chr:
      # we found a new chromosome
      prev_chr = aln.chrom
      prev_pos = 0

      # reset all the positions
      positions.clear()

    # make sure the new position is larger or equal than the previous one
    if prev_pos > aln.start:
      stderr.write_line "[dedup] Bam-file not sorted. Please sort the bam file."
      quit(2)

    # check if we alredy have the position stored
    if aln.qname in positions:
      if aln.start == positions[aln.qname]:
        # duplicated read. Skip it
        continue
    prev_pos = aln.start
    positions[aln.qname] = prev_pos

    obam.write(aln)

  obam.close()


when isMainModule:
  bam_dedup()


