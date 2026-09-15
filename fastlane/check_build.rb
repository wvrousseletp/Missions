require 'spaceship'

key_id = ENV["APP_STORE_CONNECT_API_KEY_ID"]
issuer_id = ENV["APP_STORE_CONNECT_API_KEY_ISSUER_ID"]
key_content = ENV["APP_STORE_CONNECT_API_KEY_CONTENT"]

Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: key_id,
  issuer_id: issuer_id,
  text: key_content
)

app = Spaceship::ConnectAPI::App.find("com.vicente.missions")
builds = app.get_builds(sort: "-uploadedDate", limit: 3)

builds.each do |build|
  puts "Build #{build.version} - Status: #{build.processing_state}"
end
