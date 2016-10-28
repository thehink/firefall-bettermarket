
--
-- Market Addon
--   by: Thehink
--
--[[
TODO:
Fix some chosen ??? tooltip bug
Add inventory repair pool stats in tooltip
Add Expires at in tooltip to listings

]]
--
--

require "unicode";
require "table";
require "math";
require "string";

require "lib/lib_Colors";
require "lib/lib_Items";
require "lib/lib_Slash";
require "lib/lib_HudNote"
require "lib/lib_InterfaceOptions"
require "lib/lib_RowScroller"
require "lib/lib_ToolTip"
require "lib/lib_Callback2"
require "lib/lib_DropDownList"
--require "lib/lib_Slider"
require "lib/lib_HoloPlate"
require "lib_WebCache"

require "./lib/lib_Table"
require "./lib/lib_SimpleChoiceMenu"
require "./lib/lib_MarketApi"
require "./lib/lib_ModalBox"
require "./lib/lib_ChoiceWindow"

require "./FilterData"
require "./BuyPage"
require "./SellPage"
require "./utils"
require "./CellTemplates"

local FRAME = Component.GetFrame("Main");
local BUY_PAGE = Component.GetWidget("buy_page");
local SELL_PAGE = Component.GetWidget("sell_page");

local ICON_CRYSTITE = Component.GetWidget("crystite_icon");
local ICON_COUNT = Component.GetWidget("crystite_count");

STAT_BOX = Component.GetWidget("ToolTip");
local STAT_BOX_TITLE = Component.GetWidget("BoxTxt");
local STAT_BOX_STATS = Component.GetWidget("BoxStats");


DISPATCHER = EventDispatcher.Create();

local SLASH = {};

-- ------------------------------------------
-- MARKET VARIABLES
-- ------------------------------------------

local rarities = {
	legendary = 5,
	epic = 4,
	rare = 3,
	uncommon = 2,
	common = 1,
	salvage = 0,
}

local INGAME_HOST = nil;

local currentCategories = {0};

local ListingsCycle = nil;
local SoldListings = {};

playerId = nil;
MarketAttributes = nil;
ResourceStatNames = nil;
local marketIsReady = false;

marketVisible = false;
CurrentTab = "";

local TEXT_CODES = {
	ERR_INVALID_PRICE_LOW = "Below minimum price of 50 cy.",
	LISTING_FAILED = "Listing failed.";
};

-- ------------------------------------------
-- INTERFACE OPTIONS
-- ------------------------------------------
local onOption = {};
local io_Enabled = true;
--[[
InterfaceOptions.SaveVersion(1.0)
InterfaceOptions.NotifyOnDefaults(true)

InterfaceOptions.StartGroup({label="Better Market"})
InterfaceOptions.StopGroup()]]

-- ------------------------------------------
-- OPTION CHANGE CALLBACKS
-- ------------------------------------------

onOption.ENABLED = function(val)

end

-- EVENTS

function OnComponentLoad()
	--InterfaceOptions.SetCallbackFunc(OnOptionChange, "Better Market");
	LIB_SLASH.BindCallback({slash_list = "market,ma", description = "open the market addon", func = SLASH.toggleMarket});
	--LIB_SLASH.BindCallback({slash_list = "run_test", description = " runs the sort test on all possible stats", func = SLASH.TEST});

	INGAME_HOST = System.GetOperatorSetting("ingame_host");
	
	ListingsCycle = Callback2.CreateCycle(GetMyListings);
	
	MarketApi.Init();
	MarketApi.GetAttributes(OnGetAttributes);
	MarketApi.GetResourceStatNames(OnGetResourceStatNames);
	ICON_CRYSTITE:SetUrl(Game.GetItemInfoByType(10).web_icon);
	
	OnResolutionChanged();
	
	initButtons();
	SELLPAGE.initSellPage();
	BUYPAGE.initBuyPage();
	SetBuyPage();
end

function OnPlayerReady()
	playerId = Player.GetCharacterId();
	UpdateCurrencyCount();
	CheckMarketReady();
end

function OnGetAttributes(resp, err)
	MarketAttributes = resp or {};
	CheckMarketReady();
end

function OnGetResourceStatNames(resp, err)
	ResourceStatNames = resp or {};
	CheckMarketReady();
end

