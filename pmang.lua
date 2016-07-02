--[[ Peripheral Manager by LegoStax
	Peripheral functions: line 597

	TODO:
	- fix channel range sorter
]]--

if not term.isColor() or not term.isColour() then
	print("Advanced computer required")
	return
end

-- Init variables
-- local w,h = term.getSize()
local w,h = 51,19
local displaymode = "full"
local displaymenu = "main"
local pmang = {RUNNING = true}
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
local mchannels = {}

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
	["computer"] = {
		"11111",
		"10001",
		"20002",
		"22222",
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
	["computer"] = {
		"     ",
		" >   ",
		"     ",
		"    -",
	},
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
	if displaymenu == "notecenter" then term.setBackgroundColor(colors.lightGray) end
	term.write(" ! ")
	term.setBackgroundColor(colors.red)
	term.setCursorPos(w,1)
	term.write("X")
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
local function createNote(pointer, msg)
	msg = textutils.formatTime(os.time(),true)..":"..pointer..": "..msg
	if msg:len() > w then
		table.insert(notemsgs, string.sub(msg, 1, w))
		for i = w+1,msg:len(),w do
			table.insert(notemsgs, string.sub(msg, i, i+w))
		end
	else
		table.insert(notemsgs, msg)
	end
	if displaymenu ~= "notecenter" then
		unreadnotes = true
	end
	os.queueEvent("note_center")
end
local function processMessage(pointer, channel, reply, msg, dist)
	local note = "C"..channel.."/"..reply.." D:"..dist..": "
	if type(msg) == "table" and msg.message ~= nil then
		note = note..msg.message
	else
		note = note..msg
	end
	createNote(pointer, note)
end

local function explorerDialog(pointer, canDir)
	if not canDir then canDir = false end
	local RUNNING = true
	local PATH = "/"
	local beginFiles = 0
	local scrollpos = 1
	local greatestpos = 1
	local pospossible = 1
	local oldItems = nil
	local pos = nil
	local selectedItem = -1
	local returnpath = ""
	local selectedPath = "/"

	local function clear(bg)
		bg = bg or colors.black
		term.setBackgroundColor(bg)
		term.clear()
		term.setCursorPos(1,1)
	end

	local function drawTopBar()
		term.setTextColor(colors.white)
		term.setBackgroundColor(colors.gray)
		term.setCursorPos(1,1)
		term.clearLine()
		if w < 16 then
			term.write(" exp")
		else
			term.write(" Explorer")
		end
		term.setCursorPos(w-5,1)
		noteiconxpos = w-5
		if unreadnotes then term.setBackgroundColor(colors.yellow) end
		term.write(" ! ")
		term.setBackgroundColor(colors.red)
		term.setCursorPos(w,1)
		term.write("X")
	end

	local function printPos(msg,x,y,bg,fg)
		if bg then term.setBackgroundColor(bg) end
		if fg then term.setTextColor(fg) end
		term.setCursorPos(x,y)
		term.write(msg)
	end

	local function listFiles(d)
		local dir = nil
		if d then
			dir = shell.resolve(d)
		else
			dir = shell.dir()
		end

		local all = fs.list(dir)
		local files = {}
		local folders = {}
		local hidden = settings.get("list.show_hidden")
		for n, item in pairs(all) do
			if hidden or string.sub(item,1,1) ~= "." then
				local path = fs.combine(dir, item)
				if fs.isDir(path) then
					table.insert(folders, item)
				else
					table.insert(files, item)
				end
			end
		end
		table.sort(folders)
		table.sort(files)
		return folders, files
	end

	local function calculateItems()
		local folders, files = listFiles(PATH)
		local items = folders
		beginFiles = #folders+1
		for i = 1,#files do
			table.insert(items,files[i])
		end
		-- calculate greatestpos
		for i = 1,#items do
			if items[i]:len() > greatestpos then
				greatestpos = items[i]:len()
			end
		end
		pospossible = #items-(h-6)
		return items
	end

	local function drawCurrentPath()
		term.setBackgroundColor(colors.lightGray)
		term.setCursorPos(1,2)
		term.clearLine()
		printPos(" <  "..PATH,1,2,colors.lightGray)
	end

	local function drawItems(items)
		if not items then
			items = oldItems
		end
		oldItems = items

		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.blue)
		term.setCursorPos(5,3)
		for i = scrollpos,#items do
			if i > #items then break end
			if i == beginFiles then term.setTextColor(colors.black) end
			if i == selectedItem then
				term.setBackgroundColor(colors.blue)
				term.setTextColor(colors.white)
			else
				term.setBackgroundColor(colors.white)
				if i < beginFiles then term.setTextColor(colors.blue)
				else term.setTextColor(colors.black) end
			end
			term.write(items[i])
			term.setBackgroundColor(colors.white)
			for i = 1,greatestpos do term.write(" ") end
			local x,y = term.getCursorPos()
			y = y+1
			term.setCursorPos(5,y)
			if y > h-3 then break end
		end
	end

	local function drawBottomBar()
		term.setBackgroundColor(colors.gray)
		for i = h-2,h do
			term.setCursorPos(1,i)
			term.clearLine()
		end
		printPos(" Filename: ",1,h-1,colors.gray,colors.white)
		if selectedPath ~= "" then
			printPos(selectedPath,12,h-1)
		end
		printPos(" Select ",w-8,h,colors.lightGray)
	end

	local function animSelected(msg,x,y,bg,fg)
		printPos(msg,x,y,bg,fg)
		sleep(0.1)
	end

	local function drawScreen()
		clear(colors.white)
		drawTopBar()
		drawCurrentPath()
		drawItems(calculateItems())
		drawBottomBar()
		WALL = ""
	end

	drawScreen()

	while RUNNING and pmang.RUNNING do
		local e = {os.pullEvent()}
		if e[1] == "mouse_click" and e[2] == 1 and e[3] == w and e[4] == 1 then
			RUNNING = false
			pmang.RUNNING = false
			break
		elseif e[1] == "key" and e[2] == keys.q then
			RUNNING = false
			pmang.RUNNING = false
			break
		elseif e[1] == "mouse_scroll" then
			if e[2] == 1 and scrollpos < pospossible then
				scrollpos = scrollpos+1
			elseif e[2] == -1 and scrollpos > 1 then
				scrollpos = scrollpos-1
			end
			drawItems()
		elseif e[1] == "mouse_click" and e[2] == 1 and e[3] >= 1 and e[3] <= 3 and e[4] == 2 then
			animSelected(" < ",1,2,colors.gray,colors.lightGray)
			if PATH ~= "/" then
				for i = PATH:len()-1,1,-1 do
					if string.sub(PATH,i,i) == "/" then
						PATH = string.sub(PATH,1,i)
						break
					end
				end
				selectedItem = -1
				scrollpos = 1
				drawScreen()
			else
				printPos(" < ",1,2,colors.lightGray,colors.white)
			end
		elseif e[1] == "mouse_click" then
			if e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
				displaymenu = "notecenter"
				drawNotes()
				displaymenu = "explorerdialog"
				drawScreen()
			elseif e[3] >= w-8 and e[3] <= w and e[4] == h and selectedPath ~= "" then -- select button
				if selectedPath == "/" then
					if canDir then
						returnpath = selectedPath
						RUNNING = false
						break
					end
				else
					returnpath = selectedPath
					RUNNING = false
					break
				end
			elseif e[4] >= 3 then
				pos = (e[4]-3)+scrollpos
				if pos <= #oldItems then
					if e[3] >= 5 and e[3] <= oldItems[pos]:len()+4 then
						if pos == selectedItem then
							if pos < beginFiles and e[2] == 1 then -- move into folder
								PATH = PATH..oldItems[pos].."/"
								selectedItem = -1
								scrollpos = 1
								drawScreen()
							elseif pos >= beginFiles and e[2] == 1 then
								if selectedPath == "/" then
									if canDir then
										returnpath = selectedPath
										RUNNING = false
										break
									end
								else
									returnpath = selectedPath
									RUNNING = false
									break
								end
							end
						else
							selectedItem = pos
							selectedPath = PATH..oldItems[pos]
							if fs.isDir(selectedPath) and not canDir then
								selectedPath = "/"
							end
							drawItems()
							drawBottomBar()
						end
					else
						selectedItem = -1
						selectedPath = "/"
						drawItems()
						drawBottomBar()
					end
				else
					selectedItem = -1
					selectedPath = "/"
					drawItems()
					drawBottomBar()
				end
			end
		elseif e[1] == "term_resize" then
			w,h = term.getSize()
			drawScreen()
		elseif e[1] == "peripheral" then
			scanPeripherals(e[2])
			createNote(e[2], "Attached")
		elseif e[1] == "peripheral_detach" then
			createNote(e[2], "Detached")
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

			if e[2] == pointer then
				clear()
				term.setTextColor(colors.red)
				term.setCursorPos(1,3)
				term.write("Peripheral removed!")
				sleep(3)
				returnpath = "$$removed"
				break
			end
		elseif e[1] == "note_center" then
			drawTopBar()
		elseif e[1] == "disk" then
			createNote(e[2], "Disk inserted")
		elseif e[1] == "disk_eject" then
			createNote(e[2], "Disk ejected")
		elseif e[1] == "monitor_resize" then
			local mw,mh = peripheral.call(e[2], "getSize")
			createNote(e[2], "Screen size changed to "..mw.."x"..mh)
		elseif e[1] == "monitor_touch" then
			createNote(e[2], "touched at "..e[3]..", "..e[4])
		elseif e[1] == "modem_message" then
			processMessage(e[2], e[3], e[4], e[5], e[6])
		elseif e[1] == "key" and e[2] == keys.q then
			pmang.RUNNING = false
			break
		end
	end



	if pmang.RUNNING then
		if fs.isDir(returnpath) then
			returnpath = returnpath.."/"
		end
		return returnpath
	else
		return ""
	end
