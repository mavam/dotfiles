options(repos=structure(c(CRAN="http://cran.cnr.berkeley.edu/")))

.First <- function() {
  if (interactive()) {
    installed <- utils::installed.packages()[,1]
    pkgs <- c("devtools", "colorout", "VimCom")
    lacking <- pkgs[!(pkgs %in% installed)]
    if (length(lacking) > 0) {
      install.packages("devtools")
      library(devtools)
      install_github('jalvesaq/colorout')
      install_github('jalvesaq/VimCom')
    }

    library(colorout)
    library(vimcom)
  }
}
