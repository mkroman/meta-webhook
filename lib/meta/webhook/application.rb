# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'

# FIXME
module Meta
  module RPC
    class Client
      def disconnect
        @connection.instance_variable_get(:@socket).close
      end
    end
  end
end

module Meta
  module Webhook
    # The name of the environment variable where the API token is stored.
    WEBHOOK_TOKEN_ENV = 'META_WEBHOOK_TOKEN'

    # The Webhook web server.
    class Application < Sinatra::Base
      helpers do
        # @return [bool] true if the request contains a valid api token
        def authorized?
          return request.env['HTTP_AUTHORIZATION'] == "Bearer #{settings.api_token}"
        end

        # Return a 401 unauthorized with an appropriate json message.
        def unauthorized
          status 401
          json status: 'error', message: 'invalid api token'
        end
      end

      configure :production do
        api_token = ENV[WEBHOOK_TOKEN_ENV]
        raise "missing #{WEBHOOK_TOKEN_ENV} environment variable" unless api_token

        set :api_token, api_token
      end

      configure :development do
        # Use an insecure development secret
        api_token = 'development-api-token'
        warn "Using insecure api_token = #{api_token.inspect} because this is a development environment"

        set :api_token, api_token
      end

      post '/trigger' do
        return unauthorized unless authorized?

        body = request.body.read
        json = JSON.load body

        unless json
          status 400
          return json status: 'error', message: 'missing request payload'
        end

        method = json['method']
        params = json['params']

        begin
          client = Meta::RPC::Client.new settings.rpc_url, settings.rpc_secret
          client.connect
          result = JSON.load client.call method, params
          client.disconnect

          if result['status'] == 'error'
            json status: 'error', message: "rpc error: #{result['error']}"
          end
        rescue Meta::RPC::SharedSecretError => e
          json status: 'error', message: e.message
        rescue Errno::ECONNREFUSED => e
          json status: 'error', message: 'could not connect to rpc endpoint'
        end
      end
    end
  end
end
