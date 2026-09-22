extends Node
## A plain HTML reading and keyboard surface for the normal Web game.
## It mirrors visible controls; execution always uses their real Godot signals.
## This is not the QA bridge and exposes no flags, save data, or model API.
var app: Control
var revision := 0
var _actions: Dictionary = {}
var _snapshot: Dictionary = {}
var _transcript: Array[String] = []
var _last_line := ""
var _browser_callback: JavaScriptObject
var _window: JavaScriptObject
var _busy := false

static func allowed_context(web: bool, qa_feature: bool, qa_mode: bool, headless: bool) -> bool:
	return web and not qa_feature and not qa_mode and not headless

func start(owner_app: Control) -> void:
	if not allowed_context(OS.has_feature("web"), OS.has_feature("qa_playtest"), bool(owner_app.qa_mode), DisplayServer.get_name() == "headless"):
		return
	app = owner_app
	_window = JavaScriptBridge.get_interface("window")
	_browser_callback = JavaScriptBridge.create_callback(_on_action)
	JavaScriptBridge.eval("""
	window.__larryCompanionInstall = function(callback) {
	  if (window.__larryCompanionRemove) window.__larryCompanionRemove();
	  const style = document.createElement('style');
	  style.textContent = `
	    #larry-companion { position:fixed; z-index:10000; left:12px; bottom:12px; width:min(710px,calc(100vw - 24px)); box-sizing:border-box; background:#141b2e; color:#f6e4bc; border:2px solid #70e1cb; border-radius:8px; font:16px/1.5 system-ui,sans-serif; box-shadow:0 5px 30px #0009; }
	    #larry-companion summary { cursor:pointer; padding:10px 14px; font-weight:700; }
	    #larry-companion:not([open]) { width:auto; max-width:calc(100vw - 24px); }
	    #larry-companion .body { padding:0 16px 16px; max-height:65vh; overflow:auto; overscroll-behavior:contain; }
	    #larry-companion h2 { font-size:21px; margin:12px 0 6px; } #larry-companion h3 { font-size:17px; margin:14px 0 6px; }
	    #larry-companion p { margin:6px 0 10px; white-space:pre-wrap; }
	    #larry-companion button { cursor:pointer; font:inherit; background:#253248; color:#f6e4bc; border:1px solid #98a4be; border-radius:5px; padding:8px 11px; text-align:left; }
	    #larry-companion button:disabled { opacity:.65; cursor:default; }
	    #larry-companion :focus-visible { outline:3px solid #ef83b6; outline-offset:3px; }
	    #larry-companion .controls { display:flex; gap:8px; flex-wrap:wrap; } #larry-companion .quiet { color:#b9c3d7; font-size:14px; }
	    #larry-companion .transcript { max-height:200px; overflow:auto; padding-left:24px; } #larry-companion input[type=range] { width:min(300px,90%); }
	    #larry-companion label { display:block; margin:12px 0; } #larry-companion fieldset { margin:12px 0; border:1px solid #98a4be; }
	  `;
	  document.head.append(style);
	  const panel = document.createElement('details'); panel.id='larry-companion';
	  const summary=document.createElement('summary'); summary.textContent='Text & keyboard controls'; panel.append(summary);
	  const body=document.createElement('div'); body.className='body'; panel.append(body);
	  const heading=document.createElement('h2'); heading.tabIndex=-1; body.append(heading);
	  const help=document.createElement('p'); help.className='quiet'; help.textContent='The same game, with readable text and standard keyboard buttons. Tab to a control; Enter or Space activates it. Close this drawer to return to the scene.'; body.append(help);
	  const status=document.createElement('p'); body.append(status);
	  const goal=document.createElement('p'); body.append(goal);
	  const selected=document.createElement('p'); body.append(selected);
	  const live=document.createElement('p'); live.setAttribute('role','status'); live.setAttribute('aria-live','polite'); live.setAttribute('aria-atomic','true'); body.append(live);
	  const overlay=document.createElement('section'); overlay.setAttribute('aria-label','Open game dialog'); body.append(overlay);
	  const controlsHeading=document.createElement('h3'); controlsHeading.textContent='Available controls'; controlsHeading.tabIndex=-1; body.append(controlsHeading);
	  const controls=document.createElement('div'); controls.className='controls'; body.append(controls);
	  const ranges=document.createElement('div'); body.append(ranges);
	  const transcriptHeading=document.createElement('h3'); transcriptHeading.textContent='Recent conversation'; body.append(transcriptHeading);
	  const transcript=document.createElement('ol'); transcript.className='transcript'; body.append(transcript);
	  document.body.append(panel);
	  // Stop Godot's canvas shortcuts while a player types or presses Space here.
	  panel.addEventListener('keydown', event => event.stopPropagation());
	  panel.addEventListener('keyup', event => event.stopPropagation());
	  panel.addEventListener('pointerdown', event => event.stopPropagation());
	  let pending=false, currentRevision=0;
	  function send(action) { if(pending) return; pending=true; callback(JSON.stringify({...action,revision:currentRevision})); }
	  window.__larryCompanionRender = function(serialized) {
	    const state=JSON.parse(serialized); currentRevision=state.revision; pending=false;
	    const active=document.activeElement, key=active?.dataset?.focusKey, inside=controls.contains(active)||ranges.contains(active), scroll=body.scrollTop;
	    heading.textContent=state.room; status.textContent=state.status; goal.textContent='Current plan: '+state.objective; selected.textContent=state.selection;
	    if(live.textContent!==state.dialogue) live.textContent=state.dialogue;
	    overlay.replaceChildren(); overlay.hidden=!state.overlay.length;
	    for(const text of state.overlay) {const p=document.createElement('p'); p.textContent=text; overlay.append(p);}
	    controls.replaceChildren();
	    for(const item of state.buttons) {const button=document.createElement('button'); button.type='button'; button.textContent=item.text; button.disabled=item.disabled; button.dataset.focusKey=item.focus; button.title=item.hint||''; button.onclick=()=>send({id:item.id}); controls.append(button);}
	    ranges.replaceChildren();
	    for(const item of state.ranges) {const label=document.createElement('label'); label.textContent=item.text+' '; const range=document.createElement('input'); range.type='range'; range.min=item.min; range.max=item.max; range.step=item.step; range.value=item.value; range.dataset.focusKey=item.focus; range.setAttribute('aria-label',item.text); range.onchange=()=>send({id:item.id,value:Number(range.value)}); label.append(range); ranges.append(label);}
	    transcript.replaceChildren(); for(const line of state.transcript) {const li=document.createElement('li'); li.textContent=line; transcript.append(li);}
	    if(inside && panel.open) {const next=[...controls.querySelectorAll('button'),...ranges.querySelectorAll('input')].find(node=>node.dataset.focusKey===key&&!node.disabled); (next||controlsHeading).focus({preventScroll:true});}
	    body.scrollTop=scroll;
	  };
	  window.__larryCompanionRemove = function(){panel.remove();style.remove();delete window.__larryCompanionRender;delete window.__larryCompanionRemove;};
	};
	""", true)
	_window.__larryCompanionInstall(_browser_callback)
	refresh.call_deferred()

