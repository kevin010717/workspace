# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

#if tmux has-session 2>/dev/null; then tmux attach; else tmux; fi
export PATH="$HOME/.cargo/bin:$PATH"
alias s="slides ~/termux-install/dairy.md"
alias g="glow ~/termux-install/todo.md"
alias n="nvim"
alias y="yazi"
alias c='screen -q -r -D cmus || screen -S cmus $(which --skip-alias cmus)'#shell screen -d cmus
alias gacp="git add . ; git commit -m "1" ;git push origin main"
alias h="bpytop"
alias sc="source ~/.zshrc"
alias ip="ifconfig | lolcat"
alias map="telnet mapscii.me"
alias vmwinsnapshot="sudo virsh snapshot-create-as win11 --name snapshot_name --description "快照描述""
alias vmwin='if sudo virsh domstate win11 | grep -q "shut off"; then \
    sudo nohup virsh start win11 >/dev/null 2>&1; \
fi && \
echo "f /dev/shm/looking-glass 0660 kevin kvm - " | sudo tee -a /etc/tmpfiles.d/10-looking-glass.conf && \
sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf && \
nohup looking-glass-client -F  -m KEY_ESC -m KEY_SCROLLLOCK egl:vsync >/dev/null 2>&1 &'
alias vmsuspend="sudo virsh list --name | xargs -r -I {} sudo virsh suspend {} "
alias vmshutdown="sudo virsh list --name | xargs -r -I {} sudo virsh shutdown {} "
alias vmdestroy="sudo virsh list --name | xargs -r -I {} sudo virsh destroy {} "
alias vmlist="sudo virsh list --all"
alias vl="sudo virsh list --all"
alias vubuntusnapshot="sudo virsh snapshot-create-as ubuntu24.04 --name snapshot_name --description "快照描述""
alias vmubuntu='if sudo virsh domstate ubuntu24.04 | grep -q "shut off"; then sudo nohup virsh start ubuntu24.04 >/dev/null 2>&1; fi && sudo nohup virt-viewer -f -w ubuntu24.04 >/dev/null 2>&1 &'
alias vmubuntusave="sudo virsh save ubuntu24.04 /var/lib/libvirt/qemu/save/ubuntu24.04.save"
alias vmubunturestore="sudo virsh restore /var/lib/libvirt/qemu/save/ubuntu24.04.save"
alias vmubuntuedit="sudo virsh eidt ubuntu24.04"
#neofetch
#rxfetch
#date
#curl -s 'wttr.in/{shanghai,fujin}?format=4'
