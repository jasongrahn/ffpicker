suppressMessages(library(dplyr))
A3 <- "docs/review/002-evidence/a3_trades"
x <- readRDS(file.path(A3, "final_tateOut_full.rds"))
res <- c("Patrick Mahomes", "Tre Tucker", "Brenton Strange", "T.J. Hockenson")
gl <- strsplit(x$give, " + ", fixed = TRUE)
ok <- !vapply(gl, function(g) any(g %in% res), TRUE) & !(x$team %in% c("Max’s TD Bombers", "Dave’s Bone Crushers"))
y <- x[ok, ]
y <- y[!(grepl("Matthew Stafford", y$give) & grepl("Kyler Murray", y$give)), ]
options(width = 250)
print(as.data.frame(y[order(-y$dP), c("team", "shape", "give", "get", "drop_us", "d_us", "d_them", "ppg_them", "dP", "dW", "dP_them", "P_them0")]) |>
  mutate(across(where(is.numeric), ~ round(.x, 2))) |> head(25), row.names = FALSE)
