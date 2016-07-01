-- Peripheral Manager

-- Init variables
-- local w,h = term.getSize()
local w,h = 51,19
local displaymode = "full"
local displaymenu = "main"
local noteiconxpos = 0
local RUNNING = true
local peris = {
	["top"] = nil,
	["bottom"] = nil,
	["left"] = nil,
	["right"] = nil,
	["front"] = nil,
	["back"] = nil,
}
local boxes = {
	["top"] = {x = 0, y = 0},
	["bottom"] = {x = 0, y = 0},
	["front"] = {x = 0, y = 0},
	["left"] = {x = 0, y = 0},
	["right"] = {x = 0, y = 0},
	["back"] = {x = 0, y = 0},
}

-- DRAWING
-- 0 = black
-- 1 = gray
-- 2 = lightgray
-- 3 = yellow
local pcolor = {
	["drive"] = {
		"11111",
		"11111",
		"22222",
		"22222",
	},
	["printer"] = {
		"11111",
		"11111",
		"21112",
		"22222",
	},
	["monitor"] = {
		"11111",
		"10001",
		"10001",
		"11111",
	},
	["amonitor"] = {
		"33333",
		"30003",
		"30003",
		"33333",
	},
	["modem"] = {
		"11111",
		"11111",
		"11111",
		"11111",
	},
	["wmodem"] = {
		"11111",
		"11111",
		"11111",
		"11111",
	},
}
local ptxt = {
	["drive"] = {
		" ___ ",
		" --- ",
		"     ",
		"    =",
	},
	["printer"] = {
		" ___ ",
		" --- ",
		" === ",
		"    -",
	},
	["monitor"] = {
		"     ",
		"     ",
		"     ",
		"     ",
	},
	["amonitor"] = {
		"     ",
		"     ",
		"     ",
		"     ",
	},
	["modem"] = {
		"     ",
		"  @  ",
		"  @  ",
		"     ",
	},
	["wmodem"] = {
		"     ",
		"((@))",
		"((@))",
		"     ",
	},
}

local function logmsg(msg)
	local f = fs.open("/log", "a")
	f.writeLine(msg)
	f.close()
end
-- Main menu
local function drawPeri(t,xpos,ypos)
	term.setTextColor(colors.black)

	logmsg("type: "..t..", "..xpos..", "..ypos)

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
			term.write(string.sub(ptxt[t][y], x, x))
		end
	end
end

local function drawTopBar()
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.gray)
	term.setCursorPos(1,1)
	term.clearLine()
	if w < 26 then
		term.write(" pmang")
	else
		term.write(" Peripheral Manager")
	end
	term.setCursorPos(w-5,1)
	noteiconxpos = w-5
	term.write(" ! ")
	term.setBackgroundColor(colors.red)
	term.setCursorPos(w,1)
	term.write("X")
end
local function box(startx,starty)

	-- Box width: 11
	-- Box Height: 7
	-- table width: 41
	-- table height: 15

	term.setCursorPos(startx,starty)
	term.write("___________")
	for y = starty+1,starty+5 do
		term.setCursorPos(startx,y)
		term.write("|         |")
	end
	term.setCursorPos(startx,starty+6)
	term.write("-----------")
end
local function drawBoxes()
	term.setBackgroundColor(colors.white)
	term.setTextColor(colors.lightGray)
	if displaymode == "full" then
		local starty = h-16
		local startx = w-45
		boxes["top"].x = startx
		boxes["top"].y = starty
		boxes["bottom"].x = startx+15
		boxes["bottom"].y = starty
		boxes["front"].x = startx+30
		boxes["front"].y = starty
		boxes["left"].x = startx
		boxes["left"].y = starty+8
		boxes["right"].x = startx+15
		boxes["right"].y = starty+8
		boxes["back"].x = startx+30
		boxes["back"].y = starty+8
		logmsg("starty = "..starty)
		logmsg("startx = "..startx)
		local sides = {"top", "bottom", "front", "left", "right", "back"}
		local sidestep = 1
		for x = startx,startx+30,15 do
			box(x,starty)
			local cenx = (11-sides[sidestep]:len())/2
			term.setCursorPos(x+cenx,starty+1)
			term.write(sides[sidestep])
			sidestep = sidestep+1
		end
		starty = starty+8
		for x = startx,startx+30,15 do
			box(x,starty)
			local cenx = (11-sides[sidestep]:len())/2
			term.setCursorPos(x+cenx,starty+1)
			term.write(sides[sidestep])
			sidestep = sidestep+1
		end
	end
