require 'rubygems'
require 'sinatra'

set :sessions, true

# Created a github for it: https://github.com/JPatrickWard/Week3_Blackjack_Webapp.git

BLACKJACK_AMOUNT = 21
DEALER_MIN = 17
DOLLAR_START_AMOUNT = 510

helpers do
  def calculate_total(cards)
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end
    #correct for aces
    arr.select{|element| element == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -=10
    end
    total
  end
#This

  def card_image(card)
    suit = case card[0]
             when 'H' then 'hearts'
             when 'D' then 'diamonds'
             when 'C' then 'clubs'
             when 'S' then 'spades'
           end

    value = card[1]
    if %w(J Q K A).include? value
      value = case card[1]
                when 'J' then 'jack'
                when 'Q' then 'queen'
                when 'K' then 'king'
                when 'A' then 'ace'
              end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

end

before do
  @show_hit_or_stay_buttons = true
end
# This handles when I go to localhost:9393 # if user exists, then progress to rest of the game. # Else redirect to new user forum.
get '/' do
  if session[:player_name]
    # progress to the game
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do  # get is a 'redirect'
  erb :new_player
  # erb specifies how to render the form. Or, rather the new tab.
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "No ghost players allowed. Please enter a name."
    halt erb(:new_player)
  end
  
  session[:player_name] = params[:player_name]
  # progress to the game, now that I have player name.
  redirect '/game'
end

get '/game' do
  suits = ['C', 'H', 'S', 'D']
  values = ['K', 'A', 'J', 'Q', '10', '6', '2', '7', '3', '9', '4', '8', '5']
  session[:deck] = suits.product(values).shuffle!

  # Deal Cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])

  if player_total = BLACKJACK_AMOUNT
    @success = "Way to go! #{session[:player_name]} hit blackjack"
    @show_hit_or_stay_buttons = false
  elsif player_total > BLACKJACK_AMOUNT
    @error = "Well, Crap!  It looks like #{session[:player_name]} busted :("
    @show_hit_or_stay_buttons = false
  end
  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has decided to stay."
  @show_hit_or_stay_buttons = false

  erb :game
end