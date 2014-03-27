require 'sinatra'
require 'json'
require_relative 'lib/faces.rb'

disable :protection
# set :protection, :except => [:http_origin]
# use Rack::Protection::HttpOrigin, :origin_whitelist => ['https://smokescreen.dev']

get '/' do
  File.read(File.join('public', 'index.html'))
end

post '/' do
  # puts params.to_s
  # logger.info 'This is the first one'
  # logger.info params['1'].to_s
  # image = params['upload']['1'][:tempfile].path
  # logger.info image
  # # image = 'img.png'
  headers 'Access-Control-Allow-Origin' => '*'
  # faces = Faces.faces_in(image).to_json
  body 'Foo'
end
