# frozen_string_literal: true

require_relative '../../spec_helper'

describe Meta::Webhook::Application do
  include Rack::Test::Methods

  let(:app) { described_class }

  before :each do
    rpc_secret = ENV['META_RPC_SECRET']

    raise 'missing META_RPC_SECRET' unless rpc_secret

    app.set :rpc_url, ENV['META_RPC_URL'] || 'tcp://localhost:31337'
    app.set :rpc_secret, rpc_secret
  end

  context 'POST /trigger' do
    context 'with no bearer token' do
      it 'should return 401 unauthorized' do
        post '/trigger'

        expect(last_response.status).to eq 401
      end
    end

    context 'with invalid bearer token' do
      it 'should return 401 authorized' do
        header 'Authorization', 'Bearer invalid-token'
        post '/trigger'

        expect(last_response.status).to eq 401
      end
    end

    context 'with valid bearer token' do
      it 'should return 200' do
        header 'Authorization', "Bearer #{app.settings.api_token}"
        post '/trigger', "{}"

        expect(last_response.status).to eq 200
      end
    end
  end
end