end

-- Peripheral Functions
























local function drivePeripheral(pointer)
	displaymenu = "maindrive"

	local isPlaying = false
	local label = nil
	local RUNNING = true

	local function clear()
		term.setBackgroundColor(colors.white)
		term.clear()
		drawTopBar()
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
	end
	local function drawCopyMove()
		local doCopy = true
		local sourcepath = ""
		local targetpath = ""
		local cenx = 0
		local returnvalue = true
		local function draw()
			clear()
			term.setBackgroundColor(colors.lightGray)
			term.setTextColor(colors.white)
			term.setCursorPos(1,2)
			term.write(" << Back ")

			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.black)
			term.setCursorPos((w-17)/2,4)
			term.write("Copy/Move File(s)")

			term.setTextColor(colors.black)
			if doCopy then
				term.setBackgroundColor(colors.lime)
			else
				term.setBackgroundColor(colors.lightGray)
			end
			term.setCursorPos(3,6)
			term.write(" ")
			term.setBackgroundColor(colors.white)
			term.write(" Copy")
			if not doCopy then
				term.setBackgroundColor(colors.lime)
			else
				term.setBackgroundColor(colors.lightGray)
			end
			term.setCursorPos(11,6)
			term.write(" ")
			term.setBackgroundColor(colors.white)
			term.write(" Move")

			term.setCursorPos(3,8)
			term.write("Source: "..sourcepath)
			term.setCursorPos(3,9)
			term.write("Target: "..targetpath)

			if sourcepath == "" then
				term.setBackgroundColor(colors.red)
			else
				term.setBackgroundColor(colors.lime)
			end
			term.setTextColor(colors.white)
			cenx = (w-20)/2
			term.setCursorPos(cenx,11)
			term.write(" Source ")
			if targetpath == "" then
				term.setBackgroundColor(colors.red)
			else
				term.setBackgroundColor(colors.lime)
			end
			term.setCursorPos(cenx+12,11)
			term.write(" Target ")

			term.setBackgroundColor(colors.lightGray)
			term.setCursorPos(w-6,h)
			term.write(" Go >> ")
		end
		draw()
		while true and pmang.RUNNING do
			local e = {os.pullEvent()}
			if e[1] == "mouse_click" and e[2] == 1 then
				if e[3] == w and e[4] == 1 then
					pmang.RUNNING = false
					break
				elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then -- back button
					break
				elseif e[3] >= 3 and e[3] <= 8 and e[4] == 6 then -- copy radio button
					doCopy = true
					draw()
				elseif e[3] >= 11 and e[3] <= 16 and e[4] == 6 then -- move radio button
					doCopy = false
					draw()
				elseif e[3] >= cenx and e[3] <= cenx+7 and e[4] == 11 then -- source button
					sourcepath = explorerDialog(pointer, true)
					if sourcepath == "$$removed" then
						returnvalue = false
						break
					end
					draw()
				elseif e[3] >= cenx+12 and e[3] <= cenx+19 and e[4] == 11 then -- target button
					targetpath = explorerDialog(pointer, true)
					if targetpath == "$$removed" then
						returnvalue = false
						break
					end
					draw()
				elseif e[3] >= w-6 and e[3] <= w and e[4] == h and sourcepath ~= "" and targetpath ~= "" then -- go button
					if doCopy then
						if fs.exists(targetpath..fs.getName(sourcepath)) then
							clear()
							term.setTextColor(colors.red)
							term.setCursorPos(2,3)
							term.write("Path exists")
							sleep(2)
							draw()
						else
							fs.copy(sourcepath, targetpath..fs.getName(sourcepath))
							break
						end
					else
						if fs.exists(targetpath..fs.getName(sourcepath)) then
							clear()
							term.setTextColor(colors.red)
							term.setCursorPos(2,3)
							term.write("Path exists")
							sleep(2)
							draw()
						else
							fs.move(sourcepath, targetpath..fs.getName(sourcepath))
							break
						end
					end
				elseif e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
					displaymenu = "notecenter"
					drawNotes()
					displaymenu = "maindrive"
					draw()
				end
			elseif e[1] == "term_resize" then
				w,h = term.getSize()
				drawTopBar()
				draw()
			elseif e[1] == "peripheral" then
				scanPeripherals(e[2])
				createNote(e[2], "Attached")
			elseif e[1] == "peripheral_detach" then
				createNote(e[2], "Detached")
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

				if e[2] == pointer then
					clear()
					term.setTextColor(colors.red)
					term.setCursorPos(1,3)
					term.write("Peripheral removed!")
					sleep(3)
					RUNNING = false
					break
				end
			elseif e[1] == "note_center" then
				drawTopBar()
			elseif e[1] == "disk" then
				createNote(e[2], "Disk inserted")
			elseif e[1] == "disk_eject" then
				createNote(e[2], "Disk ejected")
			elseif e[1] == "monitor_resize" then
				local mw,mh = peripheral.call(e[2], "getSize")
				createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
			elseif e[1] == "monitor_touch" then
				createNote(e[2], "touched at "..e[3]..", "..e[4])
			elseif e[1] == "modem_message" then
				processMessage(e[2], e[3], e[4], e[5], e[6])
			elseif e[1] == "key" and e[2] == keys.q then
				pmang.RUNNING = false
				break
			end
		end
		return returnvalue
	end
	local function draw()
		clear()
		term.setBackgroundColor(colors.lightGray)
		term.setTextColor(colors.white)
		term.setCursorPos(1,2)
		term.write(" << Back ")

		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
		term.setCursorPos(3,4)
		term.write("Disk Drive")
		drawPeri("drive",3,5)
		term.setBackgroundColor(colors.white)
		term.setCursorPos(10,6)
		term.write("Name: "..pointer)
		term.setCursorPos(10,7)
		if not peripheral.call(pointer, "isDiskPresent") then -- if there's a disk
			term.setTextColor(colors.red)
			term.write("No disk!")
		else
			if peripheral.call(pointer, "hasAudio") then -- if it's a music disk
				term.write("Title: "..peripheral.call(pointer, "getAudioTitle"))
				if not isPlaying then
					term.setBackgroundColor(colors.lime)
					term.setTextColor(colors.white)
					term.setCursorPos(5,13)
					term.write(" Play ")
				else
					term.setBackgroundColor(colors.red)
					term.setTextColor(colors.white)
					term.setCursorPos(5,13)
					term.write(" Stop ")
				end
			else
				local mount = peripheral.call(pointer, "getMountPath")
				term.write("Mount point: "..mount)
				term.setCursorPos(10,8)
				term.write("ID: "..peripheral.call(pointer, "getDiskID"))
				term.setCursorPos(10,9)
				label = peripheral.call(pointer, "getDiskLabel")
				if label then
					term.write("Label: "..label)
				else
					term.write("Label: ")
					term.setTextColor(colors.lightGray)
					term.write("none")
					term.setTextColor(colors.black)
				end
				term.setCursorPos(10,10)
				term.write("Free space: "..(fs.getFreeSpace(mount)/1000).." KB")

				term.setBackgroundColor(colors.gray)
				term.setTextColor(colors.white)
				term.setCursorPos(5,13)
				term.write(" Set Label ")

				term.setCursorPos(5,15)
				term.write(" Copy/Move Files ")
			end
			term.setBackgroundColor(colors.gray)
			term.setTextColor(colors.white)
			term.setCursorPos(5,11)
			term.write(" Eject ")
		end
	end
	draw()
	while RUNNING and pmang.RUNNING do
		local e = {os.pullEvent()}
		if e[1] == "mouse_click" and e[2] == 1 then
			if e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
				displaymenu = "notecenter"
				drawNotes()
				displaymenu = "maindrive"
				draw()
			elseif e[3] == w and e[4] == 1 then
				pmang.RUNNING = false
				break
			elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then
				RUNNING = false
				break
			elseif e[3] >= 5 and e[3] <= 11 and e[4] == 11 then
				peripheral.call(pointer, "ejectDisk")
			elseif e[3] >= 5 and e[3] <= 10 and e[4] == 13 and peripheral.call(pointer, "hasAudio") then
				if isPlaying then
					peripheral.call(pointer, "stopAudio")
				else
					peripheral.call(pointer, "playAudio")
				end
				isPlaying = not isPlaying
				draw()
			elseif e[3] >= 5 and e[3] <= 15 and e[4] == 13 then
				term.setBackgroundColor(colors.lightGray)
				term.setTextColor(colors.white)
				local cenx = (w-10)/2
				local ceny = (h-4)/2
				term.setCursorPos(cenx,ceny)
				term.write("Set Label ")
				term.setCursorPos(cenx,ceny+1)
				term.write("          ")
				term.setCursorPos(cenx,ceny+2)
				term.write("          ")
				term.setCursorPos(cenx,ceny+3)
				term.write("          ")
				if label then
					for i = 1,label:len() do
						os.queueEvent("char", string.sub(label,i,i))
					end
				end
				term.setCursorPos(cenx+1,ceny+2)
				local input = read()
				if input == "" then
					input = nil
				end
				peripheral.call(pointer, "setDiskLabel", input)
				draw()
			elseif e[3] >= 5 and e[3] <= 21 and e[4] == 15 then
				clear()
				displaymenu = "copymove"
				if drawCopyMove() then
					displaymenu = "maindrive"
					draw()
				else
					clear()
					term.setTextColor(colors.red)
					term.setCursorPos(1,3)
					term.write("Peripheral removed!")
					sleep(3)
					RUNNING = false
					break
				end
			end
		elseif e[1] == "disk" then
			if e[2] == pointer then
				draw()
			else
				createNote(e[2], "Disk inserted")
			end
		elseif e[1] == "disk_eject" then
			if e[2] == pointer then
				draw()
				isPlaying = false
			else
				createNote(e[2], "Disk ejected")
			end
		elseif e[1] == "term_resize" then
			w,h = term.getSize()
			drawTopBar()
			draw()
		elseif e[1] == "peripheral" then
			scanPeripherals(e[2])
			createNote(e[2], "Attached")
		elseif e[1] == "peripheral_detach" then
			createNote(e[2], "Detached")
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

			if e[2] == pointer then
				clear()
				term.setTextColor(colors.red)
				term.setCursorPos(1,3)
				term.write("Peripheral removed!")
				sleep(3)
				break
			end
		elseif e[1] == "note_center" then
			drawTopBar()
		elseif e[1] == "monitor_resize" then
			local mw,mh = peripheral.call(e[2], "getSize")
			createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
		elseif e[1] == "monitor_touch" then
			createNote(e[2], "touched at "..e[3]..", "..e[4])
		elseif e[1] == "modem_message" then
			processMessage(e[2], e[3], e[4], e[5], e[6])
		elseif e[1] == "key" and e[2] == keys.q then
			pmang.RUNNING = false
			break
		end
	end
