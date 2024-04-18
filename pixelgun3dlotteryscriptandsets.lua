lasttoast = 0 
function progressalert(message,override)
	if os.time() - lasttoast > 1 or override then
		lasttoast = os.time()
		gg.toast(message)
	end
end

function contains(item,list)
	--Not type-sensitive
	for index = 1, #list do
		if tostring(list[index]) == tostring(item) then
			return(true)
		end
	end
	return(false)
end

function generatedecimalconversionstring(choices)
	-- [[ Tool for development purposes, not used in the real script ]] --
	-- Generate 32bit
	print("32bit: Not supported. Use this python code in All Updates Script Generator python tool:" ..
			"\nconversionstring = \"{\"\nfor value in [" .. table.concat(choices, ",") ..
			"]:\n\tconversionstring += f'\\n\\t\\\"{getdecimalvaluesfromhex(armtohex(f\"mov r0, #{value}; bx lr\"," .."\"32bit\"))[0][\"Value\"]}\\\",'\n" ..
			"conversionstring = conversionstring[:-1] + \"}\"\nprint(conversionstring)\n\n\n")
	
	-- Generate 64bit
	is64bit = true
	decimalconversionstring = "{"
	for choiceindex = 1, #choices do
		decimalconversionstring = decimalconversionstring .. "\n\t\"" .. hextodecimal(armtohex(generateassemblycode(choices[choiceindex])), true) .. "\","
	end
	decimalconversionstring = decimalconversionstring .. "\n\t}"
	print("64bit: " .. decimalconversionstring)
	os.exit()
end

		

function indexof(item,list)
	--Not type-sensitive
	for index = 1, #list do
		if tostring(list[index]) == tostring(item) then
			return(index)
		end
	end
	return(nil)
end

function int(number)
	number = tostring(tonumber(number))
	decimalpointindex = string.find(number,"%.")
	if decimalpointindex ~= nil then
		--If there is a decimal point, remove the decimal point and everything after it
		number = string.sub(number,1,decimalpointindex - 1)
	end
	return(tonumber(number))
end
	
function tryrestore(original)
	progressalert("Detecting if script has been run before in this game session",true)
	listitems = gg.getListItems()
	found = false
	for i = 1, #listitems do
		if listitems[i].name == "LottoSetsRestore (Don\'t Delete)" and listitems[i].value ~= original then -- all special characters in names in this table are backslashed - idk if this is done by gameguardian itself or it's lua backend (probably gameguardian's lua backend, but no need to go in-depth), but this causes the '\' to be backslashed when you load the name of a value in your script
			found = true
			progressalert("Detected that script has been run before in this game session - reverting changes",true)
			listitems[i].value = original
		end
	end
	if found then
		gg.setValues(listitems)
		gg.clearResults()
		gg.clearList()
		gg.addListItems(listitems)
	end
	return(found)
end

function findbestsearch(searches,refine)
	searchfound = false
	bestsearch = 0
	bestsearchresultscount = 9999999999999999999999
	bestsearchresults = {}
	for i = 1, #searches do
		progressalert("Searching",false)
		thissearch = searches[i]
		gg.clearResults()
		gg.searchNumber(thissearch,gg.TYPE_AUTO)
		gg.refineNumber(refine,gg.TYPE_AUTO)
		resultscount = gg.getResultsCount()
		--[[
		--For testing
		if resultscount == 0 then
		gg.alert("Note to author (remove this code later): Search " .. search .. " not found")
		end
		--]]
		if resultscount > 0 then
			if not(searchfound) or resultscount < bestsearchresultscount then
				bestsearch = thissearch
				bestsearchresults = gg.getResults(resultscount)
				bestsearchresultscount = resultscount
				searchfound = true
				if resultscount == 1 then
					break
				end
			end
		end
	end
	if searchfound then
		progressalert("Found!",true)
		gg.loadResults(bestsearchresults)
		return(bestsearchresults)
	else
		progressalert("Nothing found",true)
		print("Error: Nothing found. Make sure you are fully loaded into the game, and you have not used any other lottery / set event scripts in this game session.\nIf you are fully loaded in and you have not used any lottery / set event scripts this game session, the script must have been patched. Please contact User123456789#6424 on discord so I can fix it.")
		gg.setVisible(true)
		os.exit()
	end
