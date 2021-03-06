function Initialize()
	XMLStripper= dofile(SKIN:ReplaceVariables('#@#Scripts\\XMLStripper.lua'))
	noconvert = tonumber(SKIN:GetVariable('HighQuality'))
	Scale = tonumber(SKIN:GetVariable('Scale'))
	Width = tonumber(SKIN:GetVariable('Width'))
	Height = tonumber(SKIN:GetVariable('Height'))

	offsetHour, offsetMinute = localTimeZone()

	load = checkLoaded()
	if load then 
		SKIN:Bang('[!SetVariable Ticker 1][!SetOption Ticker LeftMouseUpAction """[!DeactivateConfig "Feedbox 2\\FeedTicker"][!CommandMeasure ParseArticles "Initialize()"]"""][!UpdateMeter Ticker]')
	else
		SKIN:Bang('[!SetVariable Ticker 0][!SetOption Ticker LeftMouseUpAction """[!ActivateConfig "Feedbox 2\\FeedTicker"][!CommandMeasure ConvertImage Kill][!Refresh]"""][!UpdateMeter Ticker]')
	end
	MeterGenerator()
	if SKIN:GetVariable('AllMode') == 'false' then AllMode = false 
	else AllMode = true end
	if AllMode then
		cur_url = 1
		title,descr,links,times = {},{},{},{}
		sbg('SetOption RssFetcher URL #'..cur_url..'RSS#','CommandMeasure RssFetcher Update')
	end
end

a = 0
function changearticle(d)
	if (a + 1*d) <= l and (a + 1*d) >= 1 then
		a = a + 1*d
	elseif (a+1*d) > l and l < #title then
		timing4 = 1
		yoyoDir=1
		return
	elseif (a+1*d) > l and l == #title then
		timing6 = 1
		return
	elseif (a+1*d) < 1 then
		return
	end
	sbg('SetOption TitleSub Text \"\"\"'..deltaTime(times[a])..'#Crlf#'..title[a]..'\"\"\"',
		'SetOption DescriptionSub Text \"\"\"'..descr[a]..'\"\"\"',
		'SetOption ImageSub Imagename \"#CURRENTPATH#DownloadFile\\Images\\'..a..'.jpg\"',
		'SetOption Title LeftMouseUpAction \"\"\"'..links[a]..'\"\"\"',
		'UpdateMeterGroup T','UpdateMeter DescriptionSub','UpdateMeter ImageSub')
	timing2 = 1
	slideDir = d
	drawDots(false)
end

function goxml()
	local file = io.open(SKIN:GetVariable('CURRENTPATH') .. "DownloadFile\\lol.txt",'r')
	local content = file:read('*a')
	file:close()
	content = parseENT(content) 
	
	if AllMode then
		feedname = 'All'
		sbg('SetOption Title Text "All Latest News"','UpdateMeter Title')
		topten = 1
	else
		sbg('SetOption Image ImageName \"#logo#\"','UpdateMeter Image')
		feedname = content:match('<title>(.-)</title>')
		sbg('SetOption Title Text \"'..feedname..'\"','UpdateMeter Title')
		title,descr,links,times = {},{},{},{}
	end

	if string.match(SKIN:GetMeasure('RSSFetcher'):GetOption('URL'),'reddit.com') then
		for item in content:gmatch('<entry>(.-)</entry>') do
			if AllMode then if topten > 10 then break end end
			table.insert(title,stripWS(noNil(item:match('<title>(.-)</title>'))))
			table.insert(descr,stripWS(noNil(item:match('<name>(.-)</name>'))))
			table.insert(links,stripWS(noNil(item:match('<link href="(.-)"%s/>'))))
			table.insert(times,formatTimestamp_reddit(item:match('<updated>(.-)</updated>'),offsetHour,offsetMinute))
			if AllMode then topten = topten + 1 end
		end
	else
		for item in content:gmatch('<item>(.-)</item>') do
			if AllMode then if topten > 10 then break end end
			table.insert(title,stripWS(noNil(item:match('<title>(.-)</title>'))))
			table.insert(descr,stripWS(noNil(item:match('<description>(.-)</description>'))))
			table.insert(links,stripWS(noNil(item:match('<link>(.-)</link>'))))
			table.insert(times,formatTimestamp(item:match('<pubDate>(.-)</pubDate>'),offsetHour,offsetMinute))
			if AllMode then topten = topten + 1 end
		end
	end

	if AllMode then
		if cur_url < m-1 then 
			cur_url = cur_url + 1
			sbg('SetOption RssFetcher URL #'..cur_url..'RSS#','CommandMeasure RssFetcher Update')
			return
		else
			for k,v in pairs(times) do
				for i = k,#times do
					if times[k] < times[i] then
						times[k],times[i] = times[i],times[k]
						title[k],title[i] = title[i],title[k]
						descr[k],descr[i] = descr[i],descr[k]
						links[k],links[i] = links[i],links[k]
					end
				end
			end
		end
	end
	nextqueue()
	
	if load then
		pushTicker()
	end
