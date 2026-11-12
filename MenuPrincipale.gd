extends Control

# INSERISCI QUI IL TUO INDIRIZZO RENDER (senza https://, es: "://onrender.com")
const URL_SERVER = "wss://tresette-relay-1.onrender.com"


@onready var input_nome = $PannelloConnessione/Nome_Giocatore
@onready var btn_crea_stanza = $PannelloConnessione/Crea_Stanza
@onready var input_stanza = $PannelloConnessione/CODICE_STANZA
@onready var btn_unisci_stanza = $PannelloConnessione/Unisciti_Stanza
@onready var label_stato = $PannelloConnessione/LabelStato

@onready var pannello_connessione = $PannelloConnessione
@onready var pannello_attesa = $PannelloAttesa
@onready var label_stanza_id = $PannelloAttesa/LabelStanzaID
@onready var lista_giocatori = $PannelloAttesa/ListaGiocatori
@onready var btn_avvia_partita = $PannelloAttesa/BtnAvviaPartita

var azione_pendente: String = "" # "CREA" o "UNISCI"

func _ready():
	btn_crea_stanza.focus_mode = Control.FOCUS_NONE
	btn_unisci_stanza.focus_mode = Control.FOCUS_NONE
	
	btn_crea_stanza.pressed.connect(_on_crea_cliccato)
	btn_unisci_stanza.pressed.connect(_on_unisci_cliccato)
	btn_avvia_partita.pressed.connect(_on_avvia_cliccato)
	
	# Colleghiamo i segnali del nostro GestoreGioco aggiornato per WebSocket
	GestoreGioco.messaggio_lobby_ricevuto.connect(_on_messaggio_server)
	GestoreGioco.connesso_al_relay.connect(_on_connessione_stabilita)
	
	pannello_connessione.show()
	pannello_attesa.hide()
	btn_avvia_partita.hide()

func _on_crea_cliccato():
	if not _valida_campi(): return
	azione_pendente = "CREA"
	label_stato.text = "Connessione al server in corso..."
	GestoreGioco.connetti_a_server(URL_SERVER)

func _on_unisci_cliccato():
	if not _valida_campi(): return
	azione_pendente = "UNISCI"
	label_stato.text = "Connessione al server in corso..."
	GestoreGioco.connetti_a_server(URL_SERVER)

func _valida_campi() -> bool:
	if input_nome.text.strip_edges() == "":
		label_stato.text = "Inserisci il tuo nome!"
		return false
	var pwd = input_stanza.text.strip_edges()
	if pwd.length() < 5 or pwd.length() > 6 or not pwd.is_valid_int():
		label_stato.text = "Il codice deve essere di 5 o 6 NUMERI!"
		return false
	return true

func _on_connessione_stabilita():
	var pacchetto = {
		"tipo": azione_pendente,
		"codice": input_stanza.text.strip_edges(),
		"nome": input_nome.text.strip_edges()
	}
	GestoreGioco.invia_json_al_server(pacchetto)
func _on_messaggio_server(dati: Dictionary):
	var tipo = dati.get("tipo", "")
	
	if tipo == "ERRORE":
		label_stato.text = str(dati.get("msg", "Errore"))
		GestoreGioco.disconnetti_server()
		
	elif tipo == "OK_STANZA":
		GestoreGioco.mio_id_rete = int(dati.get("mioId", 1))
		GestoreGioco.codice_stanza_corrente = str(dati.get("codice", ""))
		pannello_connessione.hide()
		pannello_attesa.show()
		label_stanza_id.text = "Stanza " + GestoreGioco.codice_stanza_corrente + " - In attesa..."
		if GestoreGioco.mio_id_rete == 1:
			btn_avvia_partita.show()
			
	elif tipo == "LISTA":
		lista_giocatori.clear()
		var giocatori = dati.get("giocatori", [])
		for g in giocatori:
			var idx = lista_giocatori.add_item(str(g["nome"]))
			lista_giocatori.set_item_metadata(idx, int(g["id"]))
		if giocatori.size() == 4:
			label_stanza_id.text = "Tavolo completo (4/4)! L'Host può avviare."

func _on_avvia_cliccato():
	if GestoreGioco.mio_id_rete == 1:
		var lista_per_tavolo = []
		for i in range(lista_giocatori.item_count):
			var pid = lista_giocatori.get_item_metadata(i)
			var pnome = lista_giocatori.get_item_text(i)
			lista_per_tavolo.append({"id": pid, "nome": pnome})
			
		GestoreGioco.configura_posti_tavolo(lista_per_tavolo)
		GestoreGioco.invia_comando_partita("AVVIA_TAVOLO", {})
