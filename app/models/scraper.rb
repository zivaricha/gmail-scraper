require 'google/apis/gmail_v1'
require 'nokogiri'
require 'open-uri'
class Scraper
  def self.setup_gmail_service(current_user)
    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = current_user.gmail_access_token
    service
  end
  
  def self.scrape_from_ebay(current_user)
    debugger
    scraped_transaction = Hash.new
    scraped_transaction[:user_id] = current_user.id
    service = setup_gmail_service(current_user)
    user_id = 'me'
    service_response = service.list_user_messages(user_id, {:max_results => 10, :q => "from:ebay subject:order confirmed"})
    service_response.messages.each do |message|
      user_transaction = UserTransaction.where(message_id: message.id)
      unless user_transaction.present?
        scraped_transaction[:message_id] = message.id
        full_message = service.get_user_message(user_id, message.id)
        message_headers = full_message.payload.headers
        date_header = message_headers.select {|t| t.name == "Date"}[0]
        scraped_transaction[:date] = date_header.value.to_date
        parts = full_message.payload.parts.select {|p| p.mime_type == "text/html"}
        doc = Nokogiri::HTML(parts.first.body.data)
        doc.css(".product-price").select{ |node| node.text.upcase.include? "PAID"}.each do |node|
          match_data = /\d+(\.\d{1,2})?/.match(node.text)
          scraped_transaction[:product_price] = match_data[0].to_f if match_data.present? && match_data[0].present?
        end
        product_name_node = doc.css(".product-name")[0]
        scraped_transaction[:product_name] = product_name_node.text.strip if product_name_node.present? && product_name_node.text.present?
        links_nodeset = doc.css("a")
        scraped_transaction[:seller_name] =  links_nodeset[4].text if links_nodeset.present? && links_nodeset[4].present?
        UserTransaction.create_from_transaction(scraped_transaction)
      end
    end
  end
end