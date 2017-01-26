# sakura-rs-letsencrypt

## 前提
+ さくらのレンタルサーバスタンダードしかテストしてない
+ エラー処理してない
+ 上手くいかなくても泣かない

## 使い方

+ さくらのレンタルサーバにSSHでログインする。
+ cd ~/
+ git clone https://github.com/masa23/sakura-rs-letsencrypt.git
+ cd sakura-rs-letsencrypt
+ sh setup.sh
+ cp srl.conf.sample srl.conf
+ 事前にSNI化するドメインをコントロールパネルから登録しておく（HTTPアクセスできる状態）
+ vi srl.conf
+ sh ssl.sh
+ コントロールパネルで証明書がインストールされていることを確認する
+ SNI SSLを有効にする
