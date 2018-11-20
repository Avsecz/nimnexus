import docopt
import strutils, sequtils
import strformat


type Record* = object
    ## This type represents a genetic sequence with optional quality
    id*: string
    description*: string
    quality*: string
    sequence*: string

proc toFastq*(self: Record): string =
  ## returns FASTQ formatted string of sequence record
  var header = "@" & self.id
  if self.description != "":
    header = header & " " & self.description
  header & "\n" & self.sequence & "\n+\n" & self.quality


iterator readFastq_stdin(): Record =
  ## iterator to iterate over the FASTQ records from STDIN
  var s = Record(id: "", description:"", quality: "", sequence:"")
  var lineNum = 0
  var id_specified = false
  
  # read from stdin
  for line in stdin.lines:
    if lineNum == 0:
      # ID line
      if id_specified:
        yield s
        id_specified = false
        s.id = ""
        s.description = ""
        s.sequence = ""
        s.quality = ""
      var fields = split(line[0..len(line)-1], ' ', 1)
      if len(fields) > 1:
        (s.id, s.description) = fields
        id_specified = true
      else:
        s.id = fields[0]
        id_specified = true
    elif lineNum == 1:
      # Sequence
      s.sequence = line
    # second line (+) is skipped
    elif lineNum == 3:
      # Quality
      s.quality = line
    lineNum = (lineNum + 1) mod 4

  # No more entries
  if id_specified:
    yield s

    
proc trim(trim_len: int, min_keep: int, randombarcode: int, barcodes: seq[string]) =
  ## This function reads from STDIN and writes to STDOUT
  var s = Record(id: "", description:"", quality: "", sequence:"")
  
  let fixed_barcode_start = randombarcode
  let fixed_barcode_end = randombarcode + barcodes[0].len - 1

  var
    total_reads = 0
    included_reads = 0
  for record in readFastq_stdin():
    total_reads += 1
    # scenarios when to drop the sequence
    if record.sequence.len < min_keep:
      echo "record.sequence.len < min_keep"
      continue
    for barcode in barcodes:
      if record.sequence[fixed_barcode_start..fixed_barcode_end] == barcode:
        if record.sequence.len > trim_len:
          # replace the id
          s.id = record.sequence[0..fixed_barcode_start - 1] & "_" & record.sequence[fixed_barcode_start..fixed_barcode_end]
          s.description = ""
          # trim
          s.sequence = record.sequence[fixed_barcode_end + 1..(record.sequence.len - 1 - trim_len)]
          s.quality = record.quality[fixed_barcode_end + 1..(record.sequence.len - 1 - trim_len)]
          # print to stdout
          echo s.toFastq()
          included_reads += 1
          break  # no need to search for barcodes further
    
      # Debugging
      # else:
      #   echo record.sequence[fixed_barcode_start..fixed_barcode_end] & " doesn't match " & barcode
  let removed_reads = total_reads - included_reads
  stderr.write_line &"Removed {removed_reads}/{total_reads} of reads"


proc main*() =
  let doc = format("""
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
    """)
#  -c --chunksize <int>      Number of reads to process at once (in thousands) [default: 1000]
#  -t --threads <int>        Number of threads to use in parallel [default: 2]
  # parse the CLI
  let args = docopt(doc)
  # ------------
  let trim_len = parseInt($args["--trim"])
  let min_keep = parseInt($args["--keep"])
  let barcode = $args["<barcode>"]
  let randombarcode = parseInt($args["--randombarcode"])
  # let chunksize = parseInt($args["--chunksize"])
  # let threads = parseInt($args["--threads"])  # TODO

  # split random barcodes
  let barcodes = barcode.split(",")
  trim(trim_len, min_keep, randombarcode, barcodes)

when isMainModule:
  main()