end

function queuecondition()
	if noconvert == 1 then
		drawDots(true,q)
		nextqueue()
	else
		nextconvertqueue()
	end
end

q = 0
function nextqueue()
	if q < #title then
		q = q + 1
	else 
		return 
	end
	sbg('SetOption HTMLParser URL \"'..links[q]..'\"','CommandMeasure HTMLParser Update',
		'SetOption DownloadImage DownloadFile \"Images\\'..q..'.jpg\"')
end

c = 0
function nextconvertqueue()
	if c < #title then
		c = c + 1
	else 
		return 
	end
	sbg('SetOption ConvertImage Parameter \"\"\"\"#Currentpath#DownloadFile\\Images\\'..c..'.jpg\" -resize \"'..round(Width*Scale)..'x'..round(Height*Scale)..'^\" \"#Currentpath#DownloadFile\\Images\\'..c..'.jpg\"\"\"\"',
		'CommandMeasure ConvertImage Run')
end
function gohtml()	
	contenthtml = SKIN:GetMeasure("HTMLParser"):GetStringValue()
	foundimage,twitterimage = nil,nil
	for meta in contenthtml:gmatch('<meta(.-)>') do
		if meta:match('"twitter:image"') then --Just in case no og:image but there's twitter:image available
			twitterimage = meta:match('content="(.-)"')
		end
		if meta:match('"og:image"') then
			foundimage = meta:match('content="(.-)"')
			break
		end
	end
	if not foundimage then 
		if twitterimage then
			foundimage = twitterimage
		else
			foundimage = "#@#noimage.jpg"
		end
	end
	sbg('SetOption DownloadImage URL \"'..parseENT(foundimage)..'\"','CommandMeasure DownloadImage Update')
end

function gofailed()
	sbg('SetOption DownloadImage URL \"#@#noimage.jpg\"','CommandMeasure DownloadImage Update')
end

l = 0
function drawDots(new,total)
	dis =10*Scale
	if new and c < #title then 
		l = total 
	elseif new and c == #title then
		l = #title
	else
		l = l 
	end
	combine = "Combine Shape"
	for i = 1,l do
		sbg('SetOption Dot Shape'..(i+1)..' \"Ellipse '..((i-1)*dis)..',0,(2.5*#Scale#)\"')
		combine = combine .. "|Union Shape"..(i+1)
	end
	local x = Width/2*Scale - (a-1) * dis
	local w = (l - 1) * dis
	local head = (Width/4*Scale - x) / w
	local tail = Width/2*Scale / w
	sbg('SetOption Dot Shape'..(l+2)..' \"'..combine..'\"',
		'SetOption Dot X '..x,
		'SetOption Dot Grad \"180|#Color#,0 ;'..head..' | #Color#,86;'..(head+0.1)..'|#Color#,86;'..(head+tail-0.1)..'|#Color#,0;'..(head+tail)..'\"',
		'UpdateMeter Dot')
	if a == 1 then sbg('SetOption DotSelected Shape \"Ellipse 0,0,(3.5*#Scale#) | StrokeWidth 0 | Fill Color #Color#,180\"','UpdateMeter DotSelected') end
