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
  TRANSACTIONS_URL  = "#{BASE_MICB_URL}/history".freeze

  def self.user_input_credentials
    print 'Login for your MICB account: '
    login    = gets.chomp
    password = STDIN.getpass('Password for your MICB account: ').chomp
    [login, password]
  end

  def self.login_with(login, password)
    request {  RestClient.post LOGIN_URL,
                      { 'login' => login,
                        'password' => password,
                        'captcha' => '' }.to_json,
                      content_type: :json, accept: :json
            }
  end

  def self.logout(session)
    response = request { RestClient.delete LOGIN_URL, cookies: session.cookies }
    response.code
  end

  def self.get_accounts(session)
    response = request { RestClient.get ACCOUNTS_URL, cookies: session.cookies }
    raw_accounts = JSON.parse(response.body)
    map_accounts(raw_accounts, session)
  end

  def self.get_transactions(session, account)
    response = request {  RestClient::Request.execute(
                          method: :get,
                          url: TRANSACTIONS_URL,
                          cookies: session.cookies,
                          headers: {
                            params: {
                              'from' => Date.today.prev_month.to_s,
                              'contractId' => account.id
                              }
                            }
                          )
                        }
    raw_transactions = JSON.parse(response.body)
    map_transactions(raw_transactions)
  end

  private

  def self.map_accounts(raw_accounts, session)
    raw_accounts.map do |raw_account|
      account = Account.new
      account.id           = raw_account['id'] || ''
      account.name         = raw_account['number'] || ''
      account.balance      = raw_account['balances']['available']['value']  || ''
      account.currency     = raw_account['balances']['available']['currency']  || ''
      account.description  = raw_account['number']  || ''
      account.transactions = Service.get_transactions(session, account) || []
      account
    end
  end

  def self.map_transactions(raw_transactions)
    raw_transactions.map do |raw_transaction|
      transaction = Transaction.new
      transaction.date        = raw_transaction['operationTime'] || ''
      transaction.description = raw_transaction['service'] ? raw_transaction['service']['name'] : raw_transaction['description']
      transaction.amount      = raw_transaction['totalAmount']['value'] || ''
      transaction
    end    
  end

  def self.request
    yield
    rescue RestClient::RequestFailed => e
      case e.response.code
      when 404
        abort 'Resource not found'
      when 405
        abort 'Access denied'
      when 412
        abort 'Invalid Login or Password'
      else
        abort e.to_s  
      end
    rescue SocketError => e
      abort "Can't connect to the service"
    rescue StandardError => e
      abort "Error: #{e.message}"
    end
end