function CheckMarketReady()
	if not marketIsReady and Player.IsReady() and MarketAttributes and ResourceStatNames then
		marketIsReady = true;
		OnMarketReady();
		--todo fix the autoupdate listing system
		--WebCache.Subscribe(System.GetOperatorSetting("market_host").."/api/v1/my_listings", OnGetMyListings);
		ListingsCycle:Run(60);
	end
end

function OnMarketReady()
	DISPATCHER:DispatchEvent("OnReady");
end

function OnInventoryChanged(args)
	UpdateCurrencyCount();
	DISPATCHER:DispatchEvent("OnInventoryChanged", args);
end

function OnMarketListingComplete(args)
	DISPATCHER:DispatchEvent("OnMarketListingComplete", args);
end

function OnOpen()
	Component.SetInputMode("cursor")
end

function OnClose()
	if not marketVisible then
		Component.SetInputMode(nil);
	end
end

function OnEscape()
	HideMarket();
end

function OnOptionChange(id, val)
	if(onOption[id]) then
		onOption[id](val);
	end
end

function OnHideWebUI()
end

function OnResolutionChanged()
	local width, height = Component.GetScreenSize();
	if(width < 1400) then
		BUY_PAGE:SetDims("center-x: 50%; top:60; height:90%; width: 100%;");
		SELL_PAGE:SetDims("center-x: 50%; top:60; height:90%; width: 100%;");
	end
end





----------------------------------------------------------
-- MARKET RESPONSE
-- -------------------------------------------------------

function OnGetMyListings(args, err)
	if not err then
		SELLPAGE.listings = args;
		for _,listing in pairs(args) do
			if not SoldListings[listing.id] and listing.purchased then
				SoldListings[listing.id] = true;
				NotifySoldListing(listing);
			end
		end
	end
end

----------------------------------------------------------
-- MARKET FUNCTIONS
-- -------------------------------------------------------

function GetMyListings()
	MarketApi.GetMyListings(OnGetMyListings);
end

function LookupText(code)
	local txt = Component.LookupText(code);
	if(txt ~= "") then
		return txt;
	elseif(TEXT_CODES[code]) then
		return TEXT_CODES[code];
	else
		return code or "";
	end
end

----------------------------------------------------------
-- GUI FUNCTIONS
-- -------------------------------------------------------

function initButtons()
	local CLOSE_BUTTON = Component.GetWidget("close_market");
	CLOSE_BUTTON:BindEvent("OnMouseDown", function()
		HideMarket();
	end);
	local CBTN1 = CLOSE_BUTTON:GetChild("X");
	CLOSE_BUTTON:BindEvent("OnMouseEnter", function() CBTN1:ParamTo("exposure", 1, 0.15); end);
	CLOSE_BUTTON:BindEvent("OnMouseLeave", function() CBTN1:ParamTo("exposure", 0, 0.15); end);
	
	
	local Tabs = {{"buy_tab", SetBuyPage}, {"sell_tab", SetSellPage}};
	
	for _,v in ipairs(Tabs) do
		local BUTTON = Component.GetWidget(v[1]);
		BUTTON:BindEvent("OnMouseDown", function()
			v[2]();
		end);
		local CBTN2 = BUTTON:GetChild("bgbtn");
		BUTTON:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("tint", "#11AAFF", 0.15); end);
		BUTTON:BindEvent("OnMouseLeave", function() if(CurrentTab ~= v[1]) then CBTN2:ParamTo("tint", "#111111", 0.15); end; end);
	end
end

function SetBuyPage()
	local BUY_PAGE_BTN = Component.GetWidget("buy_tab");
	local SELL_PAGE_BTN = Component.GetWidget("sell_tab");
	
	BUY_PAGE_BTN:GetChild("bgbtn"):ParamTo("tint", "#11AAFF", 0.15);
	SELL_PAGE_BTN:GetChild("bgbtn"):ParamTo("tint", "#111111", 0.15);
	
	CurrentTab = "buy_tab";
	SELL_PAGE:Hide(true);
	BUY_PAGE:Show(true);
	--out("BUY");
end

