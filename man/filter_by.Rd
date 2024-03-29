% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/filter_by.R
\name{filter_by}
\alias{filter_by}
\title{Creates a data frame with column name given by \code{by}, and values given
by the vector \code{x}, and then uses this table to do a filtering join,
joining on the \code{by} column to return all rows matching the \code{x} values
(scientificNames, taxonIDs, etc).}
\usage{
filter_by(
  x,
  by,
  provider = getOption("taxadb_default_provider", "itis"),
  schema = c("dwc", "common"),
  version = latest_version(),
  collect = TRUE,
  db = td_connect(),
  ignore_case = FALSE
)
}
\arguments{
\item{x}{a vector of values to filter on}

\item{by}{a column name in the taxa_tbl (following Darwin Core Schema terms).
The filtering join is executed with this column as the joining variable.}

\item{provider}{from which provider should the hierarchy be returned?
Default is 'itis', which can also be configured using \verb{options(default_taxadb_provider=...")}.
See \verb{[td_create]} for a list of recognized providers.}

\item{schema}{One of "dwc" (for Darwin Core data) or "common"
(for the Common names table.)}

\item{version}{Which version of the taxadb provider database should we use?
defaults to latest.  See \link{tl_import} for details.}

\item{collect}{logical, default \code{TRUE}. Should we return an in-memory
data.frame (default, usually the most convenient), or a reference to
lazy-eval table on disk (useful for very large tables on which we may
first perform subsequent filtering operations.)}

\item{db}{a connection to the taxadb database. See details.}

\item{ignore_case}{should we ignore case (capitalization) in matching names?
Can be significantly slower to run.}
}
\value{
a data.frame in the Darwin Core tabular format containing the
matching taxonomic entities.
}
\description{
Creates a data frame with column name given by \code{by}, and values given
by the vector \code{x}, and then uses this table to do a filtering join,
joining on the \code{by} column to return all rows matching the \code{x} values
(scientificNames, taxonIDs, etc).
}
\examples{
\donttest{
  \dontshow{
   ## All examples use a temporary directory
   Sys.setenv(TAXADB_HOME=file.path(tempdir(), "taxadb"))
   options("taxadb_default_provider"="itis_test")
  }

sp <- c("Trochalopteron henrici gucenense",
        "Trochalopteron elliotii")
filter_by(sp, "scientificName")

filter_by(c("ITIS:1077358", "ITIS:175089"), "taxonID")

filter_by("Aves", "class")

}

}
\seealso{
Other filter_by: 
\code{\link{filter_common}()},
\code{\link{filter_id}()},
\code{\link{filter_name}()},
\code{\link{filter_rank}()}
}
\concept{filter_by}
