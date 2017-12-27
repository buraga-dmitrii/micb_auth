require './src/apiclient'

ApiClient.user_input_credentials

puts 'Trying to login...'
session  = ApiClient.login

puts "Fetching data..."
accounts = ApiClient.get_accounts(session)

puts 'Loging out...'
code = ApiClient.logout(session)

result = JSON.pretty_generate({ "accounts":  accounts })
puts result

