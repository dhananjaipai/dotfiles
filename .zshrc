# zmodload zsh/zprof
setopt \
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

# Do not lose history!
export HISTSIZE='1000000000'
export SAVEHIST='1000000000'

# region: OhMyZSH
export DISABLE_AUTO_UPDATE=true #Update OhMyZsh manually to speed up load times

export ZSH="$HOME/.oh-my-zsh"
plugins=(
	evalcache												# Faster Zsh Load times by caching eval outputs; 				Install: git clone https://github.com/mroth/evalcache ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/evalcache
	zsh-autosuggestions							# Autocompletions based on history; 										Install: git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	zsh-history-substring-search		# Allows fuzzy searching history; 											Install: git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
	zsh-syntax-highlighting					# Enabled syntax highlighting in zsh; 									Install: git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	auto-notify											# Notifications when long running processes complete; 	Install: git clone https://github.com/MichaelAquilina/zsh-auto-notify ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/auto-notify
	last-working-dir								# Adds a command `lwd` that allows easy switching to last working directory from other shells
	copybuffer 											# Use Ctrl+o to copy current command line command; Ref: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/copybuffer
	thefuck    											# Esc+Esc to edit last command; Conflicts with sudo; Ref: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/thefuck/README.md
	extract    											# Can unzip any compression type with `x`; Ref: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/extract/extract.plugin.zsh
	# web-search										# Allows to open search results using aliases; just alias ddg and perplexity.ai manually below
	# git														# Common git aliases; just aliased useful ones manually below
	# sudo 													# Esc+Esc to run last command as sudo; Conflicts with thefuck
	# dotenv 												# Using autoenv instead since it supports any shell scripts and functions
	# per-directory-history 				# Use Ctrl+g to switch to directory-based history for faster switching; not very useful
)

source "$ZSH/oh-my-zsh.sh"
# endregion: OhMyZSH

# region: History substring search
export HISTORY_SUBSTRING_SEARCH_FUZZY=1 # Allow fuzzy search on history
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down
# endregion: History substring search

# region: Auto notify
export AUTO_NOTIFY_THRESHOLD=60
export AUTO_NOTIFY_IGNORE=("ssh" "sleep")
# endregion: Auto notify

# region: WebSearch
alias ai='__perplexity(){ local param=$(omz_urlencode "$*"); open_command "https://www.perplexity.ai/?s=o&q=$param" }; __perplexity'
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
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"' # Commit a WIP commit; can be reverted with gunwip after switching back to the branch; Alternative is to stash and move and apply later; Ref: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh#L110
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1' # Reset a WIP commit and continue working; Better alternative may be to stash in case you want to pull upstream changes in the same branch; Ref: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh#L359
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
  [[ "$#" != 1 ]] && local b="$(git_current_branch)" # git_current_branch is part of OhMyZsh lib/git.zsh
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

# region: Zsh tab completions for command options
_comp_options+=(globdots) # Include hidden files
# autoload -U compinit # Already part of OhmyZSH
zstyle ':completion:*' menu select
zmodload zsh/complist
# compinit # Already part of OhmyZSH
# endregion: Zsh Tab completions

# region: Custom completions
_evalcache docker completion zsh
_evalcache kubectl completion zsh
# _evalcache minikube completion zsh
# endregion: Custom completions

# region: Starship prompt
## Configure prompt icon based on OS
macos=""
# ubuntu=""
# raspbian=""
export STARSHIP_PROMPT_DISTRO="$macos"
_evalcache /usr/local/bin/starship init zsh --print-full-init
# endregion: Starship

# region: autoenv + zoxide; Ref: https://github.com/hyperupcall/autoenv and https://github.com/ajeetdsouza/zoxide
export AUTOENV_ENABLE_LEAVE='yes'         # Run .env.leave when leaving directory
export AUTOENV_PRESERVE_CD='yes'          # Do not overwrite `cd`; Done through ZOxide
source /usr/local/opt/autoenv/activate.sh # Setup autoenv
_evalcache zoxide init zsh --cmd cd       # Setup Zoxide and overwrite `cd`
function __zoxide_cd() {
	autoenv_cd "${@}"
} # Overwite ZOxide to use autoenv
# endregion: autoenv + zoxide

# region: fzf
# Set up fzf key bindings and fuzzy completion
export FZF_COMPLETION_TRIGGER="*"
export FZF_DEFAULT_OPTS="--layout=reverse --history=$HOME/.fzf-history"
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
alias cc="fc -lnr -1 | copy"; bindkey -s '^x' 'cc\n' # Copy last command with ctrl-x
unalias md; function md() { [[ $# == 1 ]] && mkdir -p "$1" && cd "$1" || return; } # make and change to directory
compdef _directories md

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"

export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

# alias minikube_start='minikube start --driver=qemu --network=socket_vmnet'
# function setupdocker() {
# 	eval "$(minikube -p minikube docker-env)"
# }

# endregion: Custom aliases

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

function clearhist() { # Clear items from history
	# LC_ALL=C sed -i '' "/$1/d" $HISTFILE
	LC_ALL=C perl -0777 -pi -e "s/: \d*:\d;$1.*?:/:/gs" $HISTFILE
	# Example - clearhist "aws s3 rb"
}

# record all commands and outputs to a file
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
# endregion: Zsh Utils

# zprof