end

timing,timing2,timing3,timing4,timing5,timing6,timing7 = 0,0,0,0,-1,0,-1
MaxTime = 20
stick = false
oldpos = 0
feedChanged=false
function Update()
--[[
   ('-.         .-') _        _   .-')      ('-.     .-') _                            .-') _  
  ( OO ).-.    ( OO ) )      ( '.( OO )_   ( OO ).-.(  OO) )                          ( OO ) ) 
  / . --. /,--./ ,--,' ,-.-') ,--.   ,--.) / . --. //     '._ ,-.-')  .-'),-----. ,--./ ,--,'  
  | \-.  \ |   \ |  |\ |  |OO)|   `.'   |  | \-.  \ |'--...__)|  |OO)( OO'  .-.  '|   \ |  |\  
.-'-'  |  ||    \|  | )|  |  \|         |.-'-'  |  |'--.  .--'|  |  \/   |  | |  ||    \|  | ) 
 \| |_.'  ||  .     |/ |  |(_/|  |'.'|  | \| |_.'  |   |  |   |  |(_/\_) |  |\|  ||  .     |/  
  |  .-.  ||  |\    | ,|  |_.'|  |   |  |  |  .-.  |   |  |  ,|  |_.'  \ |  | |  ||  |\    |   
  |  | |  ||  | \   |(_|  |   |  |   |  |  |  | |  |   |  | (_|  |      `'  '-'  '|  | \   |   
  `--' `--'`--'  `--'  `--'   `--'   `--'  `--' `--'   `--'   `--'        `-----' `--'  `--'   
--]]
--Description slide up
	if timing > 0 and timing < MaxTime then
		if stick then
			timing = MaxTime
			sbg('SetOption TitleSub Y \"((#Height#-20)*#Scale#-[*DescriptionSub:H*])\"',
				'SetOption DescriptionSub Y \"((#Height#-20)*#Scale#-[*DescriptionSub:H*])\"',
				'UpdateMeterGroup T','UpdateMeterGroup D')
			return
		end
		timing=timing + 1*revealDir
		desAnimate = outQuart(timing,0,1,MaxTime)
		sbg('SetOptionGroup T Y ((#Height#-20)*#Scale#-[Description:H]*'..desAnimate..')',
			'SetOptionGroup D Y (#Height#*#Scale#-([Description:H]+20*#Scale#)*'..desAnimate..')',
			'UpdateMeterGroup T','UpdateMeterGroup D')
	elseif timing >= MaxTime then
		timing = MaxTime
	elseif timing <= 0 then
		timing = 0
	end

