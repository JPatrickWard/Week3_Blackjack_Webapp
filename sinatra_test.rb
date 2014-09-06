require 'sinatra'
require 'pry'

set :sessions, true

get '/' do
  'Hello World!'
  'This is a new line of code'
  'only the last line?'
end

get '/test' do
  binding.pry
  "Hello, this is the /test directory" + params[:some].to_s
end