DOTFILE_REPO="$(pwd)"
## Setup VSCode settings and keybindings
### Refer locations https://code.visualstudio.com/docs/getstarted/settings#_settings-file-locations
ln -sf "${DOTFILE_REPO}/.config/Code/User/settings.json" ~/Library/Application\ Support/Code/User/settings.json
ln -sf "${DOTFILE_REPO}/.config/Code/User/keybindings.json" ~/Library/Application\ Support/Code/User/keybindings.json

ln -sf "${DOTFILE_REPO}/.zshrc" ~/.zshrc
mkdir -p ~/.config/lf
ln -sf "${DOTFILE_REPO}/.config/lf/lfrc" ~/.config/lf/lfrc
ln -sf "${DOTFILE_REPO}/.config/starship.toml" ~/.config/starship.toml
mkdir -p ~/usr/local/etc/
ln -sf "${DOTFILE_REPO}/etc/proxychains.conf" /usr/local/etc/proxychains.conf

# Iterm2 preferences do not work with dotfile
cp "${DOTFILE_REPO}/iterm2/com.googlecode.iterm2.plist" ~/Library/Preferences/com.googlecode.iterm2.plist
