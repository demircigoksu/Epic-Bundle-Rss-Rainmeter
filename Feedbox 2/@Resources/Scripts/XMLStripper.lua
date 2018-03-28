entities = {["&amp;"] = "&",["&lt;"] = "<",["&gt;"] = ">",["&amp;"] = "&",["&quot;"] = '"',["&apos;"] = "'",["&nbsp;"]="",["<!%[CDATA%["]="",["]]>"]="",
			["<p>"]="",["</p>"]="",["<img.-/>"]="",["<div>"]="",["<div.->"]="",["</div>"]="",["<a href.-</a>"]="",["<a href.->"]="",["<a rel.->"]="",
			["</a>"]="",["</br>"]="",
			["&#(%d+)%;"] = function (x) return utf8char(tonumber(x)) end,
			["&#x(%x+)%;"] = function (x) return utf8char(tonumber(x,16)) end
			}
parseENT = 	function (s)
			for k,v in pairs(entities) do
				s = string.gsub(s,k,v)
			end return s end			
stripWS = 	function(s)
			s = string.gsub(s,'^%s+','')
			s = string.gsub(s,'%s+$','')
			return s end
noNil = 	function (s)
			if not s then return ''
			else return s end end

--Copyright (c) 2006-2007, Kyle Smith
char = string.char
function utf8char(unicode)
	if unicode <= 0x7F then return char(unicode) end

	if (unicode <= 0x7FF) then
		local Byte0 = 0xC0 + math.floor(unicode / 0x40);
		local Byte1 = 0x80 + (unicode % 0x40);
		return char(Byte0, Byte1);
	end;

	if (unicode <= 0xFFFF) then
		local Byte0 = 0xE0 +  math.floor(unicode / 0x1000);
		local Byte1 = 0x80 + (math.floor(unicode / 0x40) % 0x40);
		local Byte2 = 0x80 + (unicode % 0x40);
		return char(Byte0, Byte1, Byte2);
	end;

	if (unicode <= 0x10FFFF) then
		local code = unicode
		local Byte3= 0x80 + (code % 0x40);
		code       = math.floor(code / 0x40)
		local Byte2= 0x80 + (code % 0x40);
		code       = math.floor(code / 0x40)
		local Byte1= 0x80 + (code % 0x40);
		code       = math.floor(code / 0x40)
		local Byte0= 0xF0 + code;

		return char(Byte0, Byte1, Byte2, Byte3);
	end;
end