extends Control

@onready var postazione_sud = $InterfacciaGiocatore/Postazione_Sud
@onready var postazione_nord = $InterfacciaGiocatore/Postazione_Nord
@onready var postazione_ovest = $InterfacciaGiocatore/Postazione_Ovest
@onready var postazione_est = $InterfacciaGiocatore/Postazione_Est
@onready var centro_tavolo = $InterfacciaGiocatore/CentroTavolo

@onready var nome_sud = $InterfacciaGiocatore/Nome_Sud
@onready var nome_nord = $InterfacciaGiocatore/Nome_Nord
@onready var nome_ovest = $InterfacciaGiocatore/Nome_Ovest
@onready var nome_est = $InterfacciaGiocatore/Nome_Est

@onready var label_punti_a = $InterfacciaGiocatore/Punti_TeamA
@onready var label_punti_b = $InterfacciaGiocatore/Punti_TeamB

@onready var btn_bussa = $InterfacciaGiocatore/Btn_Bussa
@onready var btn_spascia = $InterfacciaGiocatore/Btn_Spascia
@onready var label_avvisi = $InterfacciaGiocatore/Label_Avvisi
@onready var btn_menu_finale = $InterfacciaGiocatore/Btn_MenuFinale

const PERCORSO_CARTE = "res://Grafica/Carte/"
var ha_gia_bussato: bool = false
var avviso_speciale_attivo: bool = false

func _ready():
	if postazione_sud: postazione_sud.hide()
	
	postazione_nord.add_theme_constant_override("h_separation", -45)
	postazione_nord.add_theme_constant_override("v_separation", -25)
	postazione_ovest.add_theme_constant_override("h_separation", -45)
	postazione_ovest.add_theme_constant_override("v_separation", -45)
	postazione_est.add_theme_constant_override("h_separation", -45)
	postazione_est.add_theme_constant_override("v_separation", -45)
	
	if btn_bussa: 
		btn_bussa.pressed.connect(_on_bussa_cliccato)
		btn_bussa.hide()
	if btn_spascia: 
		btn_spascia.pressed.connect(_on_spascia_cliccato)
		btn_spascia.hide()
	if btn_menu_finale:
		btn_menu_finale.pressed.connect(_on_torna_menu_cliccato)
		btn_menu_finale.hide()
	
	if GestoreGioco.sono_host():
		await get_tree().create_timer(0.6).timeout
		GestoreGioco.avvia_nuova_smazzata_online()

func aggiorna_tavolo_visivo():
	svuota_tutto()
	var mia_sedia = GestoreGioco.ottieni_mia_sedia_locale()
	
	var sedia_nord = (mia_sedia + 2) % 4
	var sedia_ovest = (mia_sedia + 1) % 4
	var sedia_est = (mia_sedia + 3) % 4
	
	if nome_sud: nome_sud.text = str(GestoreGioco.posti_tavolo[mia_sedia]["nome"])
	if nome_nord: nome_nord.text = str(GestoreGioco.posti_tavolo[sedia_nord]["nome"])
	if nome_ovest: nome_ovest.text = str(GestoreGioco.posti_tavolo[sedia_ovest]["nome"])
	if nome_est: nome_est.text = str(GestoreGioco.posti_tavolo[sedia_est]["nome"])
	
	var sono_nel_team_a = GestoreGioco.squadre["team_A"].has(mia_sedia)
	var miei_punti = GestoreGioco.punti_visualizzati_A if sono_nel_team_a else GestoreGioco.punti_visualizzati_B
	var punti_avv = GestoreGioco.punti_visualizzati_B if sono_nel_team_a else GestoreGioco.punti_visualizzati_A
	
	if label_punti_a: label_punti_a.text = "Noi: " + str(miei_punti) + " pt"
	if label_punti_b: label_punti_b.text = "Loro: " + str(punti_avv) + " pt"
	
	if GestoreGioco.mani_giocatori.has(mia_sedia):
		var mie_carte = GestoreGioco.mani_giocatori[mia_sedia]
		
		if mie_carte.size() == 10:
			ha_gia_bussato = false if GestoreGioco.carte_sul_tavolo.size() == 0 else ha_gia_bussato
			if btn_spascia: btn_spascia.visible = GestoreGioco.puo_spasciare(mie_carte)
			if btn_bussa:
				var accusa = GestoreGioco.calcola_punti_bussa(mie_carte)
				btn_bussa.visible = (accusa["punti"] > 0 and not ha_gia_bussato)
		else:
			if btn_spascia: btn_spascia.hide()
			if btn_bussa: btn_bussa.hide()
			
		# Carte ingrandite (190x280) e posizionate nella fascia bassa dello schermo
		var w_carta = 190.0
		var h_carta = 280.0
		var spazio_x = 12.0
		var start_x = 41.0
		var y_riga_1 = 1520.0
		var y_riga_2 = 1815.0
		
		for i in range(mie_carte.size()):
			var carta = mie_carte[i]
			var rect = TextureRect.new()
			
			var file_minuscolo = PERCORSO_CARTE + str(carta["nome"]).to_lower() + ".png"
			var file_originale = PERCORSO_CARTE + str(carta["nome"]) + ".png"
			
			if ResourceLoader.exists(file_minuscolo): 
				rect.texture = load(file_minuscolo)
			elif ResourceLoader.exists(file_originale):
				rect.texture = load(file_originale)
			else:
				var file_riserva = PERCORSO_CARTE + "dorso.png"
				if ResourceLoader.exists(file_riserva):
					rect.texture = load(file_riserva)
			
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.size = Vector2(w_carta, h_carta)
			rect.z_index = 10
			rect.mouse_filter = Control.MOUSE_FILTER_STOP
			
			var col = i % 5
			var riga = int(i / 5)
			rect.position = Vector2(start_x + col * (w_carta + spazio_x), y_riga_1 if riga == 0 else y_riga_2)
			
			var indice_corrente = i
			rect.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_carta_cliccata(indice_corrente)
			)
			$InterfacciaGiocatore.add_child(rect)
			rect.add_to_group("mie_carte_mano")
			
	disegna_carte_coperte(sedia_ovest, postazione_ovest, Vector2(140, 220), true)
	disegna_carte_coperte(sedia_nord, postazione_nord, Vector2(140, 220), false)
	disegna_carte_coperte(sedia_est, postazione_est, Vector2(140, 220), true)
	disegna_centro_tavolo()
	aggiorna_testo_turno()
