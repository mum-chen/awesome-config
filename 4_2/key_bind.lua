local awful = require("awful")
local gears = require("gears")
local Class = require("class")
local Helper = require("helper")

local Key = awful.key
local unpack = table.unpack or unpack

local KeyBind = Class()
function KeyBind:__init__(modekey)
	self._modekey = modekey
	self._keys = nil
end

function KeyBind:helpers()
	return self._keys
end

function KeyBind:mod(...)
	return {self._modekey, ...}
end

local KeyBindGroup = Class({
	_keybind_classes = {}
})

function KeyBindGroup.register(name, cls)
	assert(cls:childof(KeyBind))
	KeyBindGroup._keybind_classes[name] = cls
end

function KeyBindGroup:__init__(modekey)
	self._modekey = modekey

	self._keybinds = {}
	local k, cls
	for k, cls in pairs(KeyBindGroup._keybind_classes) do
		self._keybinds[k] = cls(self._modekey)
	end
end

function KeyBindGroup:keybinds(name)
	local inst = self._keybinds[name]
	if not inst then
		return {}
	end
	return unpack(inst:helpers())
end

function KeyBindGroup:all_keybinds()
	local ks = {}
	local keybind, key
	for _, keybind in pairs(self._keybinds) do
		for _, key in ipairs(keybind:helpers()) do
			table.insert(ks, key)
		end
	end
	return unpack(ks)
end

local AmixerKeyBind = Class(KeyBind)
function AmixerKeyBind:__init__(modekey)
	AmixerKeyBind:super(self, modekey)
	self._keys = {
		Key(self:mod(),                   "e", Helper.Amixer.set_down),
		Key(self:mod("Shift"),            "e", Helper.Amixer.set_up),
		Key(self:mod("Control", "Shift"), "e", Helper.Amixer.toggle),
	}
end

local TagKeyBind = Class(KeyBind)
function TagKeyBind:__init__(modekey)
	TagKeyBind:super(self, modekey)
	self._keys = {
		Key(self:mod(), ",", awful.tag.viewprev),
		Key(self:mod(), ".", awful.tag.viewnext),
		Key(self:mod("Shift"),   "r", Helper.Tag.rename),
		Key(self:mod(),          "a", Helper.Tag.add_with_name),
		Key(self:mod("Shift"),   "a", Helper.Tag.add),
		Key(self:mod(),          "d", Helper.Tag.delete),
		Key(self:mod("Control"), "a", Helper.Tag.move_to_new),
		Key(self:mod("Shift"),   "\\", Helper.Tag.cmd),
		Key(self:mod(),          "/", Helper.Tag.search),
	}
end

local PomodoroBind = Class(KeyBind)
function PomodoroBind:__init__(modekey)
	PomodoroBind:super(self, modekey)
	self._keys = {
		Key(self:mod("Shift"), "t", Helper.Pomodoro.toggle),
	}
end

KeyBindGroup.register("sound", AmixerKeyBind)
KeyBindGroup.register("tag", TagKeyBind)
KeyBindGroup.register("pomodoro", PomodoroBind)
return KeyBindGroup
