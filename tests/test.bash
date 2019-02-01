#!/usr/bin/env bash
diff <(../nimnexus dedup data/inp.bam 2> /dev/null ) data/expect.out.sam && echo "passed"
