


### Mydotfile + prezto : Set Up Guide

下記linkのInstllationに従う※
[prezto](https://github.com/sorin-ionescu/prezto)

※下記には、Instllation内容と重複する箇所があります。

使用可能なshellの確認
```shell
cat /etc/shells
```

#### zshが存在している場合
```shell
chsh -s /bin/zsh
```

#### zshがない場合

brew経由でinstall
```shell
brew install --without-etcdir zsh
```

zshを使用可能にするため記述を追加する
```shell
sudo vi /etc/shells
/usr/local/bin/zsh #追記
```
これでzshが使用可能になる

次にデフォルトで使用するshellの変更を行う
```shell
chsh -s /usr/local/bin/zsh
```
ターミナル再起動で表示が変わる

以下のコマンドで再ログインとすることも可能
```shell
exec $SHELL -l
```

#### シンボリックリンク
```shell
ln -s ~/dotfiles/.zshrc ~/.zshrc
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf
```
