require 'sinatra'
require 'line/bot'
require 'dotenv'

get '/' do
  'Hello'
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each do |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        # 緯度経度を取得する
        lat = event.message['latitude']
        lon = event.message['longitude']

        # ジャンルマスタAPIに投げてジャンルコードを取得する
        master_uri = "https://webservice.recruit.co.jp"
        req = Faraday::Connection.new(url: master_uri) do |conn|
          conn.adapter Faraday.default_adapter
          conn.request :url_encoded 
          #conn.response :logger # ログを出す
          conn.headers['Content-Type'] = 'application/json'
        end
        res = conn.get("/hotpepper/genre/v1/?key=#{ENV['']}&keyword=カフェ")
        code = res["genre"]["code"]

        # 緯度経度情報をホットペッパーAPIに投げ近くのカフェ情報をLINEクライアントに返す
        uri = "https://webservice.recruit.co.jp"
        req = Faraday::Connection.new(url: uri) do |conn|
          conn.adapter Faraday.default_adapter
          conn.request :url_encoded 
          #conn.response :logger # ログを出す
          conn.headers['Content-Type'] = 'application/json'
        end
        res = conn.get("/hotpepper/gourmet/v1/?key=#{ENV['']}&lat=#{lat}&lon=#{lon}&range=1&genre=code")
        res["shop"]["urls"]["pc"].each do |url|
          message = {
            type: 'text',
            text: url
          }
          client.reply_message(event['replyToken'], message)
        end
     end
    end
  end

  "OK"
end

private
# LINEインタフェースを設定
# 依存元のことを知っているので保守性良くない
def client
  @client ||= Line::Bot::Client.new {|config|
    config.channel_id = ENV["LINE_CHANNEL_ID"]
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]    
  }
end

