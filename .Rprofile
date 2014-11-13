options(repos=structure(c(CRAN="http://cran.cnr.berkeley.edu/")))

.First <- function() {
  if (interactive()) {
    library(utils)
    installed <- installed.packages()[,1]
    pkgs <- c("devtools", "colorout", "vimcom")
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

ccdf <- function(x) {
  x <- sort(x)
  n <- length(x)
  if (n < 1)
      stop("'x' must have 1 or more non-missing values")
  vals <- unique(x)
  rval <- approxfun(vals, 1 - cumsum(tabulate(match(x, vals)))/n,
      method = "constant", yleft = 1, yright = 0, f = 0, ties = "ordered")
  class(rval) <- c("ecdf", "stepfun", class(rval))
  assign("nobs", n, envir = environment(rval))
  attr(rval, "call") <- sys.call()
  rval
}

stat_ccdf <- function (mapping = NULL, data = NULL, geom = "step",
                       position = "identity", n = NULL, ...) {
  StatCcdf$new(mapping = mapping, data = data, geom = geom,
               position = position, n = n, ...)
}

StatCcdf <- proto::proto(ggplot2:::Stat, {
  objname <- "ccdf"

  calculate <- function(., data, scales, n = NULL, ...) {
    # If n is NULL, use raw values; otherwise interpolate
    if (is.null(n)) {
      xvals <- unique(data$x)
    } else {
      xvals <- seq(min(data$x), max(data$x), length.out = n)
    }

    y <- ccdf(data$x)(xvals)

    # make point with y = 0, from plot.stepfun
    rx <- range(xvals)
    if (length(xvals) > 1L) {
      dr <- max(0.08 * diff(rx), median(diff(xvals)))
    } else {
      dr <- abs(xvals)/16
    }

    x0 <- rx[1] - dr
    x1 <- rx[2] + dr
    y0 <- 1
    y1 <- 0

    data.frame(x = c(x0, xvals, x1), y = c(y0, y, y1))
  }

  default_aes <- function(.) aes(y = ..y..)
  required_aes <- c("x")
  default_geom <- function(.) GeomStep
})
