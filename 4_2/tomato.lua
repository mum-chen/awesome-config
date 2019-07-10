local os = require("os")
local math = require("math")

local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")
local beautiful = require("beautiful")

local Class = require("class")

local Shape = {}

function Shape.finish(cr, w, h)
	local gap = w / 10
	local t = w / 6
	cr:move_to(gap, h / 2)
	cr:line_to(w / 3, h - gap)
	cr:line_to(w - gap, gap + t)
	cr:line_to(w - gap - t, gap)
	cr:line_to(w / 3, h - gap - t)
	cr:line_to(gap + t, h / 2 - t)
	cr:line_to(gap, h / 2)
	cr:close_path()
end

function Shape.cancel(cr, w, h)
	local gap = w / 10
	local t = w / 6
	local xs = 0 + gap
	local xe = w - gap
	local ys = 0 + gap
	local ye = h - gap
	local midx = w / 2
	local midy = h / 2

	cr:move_to(midx, midy - t)
	cr:line_to(xs + t, ys)
	cr:line_to(xs, ys + t)
	cr:line_to(midx - t, midy)
	cr:line_to(xs, ye - t)
	cr:line_to(xs + t, ye)
	cr:line_to(midx, midy + t)
	cr:line_to(xe - t, ye)
	cr:line_to(xe, ye - t)
	cr:line_to(midx + t, midy)
	cr:line_to(xe, ys + t)
	cr:line_to(xe - t, ys)
	cr:line_to(midx, midy - t)
	cr:close_path()
end

function Shape.resume(cr, w, h)
	local t = w / 6
	cr:move_to(t, t)
	cr:line_to(t, h - t)
	cr:line_to(w - t, h / 2)
	cr:line_to(t, t)
	cr:close_path()
end

function Shape.suspend(cr, w, h)
	local t = w / 6
	local gap = w / 10
	local mid = w / 2

	local near = gap
	local far = gap + t
	cr:move_to(mid - near, t)
	cr:line_to(mid - far, t)
	cr:line_to(mid - far, h - t)
	cr:line_to(mid - near, h - t)
	cr:line_to(mid - near, t)
	cr:close_path()

	cr:move_to(mid + near, t)
	cr:line_to(mid + far, t)
	cr:line_to(mid + far, h - t)
	cr:line_to(mid + near, h - t)
	cr:line_to(mid + near, t)
	cr:close_path()
end

local TomatoTimer = Class()

function TomatoTimer:__init__()
	self._update_chain = {}
	self.seed = 0
	self.hour = 0
	self.minute = 25
	self.second = 0
	self.is_timeout = false

	self._timer = gears.timer {
		timeout = 1,
		autostart = false,
		callback = function()
			self:update()
		end
	}
end

function TomatoTimer:register(key, widget)
	self._update_chain[key] = widget
end

function TomatoTimer:broadcast()
	local t = self:time()
	for _, widget in pairs(self._update_chain) do
		widget:update(t)
	end
end

function TomatoTimer:time()
	return {
		h = self.hour,
		m = self.minute,
		s = self.second,
		is_timeout = self.is_timeout,
		is_running = self._timer.started,
		seed = self.seed,
	}
end

function TomatoTimer:next_seed()
	self.seed = self.seed + 1
end

function TomatoTimer:_sub(n)
	local h, m, s = self.hour, self.minute, self.second
	s = s - n
	if s < 0 then
		m = m + math.floor(s / 60)
		if m < 0 then
			h = h + math.floor(m / 60)
			m = m % 60
		end
		s = s % 60
	end
	self.hour, self.minute, self.second = h, m, s
end

function TomatoTimer:_add(n)
	local h, m, s = self.hour, self.minute, self.second
	s = s + n
	if s >= 60 then
		m = m + math.floor(s / 60)
		if m >= 60 then
			h = h + math.floor(m / 60)
			m = m % 60
		end
		s = s % 60
	end

	self.hour, self.minute, self.second = h, m, s
