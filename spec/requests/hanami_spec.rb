# frozen_string_literal: true

return unless Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0')

ENV['TZ'] ||= 'UTC'
ENV['HANAMI_ENV'] ||= 'test'
ENV['OPENAPI_OUTPUT'] ||= 'yaml'

require 'json'
require 'rack/test'

Dir.chdir('spec/apps/hanami') # HACK: for load hanami success
require 'hanami/prepare'

RSpec::OpenAPI.title = 'OpenAPI Documentation'
RSpec::OpenAPI.request_headers = %w[X-Authorization-Token Secret-Key]
RSpec::OpenAPI.response_headers = %w[X-Cursor]
RSpec::OpenAPI.path = File.expand_path("../apps/hanami/doc/openapi.#{ENV.fetch('OPENAPI_OUTPUT', nil)}", __dir__)
RSpec::OpenAPI.ignored_paths = ['/admin/masters/extensions']
RSpec::OpenAPI.comment = <<~COMMENT
  This file is auto-generated by rspec-openapi https://github.com/k0kubun/rspec-openapi

  When you write a spec in spec/requests, running the spec with `OPENAPI=1 rspec` will
  update this file automatically. You can also manually edit this file.
COMMENT
RSpec::OpenAPI.servers = [{ url: 'http://localhost:3000' }]
RSpec::OpenAPI.info = {
  description: 'My beautiful hanami API',
  license: {
    name: 'Apache 2.0',
    url: 'https://www.apache.org/licenses/LICENSE-2.0.html',
  },
}

RSpec::OpenAPI.security_schemes = {
  SecretApiKeyAuth: {
    type: 'apiKey',
    in: 'header',
    name: 'Secret-Key',
  },
}

RSpec.shared_context 'Hanami app' do
  let(:app) { Hanami.app }
end

RSpec.configure do |config|
  config.include Rack::Test::Methods, type: :request
  config.include_context 'Hanami app', type: :request
end

