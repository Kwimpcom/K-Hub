local UI = {}

UI.windows = {}

UI.keys = {
	up = false,
	down = false
}

UI.latch = {
	enter = false
}

local function draw_rounded_rect(x, y, w, h, r, c)
	x, y = x + r, y + r
	w, h = w - r, h - r

	valex.draw_filled_rect(x, y, w, h, c)

	valex.draw_filled_circle(w, h, r, c)
	valex.draw_filled_circle(x, h, r, c)
	valex.draw_filled_circle(x, y, r, c)
	valex.draw_filled_circle(w, y, r, c)

	valex.draw_filled_rect(w, y, w + r, h, c)
	valex.draw_filled_rect(x, h, w, h + r, c)
	valex.draw_filled_rect(x - r, y, x, h, c)
	valex.draw_filled_rect(x, y - r, w, y, c)
end

local function draw_semirounded_rect(x, y, w, h, r, c)
	x, y = x + r, y + r
	w, h = w - r, h - r
	if r > h then r = h end

	valex.draw_filled_rect(x, y, w, h, c)
	valex.draw_filled_circle(x, y, r, c)
	valex.draw_filled_circle(w, y, r, c)

	valex.draw_filled_rect(w, y, w + r, h, c)
	valex.draw_filled_rect(x - r, y, x, h, c)
	valex.draw_filled_rect(x, y - r, w, y, c)
end

local function draw_item(ix, iy, iw, ih, bg, text, tc)
	draw_rounded_rect(ix, iy, iw, ih, 6, bg)
	valex.draw_text(text, ix / 2 + iw / 2, iy + 6, tc)
end

function UI:CreateWindow(args)
	local win = {
		x = args.x,
		y = args.y,
		w = args.w,
		h = args.h,
		r = args.Radius or 6,
		c = args.AccentColor or color3.new(1, 0.85, 0),
		bc = args.BackColor or color3.new(0.15, 0.15, 0.15),
		t = args.Title or "Window",
		v = args.Visible ~= false,
		items = {},
		selected = 1
	}

	function win:CreateButton(args)
		local btn = {
			type = "button",
			text = args.text or "Button",
			bg = args.bg or win.c,
			TextColor = args.TextColor or color3.white(),
			callback = args.Callback
		}
		self.items[#self.items + 1] = btn
		return btn
	end

	function win:CreateLabel(args)
		local lbl = {
			type = "label",
			text = args.text or "",
			TextColor = args.TextColor or color3.white()
		}
		self.items[#self.items + 1] = lbl
		return lbl
	end

	function win:CreateToggle(args)
		local tgl = {
			type = "toggle",
			text = args.Text or "Toggle",
			value = args.Value or false,
			bg = args.BackColor or win.c,
			TextColor = args.TextColor or color3.white(),
			callback = args.Callback
		}
		self.items[#self.items + 1] = tgl
		return tgl
	end

	UI.windows[#UI.windows + 1] = win
	return win
end

function UI:Draw()
	for _, win in ipairs(UI.windows) do
		if not win.v then goto continue end

		draw_rounded_rect(win.x - 1, win.y - 1, win.w + 1, win.h + 1, win.r, color3.black())
		draw_rounded_rect(win.x, win.y, win.w, win.h, win.r, win.bc)
		draw_semirounded_rect(win.x, win.y, win.w, win.y + 35, win.r, win.c)

		valex.draw_text(win.t, win.x / 2 + win.w / 2, win.y + 5, color3.white())

		local iy = win.y + 40

		for i, item in ipairs(win.items) do
			local ix = win.x + 15
			local iw = win.w - 30
			local ih = iy + 30

			if item.type == "label" then
				valex.draw_text(item.text, ix + (iw - ix) / 2, iy + 6, item.TextColor)

			elseif item.type == "button" then
				draw_item(ix, iy, iw, ih, item.bg, item.text, item.TextColor)

			elseif item.type == "toggle" then
				draw_item(ix, iy, iw, ih, item.bg, item.text, item.TextColor)

				local tc = item.value and color3.green() or color3.red()
				draw_rounded_rect(iw - 5, iy + 5, iw - 25, ih - 5, 0, tc)
			end

			if i == win.selected then
				valex.draw_text("<", win.w - 18, iy + 6, color3.white())
			end

			iy = ih + 15
		end

		::continue::
	end
end

function UI:UpdateNavigation()
	local down  = valex.is_key_pressed(0x28)
	local up    = valex.is_key_pressed(0x26)
	local enter = valex.is_key_pressed(0x0D)

	for _, win in ipairs(UI.windows) do
		if not win.v then goto continue end

		local items = win.items
		local count = #items
		if count == 0 then goto continue end

		local function skip(dir)
			local safety = 0
			while items[win.selected] and items[win.selected].type == "label" do
				win.selected = win.selected + dir
				if win.selected < 1 then win.selected = count end
				if win.selected > count then win.selected = 1 end
				safety = safety + 1
				if safety > count then break end
			end
		end

		if down and not UI.keys.down then
			win.selected = win.selected % count + 1
			skip(1)
		end

		if up and not UI.keys.up then
			win.selected = win.selected - 1
			if win.selected < 1 then win.selected = count end
			skip(-1)
		end

		if enter and not UI.latch.enter then
			UI.latch.enter = true

			local item = items[win.selected]
			if item then
				if item.type == "button" and item.callback then
					item.callback()
				elseif item.type == "toggle" then
					item.value = not item.value
					if item.callback then
						item.callback(item.value)
					end
				end
			end
		end

		if not enter then
			UI.latch.enter = false
		end

		::continue::
	end

	UI.keys.down = down
	UI.keys.up   = up
end

return UI
