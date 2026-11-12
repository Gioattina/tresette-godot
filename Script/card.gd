class_name Card
extends RefCounted
## Una carta napoletana. Nessuna dipendenza dalla grafica o dalla rete.
## Rank: 1 = asso, 2..7 = numeri, 8 = donna (fante), 9 = cavallo, 10 = re.

enum Suit { DENARI, COPPE, SPADE, BASTONI }

const ASSO := 1
const DONNA := 8
const CAVALLO := 9
const RE := 10

# Gerarchia: 3 2 1 re cavallo donna 7 6 5 4 (più alto = più forte)
const STRENGTH := {
	3: 10, 2: 9, 1: 8, RE: 7, CAVALLO: 6, DONNA: 5, 7: 4, 6: 3, 5: 2, 4: 1,
}

# Punti in TERZI di punto, per evitare errori con i decimali.
# Asso = 1 punto = 3 terzi; 3, 2, re, cavallo, donna = 1/3 = 1 terzo.
const THIRDS := {
	ASSO: 3, 2: 1, 3: 1, DONNA: 1, CAVALLO: 1, RE: 1,
}

const SUIT_NAMES := ["denari", "coppe", "spade", "bastoni"]
const RANK_NAMES := {
	1: "asso", 2: "due", 3: "tre", 4: "quattro", 5: "cinque",
	6: "sei", 7: "sette", 8: "donna", 9: "cavallo", 10: "re",
}

var suit: Suit
var rank: int


func _init(p_suit: Suit, p_rank: int) -> void:
	suit = p_suit
	rank = p_rank


func strength() -> int:
	return STRENGTH[rank]


## Punti in terzi (asso = 3, figure/3/2 = 1, altre = 0).
func points_thirds() -> int:
	return THIRDS.get(rank, 0)


## Vero per le carte che valgono 1/3 di punto (3, 2, re, cavallo, donna).
func is_figure() -> bool:
	return THIRDS.get(rank, 0) == 1


## Questa carta batte `other` in una presa? Conta solo se `other` è
## dello stesso seme (le carte di altri semi non possono mai battere).
func beats(other: Card) -> bool:
	if suit != other.suit:
		return false
	return strength() > other.strength()


## Id 0..39, comodo per mandare la carta in rete.
func id() -> int:
	return int(suit) * 10 + (rank - 1)


static func from_id(card_id: int) -> Card:
	var suit_index: int = floori(card_id / 10.0)
	return Card.new(suit_index as Suit, card_id % 10 + 1)


func display_name() -> String:
	return "%s di %s" % [RANK_NAMES[rank], SUIT_NAMES[suit]]
