
-- ------------------------------------------
-- lib_MarketApi
--   by: Thehink
-- ------------------------------------------

require "table";
require "math";
require "string";

if(MarketApi) then
	return nil;
end

MarketApi = {};

----------------------------------------------------------
-- Variables
----------------------------------------------------------
local MARKET_HOST;

local Listings = {};

local PRIVATE = {};
PRIVATE.Ready = false;
PRIVATE.CurrentPage = 1;
PRIVATE.TotalPages = 0;
PRIVATE.Query = "";
PRIVATE.PerPage = 10;
PRIVATE.SearchActive = false;

PRIVATE.itemReferences = {};

PRIVATE.ListingsCallbacks = {};

----------------------------------------------------------
-- Callbacks
----------------------------------------------------------
PRIVATE.cb_Complete = nil;
PRIVATE.cb_Error = nil;

----------------------------------------------------------
-- Events
----------------------------------------------------------

function PRIVATE.OnComplete(listings)
	if(isFunction(PRIVATE.cb_Complete)) then
		PRIVATE.cb_Complete(listings);
	end
end

function PRIVATE.OnError(err)
	if(isFunction(PRIVATE.cb_Error)) then
		PRIVATE.cb_Error(err);
	end
end

function PRIVATE.OnGetSearchResult(args, err)
	if (err) then
        warn(tostring(err));
		PRIVATE.OnError(err);
    else
		local total_listings = args.total;
		local listings = args.listings;

		PRIVATE.TotalPages = math.ceil(total_listings/PRIVATE.PerPage);
		
		MarketApi.CurrentPage = PRIVATE.CurrentPage;
		MarketApi.TotalPages = PRIVATE.TotalPages;
		PRIVATE.OnComplete({listings=listings, total = args.total, page=MarketApi.CurrentPage, pages = PRIVATE.TotalPages});
	end
	PRIVATE.SearchActive = false;
end

----------------------------------------------------------
-- Functions
----------------------------------------------------------
function isFunction(func)
	return type(func) == "function";
end


function PRIVATE.DoSearch()
	local url = MARKET_HOST.."/api/v1/search?query="..PRIVATE.Query.."&page="..PRIVATE.CurrentPage.."&per_page="..PRIVATE.PerPage;
	PRIVATE.SearchActive = true;
	doHttpReq({
		url = url,
		method = "GET",
		cb = PRIVATE.OnGetSearchResult,
	});
end