--Article change 
	--Imagesub, TitleSub, DesSub (new article) slide in the box.
	--Image, Title, Des (old article) slide out of the box.
	if timing2 > 0 and timing2 < MaxTime then
		timing2 = timing2 + 1
		slideOutAnimate = inQuart(timing2,0,1,MaxTime)
		slideInAnimate = outQuart(timing2,0,1,MaxTime)
		sbg('SetOption Image X '..-2*Width*Scale*slideDir*slideOutAnimate,
			'SetOption ImageSub X '..Width*Scale*slideDir-Width*Scale*slideDir*slideInAnimate,

			'SetOption Title X '..20*Scale-Width*Scale*slideDir*slideOutAnimate,
			'SetOption TitleSub FontColor #Color#,'..255*slideOutAnimate,

			'SetOption Description X '..20*Scale-Width*Scale*slideDir*slideOutAnimate,
			'SetOption DescriptionSub FontColor #Color#,'..255*slideOutAnimate,

			'SetOption DotSelected X '..Width/2*Scale-dis*inQuart(timing2,1*slideDir,-1*slideDir,MaxTime),
			'SetOptionGroup C LeftMouseUpAction \" \"',

			'UpdateMeterGroup A','UpdateMeterGroup C')
	--ImageSub, TitleSub, DesSub disappear.
	--Image, Title, Des show up with new article.
	elseif timing2 == MaxTime then
		sbg('SetOption Image ImageName \"#CURRENTPATH#DownloadFile\\Images\\'..a..'.jpg\"',
			'SetOption Image X 0','SetOption Image Y 0',

			'SetOption Title Text \"\"\"'..deltaTime(times[a])..'#Crlf#'..parseENT(title[a])..'\"\"\"',
			'SetOption Description Text \"\"\"'..parseENT(descr[a])..'\"\"\"',

			'SetOption Title X (20*#Scale#)',
			'SetOption Description X (20*#Scale#)',

			'SetOption TitleSub FontColor #Color#,0',
			'SetOption DescriptionSub FontColor #Color#,0',

			'SetOption Next LeftMouseUpAction \"\"\"[!CommandMeasure ParseArticles "changearticle(1)"]\"\"\"',
			'SetOption Back LeftMouseUpAction \"\"\"[!CommandMeasure ParseArticles "changearticle(-1)"]\"\"\"',

			'UpdateMeterGroup A','UpdateMeterGroup C')
		if stick then
			sbg('SetOption Title Y \"((#Height#-20)*#Scale#-[Description:H])\"',
				'SetOption Description Y \"((#Height#-20)*#Scale#-[Description:H])\"',
				'UpdateMeterGroup T','UpdateMeterGroup D')
		end
		timing2 = MaxTime+1
	end

--Scrolling
	if timing3 > 0 and timing3 < 10 then
		if (oldpos + timing3/10*40*Scale*scrollDir) >= ((Height-60)*Scale - BarSize) then
			sbg('SetVariable Scroll '..(Height-60)*Scale - BarSize)
			oldpos = (Height-60)*Scale - BarSize
			timing3 = 11
		elseif (oldpos + timing3/10*40*Scale*scrollDir) <= 0 then
			sbg('SetVariable Scroll 0')
			oldpos = 0
			timing3 = 11
		else
			timing3 = timing3 + 1
			sbg('SetVariable Scroll '..oldpos + timing3/10*40*Scale*scrollDir,
				'SetOption ListShape Color \"Fill Color 50,50,50\"',
				'UpdateMeterGroup List','UpdateMeter List','UpdateMeter AddFeed','UpdateMeter ListShape')
		end
	elseif timing3 == 10 then
		timing3=11
	end

--Show "Wait"
	if timing4 > 0 and timing4 < MaxTime then
		timing4 = timing4 + 1*yoyoDir
		yoyoAnimate = outQuart(timing4,0,1,MaxTime)
		sbg('SetOption Image X '..-150*Scale*yoyoAnimate,
			'SetOption ImageSub ImageName "#@#wait"',
			'UpdateMeterGroup I')
	elseif timing4 == MaxTime then
		yoyoDir=-1
		timing4=MaxTime-1
	elseif timing4 == 0 then
		timing4 = -1
	end

