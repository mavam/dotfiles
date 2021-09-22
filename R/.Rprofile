# -- Startup ----------------------------------------------------

#options(repos=structure(c(CRAN="http://cran.cnr.berkeley.edu/")))

if (requireNamespace("rprofile", quietly = TRUE)) {
  rprofile::set_startup_options()
}

if (interactive()) {
  base::library("utils") # Needed for rdoc`?` to take precedence
  rdoc::use_rdoc()
  if (requireNamespace("rprofile", quietly = TRUE)) {
    rprofile::create_make_functions()
    .env = rprofile::set_functions()
    attach(.env)
  }
  if (requireNamespace("colorout", quietly = TRUE)) {
    base::library("colorout")
  }
  if (requireNamespace("prompt", quietly = TRUE)) {
    prompt::set_prompt(prompt::prompt_fancy)
    prettycode::prettycode()
  }
}

# -- Utilities --------------------------------------------------

# Displays a vector of colors.
swatch <- function(x) {
  par(mai=c(0.2, max(strwidth(x, "inch") + 0.4, na.rm = TRUE), 0.2, 0.4))
  barplot(rep(1, length(x)), col=rev(x), space = 0.1, axes=FALSE,
          names.arg=rev(x), cex.names=0.8, horiz=T, las=1)
}

# Generates a diverging color palette of a given size.
#   - http://tools.medialab.sciences-po.fr/iwanthue
#   - https://gist.github.com/johnbaums/45b49da5e260a9fc1cd7
iwanthue <- function(n, hmin=0, hmax=360, cmin=0, cmax=180, lmin=0, lmax=100) {
  require(colorspace)
  stopifnot(hmin >= 0, cmin >= 0, lmin >= 0,
            hmax <= 360, cmax <= 180, lmax <= 100,
            hmin <= hmax, cmin <= cmax, lmin <= lmax,
            n > 0)
  lab <- LAB(as.matrix(expand.grid(seq(0, 100, 1),
                                   seq(-100, 100, 5),
                                   seq(-110, 100, 5))))
  if (any((hmin != 0 || cmin != 0 || lmin != 0 ||
           hmax != 360 || cmax != 180 || lmax != 100))) {
    hcl <- as(lab, 'polarLUV')
    hcl_coords <- coords(hcl)
    hcl <- hcl[which(hcl_coords[, 'H'] <= hmax & hcl_coords[, 'H'] >= hmin &
                       hcl_coords[, 'C'] <= cmax & hcl_coords[, 'C'] >= cmin &
                       hcl_coords[, 'L'] <= lmax & hcl_coords[, 'L'] >= lmin), ]
    #hcl <- hcl[-which(is.na(coords(hcl)[, 2]))]
    lab <- as(hcl, 'LAB')
  }
  lab <- lab[which(!is.na(hex(lab))), ]
  clus <- kmeans(coords(lab), n, iter.max=50)
  hex(LAB(clus$centers))
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

#stat_ccdf <- function(mapping = NULL, data = NULL, geom = "step",
#                      position = "identity", n = NULL, na.rm = FALSE,
#                      show.legend = NA, inherit.aes = TRUE, ...) {
#  layer(
#    data = data,
#    mapping = mapping,
#    stat = StatCcdf,
#    geom = geom,
#    position = position,
#    show.legend = show.legend,
#    inherit.aes = inherit.aes,
#    params = list(
#      n = n,
#      na.rm = na.rm,
#      ...
#    )
#  )
#}
#
#StatCcdf <- ggproto("StatCcdf", Stat,
#  compute_group = function(data, scales, n = NULL) {
#    # If n is NULL, use raw values; otherwise interpolate
#    if (is.null(n)) {
#      xvals <- unique(data$x)
#    } else {
#      xvals <- seq(min(data$x), max(data$x), length.out = n)
#    }
#    y <- ccdf(data$x)(xvals)
#    # make point with y = 0, from plot.stepfun
#    rx <- range(xvals)
#    if (length(xvals) > 1L) {
#      dr <- max(0.08 * diff(rx), median(diff(xvals)))
#    } else {
#      dr <- abs(xvals)/16
#    }
#    x0 <- rx[1] - dr
#    x1 <- rx[2] + dr
#    y0 <- 0
#    y1 <- 1
#    data.frame(x = c(x0, xvals, x1), y = c(y0, y, y1))
#  },
#  default_aes = aes(y = ..y..),
#  required_aes = c("x")
#)

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
