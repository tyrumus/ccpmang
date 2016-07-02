--[[ Peripheral Manager by LegoStax
	TODO:
	- add about page for each peripheral type
	- add features for each peripheral type
]]--

-- Init variables
-- local w,h = term.getSize()
local w,h = 51,19
local displaymode = "full"
local displaymenu = "main"
local RUNNING = true
local networkperis = false

local noteiconxpos = 0
local notemsgs = {}
local unreadnotes = false
local scrollpos = 1
local pospossible = nil

local peris = {
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
-- Utils
local function logmsg(msg)
	local f = fs.open("/log", "a")
	f.writeLine(msg)
	f.close()
end
local function scanPeripherals(p)
	local sides = {"top", "bottom", "front", "left", "right", "back"}
	if p then
		local s = table.concat(sides)
		if string.find(s, p) then
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
		return
	end
	local allperis = peripheral.getNames()
	for a = 1,#allperis do
		local failed = 0
		for i = 1,#sides do
			if allperis[a] ~= sides[i] then
				failed = failed+1
			end
		end
		if failed == 6 then
			networkperis = true

			table.insert(peris.network, allperis[a])
		end
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
			peris["sides"][sides[i]] = ref
		end
	end
end

-- Peripheral Functions



local function drivePeripheral(pointer)
	displaymenu = "maindrive"
	logmsg("directed to drivePeripheral()")
	logmsg("pointer = "..pointer)
end




local function printerPeripheral(pointer)
	displaymenu = "mainprinter"
	logmsg("directed to printerPeripheral()")
	logmsg("pointer = "..pointer)
end




local function monitorPeripheral(pointer)
	displaymenu = "mainmonitor"
	logmsg("directed to monitorPeripheral()")
	logmsg("pointer = "..pointer)
end





local function modemPeripheral(pointer)
	displaymenu = "mainmodem"
	logmsg("directed to modemPeripheral()")
	logmsg("pointer = "..pointer)
end





local function redirectToType(pointer, isSide)
	if isSide then
		local ref = peris["sides"][pointer]
		if ref == "drive" then
			drivePeripheral(pointer)
		elseif ref == "printer" then
			printerPeripheral(pointer)
		elseif ref == "monitor" or ref == "amonitor" then
			monitorPeripheral(pointer)
		elseif ref == "modem" or ref == "wmodem" then
			modemPeripheral(pointer)
		end
	else
		local undscrpos = string.find(pointer, "_")
		logmsg("pointer = "..pointer)
		logmsg("undscrpos = "..undscrpos)
		local ref = string.sub(pointer, 1, undscrpos-1)
		logmsg("ref = "..ref)
		if ref == "drive" then
			drivePeripheral(pointer)
		elseif ref == "printer" then
			printerPeripheral(pointer)
		elseif ref == "monitor" then
			monitorPeripheral(pointer)
		elseif ref == "modem" then
			modemPeripheral(pointer)
		end
	end
end






-- Main menu
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
	if unreadnotes then term.setBackgroundColor(colors.yellow) end
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
	if displaymenu == "main" then
		if displaymode == "full" then
			local xicon = 3
			local yicon = 1
			if peris["sides"]["top"] ~= nil then
				drawPeri(peris["sides"]["top"], boxes["top"].x+xicon, boxes["top"].y+yicon)
			end
			if peris["sides"]["bottom"] ~= nil then
				drawPeri(peris["sides"]["bottom"], boxes["bottom"].x+xicon, boxes["bottom"].y+yicon)
			end
			if peris["sides"]["front"] ~= nil then
				drawPeri(peris["sides"]["front"], boxes["front"].x+xicon, boxes["front"].y+yicon)
			end
			if peris["sides"]["left"] ~= nil then
				drawPeri(peris["sides"]["left"], boxes["left"].x+xicon, boxes["left"].y+yicon)
			end
			if peris["sides"]["right"] ~= nil then
				drawPeri(peris["sides"]["right"], boxes["right"].x+xicon, boxes["left"].y+yicon)
			end
			if peris["sides"]["back"] ~= nil then
				drawPeri(peris["sides"]["back"], boxes["back"].x+xicon, boxes["left"].y+yicon)
			end
			local sides = {"top", "bottom", "front", "left", "right", "back"}
			term.setTextColor(colors.black)
			term.setBackgroundColor(colors.white)
			for i = 1,6 do
				local ref = peris["sides"][sides[i]]
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
		elseif displaymode == "frag" then
			local sides = {"top", "bottom", "front", "left", "right", "back"}
			term.setTextColor(colors.white)
			local y = ((h-12)/2)-1
			for i = 1,6 do
				if peris["sides"][sides[i]] ~= nil then
					local ref = peris["sides"][sides[i]]
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
	elseif displaymenu == "mainall" then
		term.setBackgroundColor(colors.white)
		term.clear()
		drawTopBar()
		local scrollpos = 1
		local pospossible = 1
		local data = {}
		local function draw()
			term.setBackgroundColor(colors.lightGray)
			term.setTextColor(colors.white)
			term.setCursorPos(1,2)
			term.write(" << Back ")
			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.black)
			term.write(" All Peripherals")

			local sides = {"top", "bottom", "front", "left", "right", "back"}
			data = {}
			for i = 1,6 do
				if peris["sides"][sides[i]] ~= nil then
					table.insert(data, sides[i])
				end
			end
			for i = 1,#peris["network"] do
				if peris["network"][i] ~= nil then
					table.insert(data, peris["network"][i])
				end
			end
			local greatestpos = 1
			for i = 1,#data do
				local ref = data[i]:len()
				if ref > greatestpos then
					greatestpos = ref
				end
			end
			pospossible = #data-(h-3)
			if pospossible < 1 then pospossible = 1 end

			term.setCursorPos(2,3)
			for i = scrollpos,#data do
				if i > #data then break end
				term.write(data[i])
				for i = 1,greatestpos do
					term.write(" ")
				end
				local x,y = term.getCursorPos()
				y = y+1
				term.setCursorPos(2,y)
				if y > h then break end
			end
		end
		draw()
		while true do -- MAINALL handler
			local e = {os.pullEvent()}
			if e[1] == "term_resize" then
				w,h = term.getSize()
				drawScreen()
			elseif e[1] == "peripheral" then
				scanPeripherals(e[2])
				draw()
			elseif e[1] == "peripheral_detach" then
				local success = false
				local sides = {"top", "bottom", "front", "left", "right", "back"}
				for i = 1,#peris["network"] do
					if e[2] == peris["network"][i] then
						table.remove(peris["network"], i)
						success = true
						break
					end
				end
				if not success then
					for i = 1,6 do
						if e[2] == sides[i] then
							peris["sides"][sides[i]] = nil
							break
						end
					end
				end
				draw()
			elseif e[1] == "note_center" then
				table.insert(notemsgs,e[2])
				unreadnotes = true
				drawTopBar()
			elseif e[1] == "key" and e[2] == keys.q then
				RUNNING = false
				break
			elseif e[1] == "key" and e[2] == keys.n then os.queueEvent("note_center", "this is a test") -- DEV ONLY
			elseif e[1] == "mouse_scroll" then
				if e[2] == 1 and scrollpos < pospossible then
					scrollpos = scrollpos+1
				elseif e[2] == -1 and scrollpos > 1 then
					scrollpos = scrollpos-1
				end
				draw()
			elseif e[1] == "mouse_click" and e[2] == 1 then
				if e[3] == w and e[4] == 1 then
					RUNNING = false
					break
				elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then
					break
				elseif e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
					displaymenu = "notecenter"
					drawNotes()
					displaymenu = "mainall"
					draw()
				elseif e[4] >= 3 then
					pos = (e[4]-3)+scrollpos
					if pos <= #data then
						if e[3] >= 2 and e[3] <= data[pos]:len() then -- selected peripheral
							if data[pos] == "top" or data[pos] == "bottom" or data[pos] == "front" or data[pos] == "left" or data[pos] == "right" or data[pos] == "back" then
								redirectToType(data[pos], true)
							else
								logmsg("redirectToType(networkperi)")
								redirectToType(data[pos])
							end
						end
					end
				end
			end
		end
		displaymenu = "main"
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
		if networkperis then
			term.setBackgroundColor(colors.lightGray)
			term.setTextColor(colors.white)
			term.setCursorPos(1,2)
			term.write(" More >> ")
		end
	elseif displaymenu == "mainall" then
		drawPeripherals()
	end
