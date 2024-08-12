# zmodload zsh/zprof
setopt \
	auto_cd \
	auto_param_slash \
	extended_glob \
	extended_history \
	hist_expire_dups_first \
	hist_find_no_dups \
	hist_ignore_dups \
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

export HISTSIZE='1000000000'
export SAVEHIST='1000000000'

## OhMyZSH
export DISABLE_AUTO_UPDATE=true #Update manually to speed load times

export ZSH="$HOME/.oh-my-zsh"
# shellcheck disable=2034 # Used by OhMyZsh
plugins=(
	git
	last-working-dir
	web-search
	evalcache
	auto-notify
	zsh-autosuggestions
	zsh-history-substring-search
	zsh-syntax-highlighting
	copybuffer # Use Ctrl+o to copy current command line command
	thefuck    # Esc+Esc to edit last command
	extract    # Can unzip any data type
	# sudo # Competes with thefuck
	# dotenv
	# per-directory-history # Use Ctrl+g to switch to directory-based history for faster switching
)
# shellcheck disable=1090 # Dynamic path to OhMyZsh
source "$ZSH/oh-my-zsh.sh"

# export ZSH_DOTENV_PROMPT=false ## Use direnv instead to clear env on exit

### Fix slowness of pastes with zsh-syntax-highlighting.zsh
# shellcheck disable=2296,2298
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}
zstyle :bracketed-paste-magic paste-init pasteinit
pastefinish() {
  zle -N self-insert "$OLD_SELF_INSERT"
}
zstyle :bracketed-paste-magic paste-finish pastefinish
### Fix slowness of pastes

## Basic auto/tab complete for command options
# autoload -U compinit # Already part of OhmyZSH
zstyle ':completion:*' menu select
zmodload zsh/complist
# compinit # Already part of OhmyZSH
_comp_options+=(globdots) # Include hidden files

## Configure prompt icon based on OS
macos=""
# ubuntu=""
# raspbian=""
export STARSHIP_PROMPT_DISTRO="$macos"
_evalcache /usr/local/bin/starship init zsh --print-full-init

# _evalcache direnv hook zsh # Replaced with autoenv

export AUTOENV_ENABLE_LEAVE='yes'         # Run .env.leave when leaving directory
export AUTOENV_PRESERVE_CD='yes'          # Do not overwrite `cd`; Done through ZOxide
source /usr/local/opt/autoenv/activate.sh # Setup autoenv
_evalcache zoxide init zsh --cmd cd       # Setup Zoxide and overwrite `cd`
function __zoxide_cd() {
	autoenv_cd "${@}"
} # Overwite ZOxide to use autoenv

_evalcache docker completion zsh
_evalcache kubectl completion zsh
_evalcache minikube completion zsh
_evalcache thefuck --alias
_evalcache fzf --zsh

# Set up fzf key bindings and fuzzy completion
export HISTORY_SUBSTRING_SEARCH_FUZZY=1 # Allow fuzzy search on history
export FZF_COMPLETION_TRIGGER="*"
export FZF_DEFAULT_OPTS="--layout=reverse --history=$HOME/.fzf-history"

# Configure auto-notify plugin for notifications
export AUTO_NOTIFY_THRESHOLD=60
export AUTO_NOTIFY_IGNORE=("out" "sleep")

# To work with VSCode integrated terminal
# shellcheck disable=2154 # ZSH sets the values
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

# macOS
alias flushdownloads="sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2 'delete from LSQuarantineEvent'"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; sudo killall mDNSResponderHelper"
alias wifipasswordshow="security find-generic-password -wa"
bindkey "${terminfo[kcud1]}" history-substring-search-down

# alias
alias copy="pbcopy"   # MacOs
alias paste="pbpaste" # MacOs
# alias copy="xclip -sel clip"
# alias paste="xclip -out -sel clip"
alias rm="trash"
alias hs="history | grep --color -i"
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
alias fk="fuck"
alias k8s="touch .k8s"
alias xk8s="rm .k8s"
alias socksup="networksetup -setsocksfirewallproxystate Wi-Fi on"
alias socksdown="networksetup -setsocksfirewallproxystate Wi-Fi off"
alias proxyup="networksetup -setwebproxystate Wi-Fi on && networksetup -setsecurewebproxystate Wi-Fi on"
alias proxydown="networksetup -setwebproxystate Wi-Fi off && networksetup -setsecurewebproxystate Wi-Fi off"
alias socks="ssh -D 50000 -nNT pi@192.168.2.222"
alias shellproxy="export https_proxy=socks5h://192.168.2.222:50000 && export http_proxy=socks5h://192.168.2.222:50000"

# Copy last command with ctrl-x:
alias cc="fc -lnr -1 | copy"
bindkey -s '^x' 'cc\n'

unalias md
function md() { [[ $# == 1 ]] && mkdir -p "$1" && cd "$1" || return; }
compdef _directories md

# Use lf to switch directories and bind it to ctrl-o

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

function timezsh() {
	shell=${1-$SHELL}
	for i in $(seq 1 10); do /usr/bin/time "$shell" -i -c exit; done
}

function record() {
	suffix=$1
	[[ -z "${suffix}" ]] && suffix=$(date "+%Y%m%d")
	export RECORD_FILE="${HOME}/.zsh-recording-${suffix}"
	exec > >(tee -a "${HOME}/.zsh-recording-${suffix}")
}
function open-recording() {
	suffix=$1
	[[ -z "${suffix}" ]] && suffix=$(date "+%Y%m%d")
	export RECORD_FILE="${HOME}/.zsh-recording-${suffix}"
	echo "${HOME}/.zsh-recording-${suffix}"
	\less -r "${HOME}/.zsh-recording-${suffix}"
}
function delete-recording() {
	suffix=$1
	if [[ -n "${suffix}" ]]; then
		\rm "${HOME}/.zsh-recording-${suffix}" # using \command to prevent any alias from overwriting the command
	else
		echo 'delete all recordings?[y/n]'
		read ans
		[ $ans = 'y' ] && echo 'deleting files...' && \rm -v "${HOME}/.zsh-recording-"* || echo 'cancelled.'
	fi
}

### functions
function setupdocker() {
	eval "$(minikube -p minikube docker-env)"
}
# EDITOR="code --wait" fc ## Use VSCode to edit commands
# zprof
