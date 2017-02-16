require "rubygems"
require "sinatra"
require "sinatra/contrib"
require "sinatra/reloader" if development?
require "json"
require "dotenv"
require "omniauth"
require "omniauth-facebook"

class SinatraApp < Sinatra::Base

  configure do
    Dotenv.load
    enable :sessions

    set :inline_templates, true

    use OmniAuth::Builder do
      provider :facebook, ENV["FACEBOOK_CONSUMER_KEY"], ENV["FACEBOOK_CONSUMER_SECRET"]
    end
  end

  helpers do

    def logged_in?
      session[:facebook_oauth]
    end

    def hrfmmymt?
      session[:screen_name] === "Hirofumi Miyamoto"
    end

    def facebook
      Facebook::REST::Client.new do |config|
        config.consumer_key        = ENV["FACEBOOK_CONSUMER_KEY"]
        config.consumer_secret     = ENV["FACEBOOK_CONSUMER_SECRET"]
        config.access_token        = ENV["FACEBOOK_HRFMMYMT_TOKEN"]
      end
    end

  end

  get "/" do
    erb :index
  end

  get "/auth/:provider/callback" do
    auth = env["omniauth.auth"]

    session[:facebook_oauth] = auth[:credentials]
    session[:screen_name] = auth[:info][:name]

    erb "<h2>#{params[:provider]} logined. Hello, #{session[:screen_name]}</h2>
         <pre>#{JSON.pretty_generate(auth)}</pre>"
  end

  get "/auth/failure" do
    erb "<h2>Authentication Failed:</h2>
         <h3>message:<h3>
         <pre>#{params}</pre>"
  end

  get "/auth/:provider/deauthorized" do
    erb "#{params[:provider]} has deauthorized this app."
  end

  get "/protected" do
    throw(:halt, [401, "Not authorized\n"]) unless logged_in?

    auth = env["omniauth.auth"]
    erb "<pre>#{auth.to_json}</pre><hr>
         <a href='/logout'>Logout</a>"
  end

  get "/logout" do
    session.clear
    redirect "/"
  end

  get "/admin" do
    unless logged_in?
      session[:redirect] = request.url
      redirect "/auth/facebook"
    end

    unless hrfmmymt?
      redirect "/"
    end

    erb :admin
  end

end

SinatraApp.run! if __FILE__ == $0

__END__
