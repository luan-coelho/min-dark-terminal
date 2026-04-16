# Min Dark Theme for Oh My Zsh
# Port of Min Theme by Miguel Solorio (https://github.com/miguelsolorio/min-theme)
#
# Minimal prompt inspired by the VS Code Min Dark theme aesthetic.
# Colors: red=#FF7A84, green=#67AB91, yellow=#FFAB70,
#         blue=#79B8FF, magenta=#B392F0, cyan=#7CAFC2

setopt PROMPT_SUBST

# Git prompt configuration
ZSH_THEME_GIT_PROMPT_PREFIX="%F{magenta}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{red}*%f"
ZSH_THEME_GIT_PROMPT_CLEAN=""

_min_dark_git_info() {
  local branch
  branch=$(git_current_branch)
  [[ -z "$branch" ]] && return
  echo " $(git_prompt_info)"
}

# Line 1: directory + git
# Line 2: prompt character (gray on success, red on error)
#
#   ~/directory main *
#   >
#
PROMPT='%F{blue}%~%f$(_min_dark_git_info)
%(?:%F{white}:%F{red})>%f '

# Right prompt: show non-zero exit codes
RPROMPT='%(?,,%F{red}%?%f)'