function SetSellPage()
	local BUY_PAGE_BTN = Component.GetWidget("buy_tab");
	local SELL_PAGE_BTN = Component.GetWidget("sell_tab");
	
	SELL_PAGE_BTN:GetChild("bgbtn"):ParamTo("tint", "#11AAFF", 0.15);
	BUY_PAGE_BTN:GetChild("bgbtn"):ParamTo("tint", "#111111", 0.15);
	
	CurrentTab = "sell_tab";
	BUY_PAGE:Hide(true);
	SELL_PAGE:Show(true);
	

	--out("SELL");
end

function UpdateCurrencyCount()
	ICON_COUNT:SetText(Player.GetItemCount(10));
end

----------------------------------------------------------
-- MARKET
-- -------------------------------------------------------

function OnSelectAction(args)
	if(args ~= "nothing") then
		args.WIDGET:SetSelectedByIndex(1);
		if(args.action == "cancel") then
			MarketApi.Cancel(args.listing, SELLPAGE.OnItemCanceled);
			args.WIDGET:Disable(true);
			args.WIDGET.TEXT:SetText("Canceling");
		elseif(args.action == "reap") then
			MarketApi.Claim(args.listing, SELLPAGE.OnItemReaped);
			args.WIDGET:Disable(true);
			args.WIDGET.TEXT:SetText("Claiming");
		elseif(args.action == "reap_list_again") then
			MarketApi.Claim(args.listing, SELLPAGE.OnItemReaped);
			args.WIDGET:Disable(true);
			args.WIDGET.TEXT:SetText("Claiming");
			SELLPAGE.SearchAndSelectItem(args.listing);
		elseif(args.action == "list_more") then
			SELLPAGE.SearchAndSelectItem(args.listing);
			SetSellPage();
		elseif(args.action == "relist") then
			SELLPAGE.selectItemOnInventoryChange = args.listing;
			MarketApi.Cancel(args.listing, SELLPAGE.OnItemCanceled);
			args.WIDGET:Disable(true);
			args.WIDGET.TEXT:SetText("Canceling");
			SetSellPage();
		elseif(args.action == "buy_item") then
			BUYPAGE.ShowBuyConfirmation(args.WIDGET, args.listing);
		end
	end
end

----------------------------------------------------------
-- SORT METHODS
----------------------------------------------------------


----------------------------------------------------------
-- HUD Note
----------------------------------------------------------

function NotifySoldListing(listing)
	local HUDNOTE = HudNote.Create();
	HUDNOTE:SetTitle("Sold "..listing.quantity.." "..listing.title, "for "..listing.price_cy.." cy.");
	HUDNOTE:SetIconTexture("icons", "business");
	HUDNOTE:SetDescription("for "..listing.price_cy.." cy. Show my listings?");

	HUDNOTE:SetTags({"mission"})
	HUDNOTE:SetPrompt(1, Component.LookupText("LOBBY_NOTE_PROMPT_SHOW"), function()
		SELLPAGE.UpdateListingDisplay();
		SetSellPage();
		ShowMarket();
		HUDNOTE:Remove();
	end);
	HUDNOTE:SetPrompt(2, "No", function() HUDNOTE:Remove(); end);
	HUDNOTE:SetTimeout(120, function() HUDNOTE:Remove(); end);
	HUDNOTE:Post();
end

----------------------------------------------------------
-- STAT BOX
-- -------------------------------------------------------

function ShowBox()
	STAT_BOX:ParamTo("alpha", 1, 0.2);
end

function HideBox()
	STAT_BOX:ParamTo("alpha", 0, 0.2);
end

