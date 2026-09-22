extends Control
## A reusable casino table. Adventure money belongs to the supplied state;
## a pending wager belongs to this panel and is refunded when the table closes.

signal outcome(message: String)
signal dismissed

const INK := Color("0c1020")
const PANEL := Color("141b2e")
const EDGE := Color("2a334c")
const CREAM := Color("f6e4bc")
const MUTED := Color("98a4be")
const MINT := Color("70e1cb")
const PINK := Color("ef83b6")
const BETS: Array[int] = [5, 10, 20]
const SPIN_DURATION := 1.05
const REEL_WORDS: Array[String] = ["CHERRY", "7", "COLLAR", "LEMON"]

var state: RefCounted
var game_mode := "slots"
var player_hand: Array[int] = []
var dealer_hand: Array[int] = []
var round_active := false
var slot_pending := false
var selected_bet := 5
var wager := 0
var last_message := ""

var _ui_font: Font
var _closed := false
var _slot_elapsed := 0.0
var _deck: Array[int] = []
var _draw_sequence: Array[int] = []
var _wallet_label: Label
var _result_label: Label
var _dealer_total: Label
var _player_total: Label
var _dealer_row: Control
var _player_row: Control
var _deal_button: Button
var _hit_button: Button
var _stand_button: Button
var _spin_button: Button
var _bet_buttons: Dictionary = {}
var _reel_labels: Array[Label] = []


func setup(adventure_state: RefCounted, ui_font: Font, mode: String = "slots") -> void:
	# setup may also reuse an existing table; settle its escrow first.
	close_game()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	state = adventure_state
	_ui_font = ui_font if ui_font != null else ThemeDB.fallback_font
	game_mode = "blackjack" if mode == "blackjack" else "slots"
	_closed = false
	round_active = false
	slot_pending = false
	wager = 0
	selected_bet = 5
	player_hand.clear()
	dealer_hand.clear()
	_draw_sequence.clear()
	_reel_labels.clear()
	_bet_buttons.clear()
	size = Vector2(732, 440)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	_wallet_label = _label("", Rect2(12, 0, 708, 32), 22, MINT)
	_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if game_mode == "blackjack":
		_build_blackjack()
	else:
		_build_slots()
	_refresh()


func _style(color: Color, border: Color = EDGE) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	box.content_margin_left = 12
	box.content_margin_right = 12
	return box


func _label(text: String, rect: Rect2, font_size: int = 18, color: Color = CREAM) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_override("font", _ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _button(text: String, rect: Rect2, callback: Callable, accent: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", _ui_font)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_stylebox_override("normal", _style(MINT if accent else PANEL))
	button.add_theme_stylebox_override("hover", _style(MINT.lightened(0.12) if accent else EDGE, MINT))
	button.add_theme_stylebox_override("pressed", _style(PINK, PINK))
	button.add_theme_stylebox_override("disabled", _style(INK, EDGE))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, PINK))
	button.add_theme_color_override("font_color", INK if accent else CREAM)
	button.add_theme_color_override("font_hover_color", INK if accent else MINT)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", MUTED.darkened(0.2))
	button.pressed.connect(callback)
	add_child(button)
	return button


func _build_slots() -> void:
	_label("THREE REELS. ONE VERY LOUD SUIT.", Rect2(12, 1, 490, 30), 19, CREAM)
	var rules := _label("$5 a spin. Payouts repeat: $0 → $15 → $0 → $25.", Rect2(12, 45, 708, 43), 20, MUTED)
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in range(3):
		var reel := Panel.new()
		reel.position = Vector2(27 + index * 235, 104)
		reel.size = Vector2(208, 140)
		reel.add_theme_stylebox_override("panel", _style(INK, PINK if index == 1 else EDGE))
		reel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(reel)
		var face := _label("7" if index == 1 else "CHERRY", Rect2(reel.position + Vector2(2, 20), Vector2(204, 100)), 34, MINT if index == 1 else PINK)
		face.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		face.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_reel_labels.append(face)
	_spin_button = _button("SPIN  ·  $5", Rect2(236, 267, 260, 49), spin_slots, true)
	_result_label = _label("Pull the handle. Your dignity has already left the building.", Rect2(16, 331, 700, 57), 19)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label("Low on cash? Visit the cashier below $10.", Rect2(12, 400, 500, 30), 17, MUTED)
	_button("Leave table", Rect2(538, 397, 180, 38), _dismiss)


