class Repository
  include HTTParty
  base_uri 'http://github.com/api/v2/json/repos'

  def self.for_user(username)
    get("/show/#{username}/")["repositories"]
  end
end
