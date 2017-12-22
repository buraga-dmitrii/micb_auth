require './src/apiclient'

ApiCLient.user_input_credentials

puts 'Trying to login...'
session  = ApiCLient.login

puts "Fetching data..."
accounts = ApiCLient.get_accounts(session)

puts 'Loging out...'
code = ApiCLient.logout(session)

results = JSON.pretty_generate({ "accounts":  accounts })
puts results

