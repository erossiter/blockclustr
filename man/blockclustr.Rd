% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/blockclustr.R
\name{blockclustr}
\alias{blockclustr}
\title{Constructs blocked clusters for blocked and clustered random assignment}
\usage{
blockclustr(
  data,
  id_var,
  block_vars,
  n_tr,
  n_units_per_clust,
  constraint_var = NULL,
  constraint_list = NULL,
  algorithm = "optGreedy",
  distance = "mahalanobis"
)
}
\arguments{
\item{data}{A dataframe with units in rows and variables in columns.}

\item{id_var}{A string specifying which column of \code{data} is the units' unique identifier}

\item{block_vars}{A string or vector of strings specifying which columns of \code{data} are the (continuous)
blocking covariates.}

\item{n_tr}{An integer specifying the number of experimental conditions.  This is also the number of
clusters per block.}

\item{n_units_per_clust}{An integer specifying the number of units that should be assigned to each cluster.
It will not be used if \code{constraint_list} is specified.}

\item{constraint_var}{An optional string specifying which column of \code{data} is the variable
that cluster composition is constrained by.  Must also specify \code{constraint_list}.}

\item{constraint_list}{An optional list of vectors specifying all combinations of \code{constraint_var} values
that clusters can take. Must also specify \code{constraint_var}.}

\item{algorithm}{A string specifying the algorithm used to construct blockettes.  See \code{blockTools::block}
for more options and information.}

\item{distance}{A string specifying the distance calculation used when constructing blockettes.  See \code{blockTools::block}
for more options and information.}
}
\value{
Returns a list of three elements:

\itemize{
\item{\code{design}}{ a dataframe containing information about units
included in the experimental design}
\itemize{
\item{\code{id_var}}{ the supplied unique identifier}
\item{\code{block_vars}}{ the supplied blocking covariates}
\item{\code{constraint_var}}{ the supplied constraint variable, if applicable}
\item{\code{block_id}}{ an indicator for which block the unit belongs to}
\item{\code{block_id}}{ an indicator for which cluster the unit belongs to}
\item{\code{block_id}}{ a treatment indicator, corresponding with the specified number of conditions, \code{n_tr}}
}
\item{\code{raw_blockettes}}{ is the output of the \code{blockTools::block} function, used to construct blockettes}
\item{\code{unused_units}}{ a dataframe containing information about the units in \code{data} not
included in the experimental design}
}
}
\description{
Constructs blocked clusters for blocked and clustered random assignment
}
