class_name Dichiarazioni
extends RefCounted
## Blocco 4: la dichiarazione obbligatoria. La fa SOLO chi apre la mano, la
## prima volta che apre con quel seme nella partita. Chi risponde non dichiara
## mai e, anche se cala quel seme rispondendo (per esempio scartando), non
## "consuma" la dichiarazione: la farà comunque alla prima apertura con quel seme.
## Cosa si dice, in questo ordine:
##  - una sola carta di quel seme in mano       -> "sola"
##  - 3, 2 e asso del seme                      -> "napoletana"
##  - due tra 3, 2, asso                        -> "cerco" la carta che manca
##  - una sola tra 3, 2, asso (e altre carte)   -> "ho il 3" / "ho il 2" / "ho l'asso"
##  - nessuna carta chiave                      -> "altre N" (le altre carte del seme)
## La dichiarazione la calcola l'host dalla mano e la manda a tutti,
## quindi non si può omettere né mentire. Dire "napoletana" qui non è la
## bussata: per il bonus serve comunque il tasto.

enum Kind { NONE, HO, CERCO, SOLA, NAPOLETANA, ALTRE }

const KEY_RANKS := [3, 2, 1]

const RANK_LABELS := {3: "il 3", 2: "il 2", 1: "l'asso"}


static func _has(hand: Array, suit: int, rank: int) -> bool:
	for c in hand:
		if c.suit == suit and c.rank == rank:
			return true
	return false


static func _count_suit(hand: Array, suit: int) -> int:
	var n := 0
	for c in hand:
		if c.suit == suit:
			n += 1
	return n


## Ritorna {"kind": Kind, "rank": int, "count": int}. `hand` = mano prima di
## giocare la carta. "count" = altre carte del seme (solo per ALTRE).
static func for_suit(hand: Array, suit: int) -> Dictionary:
	var n := _count_suit(hand, suit)
	if n == 1:
		return {"kind": Kind.SOLA, "rank": 0, "count": 0}
	var held: Array = []
	for rank in KEY_RANKS:
		if _has(hand, suit, rank):
			held.append(rank)
	if held.size() == 3:
		return {"kind": Kind.NAPOLETANA, "rank": 0, "count": n - 1}
	if held.size() == 2:
		for rank in KEY_RANKS:
			if not held.has(rank):
				return {"kind": Kind.CERCO, "rank": rank, "count": n - 1}
	if held.size() == 1:
		return {"kind": Kind.HO, "rank": held[0], "count": n - 1}
	if n > 1:
		return {"kind": Kind.ALTRE, "rank": 0, "count": n - 1}
	return {"kind": Kind.NONE, "rank": 0, "count": 0}


## Testo da mostrare, es. "cerco il 2" o "altre 2". Vuoto se non c'è dichiarazione.
static func label(decl: Dictionary) -> String:
	match decl["kind"]:
		Kind.HO:
			return "ho %s" % RANK_LABELS[decl["rank"]]
		Kind.CERCO:
			return "cerco %s" % RANK_LABELS[decl["rank"]]
		Kind.SOLA:
			return "sola"
		Kind.NAPOLETANA:
			return "napoletana"
		Kind.ALTRE:
			return "altre %d" % decl["count"]
	return ""
