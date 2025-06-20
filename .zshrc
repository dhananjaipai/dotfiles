# zmodload zsh/zprof
setopt \
	auto_param_slash \
	extended_glob \
	hist_expire_dups_first \
	hist_find_no_dups \
	hist_ignore_dups \
	hist_ignore_all_dups \
	hist_ignore_space \
	hist_save_no_dups \
	interactive_comments \
	multios \
	no_auto_remove_slash \
	no_beep \
	no_bg_nice \
	no_flow_control \
	no_list_types \
	no_prompt_bang \
	no_prompt_subst \
  share_history

# Do not lose history!
export HISTSIZE='1000000000'
export SAVEHIST='1000000000'
export HISTDUP=erase

# region: Zinit
zstyle ':zinit:*' disable-auto-update 'yes'

# Load Zinit (installed via Homebrew)
ZINIT_HOME="/usr/local/opt/zinit"  # Adjust to "/opt/homebrew/opt/zinit" on Apple Silicon if needed
# Source zinit.zsh if it exists
if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
else
  echo "Zinit not found at ${ZINIT_HOME}. Please install it." >&2
fi

# Enable Zinit completions
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light-mode for \
	zsh-users/zsh-completions \
  Aloxaf/fzf-tab \
	mroth/evalcache
# Turbo mode for faster loading (load plugins after prompt)
zinit wait lucid for \
	zsh-users/zsh-autosuggestions \
	zsh-users/zsh-history-substring-search \
	zdharma-continuum/fast-syntax-highlighting \
	MichaelAquilina/zsh-auto-notify

_comp_options+=(globdots) # Include hidden files
# Completion styling
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

zmodload zsh/complist

# Initialize completions
autoload -Uz compinit
compinit -C
zinit cdreplay -q

unalias zi
# endregion: Zinit

# region: OhMyZsh Helpers
# Platform detection for open_command
function open_command() {
  local open_cmd
  case "$OSTYPE" in
    darwin*) open_cmd='open' ;;
    linux*) open_cmd='xdg-open' ;;
    msys*|mingw*) open_cmd='start ""' ;;
    cygwin*) open_cmd='cygstart' ;;
    *) echo "Platform $OSTYPE not supported"; return 1 ;;
  esac
  ${=open_cmd} "$@" &>/dev/null
}

# Define the omz_urlencode function from Oh My Zsh for web search aliases
function omz_urlencode() {
  emulate -L zsh
  local -a opts
  zparseopts -D -E -a opts r m P
  local URL=${1}
  local REPLY=""
  local i ch hexch

  for ((i = 1; i <= ${#URL}; i++)); do
    ch=${URL[i]}
    case $ch in
      [a-zA-Z0-9.~_-]) REPLY+=${ch} ;;
      *) REPLY+=`printf '%%%02X' "'$ch"` ;;
    esac
  done
  echo ${REPLY}
}

# Add git_current_branch function from Oh My Zsh
function git_current_branch() {
  git branch --show-current 2>/dev/null
}

# Add git_main_branch function from Oh My Zsh
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in main trunk; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return
    fi
  done
  echo master
}

# Add git_develop_branch function from Oh My Zsh
function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel development; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return
    fi
  done
  echo develop
}
# endregion: OhMyZsh Helpers

# region: History substring search
export HISTORY_SUBSTRING_SEARCH_FUZZY=1 # Allow fuzzy search on history
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
# endregion: History substring search

# region: Auto notify
export AUTO_NOTIFY_THRESHOLD=60
export AUTO_NOTIFY_IGNORE=("ssh" "sleep")
# endregion: Auto notify

# region: zoxide
# Lazy-load zoxide
_z_load() {
  # Unset the wrapper function to avoid recursive calls
  unfunction z zi 2>/dev/null || true
  # Load zoxide using evalcache
  _evalcache zoxide init zsh || {
    echo "Failed to load zoxide" >&2
    return 1
  }
  # Call the actual zoxide function
  
}
z() { _z_load; __zoxide_z "$@"; }
zi() { _z_load; __zoxide_zi "$@"; }
# endregion: zoxide

# region: WebSearch
alias ppx='__perplexity(){ local param=$(omz_urlencode "$*"); open_command "https://www.perplexity.ai/?s=o&q=$param" }; __perplexity'
alias ddg='__ddg(){ local param=$(omz_urlencode "$*"); open_command "https://duckduckgo.com/?q=$param" }; __ddg'
# endregion: WebSearch

