sudo apt update -y
sudo apt upgrade -y
sudo apt install unzip git -y
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
source ~/.bashrc
nvm install 20.19
wget https://github.com/KerenBetGw/kerenbetgw.github.io/raw/refs/heads/main/files/V5.zip
unzip V5.zip
npm i --force
npm start