end

-- Notification Center
function drawNotes()
	term.setBackgroundColor(colors.white)
	term.clear()
	drawTopBar()
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.white)
	term.setCursorPos(noteiconxpos,1)
	term.write(" ! ")
	term.setBackgroundColor(colors.white)
	term.setTextColor(colors.black)
	term.setCursorPos(1,2)
	term.write("Notification Center")
	local function draw()
		-- calculate vars
		local greatestpos = 1
		for i = 1,#notemsgs do
			local ref = notemsgs[i]:len()
			if ref > greatestpos then
				greatestpos = ref
			end
		end

		pospossible = #notemsgs-(h-4)
		if pospossible < 1 then pospossible = 1 end

		-- draw
		term.setCursorPos(1,4)
		for i = scrollpos,#notemsgs do
			if i > #notemsgs then break end
			term.write(notemsgs[i])
			for i = 1,greatestpos do
				term.write(" ")
			end
			local x,y = term.getCursorPos()
			y = y+1
			term.setCursorPos(1,y)
			if y > h then break end
		end
	end
	pospossible = #notemsgs-(h-4)
	if pospossible < 1 then pospossible = 1 end
	if pospossible then scrollpos = pospossible end
	draw()
	unreadnotes = false
	while true do -- NOTE CENTER LOOP
		local e = {os.pullEvent()}
		if e[1] == "term_resize" then
			w,h = term.getSize()
			drawScreen()
		elseif e[1] == "peripheral" then
			scanPeripherals(e[2])
		elseif e[1] == "peripheral_detach" then
			peris[e[2]] = nil
		elseif e[1] == "note_center" then
			table.insert(notemsgs,e[2])
			pospossible = #notemsgs-(h-4)
			if pospossible < 1 then pospossible = 1 end
			scrollpos = pospossible
			draw()
		elseif e[1] == "key" and e[2] == keys.q then
			RUNNING = false
			break
		elseif e[1] == "key" and e[2] == keys.n then os.queueEvent("note_center", "this is a test from inside note center") -- DEV ONLY
		elseif e[1] == "mouse_click" and e[2] == 1 then
			if e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then
				drawScreen()
				break
			elseif e[3] == w and e[4] == 1 then
				RUNNING = false
				break
			end
		elseif e[1] == "mouse_scroll" then
			if e[2] == 1 and scrollpos < pospossible then
				scrollpos = scrollpos+1
			elseif e[2] == -1 and scrollpos > 1 then
				scrollpos = scrollpos-1
			end
			draw()
		end
	end
