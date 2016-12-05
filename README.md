
# Mydotfile

```
#使用可能なshellの確認
cat /etc/shells

#zshが存在している場合
chsh -s /bin/zsh
ln -s ~/dotfile/.zshrc ~/.zshrc
ln -s ~/dotfile/.tmux.conf ~/.tmux.conf
```

zshがない場合
```
#brew経由でinstall
brew install --without-etcdir zsh

#zshを使用可能にするため記述を追加する
sudo vi /etc/shells
#以下を追記する
/usr/local/bin/zsh
#これでzshが使用可能になる

#次にデフォルトで使用するshellの変更を行う
chsh -s /usr/local/bin/zsh
#ターミナル再起動で表示が変わる

#以下のコマンドで再ログインとすること可能
exec $SHELL -l

#ある場合の流れと同じようにシンボリックリンクの作成を行う

```
