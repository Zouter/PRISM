% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/qsub_run.R
\name{qsub_lapply}
\alias{qsub_lapply}
\title{Apply a Function over a List or Vector on a gridengine system!}
\usage{
qsub_lapply(X, FUN, object_envir = environment(FUN), qsub_config = NULL,
  qsub_environment = NULL, qsub_packages = NULL, ...)
}
\arguments{
\item{X}{A vector (atomic or list) or an expression object. Other objects (including classed objects) will be coerced by base::as.list.}

\item{FUN}{The function to be applied to each element of X.}

\item{object_envir}{The environment in which to go looking for the qsub_environment variables, if these are characters.}

\item{qsub_config}{The configuration to use for this execution.}

\item{qsub_environment}{\code{NULL}, a character vector or an environment. Specifies what data and functions will be uploaded to the server.}

\item{qsub_packages}{The packages to be loaded on the cluster.}

\item{...}{optional arguments to FUN.}
}
\description{
Apply a Function over a List or Vector on a gridengine system!
}
\examples{
\dontrun{
# Initial configuration and execution
qsub_config <- create_qsub_config(
  remote = "myserver",
  local_tmp_path = "/home/myuser/workspace/.r2gridengine",
  remote_tmp_path = "/scratch/myuser/.r2gridengine"
)
qsub_lapply(
  X = seq_len(3),
  FUN = function(i) { Sys.sleep(1); i+1 },
  qsub_config = qsub_config
)

# Setting a default configuration and short hand notation for execution
set_default_qsub_config(qsub_config, permanent = T)
qsub_lapply(seq_len(3), function(i) { Sys.sleep(1); i+1 })

# Overriding a default qsub_config
qsub_lapply(seq_len(3), function(i) i + 1,
  qsub_config = override_qsub_config(name = "MyJob"))

# Don't wait for results, get a handle instead and retrieve later.
handle <- qsub_lapply(seq_len(3), function(i) i + 1,
  qsub_config = override_qsub_config(wait = F))

# Wait until results have been generated on the remote

# Retrieve results
qsub_retrieve(handle)
}
}
\seealso{
\code{\link{create_qsub_config}}, \code{\link{set_default_qsub_config}}
}
