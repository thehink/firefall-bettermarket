--
-- Market Addon
--   by: Thehink
--
--[[
TODO:
Add inventory repair pool stats in tooltip
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

local ADDON_NAME = "ARES Texchange";
local ADDON_VERSION = "BETA v0.55";

local FRAME = Component.GetFrame("Main");
local BUY_PAGE = Component.GetWidget("buy_page");
local SELL_PAGE = Component.GetWidget("sell_page");
local TITLE = Component.GetWidget("AddonName");
TITLE:SetText(ADDON_NAME);

local ICON_CRYSTITE = Component.GetWidget("crystite_icon");
local ICON_COUNT = Component.GetWidget("crystite_count");

STAT_BOX = Component.GetWidget("ToolTip");
local STAT_BOX_TITLE = Component.GetWidget("BoxTxt");
local STAT_BOX_STATS = Component.GetWidget("BoxStats");

local HUDNOTE = nil;

DISPATCHER = EventDispatcher.Create();

local SLASH = {};

-- ------------------------------------------
-- MARKET VARIABLES
-- ------------------------------------------

local INGAME_HOST = nil;

local currentCategories = {0};

local ListingsCycle = nil;
local SoldListings = {};

local currentTerminal = "NONE";
local marketIsReady = false;
local is_RequestingListings = false;
local is_RequestingAccess = false;

playerId = nil;
MarketAttributes = nil;
ResourceStatNames = nil;
Authorized = false;


marketVisible = false;
CurrentTab = "";

local SOUNDS = {
	{title="None", name="none"},
	{title="Play_UI_RewardNotification", name="Play_UI_RewardNotification"},
	{title="Play_UI_Beep_01", name="Play_UI_Beep_01"},
	{title="Play_SFX_UI_MissionComplete", name="Play_SFX_UI_MissionComplete"},
	{title="Play_SFX_UI_AchievementEarned", name="Play_SFX_UI_AchievementEarned"},
	{title="Play_UI_MapOpen", name="Play_UI_MapOpen"},
	{title="Play_UI_Garage_PowerUpgrade", name="Play_UI_Garage_PowerUpgrade"},
	{title="Play_SFX_UI_GeneralAnnouncement", name="Play_SFX_UI_GeneralAnnouncement"},
	{title="Play_UI_Garage_MassUpgrade", name="Play_UI_Garage_MassUpgrade"},
	{title="Play_PAX_FirefallSplash_Victory", name="Play_PAX_FirefallSplash_Victory"},
	{title="Play_UI_RewardScreenOpen", name="Play_UI_RewardScreenOpen"},
	{title="Play_UI_RewardsAward", name="Play_UI_RewardsAward"},
	{title="Play_PAX_FirefallSplash_Firefall", name="Play_PAX_FirefallSplash_Firefall"},
	{title="Play_PAX_FirefallSplash_Defeat", name="Play_PAX_FirefallSplash_Defeat"},
};

local TimeZones = {
	{name = "UTC-12:00", hours = -12},
	{name = "UTC-11:00", hours = -11},
	{name = "UTC-10:00", hours = -10},
	{name = "UTC-09:00", hours = -9},
	{name = "UTC-08:00", hours = -8},
	{name = "UTC-07:00", hours = -7},
	{name = "UTC-06:00", hours = -6},
	{name = "UTC-05:00", hours = -5},
	{name = "UTC-04:30", hours = -4.5},
	{name = "UTC-04:00", hours = -4},
	{name = "UTC-03:30", hours = -3.5},
	{name = "UTC-03:00", hours = -3},
	{name = "UTC-02:00", hours = -2},
	{name = "UTC-01:00", hours = -1},
	{name = "UTC+00:00", hours = 0},
	{name = "UTC+01:00", hours = 1},
	{name = "UTC+02:00", hours = 2},
	{name = "UTC+03:00", hours = 3},
	{name = "UTC+03:30", hours = 3.5},
	{name = "UTC+04:00", hours = 4},
	{name = "UTC+04:30", hours = 4.5},
	{name = "UTC+05:00", hours = 5},
	{name = "UTC+05:30", hours = 5.5},
	{name = "UTC+05:45", hours = 5.75},
	{name = "UTC+06:00", hours = 6},
	{name = "UTC+06:30", hours = 6.5},
	{name = "UTC+07:00", hours = 7},
	{name = "UTC+08:00", hours = 8},
	{name = "UTC+09:00", hours = 9},
	{name = "UTC+09:30", hours = 9.5},
	{name = "UTC+10:00", hours = 10},
	{name = "UTC+11:00", hours = 11},
	{name = "UTC+12:00", hours = 12},
	{name = "UTC+13:00", hours = 13},
};

local TEXT_CODES = {
	ERR_INVALID_PRICE_LOW = "Below minimum price of 50 cy.",
	LISTING_FAILED = "Listing failed.";
};

-- ------------------------------------------
-- INTERFACE OPTIONS
-- ------------------------------------------
local onOption = {};
local OptionsLoaded = false;
local io_Enabled = true;
local io_ReplaceDefaultMarket = true;
local io_NotifyOnSold = false;
local io_NotifySFX = "none";
local io_HudNoteOnSold = true;
local io_SystemMsg = false;
local io_CheckFrequency = 10;
io_TimeZone = 0;
io_ListingPriceWarning = 10000;

InterfaceOptions.SaveVersion(1.0)
--InterfaceOptions.NotifyOnDefaults(true);
InterfaceOptions.NotifyOnLoaded(true);

InterfaceOptions.StartGroup({id="REPLACE_DEAFULT_MARKET", label=ADDON_NAME.." - "..ADDON_VERSION, checkbox=true, default=io_ReplaceDefaultMarket})
--InterfaceOptions.AddCheckBox({id="REPLACE_DEAFULT_MARKET", label="Override default market bindings", default=io_ReplaceDefaultMarket});
InterfaceOptions.AddSlider({id="LISTING_PRICE_WARNING", label="Listing price warning threshold", default=io_ListingPriceWarning, min=0, max=99999, inc=1000, suffix="cy"});

InterfaceOptions.AddChoiceMenu({id="TIMEZONE", label="Time Zone", default=io_TimeZone})
for i = 1, #TimeZones do
	InterfaceOptions.AddChoiceEntry({menuId="TIMEZONE", label=TimeZones[i].name, val=TimeZones[i].hours});
end

InterfaceOptions.StopGroup()

InterfaceOptions.StartGroup({id="NOTIFY_ON_SOLD", label="Notifier options", checkbox=true, default=io_NotifyOnSold})
InterfaceOptions.AddCheckBox({id="HUDNOTE_ON_SOLD", label="Create a HudNote when items are sold", default=io_HudNoteOnSold});
InterfaceOptions.AddCheckBox({id="NOTIFY_MSG", label="Show a message for each item sold", default=io_SystemMsg});
InterfaceOptions.AddSlider({id="LISTINGS_CHECK_FREQUENCY", label="Listings check frequency.", default=io_CheckFrequency, min=60, max=500, inc=1, suffix="s"});

InterfaceOptions.AddChoiceMenu({id="SOLD_SOUND", label="Sold sound FX", default=io_NotifySFX})
for i = 1, #SOUNDS do
	InterfaceOptions.AddChoiceEntry({menuId="SOLD_SOUND", label=SOUNDS[i].title, val=SOUNDS[i].name});
end

InterfaceOptions.StopGroup()


-- ------------------------------------------
-- OPTION CHANGE CALLBACKS
-- ------------------------------------------

onOption.__LOADED = function(val)
	OptionsLoaded = true;
end

onOption.TIMEZONE = function(val)
	io_TimeZone = val;
end

onOption.SOLD_SOUND = function(val)
	io_NotifySFX = val;
	if(OptionsLoaded and io_NotifySFX ~= "none") then
		System.PlaySound(io_NotifySFX);
	end
end

onOption.LISTINGS_CHECK_FREQUENCY = function(val)
	io_CheckFrequency = val;
	if(ListingsCycle.CB2:Pending()) then
		ListingsCycle:Stop();
		ListingsCycle.start_time = System.GetClientTime();
		ListingsCycle.CB2:Bind(function()
			ListingsCycle.func();
			if (not len or System.GetElapsedTime(ListingsCycle.start_time) < len) then
				ListingsCycle.CB2:Reschedule(io_CheckFrequency);
			end
		end);
		ListingsCycle.CB2:Schedule(io_CheckFrequency);
	end
end

onOption.REPLACE_DEAFULT_MARKET = function(val)
	io_ReplaceDefaultMarket = val;
end

onOption.NOTIFY_ON_SOLD = function(val)
	io_NotifyOnSold = val;
	if(io_NotifyOnSold) then
		RequestAccess();
		ListingsCycle:Run(io_CheckFrequency);
	else
		ListingsCycle:Stop();
	end
end

onOption.HUDNOTE_ON_SOLD = function(val)
	io_HudNoteOnSold = val;
end

onOption.NOTIFY_MSG = function(val)
	io_SystemMsg = val;
end

onOption.LISTING_PRICE_WARNING = function(val)
	io_ListingPriceWarning = val;
end

-- EVENTS

function OnComponentLoad()
	InterfaceOptions.SetCallbackFunc(OnOptionChange, ADDON_NAME);
	LIB_SLASH.BindCallback({slash_list = "market,ma", description = "Opens "..ADDON_NAME, func = SLASH.toggleMarket});
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
	if not marketIsReady then
		Market.Toggle(true);
	end
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
	if not marketIsReady and Player.IsReady() and MarketAttributes and Authorized then
		MarketApi.GetMyListings(OnGetMyListings);
		marketIsReady = true;
		OnMarketReady();
		--WebCache.Subscribe(System.GetOperatorSetting("market_host").."/api/v1/my_listings", OnGetMyListings);
		--ListingsCycle:Run(60);
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
	DISPATCHER:DispatchEvent("OnResolutionChanged");
		--BUY_PAGE:SetDims("center-x: 50%; top:60; height:90%; width: 100%;");
		--SELL_PAGE:SetDims("center-x: 50%; top:60; height:90%; width: 100%;");
end

function OnExitZone()
	Authorized = false;
	HideMarket();
end

function OnStreamProgress()
	if(Game.GetLoadingProgress() == 1) then
		RequestAccess();
	end
end

function OnShowWebUI(args)
	if(args.panel == "marketplace" and io_ReplaceDefaultMarket) then
		Component.GenerateEvent("MY_WEBUI_TOGGLE", {show=false});
	else
		--HideMarket();
	end
end

function OnTerminalAuthorized(args)
	--out(currentTerminal .. " => " .. args.terminal_type);

	if(args.terminal_type == "PLAYER_MARKET" and io_ReplaceDefaultMarket) then
		Authorized = true;
		
		if not is_RequestingAccess then
			if(marketIsReady) then
				ShowMarket();
			else
				CheckMarketReady();
			end
		else
			is_RequestingAccess = false;
		end
	else
		Authorized = false;
		HideMarket();
		if(currentTerminal ~= "PLAYER_MARKET" and args.terminal_type == "NONE" and io_NotifyOnSold) then
			RequestAccess();
		end
	end
	
	currentTerminal = args.terminal_type;
end

----------------------------------------------------------
-- MARKET RESPONSE
-- -------------------------------------------------------

function OnGetMyListings(args, err)
	is_RequestingListings = false;
	if not err and io_NotifyOnSold then
		SELLPAGE.listings = args;
		local listings = {};
		for _,listing in pairs(args) do
			if not SoldListings[listing.id] and listing.purchased then
				if(io_SystemMsg) then
					out("You have sold "..listing.quantity.." "..listing.title.." for "..listing.price_cy.."cy");
				end
				SoldListings[listing.id] = true;
				table.insert(listings, listing);
			end
		end
		if(#listings > 0 and io_HudNoteOnSold) then
			NotifySoldListing(listings);
		end
	end
end

----------------------------------------------------------
-- MARKET FUNCTIONS
-- -------------------------------------------------------

function GetMyListings()
	if Authorized and marketIsReady then
		MarketApi.GetMyListings(OnGetMyListings);
	end
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

function CancelListing(args)
	
end

function ReapListing(args)
	
end

function ListItem(args)
	
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
	
	
	local Tabs = {
		{"buy_tab", SetBuyPage},
		{"sell_tab", SetSellPage},
	};
	
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
	DISPATCHER:DispatchEvent("OnBuyPage");
end

function SetSellPage()
	local BUY_PAGE_BTN = Component.GetWidget("buy_tab");
	local SELL_PAGE_BTN = Component.GetWidget("sell_tab");
	
	SELL_PAGE_BTN:GetChild("bgbtn"):ParamTo("tint", "#11AAFF", 0.15);
	BUY_PAGE_BTN:GetChild("bgbtn"):ParamTo("tint", "#111111", 0.15);
	
	CurrentTab = "sell_tab";
	BUY_PAGE:Hide(true);
	SELL_PAGE:Show(true);
	SELLPAGE.W_SEARCH_INPUT:SetFocus();
	DISPATCHER:DispatchEvent("OnSellPage");
end

function UpdateCurrencyCount()
	ICON_COUNT:SetText(comma_value(Player.GetItemCount(10)));
end

----------------------------------------------------------
-- MARKET
-- -------------------------------------------------------

function OnSelectAction(args)
	if(args ~= "nothing") then
		args.WIDGET:SetSelectedByIndex(1);
		if(args.action == "cancel") then
			MarketApi.Cancel(args.listing, function(resp, err) SELLPAGE.OnItemCanceled(args, err); end);
			args.WIDGET:Disable(true);
			args.WIDGET.TEXT:SetText("Canceling");
		elseif(args.action == "reap") then
			MarketApi.Claim(args.listing, function(resp, err) SELLPAGE.OnItemReaped(args, err); end);
			args.WIDGET:Disable(true);
			args.WIDGET.TEXT:SetText("Claiming");
		elseif(args.action == "reap_list_again") then
			MarketApi.Claim(args.listing, function(resp, err) SELLPAGE.OnItemReaped(args, err); end);
			args.WIDGET:Disable(true);
			args.WIDGET.TEXT:SetText("Claiming");
			SELLPAGE.SearchAndSelectItem(args.listing);
		elseif(args.action == "list_more") then
			SELLPAGE.SearchAndSelectItem(args.listing);
			SetSellPage();
		elseif(args.action == "relist") then
			SELLPAGE.selectItemOnInventoryChange = args.listing;
			MarketApi.Cancel(args.listing, function(resp, err) SELLPAGE.OnItemCanceled(args, err); end);
			args.WIDGET:Disable(true);
			args.WIDGET.TEXT:SetText("Canceling");
		elseif(args.action == "buy_item") then
			BUYPAGE.ShowBuyConfirmation(args.WIDGET, args.listing);
		end
	end
end

----------------------------------------------------------
-- HUD Note
----------------------------------------------------------

function NotifySoldListing(listings)
	RemoveHudNote();
	HUDNOTE = HudNote.Create();
	HUDNOTE:SetTitle("You have "..#listings.." new sold item(s)");
	HUDNOTE:SetIconTexture("icons", "business");
	HUDNOTE:SetDescription("Show my listings?");

	HUDNOTE:SetTags({"mission"})
	HUDNOTE:SetPrompt(1, Component.LookupText("LOBBY_NOTE_PROMPT_SHOW"), function()
		SetSellPage();
		Market.Toggle(true);
		HUDNOTE:Remove();
	end);
	HUDNOTE:SetPrompt(2, "No", RemoveHudNote);
	HUDNOTE:SetTimeout(120, RemoveHudNote);
	HUDNOTE:Post();
	
	if(io_NotifySFX ~= "none") then
		System.PlaySound(io_NotifySFX);
	end
end

function RemoveHudNote()
	if(HUDNOTE and HUDNOTE.Remove) then
		HUDNOTE:Remove();
		HUDNOTE = nil;
	end
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
	
	item.stats["Prestige"] = item.prestige;
	
	local stats = {};
	
	for stat,val in pairs(item.stats) do
		table.insert(stats, {
			stat = stat,
			val = val,
		});
	end
	
	table.sort(stats, function(a, b) 
		if(tonumber(a.stat) > 0 and tonumber(b.stat) == 0) then
			return true;
		elseif(tonumber(a.stat) > 0 and tonumber(b.stat) > 0) then
			return a.val < b.val;
		elseif(tonumber(a.stat) == 0 and tonumber(b.stat) == 0) then
			return a.stat < b.stat;
		end
	end);
	
	
	
	for i,v in ipairs(stats) do
		local stat = v.stat;
		local val = v.val;
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
				if(ResourceStatNames[tostring(item.item_sdb_id)] and ResourceStatNames[tostring(item.item_sdb_id)]["stat"..stat]) then
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
function RequestAccess()
	if(not Authorized and marketIsReady) then
		is_RequestingAccess = true;
		Market.Toggle(true);
	end
end


function ShowMarket()
	if not marketVisible then
		marketVisible = true;
		FRAME:Show(true);
		System.BlurMainScene(true);
		DISPATCHER:DispatchEvent("ShowMarket");
	end
end

function HideMarket()
	if(marketVisible) then
		marketVisible = false;
		FRAME:Hide(true);
		Tooltip.Show(nil);
		System.BlurMainScene(false);
		DISPATCHER:DispatchEvent("HideMarket");
	end
end

----------------------------------------------------------
-- SLASH COMMANDS
-- -------------------------------------------------------

SLASH.toggleMarket = function()
	if(marketVisible) then
		HideMarket()
	else
		if Authorized then
			ShowMarket();
		else
			Market.Toggle(true);
		end
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
