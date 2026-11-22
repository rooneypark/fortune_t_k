extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := DrawLayer.make(func(ci: Control) -> void:
		ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color("#181412"))
		Px.text(ci, "운빨삼국 UI KIT (나무 · 철 · 팻말)", Rect2(0, 24, 1024, 60), 42, Px.GOLD)
		# labels
		Px.text(ci, "1. 9-SLICE: 대화창(철테+나무) · 카드(철테+어두운 안판)", Rect2(40, 100, 944, 36), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, "2. 버튼: 나무 보통 / 눌림 / 선택 · 주요 · 전투 · 보물", Rect2(40, 390, 944, 36), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, "3. 재화칩 · 초상틀 (철) / 아이콘 버튼 (나무) / 팻말 2종", Rect2(40, 720, 944, 36), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, "4. 대화창", Rect2(40, 1094, 200, 36), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	, Vector2(1024, 1792))
	add_child(bg)

	# 1. Panels
	var p1 := PxButton.make("panel_ctrl", true, Vector2(450, 220))
	p1.static_panel = true
	p1.position = Vector2(40, 148)
	add_child(p1)
	var p1l := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, "panel_ctrl (철테 + 나무)", Rect2(0, 0, ci.size.x, ci.size.y), 24, Px.WHITE), Vector2(450, 220))
	p1l.position = p1.position
	add_child(p1l)

	var p2 := PxButton.make("panel_slot", true, Vector2(450, 220))
	p2.static_panel = true
	p2.position = Vector2(534, 148)
	add_child(p2)
	var p2l := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, "panel_slot (철테 + 안판)", Rect2(0, 0, ci.size.x, ci.size.y), 24, Px.WHITE), Vector2(450, 220))
	p2l.position = p2.position
	add_child(p2l)

	# 2. Buttons
	var b_norm := PxButton.colored("wood", "보통 (Normal)", Vector2(290, 96), 28)
	b_norm.position = Vector2(40, 442)
	add_child(b_norm)

	var b_press := PxButton.make("tab_wood_pressed", true, Vector2(290, 96))
	b_press.static_panel = true
	b_press.text = "눌림 (Pressed)"
	b_press.font_size = 28
	b_press.position = Vector2(367, 445)
	add_child(b_press)

	var b_sel := PxButton.colored("wood_on", "선택 (Selected)", Vector2(290, 96), 28)
	b_sel.highlight = true
	b_sel.position = Vector2(694, 442)
	add_child(b_sel)

	var b_yel := PxButton.colored("yellow", "주요 (Yellow)", Vector2(290, 96), 28)
	b_yel.position = Vector2(40, 566)
	add_child(b_yel)

	var b_red := PxButton.colored("red", "전투 (Red)", Vector2(290, 96), 28)
	b_red.position = Vector2(367, 566)
	add_child(b_red)

	var b_pur := PxButton.colored("purple", "보물 (Purple)", Vector2(290, 96), 28)
	b_pur.position = Vector2(694, 566)
	add_child(b_pur)

	# 3. Chips, Portrait, Signpost, Icon buttons
	var gc := W.gold_chip(Vector2(310, 92))
	gc.position = Vector2(40, 770)
	add_child(gc)
	var dc := W.diamond_chip(Vector2(310, 92))
	dc.position = Vector2(370, 770)
	add_child(dc)

	var pf := W.portrait_frame("guanyu", Vector2(146, 185), "Lv.4")
	pf.position = Vector2(710, 770)
	add_child(pf)

	var icons := ["btn_mail", "btn_mission", "btn_bag", "btn_recruit", "btn_settings", "btn_pause"]
	for i in icons.size():
		var ib := PxButton.make(icons[i])
		ib.position = Vector2(40 + i * 136, 958)
		ib.size = Vector2(116, 120) if i < 5 else Vector2(100, 94)
		add_child(ib)
	var sg := PxButton.make("sign_battle")
	sg.position = Vector2(874, 754)
	sg.size = Vector2(120, 118)
	sg.overlay = func(b: PxButton, off: Vector2) -> void: Px.text(b, "1", Rect2(off + Vector2(64, 11), Vector2(45, 61)), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
	add_child(sg)
	var ar := PxButton.make("btn_arena")
	ar.position = Vector2(874, 882)
	ar.size = Vector2(120, 118)
	ar.overlay = func(b: PxButton, off: Vector2) -> void: Px.text(b, "10", Rect2(off + Vector2(64, 11), Vector2(45, 61)), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
	add_child(ar)

	# 4. Dialog container + Ribbon + X
	var dlg := PxButton.make("panel_ctrl", true, Vector2(900, 560))
	dlg.static_panel = true
	dlg.position = Vector2(62, 1170)
	add_child(dlg)
	var rib := DrawLayer.make(func(ci: Control) -> void: Px.ribbon(ci, Rect2(Vector2.ZERO, ci.size), "대화창 (Dialog)", 46), Vector2(520, 116))
	rib.position = Vector2(252, 1116)
	add_child(rib)
	var xb := W.close_button(func() -> void: pass)
	xb.position = Vector2(896, 1140)
	add_child(xb)
	var inner_slot := PxButton.make("panel_small", true, Vector2(820, 120))
	inner_slot.static_panel = true
	inner_slot.position = Vector2(102, 1280)
	add_child(inner_slot)
	var tile := DrawLayer.make(func(ci: Control) -> void:
		W.draw_battle_slot(ci, Rect2(0, 0, 120, 120), "guanyu", 2)
		W.draw_battle_slot(ci, Rect2(140, 0, 120, 120), "zhangfei", 3)
		W.draw_unit_slot(ci, Rect2(280, 0, 120, 120), "", 0, 0, "empty"), Vector2(500, 130))
	tile.position = Vector2(102, 1440)
	add_child(tile)

	call_deferred("_snap")


func _snap() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1024, 1792)
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/workspace/grok_fortune3k_shots/00_ui_kit_sheet.png")
	print("kit_sheet saved")
	get_tree().quit()
