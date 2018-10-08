local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

local AmixerHelper = {}

function AmixerHelper.set_up()
	awful.util.spawn("amixer set Master 5%+")
end

function AmixerHelper.set_down()
	awful.util.spawn("amixer set Master 5%-")
end

function AmixerHelper.toggle()
	awful.util.spawn("amixer -D pulse set Master 1+ toggle")
end

local TagHelper = {}

function TagHelper._mark(str, idx)
	return ("%s#%d"):format(str:match("([^#]*)"), idx)
end

function TagHelper.mark(tag)
	tag.name = TagHelper._mark(tag.name, tag.index)
end

function TagHelper.mark_all()
	local tags = awful.screen.focused().tags
	local tag
	for _, tag in ipairs(tags) do
		TagHelper.mark(tag)
	end
end

function TagHelper.rename()
	awful.prompt.run {
		prompt = "New tag name: ",
		textbox = awful.screen.focused().mypromptbox.widget,
		exe_callback = function(new_name)
			if not new_name or #new_name == 0 then return end

			local t = awful.screen.focused().selected_tag
			if t then
				t.name = new_name
			end
			TagHelper.mark(t)
		end
	}
end

function TagHelper._add(name)
	local t = awful.tag.add(name, {screan = awful.screen.focused()})
	TagHelper.mark(t)
	t:view_only()
end

function TagHelper.add()
	TagHelper._add("NewTag")
end

function TagHelper.add_with_name()
	awful.prompt.run {
		prompt = "New tag name: ",
		textbox = awful.screen.focused().mypromptbox.widget,
		exe_callback = function(name)
			if not name or #name == 0 then return end
			TagHelper._add(name)
		end
	}
end

function TagHelper.delete()
	local t = awful.screen.focused().selected_tag
	if not t then return end
	t:delete()
	TagHelper.mark_all()
end

function TagHelper.copy()
	local t = awful.screen.focused().selected_tag
	if not t then return end

	local clients = t:clients()
	local t2 = awful.tag.add(t.name, awful.tag.getdata(t))
	TagHelper.mark(t2)
	t2:clients(clients)
	t2:view_only()
end

function TagHelper.move_to_new()
	local c = client.focus
	if not c then return end
	local t = awful.tag.add(c.class, {screen = c.screen})
	TagHelper.mark(t)
	c:tags({t})
	t:view_only()
end

function TagHelper.move(source, target)
	local tag_source
	if source then
		local tags = awful.screen.focused().tags
		tag_source = tags[source]
	else
		tag_source = awful.screen.focused().selected_tag
	end
	awful.tag.move(target, tag_source)
	TagHelper.mark_all()
end

function TagHelper.swap(x, y)
	local tags = awful.screen.focused().tags
	tag_x, tag_y = tags[x], tags[y]
	if not tag_x then
		tag_x = awful.screen.focused().selected_tag
	end
	if not (tag_x and  tag_y) then
		local fmt = ("idx:%d %s")
		local info = ("%s\t%s"):format(
			fmt:format(x, tag_x and "found" or "not found"),
			fmt:format(y, tag_y and "found" or "not found")
		)
		naughty.notify({
			title = "Error Command!",
			text = info,
			timeout = 3
		})
		return
	end

	awful.tag.swap(tag_x, tag_y)
	TagHelper.mark(tag_x)
	TagHelper.mark(tag_y)
end

function TagHelper._parse_cmd(cmd)
	local x, op, y = cmd:match("^%s*(%d*)%s*([<%->]+)%s*(%d+)")
	local f = ({
		["->"]  = TagHelper.move,
		["<>"]  = TagHelper.swap,
		["<->"] = TagHelper.swap,
	})[op]

	x, y = tonumber(x), tonumber(y)
	if not (y and f) then
		local t = ("got %s"):format(cmd)
		naughty.notify({
			title = "Error Command!",
			text = t,
			timeout = 3
		})
		return
	end
	f(x, y)
end

function TagHelper.cmd()
	awful.prompt.run {
		prompt = "cmd: ",
		textbox = awful.screen.focused().mypromptbox.widget,
		exe_callback = TagHelper._parse_cmd
	}
end

return {
	Tag = TagHelper,
	Amixer = AmixerHelper
}