end

function TomatoTimer:_set_time(timestamp)
	local rest = timestamp
	self.hour = math.floor(rest / 3600)
	rest = timestamp % 3600
	self.minute = math.floor(rest / 60)
	self.second = rest % 60
end

function TomatoTimer:update()
	if (self.is_timeout) then
		self:_add(1)
	else
		self:_sub(1)
		local t = self.hour * 60 * 60 + self.minute * 60 + self.second
		if t <= 0 then
			self:_set_time(-t)
			self.is_timeout = true
		end
	end
	self:broadcast()
end

function TomatoTimer:start(h, m, s)
	self.hour, self.minute, self.second = h, m, s
	self.is_timeout = false
	self._timer:start()
end

function TomatoTimer:is_running()
	return self._timer.started
end

function TomatoTimer:cancel()
	self._timer:stop()
	self.hour, self.minute, self.second = 0, 25, 0
	self.is_timeout = false
	self:next_seed()
	self:broadcast()
end
function TomatoTimer:finish()
	self:cancel()
end

function TomatoTimer:suspend()
	self._timer:stop()
	self:broadcast()
end

function TomatoTimer:resume()
	self._timer:start()
	self:broadcast()
end

local TomatoPanel = Class()

function TomatoPanel:__init__(panel_size)
	self._ishide = true

	self._face = nil
	self._head = nil
	self._clock = nil
	self._panel = nil
	self._finish_btn = nil
	self._cancel_btn = nil
	self._control_btn = nil

	self:_init_panel(panel_size)
	self:_bind_keys()
end

function TomatoPanel:_is_running()
	return self._timer and self._timer:is_running()
end

function TomatoPanel:_init_panel(panel_size)
	local headline = wibox.widget {
		widget = wibox.widget.textbox,
		forced_height = panel_size / 3,
		forced_width = panel_size,
		font = "sans 12",
		align = "center",
		valign = "bottom",
	}

	local time_text = wibox.widget {
		widget = wibox.widget.textbox,
		text = "00:00:00",
		forced_height = panel_size / 3,
		forced_width = panel_size,
		align = "center",
		font = "sans 32"
	}

	local finish_btn = wibox.widget {
		widget = wibox.widget.checkbox,
		checked = true,
		color = "green",
		shape = Shape.finish,
	}

	local cancel_btn = wibox.widget {
		widget = wibox.widget.checkbox,
		checked = true,
		color = "green",
		shape = Shape.cancel,
	}

	local control_btn = wibox.widget {
		widget = wibox.widget.checkbox,
		checked = true,
		color = "green",
		shape = Shape.suspend
	}

	local control_panel = wibox.widget {
		widget = wibox.container.margin,
		left = panel_size * 0.15,
		right = panel_size * 0.15,
		top = panel_size * 0.05,
		bottom = panel_size * 0.05,
		color = "green",
		layout = wibox.layout.flex.horizontal,
		border_width = 10,
		border_color = "black",

		-- widget
		finish_btn,
		control_btn,
		cancel_btn,
	}

	local hat = wibox.widget {
		widget = wibox.container.background,
		bg = "green",
		fg = "black",
		shape = function(cr, w, h)
			return gears.shape.infobubble(
				cr, w, h / 2, 20, 10, w/2 - 10)
		end,
		headline,
	}

	local face = wibox.widget {
		widget = wibox.container.background,
		time_text,
	}

	local panel = wibox.widget {
		widget = wibox.container.background,
		bg = "#EE3D11",
		shape = function(cr, w, h)
			return gears.shape.infobubble(
				cr, w, h, 20, 10, w/2 - 10)
		end,
		{
			widget = wibox.container.arcchart,
			layout = wibox.layout.fixed.vertical,
			hat,
			face,
			control_panel,
		},
	}

	local w = wibox{
		screan = awful.screen.focused(),
		width = panel_size,
		height = panel_size,
		widget = panel,
		x = 100,
		y = 100,
		bg = "#EE3D11:0",
		border_width = 0,
		visible = false,
		ontop = true,
	}

	self._face = face
	self._head = headline
	self._clock = time_text
	self._panel = w
	self._finish_btn = finish_btn
	self._cancel_btn = cancel_btn
	self._control_btn = control_btn