func _exit_tree() -> void:
	if _window != null:
		_window.__larryCompanionRemove()
	_browser_callback = null
	_window = null

func refresh() -> void:
	if not is_instance_valid(app):
		return
	revision += 1
	_actions.clear()
	var buttons: Array = []
	var ranges: Array = []
	var overlay: Array[String] = []
	var keys: Dictionary = {}
	var scope: Control = app.modal if is_instance_valid(app.modal) else app.canvas
	_collect_controls(scope, buttons, ranges, keys)
	if is_instance_valid(app.modal):
		_collect_text(app.modal, overlay)
	var line := str(app.speaker.text) + ": " + str(app.dialogue.get_parsed_text())
	# Main clears this visible transcript on New evening. Mirror it directly so
	# even a one-line evening followed by another one-line evening resets cleanly.
	var visible_transcript: Variant = app.get("transcript")
	if visible_transcript is Array:
		_transcript.assign(visible_transcript.slice(maxi(0, visible_transcript.size() - 40)))
		_last_line = line
	elif line != _last_line:
		_last_line = line
		_transcript.append(line)
		if _transcript.size() > 40:
			_transcript.pop_front()
	_snapshot = {"revision": revision, "room": app.room_title.text, "status": app.money_label.text + " · " + app.score_label.text + " · " + app.status.text, "objective": app.objective_text.text, "selection": app.selected_label.text, "dialogue": line, "overlay": overlay, "buttons": buttons, "ranges": ranges, "transcript": _transcript.duplicate()}
	if _window != null:
		_window.__larryCompanionRender(JSON.stringify(_snapshot))

