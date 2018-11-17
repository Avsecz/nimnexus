# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

from nimnexuspkg/info import version
import nimnexuspkg/trim
import nimnexuspkg/dedup
# export fastcov
import strformat
import tables
import os

type pair = object
    f: proc()
    description: string

var dispatcher = {
  "trim": pair(f:trim.main, description:"Filter, trim and rename sequences in the fastq according to the used barcodes"),
  "dedup": pair(f:dedup.bam_dedup, description:"Remove duplicate reads from the sorted bam file"),
  }.toTable

when isMainModule:
  stderr.write_line "nimnexus version:" & version & "\n"
  var args = commandLineParams()

  if len(args) == 0 or not (args[0] in dispatcher):
    for k, v in dispatcher:
      echo &"{k}:   {v.description}"
    if len(args) > 0 and not (args[0] in dispatcher):
        echo &"unknown program '{args[0]}'"
    quit 1

  dispatcher[args[0]].f()
