class User
  include HTTParty
  base_uri 'http://github.com/api/v2/json/user'

  def self.find(username)
    get("/search/#{username}")["users"].first
  end
end
