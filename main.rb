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

# HELPERS #####################################
helpers do
def calculate_total(cards)
  array = cards.map {|e| e[1] }
  total = 0
  array.each do |a|
    if a == 'Ace' 
      total += 11
    else
      total += a.to_i == 0 ? 10 : a.to_i
    end
  end
   
  array.select {|e| e == 'Ace'}.count.times do
    break if total <= 21
      total -= 10
    end
  total
end

def card_image(card)
  suit = card[0].downcase 
  value = card[1].downcase
  "<img src='/images/cards/#{suit}_#{value}.jpg' class='image_spacing'>"
end
 
before do
  @hit_stay_buttons = true
  @show_dealer_button = false
  @play_again_button = false
end
end

# ROUTES #################################################
get '/' do
  if session[:name]
    redirect '/game'
  else
    redirect '/new_game'
  end
end

get '/new_game' do 
 erb :'new_game' 
end

post '/new_game' do
  if params[:name].empty?
      @error = "Please give your name."
      halt erb(:new_game)
  end
  session[:name] = params[:name]
  redirect '/game'
end

get '/bet' do
  erb :bet    
end

post '/bet' do
 session[:bet] = params[:bet] 
end

get '/game' do
  #Make deck and add to session
  suits = %w[Hearts Diamonds Spades Clubs]
  values = %w[2 3 4 5 6 7 8 9 10 Jack Queen King Ace]
  session[:deck] = suits.product(values).shuffle
  
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) == 21
    @success = "You hit blackjack!"
    @hit_stay_buttons = false
    @play_again_button = true
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) > 21
    @error = "You busted, Fool! Bummer."
    @hit_stay_buttons = false
    @play_again_button = true
  elsif calculate_total(session[:player_cards]) == 21
    @success = "You hit blackjack!"
    @hit_stay_buttons = false
    @play_again_button = true
  end
  erb :game
end

post '/game/player/stay' do
  @success = "You have chosen to stay."
  @hit_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @hit_stay_buttons = false
  
  total = calculate_total(session[:dealer_cards])
  
  if total == 21
    @error = "Dealer hits blackjack! You lose."
    @play_again_button = true
  elsif total > 21
    @success = "Dealer busts. You win!"
    @play_again_button = true
  elsif total >= 17
    #dealer stays
    redirect '/game/compare'
  else 
    @show_dealer_button = true
    
  end
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect 'game/dealer'
end


get '/game/compare' do
  @hit_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  
  if player_total == dealer_total
    @success = "You are tied. Push!"
    @play_again_button = true
  elsif player_total > dealer_total
    @success = "You win!"
    @play_again_button = true
  else
    @error = "Dealer wins. You lose."
    @play_again_button = true
  end
  erb :game  
end