end




local function printerPeripheral(pointer)
	displaymenu = "mainprinter"
	local pagew, pageh = 25,21

	local function clear()
		term.setBackgroundColor(colors.white)
		term.clear()
		drawTopBar()
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
	end
	local function printFromFile()

		local msg = true
		local returnvalue = true
		local sourcepath = ""
		local canPrint = false
		local cenx = 0
		local printLines = {}

		local function readFile(path)
			local flines = {}
			for line in io.lines(path) do
				table.insert(flines, line)
			end
			return flines
		end

		local function calculatePrintJob()
			printLines = {}
			local flines = readFile(sourcepath)
			local plevel = peripheral.call(pointer, "getPaperLevel")
			local ilevel = peripheral.call(pointer, "getInkLevel")

			for line = 1,#flines do
				if flines[line]:len() > pagew then
					table.insert(printLines, string.sub(flines[line],1,pagew))
					for i = pagew+1,flines[line]:len(),pagew do
						table.insert(printLines, string.sub(flines[line],i,i+pagew))
					end
				else
					table.insert(printLines, flines[line])
				end
			end
			msg = true
			if #printLines > plevel*pageh then
				local excesslines = #printLines - (plevel*pageh)
				msg = math.ceil(excesslines/pageh).." extra pages required"
			elseif #printLines > ilevel*pageh then
				local excesslines = #printLines - (ilevel*pageh)
				msg = math.ceil(excesslines/pageh).." extra ink required"
			end
			return msg
		end

		local function printFile()
			clear()
			term.setTextColor(colors.black)
			term.setBackgroundColor(colors.white)
			term.setCursorPos(2,3)
			term.write("Printing...")

			peripheral.call(pointer, "newPage")
			peripheral.call(pointer, "setPageTitle", fs.getName(sourcepath).." #1")
			local currentline = 1
			local currentpage = 1
			for i = 1,#printLines do
				peripheral.call(pointer, "setCursorPos", 1, currentline)
				peripheral.call(pointer, "write", printLines[i])
				currentline = currentline+1
				if currentline > pageh and i < #printLines then
					currentline = 1
					if not peripheral.call(pointer, "endPage") then
						clear()
						term.setTextColor(colors.red)
						term.setBackgroundColor(colors.white)
						term.setCursorPos(2,3)
						print("Please remove printed pages to continue")
						while not peripheral.call(pointer, "endPage") do
							sleep(1)
						end
						clear()
						term.setTextColor(colors.black)
						term.setBackgroundColor(colors.white)
						term.setCursorPos(2,3)
						term.write("Printing...")
					end
					peripheral.call(pointer, "newPage")
					currentpage = currentpage+1
					peripheral.call(pointer, "setPageTitle", fs.getName(sourcepath).." #"..currentpage)
				end
			end
			peripheral.call(pointer, "endPage")
		end

		local function draw()
			clear()
			term.setBackgroundColor(colors.lightGray)
			term.setTextColor(colors.white)
			term.setCursorPos(1,2)
			term.write(" << Back ")

			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.black)
			term.setCursorPos((w-15)/2,4)
			term.write("Print from File")

			cenx = (w-19)/2

			term.setCursorPos(cenx,6)
			term.write("Source: "..sourcepath)

			term.setCursorPos(cenx,8)
			if msg == true then
				term.write("Status: OK")
			else
				term.write("Status: "..msg)
			end

			term.setBackgroundColor(colors.gray)
			term.setTextColor(colors.white)
			term.setCursorPos(cenx,10)
			term.write(" Refresh ")

			term.setCursorPos(cenx,12)
			term.write(" Browse ")

			if canPrint then
				term.setBackgroundColor(colors.lime)
			else
				term.setBackgroundColor(colors.red)
			end
			term.setCursorPos(cenx+12,12)
			term.write(" Print ")
		end
		draw()
		while true do
			local e = {os.pullEvent()}
			if e[1] == "mouse_click" and e[2] == 1 then
				if e[3] == w and e[4] == 1 then
					pmang.RUNNING = false
					break
				elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then
					break
				elseif e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
					displaymenu = "notecenter"
					drawNotes()
					displaymenu = "printfromfile"
					draw()
				elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then -- back button
					break
				elseif e[3] >= cenx and e[3] <= cenx+8 and e[4] == 10 then -- refresh button
					msg = calculatePrintJob()
					if msg == true then
						canPrint = true
					else
						canPrint = false
					end
					draw()
				elseif e[3] >= cenx and e[3] <= cenx+7 and e[4] == 12 then -- browse button
					sourcepath = explorerDialog(pointer)
					if sourcepath == "$$removed" then
						returnvalue = false
						break
					end
					msg = calculatePrintJob()
					if msg == true then
						canPrint = true
					else
						canPrint = false
					end
					draw()
				elseif e[3] >= cenx+12 and e[3] <= cenx+18 and e[4] == 12 and canPrint then -- print button
					printFile()
					break
				end
			elseif e[1] == "term_resize" then
				w,h = term.getSize()
				drawTopBar()
				draw()
			elseif e[1] == "peripheral" then
				scanPeripherals(e[2])
				createNote(e[2], "Attached")
			elseif e[1] == "peripheral_detach" then
				createNote(e[2], "Detached")
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

				if e[2] == pointer then
					returnvalue = false
					break
				end
			elseif e[1] == "note_center" then
				drawTopBar()
			elseif e[1] == "disk" then
				createNote(e[2], "Disk inserted")
			elseif e[1] == "disk_eject" then
				createNote(e[2], "Disk ejected")
			elseif e[1] == "monitor_resize" then
				local mw,mh = peripheral.call(e[2], "getSize")
				createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
			elseif e[1] == "monitor_touch" then
				createNote(e[2], "touched at "..e[3]..", "..e[4])
			elseif e[1] == "modem_message" then
				processMessage(e[2], e[3], e[4], e[5], e[6])
			elseif e[1] == "key" and e[2] == keys.q then
				pmang.RUNNING = false
				break
			end
		end
		return returnvalue
	end
	local function draw()
		clear()
		term.setBackgroundColor(colors.lightGray)
		term.setTextColor(colors.white)
		term.setCursorPos(1,2)
		term.write(" << Back ")

		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
		term.setCursorPos(3,4)
		term.write("Printer")
		drawPeri("printer",3,5)
		term.setBackgroundColor(colors.white)
		term.setCursorPos(10,6)
		term.write("Name: "..pointer)
		term.setCursorPos(10,7)
		term.write("Ink level: "..peripheral.call(pointer, "getInkLevel").."/64")
		term.setCursorPos(10,8)
		term.write("Paper level: "..peripheral.call(pointer, "getPaperLevel").."/384")
		term.setCursorPos(10,9)
		term.write("Paper size: 25x21")

		if peripheral.call(pointer, "getInkLevel") < 1 or peripheral.call(pointer, "getPaperLevel") < 1 then
			term.setBackgroundColor(colors.red)
		else
			term.setBackgroundColor(colors.gray)
		end
		term.setTextColor(colors.white)
		term.setCursorPos(5,11)
		term.write(" Print from File ")
	end
	draw()
	while true and pmang.RUNNING do
		local e = {os.pullEvent()}
		if e[1] == "mouse_click" and e[2] == 1 then
			if e[3] == w and e[4] == 1 then
				pmang.RUNNING = false
				break
			elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then
				break
			elseif e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
				displaymenu = "notecenter"
				drawNotes()
				displaymenu = "mainprinter"
				draw()
			elseif e[3] >= 5 and e[3] <= 21 and e[4] == 11 then
				if peripheral.call(pointer, "getInkLevel") > 0 and peripheral.call(pointer, "getPaperLevel") > 0 then
					displaymenu = "printfromfile"
					if printFromFile() then
						displaymenu = "mainprinter"
						draw()
					else
						clear()
						term.setTextColor(colors.red)
						term.setCursorPos(1,3)
						term.write("Peripheral removed!")
						sleep(3)
						break
					end
				else
					draw()
				end
			end
		elseif e[1] == "term_resize" then
			w,h = term.getSize()
			drawTopBar()
			draw()
		elseif e[1] == "peripheral" then
			scanPeripherals(e[2])
			createNote(e[2], "Attached")
		elseif e[1] == "peripheral_detach" then
			createNote(e[2], "Detached")
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

			if e[2] == pointer then
				clear()
				term.setTextColor(colors.red)
				term.setCursorPos(1,3)
				term.write("Peripheral removed!")
				sleep(3)
				break
			end
		elseif e[1] == "note_center" then
			drawTopBar()
		elseif e[1] == "disk" then
			createNote(e[2], "Disk inserted")
		elseif e[1] == "disk_eject" then
			createNote(e[2], "Disk ejected")
		elseif e[1] == "monitor_resize" then
			local mw,mh = peripheral.call(e[2], "getSize")
			createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
		elseif e[1] == "monitor_touch" then
			createNote(e[2], "touched at "..e[3]..", "..e[4])
		elseif e[1] == "modem_message" then
			processMessage(e[2], e[3], e[4], e[5], e[6])
		elseif e[1] == "key" and e[2] == keys.q then
			pmang.RUNNING = false
			break
		end
	end
