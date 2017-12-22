require 'spec_helper'

describe 'request' do

  it 'login to service' do
    ENV['login']="your login"
    ENV['password']="your password"

    VCR.use_cassette('micb_login') do 
      response = ApiCLient.login
      expect(response.code).to eq(200)
    end
  end

  context 'get data' do

    before(:all) do
      VCR.use_cassette('micb_login') do 
        @session = ApiCLient.login
      end 
    end

    it 'fetch accounts' do
      VCR.use_cassette('fetch_accounts') do 
        response = ApiCLient.get_accounts(@session)
        expect(response).to be_an_instance_of(Array)
      end  
    end

    it 'login out' do
      VCR.use_cassette('logout') do 
        response = ApiCLient.logout(@session)
        expect(response).to eq(204)
      end  
    end
  end

end