func _collect_controls(node: Node, buttons: Array, ranges: Array, keys: Dictionary) -> void:
	for child in node.get_children():
		if child is Control and not child.is_visible_in_tree():
			continue
		if child is Button:
			var text: String = child.text
			if text == "×": text = "Cancel selected item" if child.tooltip_text.begins_with("Cancel selected item") else "Close dialog"
			elif text == "?": text = "Help"
			elif text == "H": text = "Toggle scene labels"
			if text.is_empty() or (text == "+" and not child.tooltip_text.is_empty()): text = child.tooltip_text
			var occurrence := int(keys.get(text, 0))
			keys[text] = occurrence + 1
			var id := "button_%d" % child.get_instance_id()
			buttons.append({"id": id, "text": text, "hint": child.tooltip_text, "disabled": child.disabled, "focus": "%s_%d" % [text, occurrence]})
			_actions[id] = weakref(child)
		elif child is Slider:
			var text: String = child.tooltip_text if not child.tooltip_text.is_empty() else "Volume"
			var id := "range_%d" % child.get_instance_id()
			ranges.append({"id": id, "text": text, "min": child.min_value, "max": child.max_value, "step": child.step, "value": child.value, "focus": text})
			_actions[id] = weakref(child)
		_collect_controls(child, buttons, ranges, keys)

func _collect_text(node: Node, output: Array[String]) -> void:
	for child in node.get_children():
		if child is Control and not child.is_visible_in_tree():
			continue
		if child is Label and not child.text.is_empty():
			output.append(child.text)
		elif child is RichTextLabel:
			output.append(child.get_parsed_text())
		_collect_text(child, output)

func _on_action(arguments: Array) -> void:
	if arguments.size() != 1 or not arguments[0] is String or arguments[0].length() > 2048:
		return
	var parsed: Variant = JSON.parse_string(arguments[0])
	if parsed is Dictionary:
		_activate.call_deferred(parsed)

func _activate(message: Dictionary) -> bool:
	if _busy or not is_instance_valid(app):
		return false
	if not message.get("revision") is float and not message.get("revision") is int:
		refresh()
		return false
	if float(message.revision) != float(revision) or not message.get("id") is String or not _actions.has(message.id):
		refresh()
		return false
	var control: Control = _actions[message.id].get_ref()
	if not is_instance_valid(control) or not control.is_visible_in_tree():
		refresh()
		return false
	# A modal opened since publication must never leave underlying controls active.
	if is_instance_valid(app.modal) and not app.modal.is_ancestor_of(control):
		refresh()
		return false
	_busy = true
	var performed := false
	if control is Button and not control.disabled:
		control.pressed.emit()
		performed = true
	elif control is Slider and (message.get("value") is int or message.get("value") is float):
		var value := float(message.value)
		if is_finite(value) and value >= control.min_value and value <= control.max_value:
			control.value = value
			performed = true
	_busy = false
	refresh.call_deferred()
	return performed
