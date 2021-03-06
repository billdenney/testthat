#' Generate default testing environment.
#'
#' We use a new environment which inherits from \code{\link{globalenv}}.
#' In an ideal world, we'd avoid putting the global environment on the
#' search path for tests, but it's not currently possible without losing
#' the ability to load packages in tests.
#'
#' @keywords internal
#' @export
test_env <- function() {
  new.env(parent = globalenv())
}

#' Run all of the tests in a directory.
#'
#' Test files start with \code{test} and are executed in alphabetical order
#' (but they shouldn't have dependencies). Helper files start with
#' \code{helper} and loaded before any tests are run.
#'
#' @param path path to tests
#' @param filter If not \code{NULL}, only tests with file names matching this
#'   regular expression will be executed.  Matching will take on the file
#'   name after it has been stripped of \code{"test-"} and \code{".R"}.
#' @param ... Additional arguments passed to \code{grepl} to control filtering.
#' @inheritParams test_file
#'
#' @return The results of the reporter function on all test results.
#' @export
test_dir <- function(path, filter = NULL, reporter = "summary",
                     env = test_env(), ..., encoding = "unknown", load_helpers = TRUE) {
  if (load_helpers) {
    source_test_helpers(path, env)
  }
  paths <- find_test_scripts(path, filter, ...)

  test_files(paths, reporter = reporter, env = env, encoding = encoding)
}

test_files <- function(paths, reporter = "summary", env = test_env(),
                       encoding = "unknown") {
  if (length(paths) == 0) {
    stop('No matching test file in dir')
  }

  current_reporter <- find_reporter(reporter)
  with_reporter(
    reporter = current_reporter,
    results <- lapply(
      paths,
      test_file,
      env = env,
      reporter = current_reporter,
      start_end_reporter = FALSE,
      load_helpers = FALSE,
      encoding = encoding
    )
  )

  results <- unlist(results, recursive = FALSE)

  invisible(testthat_results(results))
}

# Filter File List for Tests, used by find_test_scripts

filter_test_scripts <- function(files, filter = NULL, invert = FALSE, ...) {
  if (!is.null(filter)) {
    test_names <- basename(files)
    test_names <- sub("^test-?", "", test_names)
    test_names <- sub("\\.[rR]$", "", test_names)

    which_files <- grepl(filter, test_names, ...)

    if (isTRUE(invert)) {
      which_files <- !which_files
    }
    files <- files[which_files]
  }
  files
}

#' Find the test files.
#' @param path path to tests
#' @param filter cf \code{\link{test_dir}}
#' @param invert If \sQuote{TRUE} return files which do \emph{not} match.
#' @param ... Additional arguments passed to \code{grepl} to control filtering.
#' @return the test file paths
#' @keywords internal
#' @export

find_test_scripts <- function(path, filter = NULL, invert = FALSE, ...) {
  files <- dir(path, "^test.*\\.[rR]$", full.names = TRUE)
  filter_test_scripts(files, filter, invert, ...)
}

#' Run all tests in specified file.
#'
#' @param path path to file
#' @param reporter reporter to use
#' @param env environment in which to execute the tests
#' @param load_helpers Source helper files before running the tests?
#' @param encoding File encoding, default is "unknown"
#' \code{unknown}.
#' @inheritParams with_reporter
#' @return the results as a "testthat_results" (list)
#' @export
test_file <- function(path, reporter = "summary", env = test_env(),
                      start_end_reporter = TRUE, load_helpers = TRUE,
                      encoding = "unknown") {
  library(testthat)

  reporter <- find_reporter(reporter)

  if (load_helpers) {
    source_test_helpers(dirname(path), env = env)
  }

  lister <- ListReporter$new()
  if (!is.null(reporter)) {
    reporter <- MultiReporter$new(reporters = list(reporter, lister))
  } else {
    reporter <- lister
  }

  on.exit({
    teardown_run(dirname(path))
    gc()
  }, add = TRUE)

  with_reporter(
    reporter = reporter,
    start_end_reporter = start_end_reporter,
    {
      lister$start_file(basename(path))

      source_file(path, new.env(parent = env),
                  chdir = TRUE, encoding = encoding)

      end_context()
    }
  )

  invisible(lister$get_results())
}