func _build_blackjack() -> void:
	_label("TWENTY-ONE. TRY NOT TO LOOK SURPRISED.", Rect2(12, 1, 510, 30), 18)
	_label("Dealer stands on 17 · Aces count 1 or 11 · Blackjack pays 3:2", Rect2(12, 36, 708, 28), 17, MUTED)
	_dealer_total = _label("DEALER", Rect2(14, 75, 700, 28), 18, PINK)
	_dealer_row = Control.new()
	_dealer_row.position = Vector2(14, 106)
	_dealer_row.size = Vector2(704, 62)
	_dealer_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dealer_row)
	_player_total = _label("YOUR HAND", Rect2(14, 178, 700, 28), 18, MINT)
	_player_row = Control.new()
	_player_row.position = Vector2(14, 209)
	_player_row.size = Vector2(704, 62)
	_player_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_player_row)
	for index in range(BETS.size()):
		var amount := BETS[index]
		_bet_buttons[amount] = _button("$%d" % amount, Rect2(14 + index * 72, 288, 64, 40), _choose_bet.bind(amount))
	_deal_button = _button("Deal", Rect2(258, 288, 128, 40), func(): deal_blackjack(selected_bet), true)
	_hit_button = _button("Hit", Rect2(399, 288, 128, 40), hit_blackjack)
	_stand_button = _button("Stand", Rect2(540, 288, 178, 40), stand_blackjack)
	_result_label = _label("Pick a stake and deal. Your collar alone scores no points.", Rect2(14, 341, 704, 50), 18)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label("Leaving mid-hand returns the stake.", Rect2(14, 400, 500, 30), 17, MUTED)
	_button("Leave table", Rect2(538, 397, 180, 38), _dismiss)


func _choose_bet(amount: int) -> void:
	if _closed or round_active or slot_pending or not BETS.has(amount):
		return
	selected_bet = amount
	_refresh()


func _refresh() -> void:
	if state == null or _wallet_label == null:
		return
	_wallet_label.text = "$%d  IN YOUR WALLET" % int(state.cash)
	if game_mode == "slots":
		if is_instance_valid(_spin_button):
			_spin_button.disabled = _closed or slot_pending or int(state.cash) < 5
			_spin_button.text = "SPINNING…" if slot_pending else "SPIN  ·  $5"
		return
	for amount in _bet_buttons:
		var button: Button = _bet_buttons[amount]
		button.disabled = _closed or round_active
		button.text = ("• " if amount == selected_bet else "") + "$%d" % amount
	_deal_button.disabled = _closed or round_active or int(state.cash) < selected_bet
	_hit_button.disabled = _closed or not round_active
	_stand_button.disabled = _closed or not round_active
	var dealer_visible: Array[int] = []
	if round_active and not dealer_hand.is_empty():
		dealer_visible.append(dealer_hand[0])
	else:
		dealer_visible.assign(dealer_hand)
	_dealer_total.text = "DEALER  ·  %s" % ("%d + ?" % hand_value(dealer_visible) if round_active else str(hand_value(dealer_hand)))
	_player_total.text = "YOUR HAND  ·  %d%s" % [hand_value(player_hand), "  ·  $%d on the felt" % wager if round_active else ""]
	_render_cards(_dealer_row, dealer_hand, round_active)
	_render_cards(_player_row, player_hand, false)


func _render_cards(row: Control, cards: Array[int], hide_hole: bool) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	if cards.is_empty():
		return
	var width := minf(91, (704.0 - 8.0 * (cards.size() - 1)) / cards.size())
	for index in range(cards.size()):
		var hidden := hide_hole and index == 1
		var card := Panel.new()
		card.position = Vector2(index * (width + 8), 0)
		card.size = Vector2(width, 62)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_theme_stylebox_override("panel", _style(EDGE if hidden else CREAM, MINT if hidden else CREAM))
		row.add_child(card)
		var label := Label.new()
		label.size = card.size
		label.text = "?" if hidden else card_name(cards[index])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", _ui_font)
		label.add_theme_font_size_override("font_size", 25 if width > 60 else 19)
		var red := int((cards[index] - 1) / 13) in [1, 2]
		label.add_theme_color_override("font_color", MINT if hidden else (Color("9b234d") if red else INK))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(label)


static func card_name(card: int) -> String:
	var rank := ((card - 1) % 13) + 1
	var face: String = {1: "A", 11: "J", 12: "Q", 13: "K"}.get(rank, str(rank))
	var suit: String = ["♠", "♥", "♦", "♣"][clampi(int((card - 1) / 13), 0, 3)]
	return face + suit


static func hand_value(cards: Array[int]) -> int:
	var total := 0
	var aces := 0
	for card in cards:
		var rank := ((card - 1) % 13) + 1
		if rank == 1:
			total += 11
			aces += 1
		else:
			total += mini(rank, 10)
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total


func set_draw_sequence(cards: Array[int]) -> void:
	# Deterministic test seam. Production play always uses a shuffled 52-card deck.
	if round_active:
		return
	_draw_sequence.clear()
	for card in cards:
		if card >= 1 and card <= 52:
			_draw_sequence.append(card)


func _shuffle_deck() -> void:
	_deck.clear()
	for card in range(1, 53):
		_deck.append(card)
	_deck.shuffle()


func _draw_card() -> int:
	if not _draw_sequence.is_empty():
		return _draw_sequence.pop_front()
	if _deck.is_empty():
		_shuffle_deck()
	return _deck.pop_back()