end

-- Handler
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
			local success = false
			local sides = {"top", "bottom", "front", "left", "right", "back"}
			for i = 1,#peris["network"] do
				if e[2] == peris["network"][i] then
					table.remove(peris["network"], i)
					success = true
					break
				end
			end
			if not success then
				for i = 1,6 do
					if e[2] == sides[i] then
						peris["sides"][sides[i]] = nil
						break
					end
				end
			end

			drawScreen()
		elseif e[1] == "note_center" then
			table.insert(notemsgs,e[2])
			unreadnotes = true
			drawTopBar()
		elseif e[1] == "mouse_click" and e[2] == 1 then
			if e[3] == w and e[4] == 1 then break
			elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 and networkperis and displaymenu == "main" then
				displaymenu = "mainall"
				drawPeripherals()
				drawScreen()
			elseif e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
				displaymenu = "notecenter"
				drawNotes()
				displaymenu = "main"
				drawScreen()
			elseif displaymenu == "main" and displaymode == "full" then -- click detection for full boxes
				if e[3] >= boxes.top.x and e[3] <= boxes.top.x+10 and e[4] >= boxes.top.y and e[4] <= boxes.top.y+6 then -- TOP
					redirectToType("top", true)
				elseif e[3] >= boxes.bottom.x and e[3] <= boxes.bottom.x+10 and e[4] >= boxes.bottom.y and e[4] <= boxes.bottom.y+6 then -- BOTTOM
					redirectToType("bottom", true)
				elseif e[3] >= boxes.front.x and e[3] <= boxes.front.x+10 and e[4] >= boxes.front.y and e[4] <= boxes.front.y+6 then -- FRONT
					redirectToType("front", true)
				elseif e[3] >= boxes.left.x and e[3] <= boxes.left.x+10 and e[4] >= boxes.left.y and e[4] <= boxes.left.y+6 then -- LEFT
					redirectToType("left", true)
				elseif e[3] >= boxes.right.x and e[3] <= boxes.right.x+10 and e[4] >= boxes.right.y and e[4] <= boxes.right.y+6 then -- RIGHT
					redirectToType("right", true)
				elseif e[3] >= boxes.back.x and e[3] <= boxes.back.x+10 and e[4] >= boxes.back.y and e[4] <= boxes.back.y+6 then -- BACK
					redirectToType("back", true)
				end
			end
		elseif e[1] == "key" and e[2] == keys.q then break
		elseif e[1] == "key" and e[2] == keys.n then os.queueEvent("note_center", "this is a test") -- DEV ONLY
		end
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