RSpec.describe 'Tables', type: :request do
  describe '#index' do
    context 'returns a list of tables' do
      it 'with flat query parameters' do
        get '/tables', { page: '1', per: '10' }, { 'AUTHORIZATION' => 'k0kubun', 'X_AUTHORIZATION_TOKEN' => 'token' }
        # binding.irb
        expect(last_response.status).to eq(200)
      end

      it 'with deep query parameters' do
        get '/tables', { filter: { 'name' => 'Example Table' } }, { 'AUTHORIZATION' => 'k0kubun' }
        expect(last_response.status).to eq(200)
      end

      it 'with different deep query parameters' do
        get '/tables', { filter: { 'price' => 0 } }, { 'AUTHORIZATION' => 'k0kubun' }
        expect(last_response.status).to eq(200)
      end
    end

    # it 'has a request spec which does not make any request' do
    #   expect(last_request).to eq(nil)
    # end
    # Rack::Test::Error:
    #        No request yet. Request a page first.

    it 'does not return tables if unauthorized' do
      get '/tables'
      expect(last_response.status).to eq(401)
    end
  end

  describe '#show' do
    it 'returns a table' do
      get '/tables/1', nil, { 'AUTHORIZATION' => 'k0kubun' }
      expect(last_response.status).to eq(200)
    end

    it 'does not return a table if unauthorized' do
      get '/tables/1'
      expect(last_response.status).to eq(401)
    end

    it 'does not return a table if not found' do
      get '/tables/2', nil, { 'AUTHORIZATION' => 'k0kubun' }
      expect(last_response.status).to eq(404)
    end

    it 'does not return a table if not found (openapi: false)', openapi: false do
      get '/tables/3', nil, { 'AUTHORIZATION' => 'k0kubun' }
      expect(last_response.status).to eq(404)
    end
  end

  describe '#create' do
    it 'returns a table' do
      post '/tables', {
        name: 'k0kubun',
        description: 'description',
        database_id: 2,
      }.to_json,
           { 'AUTHORIZATION' => 'k0kubun', 'CONTENT_TYPE' => 'application/json' }
      expect(last_response.status).to eq(201)
    end

    it 'fails to create a table' do
      post '/tables', {
        description: 'description',
        database_id: 2,
      }.to_json,
           { 'AUTHORIZATION' => 'k0kubun', 'CONTENT_TYPE' => 'application/json' }
      expect(last_response.status).to eq(422)
    end

    it 'fails to create a table (2)' do
      post '/tables', {
        name: 'some_invalid_name',
        description: 'description',
        database_id: 2,
      }.to_json,
           { 'AUTHORIZATION' => 'k0kubun', 'CONTENT_TYPE' => 'application/json' }
      expect(last_response.status).to eq(422)
    end
  end

  describe '#update' do
    it 'returns a table' do
      patch '/tables/1', { name: 'test' },
            { 'AUTHORIZATION' => 'k0kubun', 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' }
      expect(last_response.status).to eq(200)
    end
  end

  describe '#destroy' do
    it 'returns a table' do
      delete '/tables/1', nil, { 'AUTHORIZATION' => 'k0kubun' }
      expect(last_response.status).to eq(200)
    end

    it 'returns no content if specified' do
      delete '/tables/1', { no_content: true },
             { 'AUTHORIZATION' => 'k0kubun', 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' }
      expect(last_response.status).to eq(202)
    end
  end
end

RSpec.describe 'Images', type: :request do
  describe '#payload' do
    it 'returns a image payload' do
      get '/images/1'
      expect(last_response.status).to eq(200)
    end
  end

  describe '#index' do
    it 'can return an object with an attribute of empty array' do
      get '/images'
      expect(last_response.status).to eq(200)
    end
  end

  describe '#upload' do
    before do
      png = 'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAAAAADhZOFXAAAADklEQVQIW2P4DwUMlDEA98A/wTjP
      QBoAAAAASUVORK5CYII='.unpack1('m')
      File.binwrite('test.png', png)
    end
    let(:image) { Rack::Test::UploadedFile.new('test.png', 'image/png') }

    it 'returns a image payload with upload' do
      post '/images/upload', { 'image' => image }
      expect(last_response.status).to eq(200)
    end
  end

  describe '#upload_nested' do
    before do
      png = 'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAAAAADhZOFXAAAADklEQVQIW2P4DwUMlDEA98A/wTjP
      QBoAAAAASUVORK5CYII='.unpack1('m')
      File.binwrite('test.png', png)
    end
    let(:image) { Rack::Test::UploadedFile.new('test.png', 'image/png') }

    it 'returns a image payload with upload nested' do
      post '/images/upload_nested',  { nested_image: { image: image, caption: 'Some caption' } }
      expect(last_response.status).to eq(200)
    end
  end

  describe '#upload_multiple' do
    before do
      png = 'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAAAAADhZOFXAAAADklEQVQIW2P4DwUMlDEA98A/wTjP
      QBoAAAAASUVORK5CYII='.unpack1('m')
      File.binwrite('test.png', png)
    end
    let(:image) { Rack::Test::UploadedFile.new('test.png', 'image/png') }

    it 'returns a image payload with upload multiple' do
      post '/images/upload_multiple', { images: [image, image] }
      expect(last_response.status).to eq(200)
    end
  end

  describe '#upload_multiple_nested' do
    before do
      png = 'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAAAAADhZOFXAAAADklEQVQIW2P4DwUMlDEA98A/wTjP
      QBoAAAAASUVORK5CYII='.unpack1('m')
      File.binwrite('test.png', png)
    end
    let(:image) { Rack::Test::UploadedFile.new('test.png', 'image/png') }

    it 'returns a image payload with upload multiple nested' do
      post '/images/upload_multiple_nested', { images: [{ image: image }, { image: image }] }
      expect(last_response.status).to eq(200)
    end
  end
end

RSpec.describe 'SecretKey securityScheme',
               type: :request,
               openapi: { security: [{ 'SecretApiKeyAuth' => [] }] } do
  describe '#secret_items' do
    it 'authorizes with secret key' do
      get '/secret_items', nil,
          {
            'Secret-Key' => '42',
          }
      expect(last_response.status).to eq(200)
    end
  end
end

RSpec.describe 'Extra routes', type: :request do
  describe '#test_block', openapi: { deprecated: true } do
    it 'returns the block content' do
      get '/test_block'
      expect(last_response.status).to eq(200)
    end
  end
end

RSpec.describe 'Engine test', type: :request do
  describe 'engine routes' do
    it 'returns some content from the engine' do
      get '/my_engine/test'
      expect(last_response.status).to eq(200)
    end
  end
end

RSpec.describe 'Engine extra routes', type: :request do
  describe '#test' do
    it 'returns the block content' do
      get '/my_engine/eng/example'
      expect(last_response.status).to eq(200)
    end
  end
end

RSpec.describe 'Namespace test', type: :request do
  describe '/admin/masters/extensions' do
    it 'returns some content' do
      get '/admin/masters/extensions'
      expect(last_response.status).to eq(200)
    end

    it 'creates a content' do
      post '/admin/masters/extensions'
      expect(last_response.status).to eq(200)
    end
  end
end