func deal_blackjack(bet: int = 5) -> String:
	if _closed or state == null or game_mode != "blackjack":
		return "The blackjack table is closed."
	if round_active or slot_pending:
		return "Finish this hand before dealing another."
	if not BETS.has(bet):
		return "Choose a $5, $10, or $20 stake."
	if int(state.cash) < bet:
		return _publish("Not enough cash for that stake. Try a smaller bet or visit the cashier.")
	selected_bet = bet
	wager = bet
	state.cash -= wager
	state.turns += 1
	round_active = true
	_shuffle_deck()
	player_hand.assign([_draw_card()])
	dealer_hand.assign([_draw_card()])
	player_hand.append(_draw_card())
	dealer_hand.append(_draw_card())
	var player_natural := hand_value(player_hand) == 21
	var dealer_natural := hand_value(dealer_hand) == 21
	if player_natural and dealer_natural:
		return _settle("push", "Two blackjacks. You share a look, and get your stake back.")
	if dealer_natural:
		return _settle("loss", "Dealer blackjack. Even the cards are showing you up.")
	if player_natural:
		return _settle("blackjack", "Blackjack! Two cards, twenty-one, one magnificent grin.")
	return _publish("Your hand: %d. Hit for another card, or stand and let the dealer sweat." % hand_value(player_hand))


func hit_blackjack() -> String:
	if _closed or not round_active:
		return "Deal a hand first."
	player_hand.append(_draw_card())
	var total := hand_value(player_hand)
	if total > 21:
		return _settle("loss", "Bust at %d. The suit's optimism has spread to your arithmetic." % total)
	if total == 21:
		return stand_blackjack()
	return _publish("You draw %s. Total: %d. Hit again or stand?" % [card_name(player_hand.back()), total])


func stand_blackjack() -> String:
	if _closed or not round_active:
		return "Deal a hand first."
	while hand_value(dealer_hand) < 17:
		dealer_hand.append(_draw_card())
	var yours := hand_value(player_hand)
	var theirs := hand_value(dealer_hand)
	if theirs > 21:
		return _settle("win", "Dealer busts at %d. For once, someone else overdid it." % theirs)
	if yours > theirs:
		return _settle("win", "Your %d beats the dealer's %d. Try to look as if this happens often." % [yours, theirs])
	if yours == theirs:
		return _settle("push", "Both show %d. A push: your stake returns, your eyebrow stays raised." % yours)
	return _settle("loss", "Dealer's %d beats your %d. The house has excellent timing." % [theirs, yours])


func _settle(result: String, message: String) -> String:
	if not round_active:
		return last_message
	var stake := wager
	round_active = false
	wager = 0
	var returned := 0
	match result:
		"blackjack": returned = stake + int(floor(stake * 1.5))
		"win": returned = stake * 2
		"push": returned = stake
	state.cash += returned
	var net := returned - stake
	var movement := "+$%d" % net if net > 0 else ("−$%d" % absi(net) if net < 0 else "Stake returned")
	return _publish(message + "  " + movement + ".")


func spin_slots() -> String:
	if _closed or state == null or game_mode != "slots":
		return "The slot machine is closed."
	if slot_pending or round_active:
		return "The reels are still moving."
	if int(state.cash) < 5:
		return _publish("A spin costs $5. The casino cashier can help a wallet below $10.")
	slot_pending = true
	_slot_elapsed = 0
	_result_label.text = "The reels spin. Larry practices his winning expression."
	_refresh()
	set_process(true)
	return "Spinning."


func _process(delta: float) -> void:
	if not slot_pending or _closed:
		return
	_slot_elapsed += delta
	var tick := int(_slot_elapsed / 0.07)
	for index in range(_reel_labels.size()):
		_reel_labels[index].text = REEL_WORDS[(tick + index * 3) % REEL_WORDS.size()]
	if _slot_elapsed >= SPIN_DURATION:
		_finish_spin()


func _finish_spin() -> void:
	if not slot_pending or _closed:
		return
	slot_pending = false
	set_process(false)
	var before: int = state.cash
	var message: String = state.interact("slots", "use")
	var won: bool = int(state.cash) > before
	var faces: Array[String] = []
	faces.assign(["CHERRY", "CHERRY", "COLLAR"] if won else ["LEMON", "COLLAR", "TAX AUDIT"])
	for index in range(_reel_labels.size()):
		_reel_labels[index].text = faces[index]
	_publish(message)


func _publish(message: String) -> String:
	last_message = message
	if is_instance_valid(_result_label):
		_result_label.text = message
	_refresh()
	outcome.emit(message)
	return message


func is_busy() -> bool:
	return slot_pending or round_active


func close_game() -> String:
	if _closed:
		return ""
	_closed = true
	slot_pending = false
	set_process(false)
	if round_active and state != null:
		var refund := wager
		# Clear escrow before emitting any signals; closing twice cannot pay twice.
		round_active = false
		wager = 0
		state.cash += refund
		return _publish("You leave the unfinished hand. Your $%d stake returns to your wallet." % refund)
	_refresh()
	return ""


func _dismiss() -> void:
	close_game()
	dismissed.emit()


func _exit_tree() -> void:
	# Defensive cleanup for window closure or a parent being removed directly.
	close_game()