end




local function monitorPeripheral(pointer)
	displaymenu = "mainmonitor"

	if peripheral.call(pointer, "isColor") then
		dispname = "Advanced Monitor"
		peritype = "amonitor"
	else
		dispname = "Monitor"
		peritype = "monitor"
	end

	local mw, mh = nil,nil

	local function clear()
		term.setBackgroundColor(colors.white)
		term.clear()
		drawTopBar()
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
	end
	local function runProgram()
		local returnvalue = true
		local sourcepath = ""
		local cenx = 0

		local function draw()
			clear()
			term.setBackgroundColor(colors.lightGray)
			term.setTextColor(colors.white)
			term.setCursorPos(1,2)
			term.write(" << Back ")

			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.black)
			term.setCursorPos((w-22)/2,3)
			term.write("Run Program on monitor")

			cenx = (w-17)/2

			term.setCursorPos(cenx,5)
			term.write("Source: "..sourcepath)

			term.setBackgroundColor(colors.gray)
			term.setTextColor(colors.white)
			term.setCursorPos(cenx,7)
			term.write(" Browse ")
			term.setCursorPos(cenx+11,7)
			term.write(" Run ")
		end
		draw()
		while true do
			local e = {os.pullEvent()}
			if e[1] == "mouse_click" and e[2] == 1 then
				if e[3] == w and e[4] == 1 then
					pmang.RUNNING = false
					break
				elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then -- back button
					break
				elseif e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
					displaymenu = "notecenter"
					drawNotes()
					displaymenu = "mainmonitor"
					draw()
				elseif e[3] >= cenx and e[3] <= cenx+7 and e[4] == 7 then -- browse button
					sourcepath = explorerDialog(pointer)
					if sourcepath == "$$removed" then
						returnvalue = false
						break
					end
					draw()
				elseif e[3] >= cenx+11 and e[3] <= cenx+15 and e[4] == 7 and sourcepath ~= "" then -- run button
					term.setBackgroundColor(colors.lightGray)
					term.setTextColor(colors.white)
					local cenx = (w-10)/2
					local ceny = (h-4)/2
					term.setCursorPos(cenx,ceny)
					term.write("Arguments ")
					term.setCursorPos(cenx,ceny+1)
					term.write("          ")
					term.setCursorPos(cenx,ceny+2)
					term.write("          ")
					term.setCursorPos(cenx,ceny+3)
					term.write("          ")

					term.setCursorPos(cenx+1, ceny+2)
					local input = read()
					shell.switchTab(shell.openTab("monitor", pointer, sourcepath, input))
					break
				end
			elseif e[1] == "term_resize" then
				w,h = term.getSize()
				drawTopBar()
				draw()
			elseif e[1] == "peripheral" then
				scanPeripherals(e[2])
				createNote(e[2], "Attached")
			elseif e[1] == "peripheral_detach" then
				createNote(e[2], "Detached")
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

				if e[2] == pointer then
					returnvalue = false
					break
				end
			elseif e[1] == "note_center" then
				drawTopBar()
			elseif e[1] == "disk" then
				createNote(e[2], "Disk inserted")
			elseif e[1] == "disk_eject" then
				createNote(e[2], "Disk ejected")
			elseif e[1] == "monitor_resize" then
				local mw,mh = peripheral.call(e[2], "getSize")
				createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
			elseif e[1] == "monitor_touch" then
				createNote(e[2], "touched at "..e[3]..", "..e[4])
			elseif e[1] == "modem_message" then
				processMessage(e[2], e[3], e[4], e[5], e[6])
			elseif e[1] == "key" and e[2] == keys.q then
				pmang.RUNNING = false
				break
			end
		end
		return returnvalue
	end
	local function draw()
		clear()
		term.setBackgroundColor(colors.lightGray)
		term.setTextColor(colors.white)
		term.setCursorPos(1,2)
		term.write(" << Back ")

		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
		term.setCursorPos(3,4)
		term.write(dispname)
		drawPeri(peritype,3,5)
		term.setBackgroundColor(colors.white)
		term.setCursorPos(10,6)
		term.write("Name: "..pointer)
		term.setCursorPos(10,7)
		mw,mh = peripheral.call(pointer, "getSize")
		term.write("Screen Size: "..mw.."x"..mh)

		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.white)
		term.setCursorPos(5,11)
		term.write(" Run program ")
	end
	draw()
	while true and pmang.RUNNING do
		local e = {os.pullEvent()}
		if e[1] == "mouse_click" and e[2] == 1 then
			if e[3] == w and e[4] == 1 then
				pmang.RUNNING = false
				break
			elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then -- back button
				break
			elseif e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
				displaymenu = "notecenter"
				drawNotes()
				displaymenu = "mainmonitor"
				draw()
			elseif e[3] >= 5 and e[3] <= 17 and e[4] == 11 then -- run program
				displaymenu = "runmonprogram"
				if not runProgram() then
					clear()
					term.setTextColor(colors.red)
					term.setCursorPos(1,3)
					term.write("Peripheral removed!")
					sleep(3)
					break
				else
					displaymenu = "mainmonitor"
					draw()
				end
			end
		elseif e[1] == "term_resize" then
			w,h = term.getSize()
			drawTopBar()
			draw()
		elseif e[1] == "peripheral" then
			scanPeripherals(e[2])
			createNote(e[2], "Attached")
		elseif e[1] == "peripheral_detach" then
			createNote(e[2], "Detached")
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

			if e[2] == pointer then
				clear()
				term.setTextColor(colors.red)
				term.setCursorPos(1,3)
				term.write("Peripheral removed!")
				sleep(3)
				break
			end
		elseif e[1] == "note_center" then
			drawTopBar()
		elseif e[1] == "disk" then
			createNote(e[2], "Disk inserted")
		elseif e[1] == "disk_eject" then
			createNote(e[2], "Disk ejected")
		elseif e[1] == "monitor_resize" then
			local mw,mh = peripheral.call(e[2], "getSize")
			createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
		elseif e[1] == "monitor_touch" then
			createNote(e[2], "touched at "..e[3]..", "..e[4])
		elseif e[1] == "modem_message" then
			processMessage(e[2], e[3], e[4], e[5], e[6])
		elseif e[1] == "key" and e[2] == keys.q then
			pmang.RUNNING = false
			break
		end
	end
