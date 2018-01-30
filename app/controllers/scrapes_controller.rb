class ScrapesController < ApplicationController
  def scrape
    Scraper.scrape_from_ebay(current_user)
    redirect_to user_transactions_path
  end
end
