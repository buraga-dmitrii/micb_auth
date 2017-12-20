require './service'

login, password = Service.user_input_credentials

session  = Service.login_with(login, password)

accounts = Service.get_accounts(session)

code = Service.logout(session)


ap accounts

