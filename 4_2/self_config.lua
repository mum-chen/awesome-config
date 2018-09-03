local Helper = require("helper")
local Class = require("class")

local Config = Class()

function Config:__init__()
	self.sock5   =    "ss-qt5"
	self.note    =    "WizNote"
	self.browser =    "chromium-browser"
	self.music   =    "netease-cloud-music"
	self.filesystem = "nautilus"
	self.screenshot = "shutter"

	self._work_space = {
		"Work", "Work", "Work",
		"Browser", "Browser", "Note",
		"Amuse", "Reserve", "Temp",
	}
end

function Config:app_menu()
	return {
	   {"browser",     self.browser },
	   {"filesystem",  self.filesystem},
	   {"screenshot",  self.screenshot},
	   {"music", self.music},
	   -- {"note",  self.note},
	   -- {"proxy", self.sock5},
	}
end

function Config:work_space()
	local ws = self._work_space
	for i = 1, #ws do
		ws[i] = Helper.Tag._mark(ws[i], i)
	end
	return ws
end

return Config()
