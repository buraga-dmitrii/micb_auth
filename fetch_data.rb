require './service'

login, password = Service.user_input_credentials

puts 'Trying to login...'
session  = Service.login_with(login, password)

puts "Fetching data..."
accounts = Service.get_accounts(session)


puts 'Loging out...'
code = Service.logout(session)

results = JSON.pretty_generate({ "accounts":  accounts })
puts results