--Menu sliding out/in
	if timing5 > 0 and timing5 < MaxTime then
		timing5 = timing5 + 1*pulloutDir
		pulloutAnimate = outQuart(timing5,0,1,MaxTime)
		sbg('SetOption ListShape X '..-Width/2*Scale+Width/2*Scale*pulloutAnimate,
			'SetOption ListShape ListShape \"0,0 | Lineto (#Width#/2*#Scale#),0 | Curveto (#Width#/2*#Scale#),(#Height#*#Scale#),'..((Width/2+50)*Scale-50*Scale*pulloutDir*outBack(timing5,-1,2,MaxTime,4))..','..randomposition..' | Lineto 0,(#Height#*#Scale#) | ClosePath 1\"',
			'SetOption ListShape Color \"Fill Color 0,0,0,0\"',

			'SetOptionGroup List X '..-(Width/2-10)*Scale+Width/2*Scale*pulloutAnimate,
			'SetOptionGroup Del X '..-25*Scale+Width/2*Scale*pulloutAnimate,

			'SetOption List LeftMouseUpAction \" \"',
			
			'UpdateMeter ListShape','UpdateMeterGroup List','UpdateMeterGroup Del','UpdateMeter List','UpdateMeter AddFeed')
	elseif timing5 == MaxTime then
		sbg('SetOption List LeftMouseUpAction \"\"\"[!CommandMeasure ParseArticles \"timing5=19;pulloutDir=-1;randomposition=math.random(0,#Height#*Scale)\"]\"\"\"',
			'UpdateMeter List')
		timing5 = MaxTime+1
	elseif timing5 == 0 then
		sbg('SetOption List LeftMouseUpAction \"\"\"[!CommandMeasure ParseArticles \"timing5=1;pulloutDir=1;randomposition=math.random(0,#Height#*Scale)\"]\"\"\"',
			'SetOption ListShape ListShape \"0,0 | Lineto 0,0\"',
			'UpdateMeter ListShape','UpdateMeter List')
		if feedChanged then sbg('Refresh') end
		timing5 = -1
	end

--Shaking menu button
	if timing6 > 0 and timing6 < MaxTime then
		timing6 = timing6 + 1
		shakingAnimate = inOutElastic(timing6,1,0,MaxTime,3,6)
		sbg('SetOption List X '..10*Scale*shakingAnimate,
			'SetOption List FontColor '..(255*timing6/MaxTime)..','..(255*timing6/MaxTime)..','..(255*timing6/MaxTime),
			'UpdateMeter List')
	elseif timing6 == MaxTime then
		sbg('SetOption List FontColor #Color#','UpdateMeter List')
		timing6 = MaxTime+1
	end

--Delete Highlight
	if timing7 > 0 and timing7 < 40 then
		timing7 = timing7 + 1
		sbg('SetOption ListShape Shape2 \"Rectangle 0,(['..delHovering..':Y]-5),(#Width#/2*#Scale#),(30*#Scale#) | StrokeWidth 0 | Fill LinearGradient DeleteGrad',
			'SetOption ListShape DeleteGrad \"180 | 00000000 ; '..outQuart(timing7,1,-1.5,40)..' | 204,50,50 ; 1',
			'UpdateMeter ListShape')
	elseif timing7 == 40 then
		timing7 = 41
	elseif timing7 == 0 then
		sbg('SetOption ListShape Shape2 \"Rectangle 0,0,0,0\"',
			'UpdateMeter ListShape')
		timing7 = -1
	end
end

function MeterGenerator()
	local file = io.open(SKIN:GetVariable('@')..'RssList.inc','w')
	m = 1
	while SKIN:GetVariable(m..'RSS') and SKIN:GetVariable(m..'RSS') ~= '' do
		file:write('['..m..'RSS]\n')
		file:write('Meter=String\n')
		file:write('MeterStyle=ListStyle\n')
		file:write('Text=#'..m..'Name#\n')
		file:write('LeftMouseUpAction=[!WriteKeyValue Variables Logo \"#'..m..'Logo#\"][!WriteKeyValue RssFetcher URL \"#'..m..'RSS#\"][!CommandMeasure ConvertImage Kill][!CommandMeasure ParseArticles \"timing5=19;pulloutDir=-1;feedChanged=true;randomposition=[#Currentsection#:Y]\"][!WriteKeyValue Variables AllMode false]"\n')
		file:write('['..m..']\n')
		file:write('Meter=String\n')
		file:write('MeterStyle=DelStyle\n')
		file:write('\n')
		m = m + 1
	end
	file:close()
	ScrollableSize = (m + 1) * (20*Scale + 30*Scale)
	if ScrollableSize > ((Height-60)*Scale) then
		BarSize = (Height-60)*Scale * (Height-60)*Scale / ScrollableSize
	else
		BarSize = (Height-60)*Scale
	end
	sbg('SetVariable MaxFeed '..m,'SetVariable ScrollableZone '..ScrollableSize/((Height-60)*Scale),
		'SetOption ListShape Shape2 \"Rectangle (#Width#/2*#Scale#),(40*#Scale#+#*scroll*#),(-5*#Scale#),'..BarSize..'|StrokeWidth 0|Extend Color\"',
		'UpdateMeter ListShape')
