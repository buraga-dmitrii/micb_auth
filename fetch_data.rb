require './service'

login, password = Service::user_input_credentials

session = Service::login_with(login, password)

accounts     = Service::fetch_data(session, :accounts)
transactions = Service::fetch_data(session, :transactions)

code = Service::logout(session)
