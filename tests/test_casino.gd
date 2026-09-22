extends SceneTree

const CasinoPanel = preload("res://scripts/casino_panel.gd")
const GameState = preload("res://scripts/game_state.gd")
var assertions := 0
var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: " + description)


func _table(mode: String = "blackjack") -> Control:
	var game = GameState.new()
	game.room = "casino"
	var table = CasinoPanel.new()
	root.add_child(table)
	table.setup(game, ThemeDB.fallback_font, mode)
	return table


func _scenario(table: Control, sequence: Array[int], bet: int = 5) -> void:
	table.close_game()
	var game = table.state
	game.cash = 80
	table.setup(game, ThemeDB.fallback_font, "blackjack")
	table.set_draw_sequence(sequence)
	table.deal_blackjack(bet)


func _run() -> void:
	_check(CasinoPanel.hand_value([]) == 0, "Empty hand")
	_check(CasinoPanel.hand_value([1, 13]) == 21, "Ace and king make blackjack")
	_check(CasinoPanel.hand_value([1, 14, 9]) == 21, "Two aces revalue correctly")
	_check(CasinoPanel.hand_value([1, 14, 27, 40]) == 14, "Four aces avoid a false bust")
	_check(CasinoPanel.hand_value([1, 9, 12]) == 20, "Soft hand becomes hard")
	_check(CasinoPanel.hand_value([10, 23, 5]) == 25, "Hard bust")
	_check(CasinoPanel.card_name(1) == "A♠" and CasinoPanel.card_name(52) == "K♣", "Card identities include rank and suit")
	var table := _table()
	_check(table.size == Vector2(732, 440), "Panel matches integration dimensions")
	_scenario(table, [1, 9, 13, 7], 5)
	_check(not table.round_active and table.state.cash == 87, "Natural blackjack pays 3:2 rounded down ($7 profit on $5)")
	_check(table.last_message.contains("Blackjack"), "Natural blackjack gives result")
	table.stand_blackjack()
	table.hit_blackjack()
	table.close_game()
	_check(table.state.cash == 87, "Finished blackjack cannot pay twice or refund again")
	_scenario(table, [1, 14, 13, 26], 10)
	_check(table.state.cash == 80 and not table.round_active, "Two natural blackjacks push")
	_scenario(table, [9, 1, 7, 13], 20)
	_check(table.state.cash == 60 and not table.round_active, "Dealer natural beats ordinary hand")
	_scenario(table, [10, 9, 8, 7, 5], 10)
	_check(table.round_active and table.state.cash == 70, "Deal places one stake in escrow")
	table.hit_blackjack()
	_check(table.state.cash == 70 and not table.round_active, "Player bust loses only the stake")
	_scenario(table, [10, 9, 8, 7, 10], 10)
	table.stand_blackjack()
	_check(table.state.cash == 90, "Dealer draws below 17, bust pays 1:1")
	_check(table.dealer_hand.size() == 3, "Dealer actually drew to resolve under 17")
	_scenario(table, [10, 9, 8, 8], 20)
	table.stand_blackjack()
	_check(table.state.cash == 100, "Higher standing hand wins")
	_scenario(table, [10, 9, 7, 8], 5)
	table.stand_blackjack()
	_check(table.state.cash == 80, "Equal totals return stake")
	_scenario(table, [10, 10, 7, 8], 5)
	table.stand_blackjack()
	_check(table.state.cash == 75, "Lower standing total loses")
	_scenario(table, [10, 1, 8, 6, 10], 5)
	table.stand_blackjack()
	_check(table.dealer_hand.size() == 2 and table.state.cash == 85, "Dealer stands on soft 17")
	_scenario(table, [10, 10, 5, 7, 6], 5)
	table.hit_blackjack()
	_check(not table.round_active and table.state.cash == 85, "Hitting to 21 settles automatically as ordinary win")
	_scenario(table, [1, 10, 5, 7, 13], 5)
	table.hit_blackjack()
	_check(table.round_active and CasinoPanel.hand_value(table.player_hand) == 16, "Hit can lower ace from 11 to 1")
	var balance: int = table.state.cash
	var cards: Array = table.player_hand.duplicate()
	table.deal_blackjack(20)
	_check(table.state.cash == balance and table.player_hand == cards, "Second deal blocked during a hand")
	_check(table.is_busy(), "Pending hand exposes busy state")
	var result: String = table.close_game()
	_check(table.state.cash == 80 and result.contains("stake returns"), "Closing mid-hand refunds escrow")
	table.close_game()
	_check(table.state.cash == 80, "Closing twice cannot refund twice")
	table.hit_blackjack()
	table.stand_blackjack()
	table.deal_blackjack()
	_check(table.state.cash == 80 and not table.round_active, "Closed panel refuses new actions")
	table.setup(table.state, ThemeDB.fallback_font, "blackjack")
	_check(table.deal_blackjack(7).contains("Choose") and table.state.cash == 80, "Invalid wager rejected without payment")
	table.state.cash = 4
	_check(table.deal_blackjack(5).contains("Not enough") and table.state.cash == 4, "Insufficient cash rejected")
	_scenario(table, [10, 9, 7, 7], 20)
	var escrow_game = table.state
	table.queue_free()
	await process_frame
	_check(escrow_game.cash == 80, "Removing the panel directly also refunds a pending stake")
	var slots := _table("slots")
	var game = slots.state
	_check(slots.spin_slots() == "Spinning." and slots.slot_pending, "Slots begin animated state")
	_check(game.cash == 80 and game.score == 0, "Animation does not charge early")
	slots.spin_slots()
	_check(game.cash == 80 and int(game.flags.get("slot_spins", 0)) == 0, "Double spin blocked while reels run")
	slots._process(0.3)
	_check(slots.slot_pending, "Reels animate before outcome")
	slots._process(0.8)
	_check(not slots.slot_pending and game.cash == 75 and game.score == 4, "First animated spin uses model's settlement and score")
	slots._process(2.0)
	_check(game.cash == 75 and int(game.flags.slot_spins) == 1, "Finished animation cannot settle twice")
	slots.spin_slots()
	slots._process(1.1)
	_check(game.cash == 85 and game.score == 4, "Second animated spin preserves model payout cycle and unique points")
	slots.spin_slots()
	slots.close_game()
	slots._process(2.0)
	_check(game.cash == 85 and int(game.flags.slot_spins) == 2, "Closing mid-spin cancels uncharged play")
	slots.setup(game, ThemeDB.fallback_font, "slots")
	game.cash = 0
	_check(slots.spin_slots().contains("costs $5") and not slots.slot_pending, "Empty-wallet slots reject without charging")
	slots.queue_free()
	await process_frame
	print("Casino tests: %d assertions, %d failures." % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