end

function deletefeed(f)
	for i=f,(m-2) do
		sbg('WriteKeyValue Variables '..i..'Name \"#'..(i+1)..'Name#\"','SetVariable '..i..'Name \"#'..(i+1)..'Name#\"',
			'WriteKeyValue Variables '..i..'RSS \"#'..(i+1)..'RSS#\"','SetVariable '..i..'RSS \"#'..(i+1)..'RSS#\"')
	end
	sbg('WriteKeyValue Variables '..(m-1)..'Name \"\"','SetVariable '..(m-1)..'Name \"\"',
		'WriteKeyValue Variables '..(m-1)..'RSS \"\"','SetVariable '..(m-1)..'RSS \"\"')
	MeterGenerator()
	sbg('Refresh')
end

function sbg(...) --concentrate bangs
	local bangs=''
	for i,v in ipairs(arg) do
		bangs = bangs .. '[!' .. tostring(v) .. ']'
	end
	SKIN:Bang(bangs)
end

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function inQuart(t, b, c, d)
  t = t / d
  return c * math.pow(t, 4) + b
end

function outQuart(t, b, c, d)
	t = t / d - 1
	return -c * (math.pow(t, 4) - 1) + b
end

function outBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d - 1
  return c * (t * t * ((s + 1) * t + s) + 1) + b
end

function inOutElastic(t, b, c, d, a, p)
  if t == 0 then return b end

  t = t / d * 2

  if t == 2 then return b + c end

  if not p then p = d * (0.3 * 1.5) end
  if not a then a = 0 end

  local s

  if not a or a < math.abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * math.pi) * math.asin(c / a)
  end

  if t < 1 then
    t = t - 1
    return -0.5 * (a * math.pow(2, 10 * t) * math.sin((t * d - s) * (2 * math.pi) / p)) + b
  else
    t = t - 1
    return a * math.pow(2, -10 * t) * math.sin((t * d - s) * (2 * math.pi) / p ) * 0.5 + c + b
  end
end

function pushTicker()
	local file = io.open(SKIN:GetVariable('@')..'TitleMeter.inc','w')
	file:write('Hola!')
	file:close()
	maxtickerarticle = tonumber(SKIN:GetVariable('MaxTickerArticle'))
	for i = 1, maxtickerarticle do
		if title[i] and links[i] then
			SKIN:Bang('[!WriteKeyValue Title'..i..' Meter String "#@#TitleMeter.inc"]'
					..'[!WriteKeyValue Title'..i..' MeterStyle TitleStyle "#@#TitleMeter.inc"]'
					..'[!WriteKeyValue Title'..i..' Text "'..title[i]..' #*Separator*#" "#@#TitleMeter.inc"]'
					..'[!WriteKeyValue Title'..i..' LeftMouseUpAction "'..links[i]..'" "#@#TitleMeter.inc"]')
			if i == maxtickerarticle then 
				SKIN:Bang('!WriteKeyValue Variables Current_Amount_Article #MaxTickerArticle# "#ROOTCONFIGPATH#FeedTicker\\FeedTicker.ini"')
			end
		else
			SKIN:Bang('!WriteKeyValue Variables Current_Amount_Article '..(i-1)..' "#ROOTCONFIGPATH#FeedTicker\\FeedTicker.ini"')
			break
		end
	end
	SKIN:Bang('[!WriteKeyValue Variables MaxTickerArticle #MaxTickerArticle# "#ROOTCONFIGPATH#FeedTicker\\FeedTicker.ini"]'
			..'[!WriteKeyValue FeedName Text "'..feedname..' #*Separator*#" "#ROOTCONFIGPATH#FeedTicker\\FeedTicker.ini"]')
	SKIN:Bang('!Refresh "Feedbox 2\\FeedTicker"')
