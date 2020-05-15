# リリース作業

## 初回セットアップ

https://cloud.google.com/storage/docs/hosting-static-website に則ってGCSのバケットをセットアップ

1. [CNAME レコードの作成](https://cloud.google.com/storage/docs/hosting-static-website?hl=ja#gsutil)
1. [バケットの作成](https://cloud.google.com/storage/docs/hosting-static-website?hl=ja#create-bucket)
    - `gsutil mb -p techno-sangyou -c standard -l asia-northeast1 gs://covid19.tecowl.co.jp`
1. バケットが作られていることを[GCP Console](https://console.cloud.google.com/storage/browser?project=techno-sangyou) で確認
1. バケットを一般公開に設定
    - `gsutil iam ch allUsers:objectViewer gs://covid19.tecowl.co.jp
1. インデックスページとエラーページの設定
    - `gsutil web set -m index.html -e 404.html gs://covid19.tecowl.co.jp`

## 手順

1. https://github.com/tecowl/covid19/blob/development/convert.rb の手順で data/data.json を更新
1. `yarn generate`
1. `gsutil rsync -R dist gs://covid19.tecowl.co.jp`
1. https://covid19.tecowl.co.jp をブラウザで開いて変更が反映されていることを確認する
