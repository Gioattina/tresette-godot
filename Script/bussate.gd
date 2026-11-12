class_name Bussate
extends RefCounted
## Blocco 5: bussate. Valgono solo se il giocatore preme il tasto
## (RoundState.claim_bussata) e solo se la squadra fa almeno 1 punto.

enum Kind { BUON_GIOCO, NAPOLETANA, BUONGIORNO }

const BONUS := {
	Kind.BUON_GIOCO: 3,
	Kind.NAPOLETANA: 3,
	Kind.BUONGIORNO: 4,
}

const LABELS := {
	Kind.BUON_GIOCO: "buon gioco",
	Kind.NAPOLETANA: "napoletana",
	Kind.BUONGIORNO: "buongiorno",
}

# Si può bussare finché non è finita la 3ª mano.
const OPEN_WHILE_TRICKS_PLAYED_BELOW := 3

# Valori che formano buon gioco / buongiorno: tre (o quattro) 3, 2 o assi.
const SET_RANKS := [3, 2, 1]


static func _count_rank(hand: Array, rank: int) -> int:
	var n := 0
	for c in hand:
		if c.rank == rank:
			n += 1
	return n


static func _has(hand: Array, suit: int, rank: int) -> bool:
	for c in hand:
		if c.suit == suit and c.rank == rank:
			return true
	return false


## Bussate possibili con questa mano: Array di {"kind": Kind, "key": String}.
## `key` distingue combinazioni diverse dello stesso tipo ("v3" = tre 3,
## "s0" = napoletana di denari), così si può bussare più volte.
## Con quattro carte uguali si ha solo il buongiorno (non anche il buon gioco).
static func available(hand: Array) -> Array:
	var out: Array = []
	for rank in SET_RANKS:
		var n := _count_rank(hand, rank)
		if n >= 4:
			out.append({"kind": Kind.BUONGIORNO, "key": "v%d" % rank})
		elif n == 3:
			out.append({"kind": Kind.BUON_GIOCO, "key": "v%d" % rank})
	for suit in Card.Suit.values():
		if _has(hand, suit, 3) and _has(hand, suit, 2) and _has(hand, suit, 1):
			out.append({"kind": Kind.NAPOLETANA, "key": "s%d" % suit})
	return out


static func is_valid(hand: Array, kind: int, key: String) -> bool:
	for b in available(hand):
		if b["kind"] == kind and b["key"] == key:
			return true
	return false
