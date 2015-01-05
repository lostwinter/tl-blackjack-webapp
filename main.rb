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
  
  def win!(msg)
    @play_again_button = true
    @hit_stay_buttons = false
    session[:player_earnings] += session[:bet]
    @winner = "<strong>#{session[:name]} wins!</strong> #{msg}"
  end
  
  def lose!(msg)
    @play_again_button = true
    @hit_stay_buttons = false
    session[:player_earnings] -= session[:bet]
    @loser = "<strong>#{session[:name]} loses.</strong> #{msg}"
  end
  
  def tie!(msg)
    @play_again_button = true
    @hit_stay_buttons = false
    @winner = "<strong>#{msg}</strong>"
  end
end
 
before do
  @hit_stay_buttons = true
  @show_dealer_button = false
  @play_again_button = false
  @bet_option = false
end

BLACKJACK = 21
INITIAL_POT_AMOUNT = 500

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
  session[:name] = params[:name].capitalize
  session[:player_earnings] = INITIAL_POT_AMOUNT
  redirect '/bet'
end

get '/bet' do
  session[:bet] = nil
  erb :bet
end

post '/bet' do
  if params[:bet].nil? || params[:bet].to_i == 0
    @error = "Please offer a valid bet!"
    halt erb(:bet)
  elsif params[:bet].to_i > session[:player_earnings]
    @error = "You can't bet what you don't have, silly."
    halt erb(:bet)
  else
    session[:bet] = params[:bet].to_i 
  end
 
 redirect '/game'
end

get '/game' do
  #Make deck and add to session
  suits = %w[Hearts Diamonds Spades Clubs]
  values = %w[2 3 4 5 6 7 8 9 10 Jack Queen King Ace]
  session[:deck] = suits.product(values).shuffle
  session[:turn] = session[:name]
  
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) == BLACKJACK
    win_tie!("You hit blackjack. You win!")
  elsif calculate_total(session[:player_cards]) == BLACKJACK
    lose!("Dealer hits blackjack. You lose")
  end
  @bet_option = true
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) > BLACKJACK
    lose!("You busted, Fool! Bummer.")
  elsif calculate_total(session[:player_cards]) == BLACKJACK
    win!("You hit blackjack!")
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @success = "You have chosen to stay."
  @hit_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @hit_stay_buttons = false
  session[:turn] = session[:dealer]
  
  total = calculate_total(session[:dealer_cards])
  
  if total == BLACKJACK
    lose!("Dealer hits blackjack! You lose.")
  elsif total > BLACKJACK
    win!("Dealer busts. You win!")
  elsif total >= 17
    #dealer stays
    redirect '/game/compare'
  else 
    @show_dealer_button = true
    
  end
  erb :game, layout: false  
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end


get '/game/compare' do
  @hit_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  
  if player_total == dealer_total
    win_tie!("You are tied. Push!")
  elsif player_total > dealer_total
    win!("You win!")
  else
    lose!("Dealer wins. You lose.")
  end
  erb :game, layout: false  
end