# region: Git aliases
alias gst='git status'
alias gss='git status --short'
alias glo='git log --oneline --decorate'
alias grf='git reflog'
alias gt='git tag --annotate'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'
alias gc='git commit'
alias gm='git merge'
alias gms='git merge --squash'
alias gcs='git commit --gpg-sign' # Sign with a valid GPG key
alias gaa='git add --all' # Stage all changes
alias ggpull='git pull origin "$(git_current_branch)"' # Pull current branch from origin
alias ggpush='git push origin "$(git_current_branch)"' # Push current branch to origin
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"' # Commit a WIP commit; can be reverted with gunwip after switching back to the branch; Alternative is to stash and move and apply later
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1' # Reset a WIP commit and continue working
function gb() { # Checkout to a new branch if it exists or create a branch and checkout; Ref: https://stackoverflow.com/a/26961416/8453502
	git checkout "$1" 2>/dev/null || git checkout -b "$1";
}
function gbda() { # Delete all merged branches; Ref: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh#L131C1-L133C2
  git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2>/dev/null
}
function gbds() { # Delete all squash merged branches; Ref: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh#L137C1-L148C2
  local default_branch=$(git_main_branch)
  (( ! $? )) || default_branch=$(git_develop_branch)

  git for-each-ref refs/heads/ "--format=%(refname:short)" | \
    while read branch; do
      local merge_base=$(git merge-base $default_branch $branch)
      if [[ $(git cherry $default_branch $(git commit-tree $(git rev-parse $branch\^{tree}) -p $merge_base -m _)) = -* ]]; then
        git branch -D $branch
      fi
    done
}
function ggu() { # Rebases current branch with changes from origin
  [[ "$#" != 1 ]] && local b="$(git_current_branch)"
  git pull --rebase origin "${b:=$1}"
}
function gggg() { gaa; gc -m "wip: debugging; squash this!"; ggpush; } # Just push current changes
# endregion: Git aliases

# region: Zsh Syntax Highlighting fix; Ref: https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}
pastefinish() {
  zle -N self-insert "$OLD_SELF_INSERT"
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish
# endregion Zsh Syntax Highlighting fix

# region: containers
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
docker() {
  unfunction docker
  _evalcache docker completion zsh || {
    echo "Failed to load docker completions" >&2
    command docker "$@"
    return
  }
  command docker "$@"
}
kubectl() {
  unfunction kubectl
  _evalcache kubectl completion zsh || {
		echo "Failed to load kubectl completions" >&2
		command kubectl "$@"
		return
	}
  command kubectl "$@"
}
# endregion: containers

# region: Starship prompt
## Configure prompt icon based on OS
case "$(uname -s)" in
  Darwin*)
    distro_icon="" # MacOs
    ;;
  Linux*)
    if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
			distro_icon="" # Raspbian
    elif [ -f /etc/os-release ] && grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
      distro_icon="" # Ubuntu
    fi
    ;;
  *)
    distro_icon="?"  # Unknown OS
    ;;
esac
export STARSHIP_PROMPT_DISTRO="$distro_icon"
_evalcache /usr/local/bin/starship init zsh --print-full-init
# endregion: Starship

# region: direnv
_evalcache direnv hook zsh
# endregion: direnv

# region: fzf
# Set up fzf key bindings and fuzzy completion
export FZF_COMPLETION_TRIGGER="*"
export FZF_DEFAULT_OPTS="--layout=reverse --history=$HOME/.fzf-history --preview 'bat --style=numbers   --color=always --line-range :500 {} || head -500 {}'"
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --glob "!.git/*"'
_evalcache fzf --zsh
# endregion: fzf

# region: lf terminal file manager
# Use lf to switch directories and bind it to ctrl-p
lfcd() {
	\umask 077
	tmp="$(command mktemp)"
	command lf -last-dir-path="$tmp" "$@"
	if [ -f "$tmp" ]; then
		dir="$(command cat "$tmp")"
		command rm -f "$tmp"
	else
		\return 1
	fi
	if [ -d "$dir" ] && [ "$dir" != "$(pwd)" ]; then
		\cd "$dir" || \return 1
	fi
}
bindkey -s '^p' 'lfcd\n'
# endregion: lf terminal file manager