end

function checkLoaded()
	file=io.open(SKIN:ReplaceVariables('#SETTINGSPATH#Rainmeter.ini'),'r')
	content=file:read("*a")
	file:close()
	for skinname,active in content:gmatch('%[(.-)%]\nActive=(.)') do
		if skinname == 'Feedbox 2\\FeedTicker' then
			if active ~= '0' then
				return true
			else
				return false
			end
		end
	end
end

monthlist={["jan"] = 1,["feb"] = 2,["mar"] = 3,["apr"] = 4,["may"] = 5,["jun"] = 6,["jul"] = 7,["aug"] = 8,["sep"] = 9,["oct"] = 10,["nov"] = 11,["dec"] = 12}
function formatTimestamp(time,GMTHour,GMTMinute)
	local d,m,y,h,minute,s = time:match('%w+,%s(%d+)%s(%w+)%s(%d+)%s(%d+):(%d+):(%d+)')
	return os.time{year = y, month = monthlist[m:lower()], day = d, hour = h + GMTHour, min = minute + GMTMinute, sec = s}
end

function formatTimestamp_reddit(time,GMTHour,GMTMinute)
	local y,m,d,h,minute,s = time:match('(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)')
	return os.time{year = y, month = m, day = d, hour = h + GMTHour, min = minute + GMTMinute, sec = s}
end

function localTimeZone()
	local offset = SKIN:GetMeasure('LocalTimeZone'):GetStringValue()
	local sign,hour,minute = offset:match('(.)(%d%d)(%d%d)')
	if sign == '-' then hour = -1 * hour end
	return tonumber(hour), tonumber(minute)
end

function deltaTime(time)
	local delta = os.time()-time
	local deltaResult = ''
	if delta < 3600 then 
		local minute = math.floor(delta/60)
		if minute > 0 then 
			deltaResult = minute .. ' minute' .. (minute > 1 and 's' or '') .. ' ago'
		else
			deltaResult = 'Just now'
		end
	elseif delta < 3600*24 	then 
		local hour = math.floor(delta/3600)
		local minute = math.floor((delta-hour*3600)/60)
		deltaResult = hour .. ' hour' .. (hour > 1 and 's' or '') .. (minute > 0 and ' ' .. minute .. ' minute' .. (minute > 1 and 's' or '') or '') .. ' ago'
	elseif delta < 3600*24*7 then
		local day = math.floor(delta/3600/24)
		local hour = math.floor((delta - day*3600*24)/3600)
		deltaResult = day .. ' day' .. (day > 1 and 's' or '') .. (hour > 0 and ' ' .. hour .. ' hour' .. (hour > 1 and 's' or '') or '') .. ' ago'
	else
		deltaResult = os.date("%a, %d %b %y", time)
	end
	return deltaResult .. '  ⏳'
end

function ResizeWindow(MouseX,MouseY)
		if MouseX >= 250 then
			sbg('SetVariable Width '..MouseX/Scale+10,
				'WriteKeyValue Variables Width '..MouseX/Scale+10)
		end
		if MouseY >= 250 then
			sbg('SetVariable Height '..MouseY/Scale+10,
				'WriteKeyValue Variables Height '..MouseY/Scale+10)
		end
		sbg('UpdateMeterGroup ResizeGroup','UpdateMeter ResizeHandle')
		Initialize()
end