end





local function modemPeripheral(pointer)
	displaymenu = "mainmodem"

	if peripheral.call(pointer, "isWireless") then
		dispname = "Wireless Modem"
		peritype = "wmodem"
	else
		dispname = "Wired Modem"
		peritype = "modem"
	end

	mchannels[pointer] = {}

	for i = 0,65535 do
		if peripheral.call(pointer, "isOpen", i) then
			table.insert(mchannels[pointer], i)
		end
	end

	local function sortNumbers(input)
		local terms = {}
		local range = {}
		if string.find(input, " ") then
			local termstart = 1
			for i = 1,input:len() do
				if string.sub(input,i,i) == " " then
					table.insert(terms, string.sub(input,termstart,i-1))
					termstart = i+1
				end
			end
		end
		for i = 1,#terms do
			if string.find(terms[i], "-") then -- range
				local ref = terms[i]
				for l = 1,ref:len() do
					if string.sub(ref,l,l) == "-" then
						local termstart = string.sub(ref,1,l-1)
						local termend = string.sub(ref,l+1,ref:len())
						if termend-termstart < 129 then
							for n = termstart,termend do
								table.insert(range,n)
							end
						end
					end
				end
			else
				table.insert(range, terms[i])
			end
		end
		return range
	end

	local function reverseSort(range)
		local terms = ""
		local termstart = range[1]
		local nextterm = termstart
		for i = 1,#range do
			nextterm = nextterm+1
			if range[i+1] ~= nextterm then
				if nextterm-termstart > 1 then
					terms = terms .. termstart.."-"..nextterm..","
				else
					terms = terms .. termstart..","
				end
				termstart = range[i+1]
			end
		end
		return terms
	end

	local function removeChannel(chan)
		peripheral.call(pointer, "close", tonumber(chan))
		for i = 1,#mchannels[pointer] do
			if tonumber(chan) == mchannels[pointer][i] then
				table.remove(mchannels[pointer], i)
				break
			end
		end
	end

	local function clear()
		term.setBackgroundColor(colors.white)
		term.clear()
		drawTopBar()
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
	end
	local function sendMessages()
		local returnvalue = true
		local cenx = 0
		local chan = mchannels[pointer][1] or 1
		local repchan = mchannels[pointer][1] or 1
		local message = ""

		local function draw()
			clear()
			term.setBackgroundColor(colors.lightGray)
			term.setTextColor(colors.white)
			term.setCursorPos(1,2)
			term.write(" << Back ")

			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.black)
			term.setCursorPos((w-13)/2,3)
			term.write("Send Messages")

			term.setCursorPos(15,5)
			term.write("Channel: "..chan)

			term.setCursorPos(15,7)
			term.write("Reply Channel: "..repchan)

			term.setCursorPos(15,9)
			term.write("Message: "..message)

			term.setBackgroundColor(colors.gray)
			term.setTextColor(colors.white)
			term.setCursorPos(9,5)
			term.write(" Set ")
			term.setCursorPos(9,7)
			term.write(" Set ")
			term.setCursorPos(9,9)
			term.write(" Set ")

			cenx = (w-6)/2
			term.setCursorPos(cenx,11)
			term.write(" Send ")
		end
		draw()
		while true do
			local e = {os.pullEvent()}
			if e[1] == "mouse_click" and e[2] == 1 then
				if e[3] == w and e[4] == 1 then
					pmang.RUNNING = false
					break
				elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then
					break
				elseif e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
					displaymenu = "notecenter"
					drawNotes()
					displaymenu = "mainmonitor"
					draw()
				elseif e[3] >= 9 and e[3] <= 13 then
					if e[4] == 5 then -- set channel
						term.setBackgroundColor(colors.lightGray)
						term.setTextColor(colors.white)
						local cenx = (w-10)/2
						local ceny = (h-4)/2
						term.setCursorPos(cenx,ceny)
						term.write("Channel   ")
						term.setCursorPos(cenx,ceny+1)
						term.write("          ")
						term.setCursorPos(cenx,ceny+2)
						term.write("          ")
						term.setCursorPos(cenx,ceny+3)
						term.write("          ")

						term.setCursorPos(cenx+1,ceny+2)
						local input = read()
						if tonumber(input) then
							chan = tonumber(input)
						end
						draw()
					elseif e[4] == 7 then -- set reply channel
						term.setBackgroundColor(colors.lightGray)
						term.setTextColor(colors.white)
						local cenx = (w-10)/2
						local ceny = (h-4)/2
						term.setCursorPos(cenx,ceny)
						term.write("Reply     ")
						term.setCursorPos(cenx,ceny+1)
						term.write("          ")
						term.setCursorPos(cenx,ceny+2)
						term.write("          ")
						term.setCursorPos(cenx,ceny+3)
						term.write("          ")

						term.setCursorPos(cenx+1,ceny+2)
						local input = read()
						if tonumber(input) then
							repchan = tonumber(input)
						end
						draw()
					elseif e[4] == 9 then -- set message
						term.setBackgroundColor(colors.lightGray)
						term.setTextColor(colors.white)
						local cenx = (w-10)/2
						local ceny = (h-4)/2
						term.setCursorPos(cenx,ceny)
						term.write("Message   ")
						term.setCursorPos(cenx,ceny+1)
						term.write("          ")
						term.setCursorPos(cenx,ceny+2)
						term.write("          ")
						term.setCursorPos(cenx,ceny+3)
						term.write("          ")

						term.setCursorPos(cenx+1,ceny+2)
						message = read()
						draw()
					end
				elseif e[3] >= cenx and e[3] <= cenx+5 and e[4] == 11 then -- send
					peripheral.call(pointer, "transmit", chan, repchan, message)
					break
				end
			elseif e[1] == "term_resize" then
				w,h = term.getSize()
				drawTopBar()
				draw()
			elseif e[1] == "peripheral" then
				scanPeripherals(e[2])
				createNote(e[2], "Attached")
			elseif e[1] == "peripheral_detach" then
				createNote(e[2], "Detached")
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

				if e[2] == pointer then
					returnvalue = false
					break
				end
			elseif e[1] == "note_center" then
				drawTopBar()
			elseif e[1] == "disk" then
				createNote(e[2], "Disk inserted")
			elseif e[1] == "disk_eject" then
				createNote(e[2], "Disk ejected")
			elseif e[1] == "monitor_resize" then
				local mw,mh = peripheral.call(e[2], "getSize")
				createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
			elseif e[1] == "monitor_touch" then
				createNote(e[2], "touched at "..e[3]..", "..e[4])
			elseif e[1] == "modem_message" then
				processMessage(e[2], e[3], e[4], e[5], e[6])
			elseif e[1] == "key" and e[2] == keys.q then
				pmang.RUNNING = false
				break
			end
		end

		return returnvalue
	end
	local function draw()
		clear()
		term.setBackgroundColor(colors.lightGray)
		term.setTextColor(colors.white)
		term.setCursorPos(1,2)
		term.write(" << Back ")

		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
		term.setCursorPos(3,4)
		term.write(dispname)
		drawPeri(peritype,3,5)
		term.setBackgroundColor(colors.white)
		term.setCursorPos(10,6)
		term.write("Name: "..pointer)
		term.setCursorPos(10,7)
		term.write("Open Channels: ")
		term.setCursorPos(10,8)
		-- term.write(reverseSort(channels))
		for i = 1,#mchannels[pointer] do
			term.write(mchannels[pointer][i]..",")
		end

		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.white)
		term.setCursorPos(5,11)
		term.write(" Open channel ")
		term.setCursorPos(5,13)
		term.write(" Close channel ")
		term.setCursorPos(5,15)
		term.write(" Close all ")
		term.setCursorPos(5,17)
		term.write(" Send ")
	end
	draw()
	while true and pmang.RUNNING do
		local e = {os.pullEvent()}
		if e[1] == "mouse_click" and e[2] == 1 then
			if e[3] == w and e[4] == 1 then
				pmang.RUNNING = false
				break
			elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then
				break
			elseif e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
				displaymenu = "notecenter"
				drawNotes()
				displaymenu = "mainmonitor"
				draw()
			elseif e[3] >= 5 and e[3] <= 18 and e[4] == 11 then -- open channel
				term.setBackgroundColor(colors.lightGray)
				term.setTextColor(colors.white)
				local cenx = (w-10)/2
				local ceny = (h-4)/2
				term.setCursorPos(cenx,ceny)
				term.write("Open      ")
				term.setCursorPos(cenx,ceny+1)
				term.write("          ")
				term.setCursorPos(cenx,ceny+2)
				term.write("          ")
				term.setCursorPos(cenx,ceny+3)
				term.write("          ")

				term.setCursorPos(cenx+1,ceny+2)
				local input = read()
				if input ~= "" then
					--[[if string.find(input, "-") or string.find(input, " ") then
						local newchannels = sortNumbers(input)
						for i = 1,#newchannels do
							if not peripheral.call(pointer, "isOpen", newchannels[i]) then
								peripheral.call(pointer, "open", newchannels[i])
							end
						end
					else]]--
						if tonumber(input) then
							peripheral.call(pointer, "open", tonumber(input))
							table.insert(mchannels[pointer], tonumber(input))
						end
					--end
				end
				draw()
			elseif e[3] >= 5 and e[3] <= 19 and e[4] == 13 then -- close channel
				term.setBackgroundColor(colors.lightGray)
				term.setTextColor(colors.white)
				local cenx = (w-10)/2
				local ceny = (h-4)/2
				term.setCursorPos(cenx,ceny)
				term.write("Close     ")
				term.setCursorPos(cenx,ceny+1)
				term.write("          ")
				term.setCursorPos(cenx,ceny+2)
				term.write("          ")
				term.setCursorPos(cenx,ceny+3)
				term.write("          ")

				term.setCursorPos(cenx+1,ceny+2)
				local input = read()
				if input ~= "" then
					--[[if string.find(input, "-") or string.find(input, " ") then
						local newchannels = sortNumbers(input)
						for i = 1,#newchannels do
							peripheral.call(pointer, "close", newchannels[i])
						end
					else]]--
						if tonumber(input) then removeChannel(input) end
					--end
				end
				draw()
			elseif e[3] >= 5 and e[3] <= 15 and e[4] == 15 then -- close all
				peripheral.call(pointer, "closeAll")
				mchannels[pointer] = {}
				draw()
			elseif e[3] >= 5 and e[3] <= 11 and e[4] == 17 then -- send
				displaymenu = "modemsend"
				if not sendMessages() then
					clear()
					term.setTextColor(colors.red)
					term.setCursorPos(1,3)
					term.write("Peripheral removed!")
					mchannels[pointer] = {}
					sleep(3)
					break
				else
					displaymenu = "mainmodem"
					draw()
				end
			end
		elseif e[1] == "term_resize" then
			w,h = term.getSize()
			drawTopBar()
			draw()
		elseif e[1] == "peripheral" then
			scanPeripherals(e[2])
			createNote(e[2], "Attached")
		elseif e[1] == "peripheral_detach" then
			createNote(e[2], "Detached")
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

			if e[2] == pointer then
				clear()
				term.setTextColor(colors.red)
				term.setCursorPos(1,3)
				term.write("Peripheral removed!")
				mchannels[pointer] = {}
				sleep(3)
				break
			end
		elseif e[1] == "note_center" then
			drawTopBar()
		elseif e[1] == "disk" then
			createNote(e[2], "Disk inserted")
		elseif e[1] == "disk_eject" then
			createNote(e[2], "Disk ejected")
		elseif e[1] == "monitor_resize" then
			local mw,mh = peripheral.call(e[2], "getSize")
			createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
		elseif e[1] == "monitor_touch" then
			createNote(e[2], "touched at "..e[3]..", "..e[4])
		elseif e[1] == "modem_message" then
			processMessage(e[2], e[3], e[4], e[5], e[6])
		elseif e[1] == "key" and e[2] == keys.q then
			pmang.RUNNING = false
			break
		end
	end