function setBoxStats(item)
	ClearBoxStats();
	
	local height = 20;
	
	local total_height = 30;
	
	if(item.stats.mass) then
		local WIDGET = Component.CreateWidget("constraintsEntry", STAT_BOX_STATS);
		WIDGET:SetDims("top:0; height:"..(75));
	
		local CLIST = WIDGET:GetChild("constraintList");
			
		for i = CLIST:GetChildCount(), 1, -1 do
			local WIDGET = CLIST:GetChild(i);
			local ICON = WIDGET:GetChild("Icon");
			local STAT = WIDGET:GetChild("stat");
			local VAL = WIDGET:GetChild("value");
			
			
			local stat = "cpu";
			local value = item.stats.cpu;
			local url = "https://market.firefallthegame.com/assets/icon_search_cpu-29db56c5084f7ce61b392ef9ee7c3db9.png";
			if(i==1) then
				stat = "mass";
				value = item.stats.mass;
				url = "https://market.firefallthegame.com/assets/icon_search_weight-03e1481bb017231db3ec9ecd7a3f6b37.png";
			elseif(i==2) then
				stat = "power";
				value = item.stats.power;
				url = "https://market.firefallthegame.com/assets/icon_search_power-7dae1125bb2c7ccfd79e4d0b504cbcc4.png";
			end
			
			if(MarketAttributes[stat]) then
				VAL:SetText(string.format(MarketAttributes[stat].format, value or 0));
				stat = MarketAttributes[stat].name;
			else
				VAL:SetText(round(value, 2));
			end
			
			ICON:SetUrl(url);
			
			STAT:SetText(stat);
			
		end
		
		total_height = total_height + 75;
	end
	
	if(item.expires_at) then
		item.stats["Expires"] = timeCountDown(timeParser(item.expires_at));
	end
	
	for stat,val in pairs(item.stats) do
		if(stat ~= "mass" and stat ~= "power" and stat ~= "cpu") then
			local WIDGET = Component.CreateWidget("statEntry2", STAT_BOX_STATS);
			WIDGET:SetDims("top:0; height:"..height);
			local STAT_TEXT = WIDGET:GetChild("stat");
			local VALUE_TEXT = WIDGET:GetChild("value");
			
			if(stat == "quality") then
				stat = "Quality";
				VALUE_TEXT:SetTextColor(qColor(val));
			end

			if(item.resource_type) then
				if(ResourceStatNames[tostring(item.item_sdb_id)]) then
					stat = ResourceStatNames[tostring(item.item_sdb_id)]["stat"..stat] or "stat"..stat;
					VALUE_TEXT:SetTextColor(qColor(val));
				end
			end
			
			local name = stat.."";
			local format = "";
			if(MarketAttributes[stat]) then
				name = MarketAttributes[stat].name;
				format = MarketAttributes[stat].format;
			end
			
			STAT_TEXT:SetText(name)
			if(type(val)=="number" and MarketAttributes[stat]) then
				if(MarketAttributes[stat].format ~= "") then
					VALUE_TEXT:SetText(string.format(format, val));
				else
					VALUE_TEXT:SetText(round(val, 2));
				end
			else
				VALUE_TEXT:SetText(val)
			end
			
			total_height  = total_height + height + 3;
		end
	end
	STAT_BOX:SetDims("top:0; width:_; height:"..total_height);
	
end

function ClearBoxStats()
	for i = STAT_BOX_STATS:GetChildCount(), 1, -1 do
		Component.RemoveWidget(STAT_BOX_STATS:GetChild(i))
	end
end


----------------------------------------------------------
-- FUNCTIONS
-- -------------------------------------------------------

function ShowMarket()
	marketVisible = true;
	FRAME:Show(true);
	System.BlurMainScene(true);
	DISPATCHER:DispatchEvent("ShowMarket");
end

function HideMarket()
	marketVisible = false;
	FRAME:Hide(true);
	ToolTip.Show(nil);
	System.BlurMainScene(false);
	DISPATCHER:DispatchEvent("HideMarket");
end

----------------------------------------------------------
-- SLASH COMMANDS
-- -------------------------------------------------------

SLASH.toggleMarket = function()
	if(marketVisible) then
		HideMarket()
	else
		ShowMarket()
	end
end
local testing = nil;
local tests = {};
local tested = {};
function testDone(args, err)
	if not err then
		table.insert(tested, testing);
	elseif(err.data.code == "ERR_SEARCH_RATE") then
		callback(nextTest, nil, 5);
		out("Too fast, running again!");
		return nil;
	end
	table.remove(tests, 1);
	out("Testdone: "..#tested.."/"..#tests);
	callback(nextTest, nil, 1);
end

function nextTest()
	local sortstr = tests[1];
	if(sortstr) then
		local url = System.GetOperatorSetting("market_host").."/api/v1/search?query=sort:"..sortstr.internal_name..":asc&page=1&per_page=1";
		if ( HTTP.IsRequestPending(url) ) then
			return;
		end
		testing = {title = sortstr.name, name = sortstr.internal_name, format=sortstr.format};
		HTTP.IssueRequest(url, "GET", nil, testDone);
	else
		log(tostring(tested));
	end
end

SLASH.TEST = function()
	for _,v in pairs(MarketAttributes) do
		table.insert(tests, v);
	end
	nextTest();
end
