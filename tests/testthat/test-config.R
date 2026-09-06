test_that("real config/ files load and validate", {
  league <- load_config("league", config_dir = file.path("..", "..", "config"))
  expect_type(league, "list")
  # teams is confirmed at 10 (2026-09-04); my_slot stays null until the draft
  # order is set or Pete assigns it.
  expect_equal(league$teams, 10L)
  expect_null(league$draft$my_slot)

  scoring <- load_config("scoring", config_dir = file.path("..", "..", "config"))
  expect_equal(scoring$passing$td, 4)
})

test_that("null teams and my_slot are valid (sweep mode requirement)", {
  # The schema must accept teams/my_slot as JSON null, independent of what the
  # real config/league.json currently has filled in -- built from a synthetic
  # fixture rather than copying the real file, so this stays a true test of
  # the schema even after teams/my_slot get confirmed for real.
  tmp <- withr::local_tempdir()
  dir.create(file.path(tmp, "schema"))
  file.copy(file.path("..", "..", "config", "schema", "league.schema.json"), file.path(tmp, "schema"))

  cfg <- jsonlite::fromJSON(file.path("..", "..", "config", "league.json"), simplifyVector = FALSE)
  # `cfg$teams <- NULL` would remove the key entirely (base R list semantics);
  # single-bracket assignment with a wrapped NULL is what keeps the key with
  # an explicit null value, matching how the real config expresses "unknown".
  cfg["teams"] <- list(NULL)
  cfg$draft["my_slot"] <- list(NULL)
  jsonlite::write_json(cfg, file.path(tmp, "league.json"), auto_unbox = TRUE, null = "null")

  expect_no_error(load_config("league", config_dir = tmp, schema_dir = file.path(tmp, "schema")))
})

test_that("missing required key fails loudly", {
  tmp <- withr::local_tempdir()
  dir.create(file.path(tmp, "schema"))
  file.copy(file.path("..", "..", "config", "schema", "league.schema.json"), file.path(tmp, "schema"))

  cfg <- jsonlite::fromJSON(file.path("..", "..", "config", "league.json"), simplifyVector = FALSE)
  cfg$roster <- NULL
  jsonlite::write_json(cfg, file.path(tmp, "league.json"), auto_unbox = TRUE)

  expect_error(
    load_config("league", config_dir = tmp, schema_dir = file.path(tmp, "schema")),
    "failed schema validation"
  )
})

test_that("wrong type fails loudly", {
  tmp <- withr::local_tempdir()
  dir.create(file.path(tmp, "schema"))
  file.copy(file.path("..", "..", "config", "schema", "league.schema.json"), file.path(tmp, "schema"))

  cfg <- jsonlite::fromJSON(file.path("..", "..", "config", "league.json"), simplifyVector = FALSE)
  cfg$teams <- "twelve"  # should be integer or null, not string
  jsonlite::write_json(cfg, file.path(tmp, "league.json"), auto_unbox = TRUE)

  expect_error(
    load_config("league", config_dir = tmp, schema_dir = file.path(tmp, "schema")),
    "failed schema validation"
  )
})

test_that("missing config file fails loudly", {
  tmp <- withr::local_tempdir()
  expect_error(load_config("league", config_dir = tmp), "not found")
})