end





local function computerPeripheral(pointer)
	displaymenu = "maincomputer"
	local status = peripheral.call(pointer, "isOn")
	local function clear()
		term.setBackgroundColor(colors.white)
		term.clear()
		drawTopBar()
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
	end
	local function draw()
		clear()
		term.setBackgroundColor(colors.lightGray)
		term.setTextColor(colors.white)
		term.setCursorPos(1,2)
		term.write(" << Back ")

		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
		term.setCursorPos(3,4)
		term.write("Computer")
		drawPeri("computer",3,5)

		term.setBackgroundColor(colors.white)
		term.setCursorPos(10,6)
		term.write("Name: "..pointer)
		term.setCursorPos(10,7)
		term.write("ID: "..peripheral.call(pointer, "getID"))

		term.setCursorPos(10,8)
		term.write("Status: ")
		status = peripheral.call(pointer, "isOn")
		if status then
			term.setTextColor(colors.lime)
			term.write("Online")
		else
			term.setTextColor(colors.lightGray)
			term.write("Offline")
		end

		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.white)
		term.setCursorPos(5,11)
		term.write(" Refresh ")
		term.setCursorPos(5,13)
		if status then
			term.write(" Shutdown ")
			term.setCursorPos(5,15)
			term.write(" Reboot ")
		else
			term.write(" Turn On ")
		end
	end
	draw()
	while true do
		local e = {os.pullEvent()}
		if e[1] == "mouse_click" and e[2] == 1 then
			if e[3] == w and e[4] == 1 then
				pmang.RUNNING = false
				break
			elseif e[3] >= 1 and e[3] <= 9 and e[4] == 2 then -- back button
				break
			elseif e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then -- NOTE CENTER HANDLER
				displaymenu = "notecenter"
				drawNotes()
				displaymenu = "mainmonitor"
				draw()
			elseif e[3] >= 5 and e[3] <= 13 and e[4] == 11 then -- refresh button
				status = peripheral.call(pointer, "isOn")
				draw()
			else
				if status then
					if e[3] >= 5 and e[3] <= 14 and e[4] == 13 then -- shutdown button
						peripheral.call(pointer, "shutdown")
						-- status = false
						draw()
					elseif e[3] >= 5 and e[3] <= 12 and e[4] == 15 then -- reboot button
						peripheral.call(pointer, "reboot")
					end
				else
					if e[3] >= 5 and e[3] <= 13 and e[4] == 13 then -- turn on button
						peripheral.call(pointer, "turnOn")
						sleep(0.1)
						-- status = true
						draw()
					end
				end
			end
		elseif e[1] == "term_resize" then
			w,h = term.getSize()
			drawTopBar()
			draw()
		elseif e[1] == "peripheral" then
			scanPeripherals(e[2])
			createNote(e[2], "Attached")
		elseif e[1] == "peripheral_detach" then
			createNote(e[2], "Detached")
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

			if e[2] == pointer then
				clear()
				term.setTextColor(colors.red)
				term.setCursorPos(1,3)
				term.write("Peripheral removed!")
				sleep(3)
				break
			end
		elseif e[1] == "note_center" then
			drawTopBar()
		elseif e[1] == "disk" then
			createNote(e[2], "Disk inserted")
		elseif e[1] == "disk_eject" then
			createNote(e[2], "Disk ejected")
		elseif e[1] == "monitor_resize" then
			local mw,mh = peripheral.call(e[2], "getSize")
			createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
		elseif e[1] == "monitor_touch" then
			createNote(e[2], "touched at "..e[3]..", "..e[4])
		elseif e[1] == "modem_message" then
			processMessage(e[2], e[3], e[4], e[5], e[6])
		elseif e[1] == "key" and e[2] == keys.q then
			pmang.RUNNING = false
			break
		end
	end
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
		elseif ref == "computer" then
			computerPeripheral(pointer)
		end
	else
		local undscrpos = string.find(pointer, "_")
		local ref = string.sub(pointer, 1, undscrpos-1)
		if ref == "drive" then
			drivePeripheral(pointer)
		elseif ref == "printer" then
			printerPeripheral(pointer)
		elseif ref == "monitor" then
			monitorPeripheral(pointer)
		elseif ref == "modem" then
			modemPeripheral(pointer)
		elseif ref == "computer" then
			computerPeripheral(pointer)
		end
	end