end

function TomatoPanel:_bind_keys()
	self._panel:buttons(gears.table.join(
		awful.button({}, 3, nil, function ()
			self:hide()
		end)
	))

	self._finish_btn:buttons(gears.table.join(
		awful.button({}, 1, nil, function ()
			self._timer:finish()
		end)
	))

	self._cancel_btn:buttons(gears.table.join(
		awful.button({}, 1, nil, function ()
			self._timer:cancel()
		end)
	))

	self._control_btn:buttons(gears.table.join(
		awful.button({}, 1, nil, function ()
			if self:_is_running() then
				self._timer:suspend()
			else
				self._timer:resume()
			end
		end)
	))
end

function TomatoPanel:ishide()
	return self._ishide
end

function TomatoPanel:hide()
	self._ishide = true
	self._panel.visible = false
end

function TomatoPanel:show()
	self._ishide = false
	local panel = self._panel
	local mcoords = mouse.coords()
	local geo = panel:geometry()
	panel.screan = awful.screen.focused()
	geo.x = mcoords.x - geo.width / 2
	geo.y = mcoords.y - geo.height / 2
	panel:geometry(geo)
	panel.visible = true
end

function TomatoPanel:connect_timer(timer)
	timer:register("panel", self)
	self._timer = timer
end

function TomatoPanel:update(time)
	local text = ("%02d:%02d:%02d"):format(time.h, time.m, time.s)
	self._clock.text = text
	if time.is_running then
		self._control_btn.shape = Shape.suspend
	else
		self._control_btn.shape = Shape.resume
	end

	if time.is_timeout then
		self._head.text = "TIMEOUT!!!"
		self._face.fg = "#5B351C"
	else
		self._head.text = ""
		self._face.fg = "white"
	end
end

local TomatoNotify = Class()

function TomatoNotify:__init__()
	self._is_notified = false
	self._seed = nil
end

function TomatoNotify:update(time)
	local seed = time.seed
	if seed ~= self._seed then
		self._is_notified = false
		self._seed = seed
		return
	end

	if not time.is_timeout then
		return
	end

	if self._is_notified then
		return
	end
	self:notify()
	self._is_notified = true
end

function TomatoNotify:notify()
	naughty.notify({
		title = "I'm a tomato",
		text = "\n\nREST PLEASE!!!",
		timeout = 0,
		hover_timeout = 1,
		position = "top_right",
		width = 150,
		height = 100,
		fg = "black",
		bg = "red",
		shape = (function(cr, w, h)
			return gears.shape.infobubble(
				cr, w, h, 20, 10, w/2 - 10)
		end),
		screen = awful.screen.focused(),
		border_width = 3,
		margin       = 15,
	})
end

function TomatoNotify:connect_timer(timer)
	timer:register("notify", self)
end

local Tomato = Class()
Tomato.PANEL_SIZE = 200

function Tomato:__init__()
	local timer = TomatoTimer()
	self._timer = timer

	self._time_panel = TomatoPanel(self.PANEL_SIZE)
	self._time_panel:connect_timer(timer)

	self._notify = TomatoNotify()
	self._notify:connect_timer(timer)

	timer:broadcast()
end

-- TODO
function Tomato:wibar() end
function Tomato:hide()
	self._time_panel:hide()
end

function Tomato:show()
	self._time_panel:show()
end

function Tomato:toggle()
	if self._time_panel:ishide() then
		self:show()
	else
		self:hide()
	end
end

return Tomato
