require 'helper'

scope Hobbit::Session do
  setup do
    mock_app do
      include Hobbit::Session
      use Rack::Session::Cookie, secret: SecureRandom.hex(64)

      get '/' do
        session[:name] = 'hobbit'
      end

      get '/name' do
        session[:name]
      end
    end
  end

  scope '#session' do
    test 'returns a session object' do
      get '/'
      assert last_response.ok?
      assert_equal 'hobbit', last_response.body

      get '/name'
      assert last_response.ok?
      assert_equal 'hobbit', last_response.body
    end
  end
end