end
local function drawPeripherals()
	if displaymode == "full" then
		local xicon = 3
		local yicon = 1
		if peris["top"] ~= nil then
			drawPeri(peris["top"], boxes["top"].x+xicon, boxes["top"].y+yicon)
		end
		if peris["bottom"] ~= nil then
			drawPeri(peris["bottom"], boxes["bottom"].x+xicon, boxes["bottom"].y+yicon)
		end
		if peris["front"] ~= nil then
			drawPeri(peris["front"], boxes["front"].x+xicon, boxes["front"].y+yicon)
		end
		if peris["left"] ~= nil then
			drawPeri(peris["left"], boxes["left"].x+xicon, boxes["left"].y+yicon)
		end
		if peris["right"] ~= nil then
			drawPeri(peris["right"], boxes["right"].x+xicon, boxes["left"].y+yicon)
		end
		if peris["back"] ~= nil then
			drawPeri(peris["back"], boxes["back"].x+xicon, boxes["left"].y+yicon)
		end
		local sides = {"top", "bottom", "front", "left", "right", "back"}
		term.setTextColor(colors.black)
		term.setBackgroundColor(colors.white)
		for i = 1,6 do
			local ref = peris[sides[i]]
			local dispname = nil
			if ref ~= nil then
				if ref == "drive" then dispname = "Disk Drive"
				elseif ref == "printer" then dispname = "Printer"
				elseif ref == "monitor" then dispname = "Monitor"
				elseif ref == "amonitor" then dispname = "Adv Monitor"
				elseif ref == "modem" then dispname = "Wired Modem"
				elseif ref == "wmodem" then dispname = "Wireless Modem"
				end
				local cenx = (11-dispname:len())/2
				term.setCursorPos(cenx+boxes[sides[i]].x, boxes[sides[i]].y+7)
				term.write(dispname)
			end
		end
	else
		local sides = {"top", "bottom", "front", "left", "right", "back"}
		term.setTextColor(colors.white)
		local y = ((h-12)/2)-1
		for i = 1,6 do
			if peris[sides[i]] ~= nil then
				local ref = peris[sides[i]]
				if ref == "drive" then dispname = "Disk  Drive"
				elseif ref == "printer" then dispname = "Printer"
				elseif ref == "monitor" then dispname = "Monitor"
				elseif ref == "amonitor" then dispname = "Adv Monitor"
				elseif ref == "modem" then dispname = "Wired Modem"
				elseif ref == "wmodem" then dispname = "Wireless Modem"
				end
				local cenx = (w-dispname:len())/2
				term.setBackgroundColor(colors.lime)
				term.setCursorPos(cenx, y+i)
				term.write(" "..dispname.." ")
			else
				local cenx = (w-sides[i]:len())/2
				term.setBackgroundColor(colors.red)
				term.setCursorPos(cenx, y+i)
				term.write(" "..sides[i].." ")
			end
			y = y+1
		end
	end
end
-- Draw wrapper function
local function drawScreen()
	term.setBackgroundColor(colors.white)
	term.clear()
	if h < 18 or w < 46 then
		displaymode = "frag"
	else
		displaymode = "full"
	end
	drawTopBar()
	if displaymenu == "main" then
		drawBoxes()
		drawPeripherals()
	end
end

-- Handler
local function scanPeripherals(s)
	local sides = peripheral.getNames()
	if s then
		sides = {s}
	end
	for i = 1,#sides do
		if peripheral.isPresent(sides[i]) then
			local ref = peripheral.getType(sides[i])
			if ref == "modem" then
				if peripheral.call(sides[i], "isWireless") then
					ref = "wmodem"
				else
					ref = "modem"
				end
			elseif ref == "monitor" then
				if peripheral.call(sides[i], "isColor") then
					ref = "amonitor"
				else
					ref = "monitor"
				end
			end
			peris[sides[i]] = ref
			logmsg("peris["..sides[i].."] = "..ref)
		end
	end
end
scanPeripherals()
local function evtHandler()
	while RUNNING do
		local e = {os.pullEvent()}
		if e[1] == "term_resize" then
			w,h = term.getSize()
			drawScreen()
		elseif e[1] == "peripheral" then
			scanPeripherals(e[2])
			drawScreen()
		elseif e[1] == "peripheral_detach" then
			peris[e[2]] = nil
			drawScreen()
		elseif e[1] == "mouse_click" and e[2] == 1 then
			if e[3] == w and e[4] == 1 then break end
		elseif e[1] == "key" and e[2] == keys.q then break end
	end
end
drawScreen()
evtHandler()
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
print("Thank you for using")
print("Peripheral Manager by LegoStax")
coroutine.yield()
