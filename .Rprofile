options(repos=structure(c(CRAN="http://cran.cnr.berkeley.edu/")))

.First <- function() {
  if (interactive()) {
    library(utils)
    installed <- installed.packages()[,1]
    pkgs <- c("devtools", "colorout", "vimcom", "ggplot2")
    lacking <- pkgs[!(pkgs %in% installed)]
    if (length(lacking) > 0) {
      install.packages("devtools")
      library(devtools)
      install_github(c('jalvesaq/colorout', 'jalvesaq/VimCom'))
      install.packages("ggplot2")
    }

    library(ggplot2)
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

# Extract the top k most dominant frequencies from a periodogram. When
# neighborhood has a value greater than zero, this many neighboring frequencies
# left and right of a dominant frequency are also removed before considering
# the next most dominant one.
# periodogram: a periodogram object, e.g., as returned by spec.pgram().
# k: the number of most dominant frequencies to extract.
#    neighborhood: when selecting a dominant function, remove that many
#    neighbors around this frequency as well.
top.frequencies <- function(periodogram, k=3, neighborhood=0) {
    spc <- periodogram$spec
    frq <- periodogram$freq

    topk <- c()
    while (length(topk) < k)
    {
        top <- which.max(spc)
        topk[length(topk)+1] <- frq[top]
        if (neighborhood > 0)
        {
            idx <- seq(top - neighborhood, top + neighborhood)
            spc <- spc[-idx]
            frq <- frq[-idx]
        } else {
            spc <- spc[-top]
            frq <- frq[-top]
        }
    }

    topk
}

# Fit a periodic linear model with the given frequencies to a time series.
# Avoiding an intercept term in the fit can be achieved via setting
# intercept=F.
# x: the time series
# f: vector of frequencies to fit.
# intercept: whether to include an intercept term in the regression.
periodic.fit <- function(x, frequencies, intercept=T) {
  idx <- 1:length(x)
  sin.fit <- function(f) sin(2*pi*idx*f)
  cos.fit <- function(f) cos(2*pi*idx*f)

  f <- lapply(frequencies, function(f) cbind(cos.fit(f), sin.fit(f)))
  covariates <- sapply(1:length(f), function(i) paste("f[[", i, "]]", sep=""))
  add <- function(a, b) paste(a, b, sep= " + ")
  covariates <- Reduce(add, covariates)

  form <- "x ~"
  if (! intercept)
    form <- paste(form, 0, "+")
  form <- paste(form, covariates)

  lm(as.formula(form))
}

# Example usage of the above two functions.
#x1 = 2*cos(2*pi*1:100*6/100)  + 3*sin(2*pi*1:100*6/100)
#x2 = 4*cos(2*pi*1:100*10/100) + 5*sin(2*pi*1:100*10/100)
#x3 = 6*cos(2*pi*1:100*40/100) + 7*sin(2*pi*1:100*40/100)
#x = x1 + x2 + x3
#spc = spec.pgram(x, taper=0, log="no")
#freqs = top.frequencies(spc)
#fit = periodic.fit(x, freqs)
#plot.ts(x)
#lines(fitted(fit), col="red", lty=2)
