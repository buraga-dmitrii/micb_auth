require 'pry'
require 'ap'

require 'io/console'
require 'json'
require 'rest-client'
require './account'
require './transaction'


class Service 

  BASE_MICB_URL     = "https://wb.micb.md/way4u-wb2/api/v2"
  LOGIN_URL         = "#{BASE_MICB_URL}/session"
  ACCOUNTS_URL      = "#{BASE_MICB_URL}/contracts"
  TRANSACTIONS_URL  = "#{BASE_MICB_URL}/history?from=2017-11-13"  
  DATA = { 
           accounts: ACCOUNTS_URL,
           transactions: TRANSACTIONS_URL
         }

  def self.user_input_credentials
    print "Login for your MICB account: "
    login    = gets.chomp
    password = STDIN.getpass("Password for your MICB account: ").chomp
    [login, password]
  end


  def self.login_with(login, password)
    puts 'Trying to login...'
    begin
      response = RestClient.post LOGIN_URL,
              {"login" => login,
               "password" => password,
               "captcha" => ""}.to_json,
              {content_type: :json, accept: :json}
      
    rescue RestClient::ExceptionWithResponse => e
      if e.response.code == 412
        abort "Invalid Login or Password"
      end
    rescue StandardError => e
      binding.pry  
      p e  
    else
      cookies = response.cookies  
    end  

    response
  end


  def self.fetch_data(session, info_type)
    puts 'Fetching data...'  
    begin
      response = RestClient.get DATA[info_type], {:cookies => session.cookies}
    rescue RestClient::ExceptionWithResponse => e
      case e.response.code
      when 405
        abort "Not Allowed"
      when 412
        abort "Invalid Login or Password"
      end
    rescue StandardError => e
      binding.pry  
      p e  
    end  
    JSON.parse(response.body)
  end


  def self.logout(session)
    puts 'Loging out...'
    begin
      response = RestClient.delete LOGIN_URL, {:cookies => session.cookies}
    rescue RestClient::ExceptionWithResponse => e
      if e.response.code == 412
        abort "Invalid Login or Password"
      end
    rescue StandardError => e
      binding.pry  
    end  

    response.code
  end  

  def self.get_accounts(session)
    raw_accounts = Service::fetch_data(session, :accounts)
    accounts = []
    raw_accounts.map do |raw_account|

      account = Account.new
      account.name        = raw_account["number"]
      account.balance     = raw_account["balances"]["available"]["value"]
      account.currency    = raw_account["balances"]["available"]["currency"]
      account.description = raw_account["number"]

      accounts << account
    end

    accounts
  end  

  def self.get_transactions(session)
    raw_transactions = Service::fetch_data(session, :transactions)
    transactions = []
    raw_transactions.map do |raw_transaction|
      transaction = Transaction.new
      transaction.date        = raw_transaction["effectiveFrom"]
      transaction.description = 
           if raw_transaction["service"]
            raw_transaction["service"]["name"]
           else  
            raw_transaction["description"]
           end 
      transaction.amount      = raw_transaction["totalAmount"]["value"]

      transactions << transaction
    end

    transactions
  end    
  
end