options(repos=structure(c(CRAN="http://cran.cnr.berkeley.edu/")))

.First <- function() {
  if (interactive()) {
    installed <- utils::installed.packages()[,1]
    pkgs <- c("setwidth", "vimcom")
    lacking <- pkgs[!(pkgs %in% installed)]
    if (length(lacking))
      install.packages(lacking)
    lapply(pkgs, library, character.only=T)

    # See http://www.lepem.ufc.br/jaa/colorout.html for details.
    if (! is.element("colorout", installed)) {
      download.file("http://www.lepem.ufc.br/jaa/colorout_1.0-1.tar.gz",
                    destfile="colorout.tar.gz")
      install.packages("colorout.tar.gz", type="source", repos=NULL)
    }
    library(colorout)
  }
}
