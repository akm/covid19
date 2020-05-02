# coding: utf-8

# 概要
# data/data.json の生成
#
# 入力1: 発生状況のCSV
# 入力2: データ更新日時
# 出力: data/data.jsonを上書き

# 手順
# 1. 栃木県の公式ホームページの[栃木県における新型コロナウイルス感染症の発生状況および検査状況について]から
#    [栃木県における新型コロナウイルス感染症の発生状況一覧（エクセル）] をダウンロード
#    http://www.pref.tochigi.lg.jp/e04/welfare/hoken-eisei/kansen/hp/coronakensahasseijyoukyou.html
# 2. ダウンロードしたEXCELを開き、以下の作業を行う
#    1. 余計な行の削除
#        - 先頭のヘッダの上の1行
#        - 末尾の2行
#    2. `陽性判明日` と `退院日` の列のフォーマットを YYYY-MM-DD あるいは YYYY/MM/DD の形式に変更
#    3. CSV形式(UTF-8)で保存
# 3. convert.rb の実行
#    $ ruby convert.rb path/to/patients.csv '2020-05-02 17:35'
# 4. 動作確認
#    $ yarn dev
# 5. data/data.json の変更をコミット

require 'csv'
require 'time'
require 'date'
require 'json'

if ARGV.length < 2
  $stderr.puts("Usage: ruby convert.rb path/to/patients.csv 'YYYY-MM-DD hh:mm'")
  exit(1)
end

filepath = ARGV[0]
updated = Time.parse(ARGV[1])
residence = '那須塩原市'

def parse_date(s)
  return nil if s.nil? || s.empty?
  return Date.parse(s)
end

# CSVのヘッダ
# 番号,年代,性別,居住地,陽性判明日,退院日,備考

class Patient
  # attr_reader :num          # 番号
  attr_reader :generation   # 年代
  attr_reader :gender       # 性別
  attr_reader :residence    # 居住地
  attr_reader :released_on  # 陽性判明日
  attr_reader :recovered_on # 退院日
  attr_reader :memo         # 備考

  def initialize(row)
    # @num = row['番号']
    @residence, @generation, @gender = row['居住地'], row['年代'], row['性別']
    @released_on = parse_date(row['陽性判明日'])
    @recovered_on = parse_date(row['退院日'])
    @memo = row['備考']
  end

  def to_json(*)
    {
      "リリース日" => released_on,
     "居住地" => residence,
     "年代" => generation,
     "性別" => gender,
     "退院" => recovered_on
    }.to_json
  end
end

START_DATE = Date.new(2020, 4, 1)

def count_up_patients_by_date(dates, patients)
  date2group = patients.group_by(&:released_on)
  return dates.map do |d|
    [d, (patients = date2group[d] || []).length]
  end
end

patients = []

# https://docs.ruby-lang.org/ja/2.5.0/class/CSV.html#S_OPEN
CSV.open(filepath, headers: true) do |csv|
  csv.each do |row|
    if row['居住地'] == residence
      patients << Patient.new(row)
    end
  end
  # csv.first # => #<CSV::Row "id":"1" "first name":"taro" "last name":"tanaka" "age":"20">
end

recovered_count = patients.select(&:recovered_on).length

result = {
  "lastUpdate": updated,
  "patients" => {
    "date" => updated,
    "data" => patients,
   },
  "patients_summary" => {
    "date" => updated,
    "data" => count_up_patients_by_date(START_DATE...updated.to_date, patients),
  },
  "main_summary": {
    "attr": "検査実施人数",
    "value": 999999,
    "children": [
      {
        "attr": "陽性患者数",
        "value": patients.length,
        "children": [
          {
            "attr": "入院中",
            "value": patients.length - recovered_count,
            "children": [
              {
                "attr": "軽症・中等症",
                "value": patients.length - recovered_count,
              },
              {
                "attr": "重症",
                "value": 0
              }
            ]
          },
          {
            "attr": "退院",
            "value": recovered_count,
          },
          {
            "attr": "死亡",
            "value": 0
          }
        ]
      }
    ]
  }
}

open('data/data.json', 'w') do |f|
  f.puts JSON.pretty_generate(result)
end
