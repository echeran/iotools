ioreadBlock <- function(input, block=100000L) {
}

iostream <- function(expr, sep="|", input=file("stdin"), output=file("stdout"), block=100000L) {
}

as.output <- function(x) UseMethod("as.output")
as.output.default <- function(x) if (is.null(names(x))) as.character(x) else paste(names(x), as.character(x), sep='\t')
as.output.table <- function(x) paste(names(x), x, sep='\t')
as.output.matrix <- function(x) { o <- apply(x, 1, paste, collapse='|'); if (!is.null(rownames(x))) o <- paste(rownames(x), o, sep='\t'); o }
as.output.list <- function(x) paste(names(x), sapply(x, function (e) paste(as.character(e), collapse='|')), sep='\t')

run.chunked <- function(FUN, formatter=mstrsplit) {
  load("stream.RData", .GlobalEnv)
  if (!is.null(.GlobalEnv$load.packages)) try(for(i in .GlobalEnv$load.packages) require(i, quietly=TRUE, character.only=TRUE), silent=TRUE)
  input <- file("stdin", "rb")
  output <- stdout()
  reader <- chunk.reader(input)
  parallel <- if (!is.null(.GlobalEnv$parallel.chunks)) as.integer(.GlobalEnv$parallel.chunks)[1L] else 1L
  if (is.na(parallel) || parallel < 2L) {
    while (TRUE) {
      chunk <- read.chunk(reader)
      if (!length(chunk)) break
      writeLines(as.output(FUN(formatter(chunk))), output)
    }
  } else {
    require(parallel)
    pj <- replicate(parallel, integer())
    i <- 1L
    while (TRUE) {
      chunk <- read.chunk(reader)
      if (!length(chunk)) break
      if (inherits(pj[[i]], "parallelJob")) {
        writeLines(mccollect(pj[[i]]), output)
	mccollect(pj[[i]]) ## close child
	pj[[i]] <- integer()
      }
      pj[[i]] <- mcparallel(as.output(FUN(formatter(chunk))))
      i <- (i %% parallel) + 1L
    }
    ## collect all outstanding jobs
    while (inherits(pj[[i]], "parallelJob")) {
      writeLines(mccollect(pj[[i]]), output)
      mccollect(pj[[i]]) ## close child
      pj[[i]] <- integer()
      i <- (i %% parallel) + 1L
    }
  }
  invisible(TRUE)
}

run.map <- function() run.chunked(.GlobalEnv$map, .GlobalEnv$map.formatter)
run.reduce <- function() run.chunked(.GlobalEnv$reduce, .GlobalEnv$red.formatter)

chunk.apply <- function(input, FUN, ..., CH.MERGE=rbind, CH.MAX.SIZE=33554432) {
  if (!inherits(inherits, "ChunkReader"))
    reader <- chunk.reader(input)
  .Call(chunk_apply, reader, CH.MAX.SIZE, CH.MERGE, FUN, parent.frame(), .External(pass, ...))
}

chunk.tapply <- function(input, FUN, ..., sep='\t', CH.MERGE=rbind, CH.MAX.SIZE=33554432) {
  if (!inherits(inherits, "ChunkReader"))
    reader <- chunk.reader(input)
  .Call(chunk_tapply, reader, CH.MAX.SIZE, CH.MERGE, sep, FUN, parent.frame(), .External(pass, ...))  
}
