% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/source.R
\name{source_file}
\alias{source_dir}
\alias{source_file}
\alias{source_test_helpers}
\title{Source a file, directory, or all helpers.}
\usage{
source_file(path, env = test_env(), chdir = TRUE, encoding = "unknown")

source_dir(path, pattern = "\\\\.[rR]$", env = test_env(), chdir = TRUE)

source_test_helpers(path = "tests/testthat", env = test_env())
}
\arguments{
\item{path}{Path to tests}

\item{env}{Environment in which to evaluate code.}

\item{chdir}{Change working directory to \code{dirname(path)}?}

\item{encoding}{File encoding, default: "unknown"}

\item{pattern}{Regular expression used to filter files}
}
\description{
The expectation is that the files can be sourced in alphabetical order.
Helper scripts are R scripts accompanying test scripts but prefixed by
\code{helper}. These scripts are once before the tests are run.
}

