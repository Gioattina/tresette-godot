class_name Deck
extends RefCounted
## Mazzo di 40 carte napoletane.

var cards: Array[Card] = []


func _init() -> void:
	for s in Card.Suit.values():
		for r in range(1, 11):
			cards.append(Card.new(s, r))


## Mescola con Fisher-Yates. Passando un RandomNumberGenerator con seed
## si ottiene una mescolata ripetibile (utile per i test).
func shuffle(rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	for i in range(cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := cards[i]
		cards[i] = cards[j]
		cards[j] = tmp


## Distribuisce a `num_players` giocatori, `per_round` carte per volta,
## per `rounds` giri (default: 4 giocatori, 5 per volta, 2 giri = 10 carte
## a testa). Ritorna un Array di mani (ogni mano è un Array[Card]).
func deal(num_players: int = 4, per_round: int = 5, rounds: int = 2) -> Array:
	assert(num_players * per_round * rounds <= cards.size())
	var hands: Array = []
	for p in num_players:
		var hand: Array[Card] = []
		hands.append(hand)
	var index := 0
	for r in rounds:
		for p in num_players:
			for k in per_round:
				hands[p].append(cards[index])
				index += 1
	return hands