function PRIVATE.BuildQuery(args)
	local q = "";
	if(args.categories) then
		q = q.."category:";
		for _,v in ipairs(args.categories) do
			q = q..v..",";
		end
		q = string.sub(q, 1, -2);
	end
	
	if(args.string and args.string ~="") then
		q = q.." string:"..string.gsub(args.string, " ", "%%2520");
	end
	
	if(args.item_sdb_id) then
		q = q.." item_sdb_id:"..args.item_sdb_id;
	end
	
	if(args.filters) then
		for _,filter in ipairs(args.filters) do
			if(filter.value and #filter.value > 0) then
				q = q.." "..filter.name..":"..(filter.value or "");
			elseif(filter.min ~= 0 or filter.max ~= 0) then
				if(filter.min <= 0) then
					filter.min = nil;
				end
				if(filter.max <= 0) then
					filter.max = nil;
				end
				q = q.." "..filter.name..":"..(filter.min or "")..".."..(filter.max or "");
			end
		end
	end
	
	if(args.sort) then
		q = q.." sort:"..args.sort.name..":"..args.sort.method;
	end
	
	return q;
end

function PRIVATE.PutForSaleR(args)
	--log("TEST: "..args.item.item_sdb_id..", "..args.item.resource_type);
	return Market.SellResourceStack(args.item.item_sdb_id, args.item.resource_type or "", args.quantity or 1, args.price)
end

function PRIVATE.PutForSaleI(args)
	return Market.SellItem(args.item.item_sdb_id, args.item.item_id, args.price);
end

function doHttpReq(args)
	if ( HTTP.IsRequestPending(args.url) ) then
		callback(doHttpReq, args, 0.1);
		return;
	end
	HTTP.IssueRequest(args.url, args.method, args.data, args.cb);
end


----------------------------------------------------------
-- Public API
----------------------------------------------------------
MarketApi.CurrentPage = 0;
MarketApi.TotalPages = 0;

function MarketApi.OnMarketListingComplete(args)
	if(PRIVATE.itemReferences[args.reference]) then
		if (not args.success) then
			PRIVATE.itemReferences[args.reference](nil, args);
		elseif (args.success==true) then
			local listing = jsontotable(args.listing_id);
			PRIVATE.itemReferences[args.reference](listing);
		end
		PRIVATE.itemReferences[args.reference] = nil;
	end
end

function MarketApi.Init()
	MARKET_HOST = System.GetOperatorSetting("market_host");
	PRIVATE.Ready = true;
end

function MarketApi.Buy(args, callback)
	if not PRIVATE.Ready then
		return;
	end
	
	local url = MARKET_HOST.."/api/v1/buy/"..args.sale_guid;
	
	doHttpReq({
		url = url,
		method = "POST",
		cb = callback,
	});
end

function MarketApi.Sell(sellData, callback)
	if not PRIVATE.Ready then
		return;
	end

	local success, internal_reference = nil;
	
	if(sellData.item.item_id) then
		success, internal_reference = pcall(PRIVATE.PutForSaleI, sellData);
	else
		success, internal_reference = pcall(PRIVATE.PutForSaleR, sellData);
	end
	
	if(success) then
		PRIVATE.itemReferences[internal_reference] = callback;
		return true;
	else
		callback(nil,{error_code="LISTING_FAILED"});
		return false;
	end
end

function MarketApi.Cancel(args, callback)
	if not PRIVATE.Ready then
		return;
	end
	
	local url = MARKET_HOST.."/api/v1/listings/"..(args.id or args).."/cancel";
	
	doHttpReq({
		url = url,
		method = "POST",
		cb = callback,
	});
end

function MarketApi.Claim(args, callback)
	if not PRIVATE.Ready then
		return;
	end
	local url = MARKET_HOST.."/api/v1/listings/"..(args.id or args).."/reap";
	
	doHttpReq({
		url = url,
		method = "POST",
		cb = callback,
	});
end

function MarketApi.GetAttributes(callback)
	if not PRIVATE.Ready then
		return;
	end
	local url = MARKET_HOST.."/api/v1/item_display_attributes";
	--https://market.firefallthegame.com/api/v1/resources/stat_names

	doHttpReq({
		url = url,
		method = "GET",
		cb = callback,
	});
end

function MarketApi.GetResourceStatNames(callback)
	if not PRIVATE.Ready then
		return;
	end
	local url = MARKET_HOST.."/api/v1/resources/stat_names";

	local data = {["item_sdb_ids"]={78014,77703,78015,77704,78016,77705,78017,77706,78018,77707,78019,77708,78020,77709,78021,77710,78022,77711,78023,77713,78024,77714,78025,77715,78026,77716,78027,77736,78028,77737,82420,82419}};
	
	doHttpReq({
		url = url,
		method = "POST",
		data = data,
		cb = callback,
	});
end


function MarketApi.GetMyListings(callback)
	if not PRIVATE.Ready or (callback and PRIVATE.ListingsCallbacks[callback]) then
		return;
	end
	
	if(callback) then
		PRIVATE.ListingsCallbacks[callback] = true;
	end
	
	local url = MARKET_HOST.."/api/v1/my_listings";
	
	doHttpReq({
		url = url,
		method = "GET",
		cb = function(args, err)
			PRIVATE.ListingsCallbacks[callback] = nil;
			callback(args, err);
		end,
	});
end

function GetNextPage()
	if(PRIVATE.TotalPages > 0 and PRIVATE.TotalPages >= PRIVATE.CurrentPage) then
		PRIVATE.CurrentPage = PRIVATE.CurrentPage + 1;
		PRIVATE.DoSearch();
	end
end

function GetPrevPage()
	if(PRIVATE.TotalPages > 0 and PRIVATE.CurrentPage > 0) then
		PRIVATE.CurrentPage = PRIVATE.CurrentPage - 1;
		PRIVATE.DoSearch();
	end
end

function UpdatePage()
	if(PRIVATE.TotalPages > 0 and PRIVATE.CurrentPage > 0) then
		PRIVATE.DoSearch();
	end
end

function MarketApi.GetListingFee(price)
	if(type(price)=="number") then
		return math.floor((price * 20 + 999) / 1000 + 10);
	end
end

function MarketApi.GetReapingFee(price)
	if(type(price)=="number") then
		return math.floor((price * 50 + 999) / 1000);
	end
end

function MarketApi.GetMinPrice()
	return 50;
end

function MarketApi.GetMaxPrice()
	return 99999999;
end

function MarketApi.SearchListings(args, cb_OnComplete, cb_OnError)
	if not PRIVATE.Ready then
		return;
	end
	
	PRIVATE.cb_Complete = cb_OnComplete;
	PRIVATE.cb_Error = cb_OnError;
	
	PRIVATE.CurrentPage = args.page or PRIVATE.CurrentPage;
	local newQuery = PRIVATE.BuildQuery(args);
	
	if(PRIVATE.Query == newQuery and PRIVATE.SearchActive) then
		--warn("Already Requesting that URL");
		return;
	else
		PRIVATE.Query = newQuery;
	end
	
	PRIVATE.DoSearch();
end
