require 'spec_helper'

describe 'ApiClient' do
  before(:all) do
    load_credentials
  end

  before(:each) do
    VCR.use_cassette('login') do
      @session = ApiClient.login
    end
  end

  describe 'methods' do
    context '#login' do
      it 'returns http success' do
        VCR.use_cassette('login') do

          response = ApiClient.login

          expect(response.code).to eq(200)
        end
      end

      it 'returns cookies' do
        VCR.use_cassette('login') do
          response = ApiClient.login

          expect(response.cookies).to_not be_nil
        end
      end

      context 'raise error' do
        it 'wrong credentials' do
          VCR.use_cassette('login_error') do
            ENV['login'] = 'wrong_login'

            expect { ApiClient.login }.to raise_error(SystemExit, 'Invalid Login or Password')
          end
        end
      end
    end

    context '#fetch_accounts' do
      it 'returns array of Accounts' do
        VCR.use_cassette('fetch_accounts') do
          response = ApiClient.get_accounts(@session)

          expect(response).to be_an_instance_of(Array)
          expect(response.first).to be_a(Account)
        end
      end
    end

    context '#logout' do
      it 'returns status code 204' do
        VCR.use_cassette('logout') do
          response = ApiClient.logout(@session)

          expect(response).to eq(204)
        end
      end
    end
  end

  describe 'API requests' do
    context '#login' do
      it 'returns http success' do
        VCR.use_cassette('login') do
          response = ApiClient.login

          expect(@session.code).to eq(200)
        end
      end

      it 'returns cookies' do
        VCR.use_cassette('login') do
          response = ApiClient.login

          expect(@session.cookies).to_not be_nil
        end
      end
    end

    context '#api_accounts' do
      before do
        VCR.use_cassette('fetch_accounts') do
          @response = ApiClient.api_accounts(@session)
        end
      end

      it 'returns http success' do
        expect(@response.code).to eq(200)
      end

      it 'response with JSON body containing expected Account attributes' do
        expect(@response.body).to look_like_json
        expect(body_as_json.first).to include('id', 'number', 'balances')
        expect(body_as_json.first['balances']).to include('available')
        expect(body_as_json.first['balances']['available']).to include('value')
      end
    end

    context '#api_transactions' do
      before do
        VCR.use_cassette('fetch_accounts') do
          response = ApiClient.api_accounts(@session)
          accounts = JSON.parse(response.body)
          @account_id = accounts[0]['id']

          @response = ApiClient.api_transactions(@session, @account_id)
        end
      end

      it 'returns http success' do
        expect(@response.code).to eq(200)
      end

      it 'response with JSON body containing expected Transaction attributes' do
        expect(@response.body).to look_like_json
        expect(body_as_json.first).to include('operationTime', 'totalAmount', 'description')
      end
    end

    context '#logout' do
      it 'returns status code 204' do
        VCR.use_cassette('logout') do
          response = ApiClient.api_logout(@session)
          
          expect(response.code).to eq(204)
        end
      end
    end
  end
end