end

function getis64bit()
	progressalert("Detecting device architecture",true)
	return(gg.getTargetInfo().x64)
end

function chooseedit(choices)
	if is64bit then
		hascustom = true
	else
		-- Disable custom for 32bit - does not work :(
		hascustom = false
	end
	--If choices is not specified, it defaults to {"0", "300","1000","10000","25000","40000","45000"}
	choices = choices or {"0", "300","1000","10000","25000","40000","45000"}
	if hascustom then
		table.insert(choices,1,"Custom")
	end
	editchoice = gg.choice(choices,nil,"What would you like to change the quantities of all lottery and set event rewards to?\n\nNotice: Changing the rewards to a number over 45k and receiving a reward will instantly ban you!")
	if editchoice == nil then
		--User Clicked Cancel
		os.exit()
	else
		if hascustom and editchoice == 1 then
			--Custom
			editvalueprompt = gg.prompt({"What integer value would you like to edit the quantities of all lottery and set event rewards to (the maximum value is 65536)?\n\nNotice: Changing the rewards to a number over 45k and receiving a reward will instantly ban you!"},{[1] = 45000},{[1] = 'number'})
			if editvalueprompt == nil then
				--User Clicked Cancel
				os.exit()
			else
				choseneditvalue = editvalueprompt[1]
			end
		else
			choseneditvalue = choices[editchoice]
		end
	end
		choseneditvalue = int(choseneditvalue)
		if is64bit then
			--armv8 (64bit)
			if choseneditvalue > 65536 then
				gg.alert("The maximum value is 65536! Setting to 65536.")
				choseneditvalue = 65536
			end
			--[[if choseneditvalue < -65536 then
				gg.alert("The minimum value is -65536! Setting to -65536.")
				choseneditvalue = -65536
			end--]]
			if choseneditvalue < 0 then
				gg.alert("Sorry, but negative numbers are not supported. Setting to 0.")
				choseneditvalue = 0
			end
		else
			--armv7 (32bit)
			if choseneditvalue > 65536 then
				gg.alert("The maximum value is 65536! Setting to 65536.")
				choseneditvalue = 65536
			end
			if choseneditvalue < 0 then
				gg.alert("Sorry, but negative numbers are not supported. Setting to 0.")
				choseneditvalue = 0
			end
		end
		if choseneditvalue > 45000 then
			confirm = gg.choice({"Uh-oh, set it to 45k","Keep it at " .. choseneditvalue .. " (Dangerous)"},nil,"WARNING:\nAre you sure you want to set the quantity to over 45k? If you do this and receive any reward from the lottery or set event, you will be instantly banned.")
			if confirm == nil or confirm == 1 then
				--User clicked cancel or "Uh-oh, set it to 45k"
				choseneditvalue = 45000
			end
		end
	return(choseneditvalue)
end

function generateassemblycode(returnvalue)
	progressalert("Converting edit value",false)
	if is64bit then
		--Armv8 (64bit)
		code = "Mov W0, #" .. returnvalue .. "\nRet"
	else
		--Armv7 (32bit)
		code = "Mov R0, #" .. returnvalue .. "\nBX LR"
	end
	return(code)
end

function armtohex(fullarm)
	progressalert("Converting edit value",false)
	fullhex = ""
	--Thanks to Enyby for the original arm hex converter I used code from:
	-- https://gameguardian.net/forum/files/file/2004-arm-converter/
	for arm in string.gmatch(fullarm,'[^\r\n]+') do 
		progressalert("Converting edit value",false)
		local addr = gg.getRangesList('libc.so')
		for i, v in ipairs(addr) do
			if v.type:sub(2,2) == 'w' then
				addr = {{address = v.start, flags = gg.TYPE_DWORD}}
			end
		end
		if not addr[1].address then
			print("Error occured converting arm code to hex: Failed to get address ", addr)
			gg.setVisible(true)
			os.exit()
		end
		if is64bit then
			--Armv8 (64bit)
			local old = gg.getValues(addr)
			addr[1].value = '~A8 '..arm
			local ok, err = pcall(gg.setValues, addr)
			local out
			if not ok then
				err = err:gsub("^.* '1': ", ''):gsub('\nlevel = 1.*$', '')
				print("Error occured converting arm code to hex: " .. err)
				gg.setVisible(true)
				os.exit()
			else
				out = gg.getValues(addr)
				out = out[1].value & 0xFFFFFFFF
				gg.setValues(old)
				if not hex then
					out = string.unpack('>I4', string.pack('<I4', out))
				end
				out = string.format('%08X', out)
				fullhex = fullhex .. out
			end
		else
			--Armv7 (32bit)
			local old = gg.getValues(addr)
			addr[1].value = '~A '..arm
			local ok, err = pcall(gg.setValues, addr)
			local out
			--For some reason, it says it fails to recognize 32bit opcodes, even though it works fine if we ignore the error
			--if not ok then
			if false then
				err = err:gsub("^.* '1': ", ''):gsub('\nlevel = 1.*$', '')
				print("Error occured converting arm code to hex: " .. err)
				gg.setVisible(true)
				os.exit()
			else
				out = gg.getValues(addr)
				out = out[1].value & 0xFFFFFFFF
				gg.setValues(old)
				if not hex then
					out = string.unpack('>I4', string.pack('<I4', out))
				end
				out = string.format('%08X', out)
				fullhex = fullhex .. out
			end
		end
	end
	return(fullhex)
end

function hextodecimal(hex,bigendian)
	-- [[ WARNING: This function does not work for values that exceed lua's integer limit. ]]
	progressalert("Converting edit value",false)

	originalhex = hex
	-- Pre-formatting: Remove spaces, remove 0x prefix if present, and make it uppercase
	hex = tostring(hex):gsub(" ",""):gsub("0x",""):upper()
	if #hex % 2 ~= 0 then
		print("Error occured converting hex to decimal: Invalid hex -" .. originalhex)
		gg.setVisible(true)
		os.exit()
	end

	if bigendian then
		--Reverse bytes (ex: A1B2 -> B2A1)
		newhex = ""
		byte = ""
		for i = 1, #hex do
			byte = byte .. hex:sub(i,i)
			if #byte == 2 then
				newhex = byte .. newhex
				byte = ""
			end
		end
		hex = newhex
	end

	if not(string.sub(hex,1,2) == "0x") then
		hex = "0x" .. hex
	end
	return tonumber(hex)
end

function generateeditvalue(realeditnumber)
	progressalert("Converting edit value",true)
	knowneditvalues = {"0", "300", "1000","10000","25000","40000","45000"}
	editvalueconversion64bit = {
	"-2999674702252736512",
	"-2999674702252726912",
	"-2999674702252704512",
	"-2999674702252416512",
	"-2999674702251936512",
	"-2999674702251456512",
	"-2999674702251296512",
	}
	editvalueconversion32bit = {
	"16226468490572201984",
	"16226468490572205899",
	"16226468490572206074",
	"16226468490561849104",
	"16226468490562109864",
	"16226468490562309184",
	"16226468490562375624"
	}
	if contains(realeditnumber,knowneditvalues) then
		if is64bit then
			--armv8 (64bit)
			editvalue = editvalueconversion64bit[indexof(realeditnumber,knowneditvalues)]
		else
			--armv7 (32bit)
			editvalue = editvalueconversion32bit[indexof(realeditnumber,knowneditvalues)]
			end
	else
		--[[
		Algorithm:
		1. Generate arm (assembly) code
		2. Convert arm code to hex
		3. Convert hex to decimal
		--]]
		editvalue = hextodecimal(armtohex(generateassemblycode(realeditnumber)), true)
	end
	return(editvalue)
end

--generatedecimalconversionstring({"0", "300","1000","10000","25000","40000","45000"}) -- Development purposes

gg.setVisible(false)
--Get whether the script is being run on an armv7 (32bit) or armv8 (64bit) device
is64bit = getis64bit()
if is64bit then
	progressalert("armv8 (64bit) device detected",true)
else
	progressalert("armv7 (32bit) device detected",true)
end
gg.alert("Pixel Gun 3D Lottery / Set Event Rewards Hacker by HorridModz (User123456789#6424 / @horridmodz) UPDATED 24.3.2+. This script should work on both 32bit and 64bit devices, and it should work in future game updates.")
gg.alert("DISCLAIMER:\nThis script may be bannable! I advise only opening a few thousand gems worth of chests a day, or your account has a high chance of being banned. USE AT YOUR OWN RISK.")
if not is64bit then
	-- 32bit does not work because of a weird issue that has to do with how lua handles numbers (sounds crazy, right? it is)
	gg.alert("32bit support has finally been added, but unfortunately, the custom option is unavailable. Sorry!")
end

gg.setRanges(gg.REGION_CODE_APP)
editrealnumber = tonumber(chooseedit())
progressalert("Attempting to set lottery and set event rewards to " .. editrealnumber,true)
edit = generateeditvalue(editrealnumber)
if is64bit then
	searches = {"2853372916D;3035148941626901472Q;12255424750771241633Q;12249795255531995778Q;4177527807D;4181722089D;17960358344757609460Q;12249795337136374465Q::489"}
	refine = "2853372916"
	offset = 76
else
	searches = {"16258082636822317104Q;16541774211741212672Q;17609086430978535437Q;17601873635012774601Q;17600114416408611535Q;4100393673D;17610282699944569551Q;17600079232038759119Q::489"}
	refine = "16258082636822317104"
	offset = 92
end
if tryrestore(refine) then
	progressalert("Detected that script has been run before in this game session - changes reverted",true)
end
progressalert("Searching",true)
findbestsearch(searches,refine)
progressalert("Editing to " .. editrealnumber .. "!",true)
results = gg.getResults(gg.getResultsCount())
for i = 1, #results do
    results[i].address = results[i].address - offset
    results[i].name = "LottoSetsRestore (Don't Delete)"
    results[i].flags = gg.TYPE_QWORD
end
gg.loadResults(results)
results = gg.getResults(gg.getResultsCount())
gg.editAll(edit, gg.TYPE_QWORD)
gg.addListItems(results)
gg.clearResults()
progressalert("Successfully edited to " .. editrealnumber .. "!",true)
gg.alert("The quantities of all lottery and set event rewards have been changed to " .. editrealnumber .. ". Enjoy!\nIf you would like to set the rewards back to normal, restart the game.\nDISCLAIMER:\nThis script may be bannable! I advise only opening a few thousand gems worth of chests a day, or your account has a high chance of being banned.")
print("The quantities of all lottery and set event rewards have been changed to " .. editrealnumber .. ". Enjoy!\nIf you would like to set the rewards back to normal, restart the game.\nDISCLAIMER:\nThis script may be bannable! I advise only opening a few thousand gems worth of chests a day, or your account has a high chance of being banned.")
print("\nSummary:")
if is64bit then
	print("Device Architecture Detected:\t armv8 (64bit)")
else
	print("Device Architecture Detected:\t armv7 (32bit)")
end
print("Search Used:\t" .. bestsearch)
print("Edit Value:\t" .. editrealnumber)
print("Converted edit value:\t" .. edit)