func _on_bussa_cliccato():
	ha_gia_bussato = true
	if btn_bussa: btn_bussa.hide()
	GestoreGioco.richiedi_bussa_online()

func _on_spascia_cliccato():
	if btn_spascia: btn_spascia.hide()
	if btn_bussa: btn_bussa.hide()
	GestoreGioco.richiedi_spascio_online()

func _on_carta_cliccata(indice_carta: int):
	var mia_sedia = GestoreGioco.ottieni_mia_sedia_locale()
	if GestoreGioco.turno_corrente != mia_sedia: return
	
	if btn_spascia: btn_spascia.hide()
	if btn_bussa: btn_bussa.hide()
	
	GestoreGioco.richiedi_giocata_online(indice_carta)

func disegna_centro_tavolo():
	var carte_piatto = GestoreGioco.carte_sul_tavolo
	randomize()
	for i in range(carte_piatto.size()):
		var giocata = carte_piatto[i]
		var dati_carta = giocata["carta"]
		var rect = TextureRect.new()
		
		var file_minuscolo = PERCORSO_CARTE + str(dati_carta["nome"]).to_lower() + ".png"
		var file_originale = PERCORSO_CARTE + str(dati_carta["nome"]) + ".png"
		if ResourceLoader.exists(file_minuscolo): 
			rect.texture = load(file_minuscolo)
		elif ResourceLoader.exists(file_originale):
			rect.texture = load(file_originale)
			
		var dim = Vector2(180, 280)
		rect.custom_minimum_size = dim
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.pivot_offset = dim / 2
		
		var centro_box = centro_tavolo.size / 2 if centro_tavolo.size != Vector2.ZERO else Vector2(350, 350)
		rect.position = Vector2(centro_box.x - (dim.x / 2) + randf_range(-50.0, 50.0), centro_box.y - (dim.y / 2) + randf_range(-50.0, 50.0))
		rect.rotation_degrees = randf_range(-15.0, 15.0)
		centro_tavolo.add_child(rect)

func disegna_carte_coperte(id_giocatore: int, contenitore: Control, dimensione: Vector2, deve_ruotare: bool):
	if GestoreGioco.mani_giocatori.has(id_giocatore):
		var carte_rimanenti = GestoreGioco.mani_giocatori[id_giocatore].size()
		for i in range(carte_rimanenti):
			var rect = TextureRect.new()
			var file_dorso = PERCORSO_CARTE + "dorso.png"
			if ResourceLoader.exists(file_dorso): rect.texture = load(file_dorso)
			rect.custom_minimum_size = dimensione
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if deve_ruotare:
				rect.pivot_offset = dimensione / 2
				rect.rotation_degrees = 90
			contenitore.add_child(rect)

func svuota_tutto():
	for carta_nodo in get_tree().get_nodes_in_group("mie_carte_mano"):
		if carta_nodo.get_parent():
			carta_nodo.get_parent().remove_child(carta_nodo)
		carta_nodo.queue_free()
		
	var contenitori = [postazione_nord, postazione_ovest, postazione_est, centro_tavolo]
	for box in contenitori:
		if box:
			for child in box.get_children():
				box.remove_child(child)
				child.queue_free()

func aggiorna_testo_turno():
	if avviso_speciale_attivo or not label_avvisi:
		return
		
	var mia_sedia = GestoreGioco.ottieni_mia_sedia_locale()
	if GestoreGioco.turno_corrente == mia_sedia:
		label_avvisi.text = "TOCCA A TE!"
	else:
		var nome_turno = GestoreGioco.posti_tavolo[GestoreGioco.turno_corrente]["nome"]
		label_avvisi.text = "Turno di " + str(nome_turno)

func mostra_avviso_temporaneo(testo: String, durata: float):
	if not label_avvisi: return
	avviso_speciale_attivo = true
	label_avvisi.text = testo
	
	await get_tree().create_timer(durata).timeout
	avviso_speciale_attivo = false
	aggiorna_testo_turno()

func mostra_schermata_vittoria(team_vincitore: String, tot_a: int, tot_b: int):
	avviso_speciale_attivo = true
	svuota_tutto()
	if btn_bussa: btn_bussa.hide()
	if btn_spascia: btn_spascia.hide()
	
	if label_avvisi:
		label_avvisi.text = "PARTITA FINITA!\nVince il " + team_vincitore + "\n(" + str(tot_a) + " a " + str(tot_b) + ")"
	if btn_menu_finale:
		btn_menu_finale.show()

func _on_torna_menu_cliccato():
	GestoreGioco.disconnetti_server()
	GestoreGioco.punti_totali_partita = {"team_A": 0, "team_B": 0}
	GestoreGioco.punti_visualizzati_A = 0
	GestoreGioco.punti_visualizzati_B = 0
	get_tree().change_scene_to_file("res://MenuPrincipale.tscn")
