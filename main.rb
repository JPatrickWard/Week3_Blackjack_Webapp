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
    #Account for aces
    arr.select{|element| element == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -=10
    end
    total
  end

  def card_image(card)
    suit = case card[0]
             when 'C' then 'clubs'
             when 'S' then 'spades'
             when 'D' then 'diamonds'
             when 'H' then 'hearts'
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

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>#{session[:player_name]} wins! </strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @error = "<strong>#{session[:player_name]} loses! </strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>It's a tie.</strong> #{msg}"
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
  session[:turn] = session[:player_name]
  #Create the deck and make ready for a session
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

  dealer_total = calculate_total(session[:dealer_cards])
  if player_total = BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} stayed at #{player_total} and dealer stayed at #{dealer_total}")
  elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} overshot it at #{player_total} and dealer stayed at #{dealer_total}")
  end
  erb :game
end

post '/game/player/stay' do
  # winner!("#{session[:player_name]} stayed at #{player_total} and dealer stayed at #{dealer_total}")
  winner!("good job")
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
  # erb :game
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  #Determine the winner
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("You lost.  Dealer hit blackjack")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}")
  elsif dealer_total >= DEALER_MIN
    #Dealer stays if between 17 and 20
    # dealer stays: If dealer is at this point, that means player has already stayed
    # Must mean it's time to compare hands. Redirect to compare hands
    redirect '/game/compare'
  else
    # dealer hits.  Need to show the dealer hit button.  But when dealer doesn't hit, button should not show
    @show_dealer_hit_button = true
  end
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total} and dealer stayed at #{dealer_total}")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total} and dealer stayed at #{dealer_total}")

  else
    tie!("Both #{session[:player_name]} and dealer stayed at #{dealer_total}")

  end
  erb :game
end

get '/game_over' do
  erb :game_over
end
