-- Peripheral Manager by LegoStax

if not term.isColor() or not term.isColour() then
	print("Advanced computer required")
	return
end

local w,h = term.getSize()
--w,h = 51,19
local GITHUB_VERSION_URL = "http://github.com"
local pmang = {
    running = true,
    state = "mainmenu",
}
local notes = {
    noteiconxpos = 0,
    notemsgs = {},
    unreadnotes = false,
    scrollpos = 1,
    pospossible = nil,
    greatestpos = 1,
}
local peris = {
    netperis = false,
	["sides"] = {
		top = nil,
		bottom = nil,
		left = nil,
		right = nil,
		front = nil,
		back = nil,
	},
	["network"] = {},
}
local sides = rs.getSides()
local boxes = {["top"] = {x = 0, y = 0},["bottom"] = {x = 0, y = 0},["front"] = {x = 0, y = 0},["left"] = {x = 0, y = 0},["right"] = {x = 0, y = 0},["back"] = {x = 0, y = 0},}
-- DRAWING
-- 0 = black
-- 1 = gray
-- 2 = lightgray
-- 3 = yellow
local pcolor = {
	["drive"] = {"11111","11111","22222","22222",},
	["printer"] = {"11111","11111","21112","22222",},
	["monitor"] = {"11111","10001","10001","11111",},
	["amonitor"] = {"33333","30003","30003","33333",},
	["modem"] = {"11111","11111","11111","11111",},
	["wmodem"] = {"11111","11111","11111","11111",},
	["computer"] = {"11111","10001","20002","22222",},
}
local ptxt = {
	["drive"] = {" ___ "," --- ","     ","    =",},
	["printer"] = {" ___ "," --- "," === ","    -",},
	["monitor"] = {"     ","     ","     ","     ",},
	["amonitor"] = {"     ","     ","     ","     ",},
	["modem"] = {"     ","  @  ","  @  ","     ",},
	["wmodem"] = {"     ","((@))","((@))","     ",},
	["computer"] = {"     "," >   ","     ","    -",},
}




-- Utils




local function logmsg(msg)
	local f = fs.open("/log", "a")
	f.writeLine(msg)
	f.close()
end
local function mod(a,b)
	return a - math.floor(a/b)*b
end
local function printPos(text,x,y,bg,fg)
	if fg then term.setTextColor(fg) end
	if bg then term.setBackgroundColor(bg) end
	if x == true then
		x = w/2 - text:len()/2
	end
	term.setCursorPos(x,y)
	term.write(text)
end






-- Init



local function checkUpdates()
    local response = http.get(GITHUB_VERSION_URL)
    local data = response.readAll()
    response.close()
    logmsg("Got data")
    logmsg(data)
end
local function scanPeripherals(p)
    local function load(p)
        if string.find(table.concat(sides), p) then
            local ref = peripheral.getType(p)
            if ref == "modem" then
                if peripheral.call(p, "isWireless") then
                    ref = "wmodem"
                else
                    ref = "modem"
                end
            elseif ref == "monitor" then
                if peripheral.call(p, "isColor") then
                    ref = "amonitor"
                else
                    ref = "monitor"
                end
            end
            peris["sides"][p] = ref
        else
            table.insert(peris.network, p)
        end
    end
    if p then
        load(p)
        return
    else
        local allperis = peripheral.getNames()
        for a = 1,#allperis do
            local failed = 0
            for i = 1,#sides do
                if allperis[a] ~= sides[i] then
                    failed = failed+1
                end
            end
            if failed == 6 then
                peris.netperis = true

                table.insert(peris.network, allperis[a])
            end
        end
        for i = 1,#sides do
    		if peripheral.isPresent(sides[i]) then
    			load(sides[i])
    		end
    	end
    end
end
local function init()
    checkUpdates()
    scanPeripherals()
end




-- Drawing functions

local function drawTopBar()
	if w < 26 then printPos(" pmang",1,1,colors.gray,colors.white)
	else printPos(" Peripheral Manager",1,1,colors.gray,colors.white) end
	notes.noteiconxpos = w-5
	if notes.unreadnotes then
		printPos(" ! ",notes.noteiconxpos,1,colors.yellow)
	elseif 0 == 0 then -- if note menu is open
		printPos(" ! ",notes.noteiconxpos,1,colors.lightGray)
	else
		printPos(" ! ",notes.noteiconxpos,1,colors.gray)
	end
	printPos("x",w,1,colors.red)
end

local function drawPeri(t,xpos,ypos)
	term.setTextColor(colors.black)

	for y = 1,4 do
		for x = 1,5 do
			local pos = string.sub(pcolor[t][y], x, x)
			if pos == "0" then
				term.setBackgroundColor(colors.black)
			elseif pos == "1" then
				term.setBackgroundColor(colors.gray)
			elseif pos == "2" then
				term.setBackgroundColor(colors.lightGray)
			elseif pos == "3" then
				term.setBackgroundColor(colors.yellow)
			end
			term.setCursorPos(x+(xpos-1), y+ypos)
			if string.sub(ptxt[t][y],x,x) == ">" then
				term.setTextColor(colors.white)
				term.write(string.sub(ptxt[t][y], x, x))
				term.setTextColor(colors.black)
			else
				term.write(string.sub(ptxt[t][y], x, x))
			end
		end
	end
end