# region: macOS poweruser aliases
alias flushdownloads="sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2 'delete from LSQuarantineEvent'"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; sudo killall mDNSResponderHelper"
alias wifipasswordshow="security find-generic-password -wa"
alias socksup="networksetup -setsocksfirewallproxystate Wi-Fi on"
alias socksdown="networksetup -setsocksfirewallproxystate Wi-Fi off"
alias proxyup="networksetup -setwebproxystate Wi-Fi on && networksetup -setsecurewebproxystate Wi-Fi on"
alias proxydown="networksetup -setwebproxystate Wi-Fi off && networksetup -setsecurewebproxystate Wi-Fi off"
# endregion: macOS poweruser aliases

# region: Custom aliases
alias copy="pbcopy"
alias paste="pbpaste"
alias rm="trash"
alias grep='grep --color'
alias ls="lsd --color always --icon always --group-directories-first"
alias ll="lsd --color always --icon always --group-directories-first --long -a"
alias lst="lsd --color always --icon always --group-directories-first --tree"
alias p="proxychains4"
alias k="kubectl"
alias ksn="kubectl config set-context --current --namespace"
alias h="helm"
alias t="terraform"
alias tap="terraform apply --auto-approve"
alias a="ansible"
alias ap="ansible-playbook"
alias socks="ssh -D 50000 -nNT pi &"
alias shellproxy="export https_proxy=socks5h://localhost:50000 && export http_proxy=socks5h://localhost:50000"
function md() { [[ $# == 1 ]] && mkdir -p "$1" && cd "$1" || return; } # make and change to directory
compdef _directories md
# endregion: Custom aliases

# region: nodejs
# Lazy-load NVM
export NVM_DIR="$HOME/.nvm"
_nvm_load() {
  # Load NVM and its completions
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
  # Remove wrapper functions to restore original commands
  unfunction nvm node npx npm yarn 2>/dev/null || true
}
# Override Node-related commands to load NVM on first use
nvm() { _nvm_load; nvm "$@"; }
node() { _nvm_load; node "$@"; }
npm() { _nvm_load; npm "$@"; }
npx() { _nvm_load; npx "$@"; }
yarn() { _nvm_load; yarn "$@"; }
# endregion: nodejs

# region: Zsh widgets
# Widget to copy the last command to clipboard
_copy_last_command() {
  local last_cmd
  # Get the last command from history, trimming whitespace
  last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [[ -n "$last_cmd" ]]; then
    # Detect platform and copy to clipboard
    if [[ "$OSTYPE" == "darwin"* ]]; then
      print -n "$last_cmd" | pbcopy
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      print -n "$last_cmd" | xclip -selection clipboard 2>/dev/null || print -n "$last_cmd" | xsel --clipboard 2>/dev/null
    fi
    # Provide feedback
    print -P "%F{green}Last command copied to clipboard: $last_cmd%f"
  else
    print -P "%F{red}No command found in history%f"
  fi
  zle reset-prompt
}

# Register widget and bind to Ctrl+X
zle -N _copy_last_command
bindkey '^X' _copy_last_command
# endregion: Zsh widgets

# region: Zsh Utils
function timezsh() { # Look at time taken to start zsh
	shell=${1-$SHELL}
	for i in $(seq 1 10); do /usr/bin/time "$shell" -i -c exit; done
}

function alive() {
	while true; do
		cliclick m:300,300
		sleep 10
		cliclick m:305,305
	done;
}

function clearhist() { # Clear items frkom history
    if [[ -z "$1" ]]; then; echo "Usage: clearhist <command_to_clear>"; return 1; fi
    LC_ALL=C perl -i -ne "print unless /$1/" "$HISTFILE"
    local old_histsize="$HISTSIZE"
    # Set HISTSIZE to 0 to effectively clear in-memory history
    HISTSIZE=0
    # Then restore HISTSIZE
    HISTSIZE="$old_histsize"
    fc -R # Reload history from HiSTFILE
    echo "Cleared history entries containing '$1'."
}

# Load Zsh Session Recording Script
if [[ -f "${HOME}/.zshrecord" ]]; then
  source "${HOME}/.zshrecord"
fi

# endregion: Zsh Utils

# zprof
