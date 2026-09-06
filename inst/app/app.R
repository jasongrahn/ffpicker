#' Minimal pick-entry loop: search a player (full Draft Pool, Board + fallback
#' rookies), assign to a team, append to the Pick Log, and watch the Board
#' (tiered VOR, remaining players only) re-render. Gated behind a
#' session-start setup screen (team name + your draft slot) so the Pick Log
#' always opens with that captured. Last-pick-only undo and a
#' picks-until-your-turn readout are wired in. Static pre-draft PDF export is
#' the one remaining Phase 3.5 polish item, not built here.
library(shiny)

# shiny::runApp() sets the working directory to this file's own directory
# (inst/app) for the duration of the app, so the project root is two levels up.
root <- normalizePath(file.path(getwd(), "..", ".."))

targets::tar_source(file.path(root, "R"))
league_config <- targets::tar_read(league_config, store = file.path(root, "_targets"))
draft_board <- targets::tar_read(draft_board, store = file.path(root, "_targets"))
draft_fallback <- targets::tar_read(draft_fallback, store = file.path(root, "_targets"))

log_path <- file.path(root, "data", "pick_log.jsonl")
dir.create(dirname(log_path), showWarnings = FALSE, recursive = TRUE)

setup_ui <- tagList(
  titlePanel("ffdraft — session setup"),
  fluidRow(column(
    4,
    textInput("my_team", "Your team name", value = "JGrahnasaurs"),
    numericInput("my_slot", paste0("Your draft slot (1–", league_config$teams, ")"),
                 value = NA, min = 1, max = league_config$teams, step = 1),
    actionButton("start_draft_btn", "Start Draft", class = "btn-primary"),
    div(style = "color: #b00020;", textOutput("setup_error"))
  ))
)

pick_ui <- function(initial_team) {
  tagList(
    titlePanel("ffdraft — pick entry"),
    div(
      style = "font-size: 1.3em; font-weight: bold; padding: 8px 12px; margin-bottom: 12px; background: #eef; border-radius: 4px;",
      textOutput("turn_readout", inline = TRUE)
    ),
    fluidRow(
      column(
        4,
        textInput("team", "Team", value = initial_team),
        helpText("Auto-filled by draft order (\"Team 3\", etc.) until you type",
                 "their real name — that sticks for their next turns."),
        selectizeInput("player", "Player", choices = NULL,
                       options = list(placeholder = "search a player")),
        actionButton("make_pick", "Make Pick", class = "btn-primary"),
        div(style = "margin-top: 8px;", uiOutput("undo_btn"))
      ),
      column(
        8,
        tableOutput("board"),
        h4("No current-season data yet (mostly rookies)"),
        tableOutput("fallback_board")
      )
    )
  )
}

ui <- fluidPage(uiOutput("session_ui"))

server <- function(input, output, session) {
  started <- reactiveVal(!needs_setup(log_path))

  refresh <- reactiveVal(0)
  state <- reactive({
    req(started())
    refresh()
    replay_pick_log(log_path)
  })

  output$session_ui <- renderUI({
    # isolate(): this must render pick_ui exactly once, when started() flips
    # (or on initial load if already started) -- not on every pick. state()
    # invalidates on every refresh() bump, and depending on it here would
    # rebuild the whole DOM (wiping the selectize widget) after each pick.
    if (started()) pick_ui(isolate(next_team_name(state()))) else setup_ui
  })

  output$setup_error <- renderText("")

  observeEvent(input$start_draft_btn, {
    if (!valid_my_slot(input$my_slot, league_config$teams)) {
      output$setup_error <- renderText(
        paste0("Enter a whole number between 1 and ", league_config$teams, ".")
      )
      return()
    }
    start_draft(log_path, league_config$teams, input$my_team, input$my_slot)
    started(TRUE)
  })

  observeEvent(state(), {
    # Search must draw from the full Draft Pool (Board + fallback rookies), not
    # just the ranked Board -- otherwise players with no current-season data yet
    # (has_current_data = FALSE, e.g. 2026 rookies) are invisible to search and
    # can never be drafted through the app. See combined_selectable_pool().
    s <- state()
    selectable_pool <- combined_selectable_pool(draft_board, draft_fallback)
    remaining <- remaining_draft_pool(selectable_pool, s)
    choices <- setNames(remaining$player_key,
                         paste0(remaining$player, " (", remaining$pos, " - ", remaining$team, ")"))
    # Auto-advance the Team field to whoever's on the clock next, so the
    # drafter never has to retype the correct opponent name from memory.
    team_value <- next_team_name(s)
    # onFlushed: right after started() flips, pick_ui (and its #player/#team
    # widgets) doesn't exist in the DOM yet until this reactive flush
    # completes -- an immediate update* call here would target elements the
    # client hasn't created. Deferring to onFlushed guarantees render-then-update order.
    session$onFlushed(function() {
      updateSelectizeInput(session, "player", choices = choices, selected = "", server = TRUE)
      updateTextInput(session, "team", value = team_value)
    }, once = TRUE)
  })

  observeEvent(input$make_pick, {
    req(input$player, input$team)
    player_key <- as.numeric(input$player)
    if (player_key %in% state()$drafted_players) return()
    next_slot <- length(state()$drafted_players) + 1
    append_pick_event(log_path, list(
      type = "pick_made", slot = next_slot,
      team = input$team, player_key = player_key
    ))
    refresh(isolate(refresh()) + 1)
  })

  # Last-pick-only undo: append a pick_corrected event for the most recent
  # live pick_made event's slot (docs/adr/0001-event-sourced-pick-log.md --
  # corrections are new events, history is never mutated). Disabled when
  # there's no live pick to undo (last_pick_slot is NULL).
  output$undo_btn <- renderUI({
    last_slot <- state()$last_pick_slot
    btn <- actionButton("undo_pick", "Undo Last Pick", class = "btn-warning")
    if (is.null(last_slot)) btn <- tagAppendAttributes(btn, disabled = "disabled")
    btn
  })

  observeEvent(input$undo_pick, {
    last_slot <- state()$last_pick_slot
    if (is.null(last_slot)) return()
    append_pick_event(log_path, list(type = "pick_corrected", slot = last_slot))
    refresh(isolate(refresh()) + 1)
  })

  output$turn_readout <- renderText({
    req(started())
    n <- picks_until_my_turn(state())
    if (n == 0) {
      "You're on the clock now."
    } else {
      paste0(n, if (n == 1) " pick" else " picks", " until your turn.")
    }
  })

  output$board <- renderTable({
    req(started())
    available <- remaining_draft_pool(draft_board, state())
    available <- available[order(available$tier, -available$vor), ]
    head(available[, c("tier", "player", "pos", "team", "vor")], 30)
  })

  output$fallback_board <- renderTable({
    req(started())
    available <- remaining_draft_pool(draft_fallback, state())
    head(available[, c("ecr", "player", "pos", "team")], 30)
  })
}

shinyApp(ui, server)
