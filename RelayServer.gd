extends Node

const PORTA = 8080 # Porta standard richiesta dai servizi cloud gratuiti

var peer = WebSocketMultiplayerPeer.new()
# Dizionario stanze: {"12345": {"host": 1234, "giocatori": [1234, 5678]}}
var stanze: Dictionary = {}

func _ready():
	# Legge la porta assegnata da Render (di default 10000)
	var porta_env = OS.get_environment("PORT")
	var porta = porta_env.to_int() if porta_env != "" else 10000
	
	# Il secondo parametro "0.0.0.0" è obbligatorio per esporre il server su internet
	var err = peer.create_server(porta, "0.0.0.0")
	if err != OK:
		print("Errore avvio server WebSocket: ", err)
		return
		
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_on_client_disconnesso)
	print("--- SERVER RELAY TRESSETTE AVVIATO SULLA PORTA ", porta, " ---")

func _on_client_disconnesso(id_client: int):
	# Rimuove il giocatore disconnesso dalle stanze
	for codice in stanze.keys():
		var lista = stanze[codice]["giocatori"]
		if lista.has(id_client):
			lista.erase(id_client)
			if lista.size() == 0:
				stanze.erase(codice)
			break

# Chiamata dal client che vuole creare una stanza con codice
@rpc("any_peer")
func richiedi_creazione_stanza(codice: String, nome_giocatore: String):
	var id_mittente = multiplayer.get_remote_sender_id()
	if stanze.has(codice):
		rpc_id(id_mittente, "risposta_stanza", false, "Codice già in uso! Scegline un altro.")
		return
		
	stanze[codice] = {
		"host": id_mittente,
		"giocatori": [id_mittente],
		"nomi": {id_mittente: nome_giocatore}
	}
	rpc_id(id_mittente, "risposta_stanza", true, codice)

# Chiamata dal client che vuole entrare in una stanza esistente
@rpc("any_peer")
func richiedi_unione_stanza(codice: String, nome_giocatore: String):
	var id_mittente = multiplayer.get_remote_sender_id()
	if not stanze.has(codice):
		rpc_id(id_mittente, "risposta_stanza", false, "Stanza non trovata!")
		return
		
	var stanza = stanze[codice]
	if stanza["giocatori"].size() >= 4:
		rpc_id(id_mittente, "risposta_stanza", false, "Stanza piena (4/4)!")
		return
		
	stanza["giocatori"].append(id_mittente)
	stanza["nomi"][id_mittente] = nome_giocatore
	rpc_id(id_mittente, "risposta_stanza", true, codice)
	
	# Notifica a tutti nella stanza l'elenco aggiornato dei nomi
	for pid in stanza["giocatori"]:
		rpc_id(pid, "aggiorna_lista_lobby", stanza["nomi"])

# Smista qualsiasi azione di gioco (carte, busse, turni) solo agli altri 3 nella stessa stanza
@rpc("any_peer")
func inoltra_pacchetto_stanza(codice: String, nome_funzione: String, argomenti: Array):
	if not stanze.has(codice): return
	for pid in stanze[codice]["giocatori"]:
		rpc_id(pid, "esegui_comando_relay", nome_funzione, argomenti)

# Funzioni fantoccio sul server per far combaciare la firma RPC con i client
@rpc("any_peer") func risposta_stanza(_ok: bool, _msg: String): pass
@rpc("any_peer") func aggiorna_lista_lobby(_nomi: Dictionary): pass
@rpc("any_peer") func esegui_comando_relay(_fn: String, _args: Array): pass