end






-- Main menu
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
					elseif ref == "computer" then dispname = "Computer"
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
		local RUNNING = true
		local function clear()
			term.setBackgroundColor(colors.white)
			term.clear()
			drawTopBar()
			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.black)
		end
		local function draw()
			clear()
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
		while RUNNING and pmang.RUNNING do -- MAINALL handler
			local e = {os.pullEvent()}
			if e[1] == "term_resize" then
				w,h = term.getSize()
				drawScreen()
			elseif e[1] == "peripheral" then
				scanPeripherals(e[2])
				createNote(e[2], "Attached")
				draw()
			elseif e[1] == "peripheral_detach" then
				createNote(e[2], "Detached")
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
				drawTopBar()
			elseif e[1] == "disk" then
				createNote(e[2], "Disk inserted")
			elseif e[1] == "disk_eject" then
				createNote(e[2], "Disk ejected")
			elseif e[1] == "monitor_resize" then
				local mw,mh = peripheral.call(e[2], "getSize")
				createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
			elseif e[1] == "monitor_touch" then
				createNote(e[2], "touched at "..e[3]..", "..e[4])
			elseif e[1] == "modem_message" then
				processMessage(e[2], e[3], e[4], e[5], e[6])
			elseif e[1] == "key" and e[2] == keys.q then
				pmang.RUNNING = false
				break
			elseif e[1] == "mouse_scroll" then
				if e[2] == 1 and scrollpos < pospossible then
					scrollpos = scrollpos+1
				elseif e[2] == -1 and scrollpos > 1 then
					scrollpos = scrollpos-1
				end
				draw()
			elseif e[1] == "mouse_click" and e[2] == 1 then
				if e[3] == w and e[4] == 1 then
					pmang.RUNNING = false
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
								redirectToType(data[pos])
							end
							displaymenu = "mainall"
							draw()
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
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
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
	while true and pmang.RUNNING do -- NOTE CENTER LOOP
		local e = {os.pullEvent()}
		if e[1] == "term_resize" then
			w,h = term.getSize()
			drawScreen()
		elseif e[1] == "peripheral" then
			scanPeripherals(e[2])
			createNote(e[2], "Attached")
		elseif e[1] == "peripheral_detach" then
			createNote(e[2], "Detached")
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
			drawTopBar()
			pospossible = #notemsgs-(h-4)
			if pospossible < 1 then pospossible = 1 end
			scrollpos = pospossible
			draw()
		elseif e[1] == "disk" then
			createNote(e[2], "Disk inserted")
		elseif e[1] == "disk_eject" then
			createNote(e[2], "Disk ejected")
		elseif e[1] == "monitor_resize" then
			local mw,mh = peripheral.call(e[2], "getSize")
			createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
		elseif e[1] == "monitor_touch" then
			createNote(e[2], "touched at "..e[3]..", "..e[4])
		elseif e[1] == "modem_message" then
			processMessage(e[2], e[3], e[4], e[5], e[6])
		elseif e[1] == "key" and e[2] == keys.q then
			pmang.RUNNING = false
			break
		elseif e[1] == "mouse_click" and e[2] == 1 then
			if e[3] >= noteiconxpos and e[3] <= noteiconxpos+2 and e[4] == 1 then
				drawScreen()
				break
			elseif e[3] == w and e[4] == 1 then
				pmang.RUNNING = false
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
	while pmang.RUNNING do
		local e = {os.pullEvent()}
		if e[1] == "term_resize" then
			w,h = term.getSize()
			drawScreen()
		elseif e[1] == "peripheral" then
			createNote(e[2], "Attached")
			scanPeripherals(e[2])
			drawScreen()
		elseif e[1] == "peripheral_detach" then
			createNote(e[2], "Detached")
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
			drawTopBar()
		elseif e[1] == "disk" then
			createNote(e[2], "Disk inserted")
		elseif e[1] == "disk_eject" then
			createNote(e[2], "Disk ejected")
		elseif e[1] == "monitor_resize" then
			local mw,mh = peripheral.call(e[2], "getSize")
			createNote(e[2], "Monitor size changed to "..mw.."x"..mh)
		elseif e[1] == "monitor_touch" then
			createNote(e[2], "touched at "..e[3]..", "..e[4])
		elseif e[1] == "modem_message" then
			processMessage(e[2], e[3], e[4], e[5], e[6])
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
					displaymenu = "main"
					drawScreen()
				elseif e[3] >= boxes.bottom.x and e[3] <= boxes.bottom.x+10 and e[4] >= boxes.bottom.y and e[4] <= boxes.bottom.y+6 then -- BOTTOM
					redirectToType("bottom", true)
					displaymenu = "main"
					drawScreen()
				elseif e[3] >= boxes.front.x and e[3] <= boxes.front.x+10 and e[4] >= boxes.front.y and e[4] <= boxes.front.y+6 then -- FRONT
					redirectToType("front", true)
					displaymenu = "main"
					drawScreen()
				elseif e[3] >= boxes.left.x and e[3] <= boxes.left.x+10 and e[4] >= boxes.left.y and e[4] <= boxes.left.y+6 then -- LEFT
					redirectToType("left", true)
					displaymenu = "main"
					drawScreen()
				elseif e[3] >= boxes.right.x and e[3] <= boxes.right.x+10 and e[4] >= boxes.right.y and e[4] <= boxes.right.y+6 then -- RIGHT
					redirectToType("right", true)
					displaymenu = "main"
					drawScreen()
				elseif e[3] >= boxes.back.x and e[3] <= boxes.back.x+10 and e[4] >= boxes.back.y and e[4] <= boxes.back.y+6 then -- BACK
					redirectToType("back", true)
					displaymenu = "main"
					drawScreen()
				end
			end
		elseif e[1] == "key" and e[2] == keys.q then break
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
