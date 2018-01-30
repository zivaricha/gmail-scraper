require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'nokogiri'
require 'open-uri'
class SessionsController < ApplicationController
  def new
    
  end
  
  def create
    @auth = request.env['omniauth.auth']['credentials']
    @token = Token.create(access_token: @auth['token'],
      refresh_token: @auth['refresh_token'],
      expires_at: Time.at(@auth['expires_at']).to_datetime)
    debugger
    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = @token.access_token
    user_id = 'me'
    result = service.list_user_messages(user_id, {:max_results => 10, :q => "from:ebay subject:order confirmed"})
    result.messages.each do |message|
      debugger
      full_message = service.get_user_message(user_id, message.id)
      message_headers  = full_message.payload.headers
      date_header = message_headers.select {|t| t.name == "Date"}[0]
      @message_date = date_header.value.to_date
      parts = full_message.payload.parts.select {|p| p.mime_type == "text/html"}
      parts.first
      doc = Nokogiri::HTML(full_message.payload.parts.first.body.data)
      doc.css(".product-price").select{ |node| node.text.upcase.include? "PAID"}.each do |node|
       debugger
       match_data = /\d+(\.\d{1,2})?/.match(node.text)
       @price = match_data[0].to_f if match_data.present? && match_data[0].present?
      end
      product_name_node = doc.css(".product-name")[0]
      @product_name = product_name_node.text.strip if product_name_node.present? && product_name_node.text.present?
      nodeset = doc.css("a")
      @seller_name =  nodeset[4].text if nodeset.present? && nodeset[4].present?
      puts 1
    end
  end
end
