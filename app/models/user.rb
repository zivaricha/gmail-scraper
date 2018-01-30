require 'net/http'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, omniauth_providers: [:google_oauth2]
         
  has_many :user_transactions

  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data['email']).first
    auth_credentials = access_token['credentials']
    if user.expired?
      user.update_attributes(
      gmail_access_token: auth_credentials['token'],
      gmail_refresh_token: auth_credentials['refresh_token'],
      expires_at: Time.at(auth_credentials['expires_at']).to_datetime)
    else
        user = User.create(email: data['email'],
            password: Devise.friendly_token[0,20],
            gmail_access_token: auth_credentials['token'],
            gmail_refresh_token: auth_credentials['refresh_token'],
            expires_at: Time.at(auth_credentials['expires_at']).to_datetime)
    end
    user
  end
  
  def to_params
    {'refresh_token' => gmail_refresh_token,
    'client_id' => ENV['CLIENT_ID'],
    'client_secret' => ENV['CLIENT_SECRET'],
    'grant_type' => 'refresh_token',
    'prompt' => 'consent'}
  end
  
  def request_token_from_google
    url = URI("https://accounts.google.com/o/oauth2/token")
    Net::HTTP.post_form(url, self.to_params)
  end
  
  def refresh!
    response = request_token_from_google
    data = JSON.parse(response.body)
    update_attributes(
    gmail_access_token: data['access_token'],
    expires_at: Time.now + (data['expires_in'].to_i).seconds)
  end
  
  def expired?
    expires_at < Time.now
  end
  
  def fresh_token
    refresh! if expired?
    gmail_access_token
  end
end
