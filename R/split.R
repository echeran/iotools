mstrsplit <- function(x, sep="|", nsep=NA, line=1L, quiet=FALSE, ncol = NA) .Call(mat_split, x, sep, nsep, line, quiet, ncol)
