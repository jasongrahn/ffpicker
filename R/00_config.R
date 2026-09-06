#' Load and validate a JSON config file against its schema.
#'
#' Fails loudly (stop()) if the config does not conform. Never returns a
#' partially-valid config, since a bad league.json must not reach a model fit.
#'
#' @param name Base name of the config, e.g. "league" or "scoring".
#' @param config_dir Directory containing `<name>.json`.
#' @param schema_dir Directory containing `<name>.schema.json`.
#' @return The parsed config as a list.
load_config <- function(name,
                         config_dir = "config",
                         schema_dir = file.path(config_dir, "schema")) {
  config_path <- file.path(config_dir, paste0(name, ".json"))
  schema_path <- file.path(schema_dir, paste0(name, ".schema.json"))

  if (!file.exists(config_path)) stop("Config file not found: ", config_path)
  if (!file.exists(schema_path)) stop("Schema file not found: ", schema_path)

  validator <- jsonvalidate::json_validator(schema_path, engine = "ajv")
  result <- validator(config_path, verbose = TRUE, greedy = TRUE)

  if (!isTRUE(result)) {
    errors <- attr(result, "errors")
    stop(
      "Config '", name, "' failed schema validation:\n",
      paste(capture.output(print(errors)), collapse = "\n")
    )
  }

  jsonlite::fromJSON(config_path, simplifyVector = FALSE)
}
