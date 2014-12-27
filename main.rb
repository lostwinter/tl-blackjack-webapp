require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'aria0213'
# Set port for compatability with cloud IDE
configure :development do   
  set :bind, '0.0.0.0'   
  set :port, 3000 
end
 
get '/' do
  "This is my root page!"
end

get '/home' do 
   "Welcome yo!" 
end

get '/form' do
    erb :form
end

post '/myaction' do
    puts params[:username]
end
