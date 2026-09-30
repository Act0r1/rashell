[[ ":${${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-}}:l}:" == *:niri:* ]] && return 0
[[ "${RASHELL_TERMINAL_SESSION:-}" == rashell || ":${${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-}}:l}:" == *:hyprland:* ]] || return 0

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES+=(
  default none
  unknown-token fg=red,bold
  reserved-word fg=yellow
  alias fg=blue
  suffix-alias fg=blue,underline
  global-alias fg=cyan
  builtin fg=blue
  function fg=blue
  command fg=blue
  hashed-command fg=blue
  arg0 fg=blue
  precommand fg=yellow,underline
  commandseparator fg=yellow
  autodirectory fg=cyan,underline
  path fg=cyan,underline
  path_prefix fg=cyan,underline
  globbing fg=magenta
  history-expansion fg=magenta
  single-hyphen-option fg=magenta
  double-hyphen-option fg=magenta
  single-quoted-argument fg=green
  double-quoted-argument fg=green
  dollar-quoted-argument fg=green
  rc-quote fg=cyan
  dollar-double-quoted-argument fg=magenta
  back-double-quoted-argument fg=cyan
  back-dollar-quoted-argument fg=cyan
  command-substitution-delimiter fg=magenta
  process-substitution-delimiter fg=magenta
  back-quoted-argument-delimiter fg=magenta
  assign fg=magenta
  redirection fg=yellow
  comment fg=8
)
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=8
