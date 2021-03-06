if(utils) then
	return;
end

utils = {};

function numberToReadable(num)
	num = math.abs(num);
	if(num>1000000) then
		return round(num/1000000, 2).."M";
	elseif(num>1000) then
		return round(num/1000, 2).."K";
	else
		return round(num, 2);
	end
end

function qColor(quality)
	if tonumber(quality) >= 1000 or tostring(quality) == "legendary" then
		return "#f78f0b"
	elseif tonumber(quality) >= 901 or tostring(quality) == "epic" then
		return "#A752D8"
	elseif tonumber(quality) >= 701 or tostring(quality) == "rare" then
		return "#2c6bd1"
	elseif tonumber(quality) >= 401 or tostring(quality) == "uncommon" then
		return "#08C153"
	else
		return "#cccccc"
	end
end

function GetTimeZone()

end

function timeCountDown(deltaSeconds)
	GetTimeZone();
	--local deltaSeconds = ads-timeSeconds; --System.GetElapsedUnixTime(timeSeconds);
	local secs = math.abs(deltaSeconds);
	local days = math.floor(secs / 86400);
	local hours = math.floor(secs / 3600) % 24;
	local minutes = math.floor(secs / 60) % 60;
	local seconds = secs % 60;
	
	local timeString = "";
	if(days > 0) then
		timeString = System.GetDate("%x %I:%M%p", tonumber(System.GetLocalUnixTime()) - deltaSeconds);
	else
		if(days > 0) then
			timeString = days.." day";
			if(days > 1) then
				timeString = timeString.."s";
			end
		elseif(hours > 0) then
			timeString = hours.." hour";
			if(hours > 1) then
				timeString = timeString.."s";
			end
		elseif(minutes > 0) then
			timeString = minutes.." minute";
			if(minutes > 1) then
				timeString = timeString.."s";
			end
		else
			--timeString = "<1 minute";

			timeString = seconds.." second";
			if(seconds > 1) then
				timeString = timeString.."s";
			end
		end
		
		
		
		if(deltaSeconds < 0) then
			timeString = timeString.."";
		else
			timeString = timeString.." ago";
		end
	end
	
	return timeString;
end

function timeParser(datetime)
	--local datetime = "2013-10-11T21:37:49+00:00"
	local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)+(%d+):(%d+)"
	local xyear, xmonth, xday, xhour, xminute, 
			xseconds, xmillies, xoffset = datetime:match(pattern);
	local seconds = (xyear-1970) * 31556926 + (xmonth - 1) * 2629743 + (xday-1) * 86400 + xhour * 3600 + xminute * 60 + xseconds;

	local date = System.GetDate("*t");

	local ads = (date.year-1970) * 31556926 + (date.month - 1) * 2629743 + (date.day-1) * 86400 + date.hour * 3600 + date.min * 60 + date.sec;

	return ads - seconds - io_TimeZone * 3600;
end


function comma_value(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function out(data)
  Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text=tostring(data)});
end

function round(num, idp)
	if(type(num) == "number") then
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	else
		return 0
	end
end
