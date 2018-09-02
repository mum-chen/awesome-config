--[[
@auth   get from web
@desc   print with color, and can print table
@reference
	ANSI 控制码
	http://blog.chinaunix.net/uid-28917424-id-3889917.html
@usage
	local print = require("./color-p")
@date	auth        | date         | desc
	mum-chen    | 2016-11-26   | modify api
--]]
--======== include and declare constant =======================================
local cn = "\27[0m"

local color = {
	r = "\27[1;31m",
	g = "\27[1;32m",
	y = "\27[1;33m",
	b = "\27[1;34m",
	p = "\27[1;35m",
}

local ttc = {
	['nil']      = 'r',
	['boolean']  = 'y',
	['number']   = 'g',
	['string']   = 'b',
	['function'] = 'p'
}

--======== private function ===================================================
local function pi(indent)
	io.write(string.rep("  ", indent))
end

local function pl()
	io.write("\n")
end

local function pv(var, c)
	if c and color[c] then
		io.write(color[c] .. tostring(var) .. cn)
	else
		io.write(tostring(var))
	end
end

local function pt(var, indent)
	pv('{'); pl()

	for k,v in pairs(var) do
		pi(indent + 1); pv('['); pv(k,ttc[type(k)]); pv(']  ')
		
		local t = type(v)
		if t == 'table' then
			pt(v, indent + 1)
		else
			pv(v, ttc[t]); pl()
		end
	end
	pi(indent); pv('}'); pl()
end

local function _p(var)
	local t = type(var)

	if t == 'table' then
		pt(var, 0)
	else
		pv(var, ttc[t]); pl()
	end
end

--======== public function ====================================================
-- tips: select('#', ...)  and #arg is alternative opt in function
local function p(...)
	local arg1, arg2 = select(1, ...)

	if arg1 == nil then	-- noting input
		_p(nil)
	elseif arg2 then	-- input more than one arg
		_p({...})
	else			-- input only one arg
		_p(arg1)
	end
end

---------- retuern entry -------------------------------------------------------
return p
