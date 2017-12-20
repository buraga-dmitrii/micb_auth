require 'pry'
require 'ap'

require 'io/console'
require 'json'
require 'rest-client'
require './account'
require './transaction'

class Service
  BASE_MICB_URL     = 'https://wb.micb.md/way4u-wb2/api/v2'.freeze
  LOGIN_URL         = "#{BASE_MICB_URL}/session".freeze
  ACCOUNTS_URL      = "#{BASE_MICB_URL}/contracts".freeze
  TRANSACTIONS_URL  = "#{BASE_MICB_URL}/history?from=2017-11-13".freeze
  FETCHING_DATA = {
    accounts: ACCOUNTS_URL,
    transactions: TRANSACTIONS_URL
  }.freeze

  def self.user_input_credentials
    print 'Login for your MICB account: '
    login    = gets.chomp
    password = STDIN.getpass('Password for your MICB account: ').chomp
    [login, password]
  end

  def self.login_with(login, password)
    puts 'Trying to login...'
    request {
      RestClient.post LOGIN_URL,
                      { 'login' => login,
                        'password' => password,
                        'captcha' => '' }.to_json,
                      content_type: :json, accept: :json
    }
  end

  def self.fetch_data(session, info_type)
    puts "Fetching #{info_type}..."
    response = request {
      RestClient.get FETCHING_DATA[info_type],
                     cookies: session.cookies
    }
    JSON.parse(response.body)
  end

  def self.logout(session)
    puts 'Loging out...'
    response = request { RestClient.delete LOGIN_URL, cookies: session.cookies }
    response.code
  end

  def self.get_accounts(session)
    raw_accounts = Service.fetch_data(session, :accounts)
    raw_accounts.map do |raw_account|
      account = Account.new
      account.name        = raw_account['number']
      account.balance     = raw_account['balances']['available']['value']
      account.currency    = raw_account['balances']['available']['currency']
      account.description = raw_account['number']
      account
    end
  end

  def self.get_transactions(session)
    raw_transactions = Service.fetch_data(session, :transactions)
    raw_transactions.map do |raw_transaction|
      transaction = Transaction.new
      transaction.date        = raw_transaction['operationTime']
      transaction.description = raw_transaction['service'] ? raw_transaction['service']['name'] : raw_transaction['description']
      transaction.amount      = raw_transaction['totalAmount']['value']
      transaction
    end
  end

  private

  def self.request
    yield
    rescue RestClient.ExceptionWithResponse => e
      case e.response.code
      when 405
        abort 'Access denied'
      when 412
        abort 'Invalid Login or Password'
      end
    rescue SocketError => e
      abort "Can't connect to the service"
    rescue StandardError => e
      abort "Error: #{e.message}"
    end
end
