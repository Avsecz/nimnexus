# Package
version       = "0.1.0"
author        = "Ziga Avsec"
description   = "Collection of command-line tools for working with ChIP-nexus data"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["nimnexus"]

# Dependencies

requires "nim >= 0.19.0", "hts >= 0.2.7", "docopt#0abba63" # , "nimbioseq"

# nimble build --threads:on
