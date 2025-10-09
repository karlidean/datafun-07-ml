# Importing the Cards
from deck import DeckOfCards

# Looking at the Standard Deck
deck = DeckOfCards()
print('This is your unshuffled deck:')
print(deck)

# Shuffling the Deck
deck.shuffle()
print('This is your shuffled deck:')
print (deck)

# Dealing the first 2 cards in BlackJack
print('Your Cards Are...')
for _ in range(2):
    print(deck.deal_card())
    