SELLPAGE = {
	W_CATEGORIES = Component.GetWidget("InventoryCategories"),
	f_SORT = {},
	f_FILTER = {},
	selectedCategory = 1,
	W_INVENTORY = Component.GetWidget("inventoryItems"),
	W_SEARCH_INPUT = Component.GetWidget("InventorySearch"),
	INVENTORY_SCROLLER = nil,
	Count = 1,
	cb_InputTimeout = nil,
	listings = {},
	rarities = {
		legendary = 5,
		epic = 4,
		rare = 3,
		uncommon = 2,
		common = 1,
		salvage = 0,
	},
	selectedItem = nil,
	W_LIST_BTN = Component.GetWidget("list_button"),
	W_LIST_ERROR = Component.GetWidget("ListingError"),
	W_PPU_INPUT = Component.GetWidget("PPUInput"),
	W_QUANTITY_INPUT = Component.GetWidget("QuantityInput"),
	W_PRICE_INPUT = Component.GetWidget("PriceInput"),
	W_PROFIT_INPUT = Component.GetWidget("ProfitInput"),
	cb_ListingStatus = nil,
	selectItemOnInventoryChange = nil,
	cb_InventoryUpdate = nil,
	InventoryDirty = nil,
};

local BP_ROW = [[
<Group name="row" dimensions="width:100%; height:60;">
	<Border name="bg" dimensions="height:100%-4; width:100%-10;" class="BlueBackDrop" style="tint:#00FF00; alpha: 0.2"/>
	<Border dimensions="height:100%-6; width:100%-12; center-x:50%; center-y: 50%;" class="BlueBackDrop" style="tint:#000000; alpha: 0.5"/>
</Group>
]]


SELLPAGE.categories = {
	--{name = "All", sort = "Default"},
	{name = "Resources", sort = "NameAndQuality", filters={"Resources"}},
	{name = "Raw Resources", sort = "NameAndQuality", filters={"RawResources"}},
	{name = "New You", sort = "Quality", filters={"NewYou"}},
	{name = "Packaged", sort = "QualityAndName", filters={"Packaged"}},
	{name = "Crafted Gear", sort = "NameAndQuality", filters={"CraftedGear"}},
	{name = "Looted Gear", sort = "NameAndQuality", filters={"LootedGear"}},
	{name = "Components", sort = "NameAndQuality", filters={"CraftingComponents"}},
	{name = "Bag", sort = "QualityAndName", filters={"Bag"}},
	{name = "Other", sort = "Quality", filters={"Cache"}},
	{name = "All", sort = "NameAndQuality"},
};

SELLPAGE_UpdateInventory = function() SELLPAGE.UpdateDisplayInventory(); end;
SELLPAGE_OnEnterSearchText = function() SELLPAGE.OnEnterSearchText(); end;

function SELLPAGE.initSellPage()
	DISPATCHER:AddHandler("ShowMarket", SELLPAGE.OnShowMarket);
	DISPATCHER:AddHandler("OnReady", SELLPAGE.OnReady);
	DISPATCHER:AddHandler("OnMarketListingComplete", SELLPAGE.OnMarketListingComplete);
	DISPATCHER:AddHandler("OnInventoryChanged", SELLPAGE.OnInventoryChanged);
	DISPATCHER:AddHandler("OnSellPage", SELLPAGE.OnSetSellPage);

	SELLPAGE.InitListings();
	SELLPAGE.InitInventory();
	SELLPAGE.initCategories();
	SELLPAGE.InitListForm();
end

function SELLPAGE.OnReady()
	SELLPAGE.UpdateInventory();
	SELLPAGE.selectCategory(1);
	SELLPAGE.UpdateListings();
	DISPATCHER:AddHandler("OnResolutionChanged", SELLPAGE.OnResolutionChanged);
end

function SELLPAGE.OnSetSellPage()
	SELLPAGE.UpdateListingDisplay();
end

function SELLPAGE.OnMarketListingComplete(args)
	MarketApi.OnMarketListingComplete(args);
end

function SELLPAGE.OnInventoryChanged(args)
	if(SELLPAGE.selectItemOnInventoryChange) then
		if(args.guid and tonumber(args.guid) == tonumber(SELLPAGE.selectItemOnInventoryChange.item_guid) or
		   tonumber(args.sdb_id) == tonumber(SELLPAGE.selectItemOnInventoryChange.item_sdb_id) or
		   args.minerals_changed and SELLPAGE.selectItemOnInventoryChange.resource_type) then
			SELLPAGE.selectItemOnInventoryChange.inInventory = true;
		end
	end

	if(marketVisible) then
		if(SELLPAGE.cb_InventoryUpdate) then
			cancel_callback(SELLPAGE.cb_InventoryUpdate);
			SELLPAGE.cb_InventoryUpdate = nil;
		end
		
		if(SELLPAGE.selectItemOnInventoryChange and SELLPAGE.selectItemOnInventoryChange.inInventory) then
			SELLPAGE.UpdateInventory();
			SELLPAGE.SearchAndSelectItem(SELLPAGE.selectItemOnInventoryChange);
			SELLPAGE.selectItemOnInventoryChange = nil;
			SetSellPage();
		else
			SELLPAGE.cb_InventoryUpdate = callback(function()
				SELLPAGE.UpdateInventory();
			end, nil, 2.0);
		end
	else
		SELLPAGE.InventoryDirty = true;
	end
end

function SELLPAGE.OnResolutionChanged()
	callback(function()
		SELLPAGE.w_TABLE:ReorderHeader();
		SELLPAGE.INVENTORY_SCROLLER:UpdateSize();
		SELLPAGE.w_TABLE:UpdateSize();
	end, nil, 0.1);
end

-- ------------------------------------------
-- Events
-- ------------------------------------------

function SELLPAGE.OnShowMarket()
	if(SELLPAGE.InventoryDirty) then
		SELLPAGE.UpdateInventory();
		SELLPAGE.InventoryDirty = false;
	end
end

function SELLPAGE.OnItemListed(args, err)
	if not err then
		--SELLPAGE.UpdateListings();
		SELLPAGE.AddListingRow(args, true);
		SELLPAGE.SetListingStatus("Listed Successfully!", "#00FF00");
		--out("Success Error");
	else
		--out("Listing Error: "..err.error_code);
		SELLPAGE.SetListingStatus("Error: "..LookupText(err.error_code), "#FF0000");
	end
end

function SELLPAGE.OnItemCanceled(args, err)
	if not err then
		SELLPAGE.RemoveListingRow(args.listing.id);
	else
		--todo
		--better error handling
	end
end

function SELLPAGE.OnItemReaped(args, err)
	if not err then
		SELLPAGE.RemoveListingRow(args.listing.id);
	else
		--todo
		--better error handling
	end
end

-- ------------------------------------------
-- Inventory Categories
-- ------------------------------------------

function SELLPAGE.initCategories()
	for i,cat in ipairs(SELLPAGE.categories) do
		local WIDGET = Component.CreateWidget("InventoryCategory", SELLPAGE.W_CATEGORIES);
		WIDGET:SetDims("width:100%; height:30;");
		local BUTTON = WIDGET:GetChild("categoryBtn");
		BUTTON:GetChild("title"):SetText(cat.name);
		
		BUTTON:BindEvent("OnMouseDown", function()
			SELLPAGE.selectCategory(i);
		end);
		local CBTN2 = BUTTON:GetChild("bg");
		BUTTON:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("tint", "#11AAFF", 0.15); end);
		BUTTON:BindEvent("OnMouseLeave", function() if(SELLPAGE.selectedCategory ~= i) then CBTN2:ParamTo("tint", "#111111", 0.15); end; end);
	end
end

function SELLPAGE.selectCategory(index)
	local cat = SELLPAGE.categories[index];
	if(cat) then
		local prevButton = SELLPAGE.W_CATEGORIES:GetChild(SELLPAGE.selectedCategory):GetChild("categoryBtn.bg");
		local newButton = SELLPAGE.W_CATEGORIES:GetChild(index):GetChild("categoryBtn.bg");
		prevButton:ParamTo("tint", "#111111", 0.15);
		newButton:ParamTo("tint", "#11AAFF", 0.15);
	end
	SELLPAGE.selectedCategory = index;
	SELLPAGE.UpdateDisplayInventory();
end

--Sort Functions
function SELLPAGE.f_SORT.Default(a, b)
	return a.name < b.name;
end

function SELLPAGE.f_SORT.Quality(a, b)
	return a.quality and b.quality and a.quality > b.quality or SELLPAGE.rarities[a.rarity] > SELLPAGE.rarities[b.rarity];
end

function SELLPAGE.f_SORT.NameAndQuality(a, b)
	if(a.name < b.name) then
		return true;
	elseif(a.name == b.name) then
		return a.quality and b.quality and a.quality > b.quality or SELLPAGE.rarities[a.rarity] > SELLPAGE.rarities[b.rarity];
	end
end

function SELLPAGE.f_SORT.QualityAndName(a, b)
	if(a.quality and b.quality and a.quality > b.quality or SELLPAGE.rarities[a.rarity] > SELLPAGE.rarities[b.rarity]) then
		return true;
	elseif(a.quality and b.quality and a.quality == b.quality or not (a.quality and b.quality) and a.rarity == b.rarity) then
		return a.name < b.name;
	end
end

--Filter Functions
function SELLPAGE.f_FILTER.All(item)
	return true;
end

function SELLPAGE.f_FILTER.Resources(item)
	return item.is_resource and item.is_refined;
end

function SELLPAGE.f_FILTER.RawResources(item)
	return item.is_resource and item.is_raw;
end

function SELLPAGE.f_FILTER.NewYou(item)
	return string.find(item.name, "New You Unlock:");
end

function SELLPAGE.f_FILTER.Packaged(item)
	return string.find(item.name, "Packaged");
end

function SELLPAGE.f_FILTER.CraftedGear(item)
	return item.repair_pool and item.repair_pool > 0;
end

function SELLPAGE.f_FILTER.LootedGear(item)
	return item.repair_pool and item.durability and item.repair_pool == 0;
end

function SELLPAGE.f_FILTER.CraftingComponents(item)
	return item.sub_inventory == "crafting";
end

function SELLPAGE.f_FILTER.Cache(item)
	return item.sub_inventory == "cache" and not string.find(item.name, "New You Unlock:") and not string.find(item.name, "Packaged ");
end

function SELLPAGE.f_FILTER.Bag(item)
	return item.sub_inventory == "bag";
end

-- ------------------------------------------
-- Inventory Listings
-- ------------------------------------------

function SELLPAGE.InitInventory()
	if(SELLPAGE.INVENTORY_SCROLLER) then
		SELLPAGE.INVENTORY_SCROLLER:Destroy();
		SELLPAGE.INVENTORY_SCROLLER = nil;
	end
	
	SELLPAGE.INVENTORY_SCROLLER = RowScroller.Create(SELLPAGE.W_INVENTORY);
	SELLPAGE.INVENTORY_SCROLLER:SetSlider(RowScroller.SLIDER_DEFAULT);
end

function SELLPAGE.OnEnterSearchText()
	local txt = SELLPAGE.W_SEARCH_INPUT:GetText();
	if(SELLPAGE.cb_InputTimeout) then
		cancel_callback(SELLPAGE.cb_InputTimeout);
		SELLPAGE.cb_InputTimeout = nil;
	end
	
	SELLPAGE.cb_InputTimeout = callback(SELLPAGE.UpdateDisplayInventory, nil, 0.3);
end

function SELLPAGE.UpdateDisplayInventory()
	--out("Update inventory");
	--SELLPAGE.INVENTORY_SCROLLER:Reset();
	SELLPAGE.InitInventory();

	local items = {};
	
	for _,v in pairs(SELLPAGE.items) do
		table.insert(items, v);
	end
	
	for _,v in pairs(SELLPAGE.resources) do
		table.insert(items, v);
	end
	
	local search_txt = SELLPAGE.W_SEARCH_INPUT:GetText();
	
	local cat = SELLPAGE.categories[SELLPAGE.selectedCategory];
	
	if(SELLPAGE.f_SORT[cat.sort]) then
		table.sort(items, SELLPAGE.f_SORT[cat.sort]);
	end
	
	for _, item in ipairs(items) do
		if(item.flags.is_tradable and item.quantity > 0 and (#search_txt == 0 or string.find(item.name:lower(), search_txt:lower()))) then
			local add = true;
			if(cat.filters) then
				for _, filter in ipairs(SELLPAGE.categories[SELLPAGE.selectedCategory].filters) do
					if(add and SELLPAGE.f_FILTER[filter] and not SELLPAGE.f_FILTER[filter](item)) then
						add = false;
						break;
					end
				end
			end
			if add then
				local ROW = SELLPAGE.INVENTORY_SCROLLER:AddRow(tonumber("43543"..SELLPAGE.Count));
				SELLPAGE.Count = SELLPAGE.Count + 1;
				local WIDGET = Component.CreateWidget([[
				<Group name="row" dimensions="width:100%; height:20;" style="cursor:sys_hand">
					<Border name="bg" dimensions="dock:fill" class="BlueBackDrop"  style="alpha:0.0; padding:5;" />
					<Text name="title" key="{My Listings}" dimensions="left:0; width:100%-50; height:20;" style="font:Demi_11; clip:true; halign:left; valign:center; shadow:1; color:#00AA00" />
					<Text name="quantity" key="{Quantity}" dimensions="left:100%-50; width:50; height:20;" style="font:Narrow_11; halign:right; valign:center; shadow:1; color:#AAAAAA" />
				</Group>
				]], ROW.SCROLLER.HIDDEN_FOSTER);
				--WIDGET:SetText(item.name);
				
				if(item.quality and not string.find(item.name, "CY") and not string.find(item.name, "Q")) then
					item.name = item.name.."^Q";
				end
				
				LIB_ITEMS.GetNameTextFormat({
					name = item.name,
					rarity = item.rarity,
				}, {quality=item.quality}):ApplyTo(WIDGET:GetChild("title"));
				WIDGET:GetChild("quantity"):SetText("x"..item.quantity);
				
				ROW:AddHandler("OnMouseEnter", function() 
					setBoxStats(SELLPAGE.FormatItemToMarketListing(item));
					Tooltip.Show(STAT_BOX);
					WIDGET:GetChild("bg"):ParamTo("alpha", 1.0, 0.15);
				end);
				ROW:AddHandler("OnMouseLeave", function()
					Tooltip.Show(nil);
					WIDGET:GetChild("bg"):ParamTo("alpha", 0, 0.15);
				end);
				
				ROW:AddHandler("OnMouseUp", function()
					SELLPAGE.SelectItem(item);
				end);
				
				ROW:SetWidget(WIDGET);
				ROW:UpdateSize({height=20});
			end
		end
	end
end

function SELLPAGE.UpdateInventory()
	SELLPAGE.items, SELLPAGE.resources = Player.GetInventory();
	SELLPAGE.resources = SELLPAGE.FormatResources(SELLPAGE.resources);
	SELLPAGE.UpdateDisplayInventory();
end

function SELLPAGE.FormatResources(resources)
	local stacks = {};
	for _,v in pairs(resources) do
		if(v.refined and v.refined.stacks) then
			for _,stack in pairs(v.refined.stacks) do
				if(stack.quantity > 0) then
					stack.name = v.refined.name;
					stack.flags = {is_tradable = true};
					stack.is_resource = true;
					stack.is_refined = true;
					stack.item_sdb_id = v.refined.item_sdb_id;
					table.insert(stacks, stack);
				end
			end
		end
		
		if(v.raw and v.raw.stacks) then
			for _,stack in pairs(v.raw.stacks) do
				if(stack.quantity > 0) then
					stack.name = v.raw.name;
					stack.is_raw = true;
					stack.flags = {is_tradable = true};
					stack.is_resource = true;
					stack.item_sdb_id = v.raw.item_sdb_id;
					table.insert(stacks, stack);
				end
			end
		end
	end
	return stacks;
end


function SELLPAGE.FormatItemToMarketListing(item)
	local listing = {
		item_sdb_id = item.item_sdb_id,
		title = item.name,
		rarity = item.rarity,
		resource_type = item.resource_type,
		stats = {},
	}
	
	listing.stats.quality = item.quality or 0;
	listing.stats.repair_pool = item.repair_pool;
	
	if(item.attributes) then
		for _, attribute in ipairs(item.attributes) do
			if(attribute.format ~= "") then 
				listing.stats[attribute.display_name] = string.format(attribute.format, attribute.value);
			else
				listing.stats[attribute.display_name] = attribute.value;
			end
		end
	end
	if(item.constraints) then
		for constrain, value in pairs(item.constraints) do
			listing.stats[constrain] = value;
		end
	end
	return listing;
end

-- ------------------------------------------
-- My Listings
-- ------------------------------------------

function SELLPAGE.InitListings()
	SELLPAGE.w_TABLE = Table.Create(Component.GetWidget("listingsTable"));
	local HeaderData = {
		{title="Type", name="item_sdb_id", blueprint="type", width=70},
		{title="Title",  name="title.en", blueprint="title", width=350},
		--{title="Quality",  name="quality", blueprint="quality", width=90},
		{title="Quantity",  name="quantity", width=100},
		{title="Price",  name="price_cy", blueprint="price_cy", width=90},
		{title="PPU",  name="price_per_unit", blueprint="price_per_unit", width=90},
		{title="Expires",  name="expires_at", blueprint="expires_at", width=150},
		{title="Action",  name="action_btn", blueprint="buy_btn", width=120, align="right"},
	}
	SELLPAGE.w_TABLE:SetHeaders(HeaderData);
	
	local BTN = Component.GetWidget("claim_all_listings_btn");
	BTN:BindEvent("OnMouseEnter", function() BTN:GetChild("icon"):ParamTo("exposure", 0.5, 0.15);  Tooltip.Show("Claim all sold listings"); end);
	BTN:BindEvent("OnMouseLeave", function() BTN:GetChild("icon"):ParamTo("exposure", -0.2, 0.15);  Tooltip.Show(nil); end);
	BTN:BindEvent("OnMouseUp", function() SELLPAGE.ClaimAll(); end);
	
	local BTN1 = Component.GetWidget("refresh_listings_btn");
	BTN1:BindEvent("OnMouseEnter", function() BTN1:GetChild("icon"):ParamTo("exposure", 0.5, 0.15);  Tooltip.Show("Refresh listings"); end);
	BTN1:BindEvent("OnMouseLeave", function() BTN1:GetChild("icon"):ParamTo("exposure", -0.2, 0.15); Tooltip.Show(nil); end);
	BTN1:BindEvent("OnMouseUp", function() SELLPAGE.UpdateListings(); end);
end

function SELLPAGE.IsListingMine(id)
	for _,listing in ipairs(SELLPAGE.listings) do
		if(listing.id == id) then
			return true;
		end
	end
	return false;
end

function SELLPAGE.ClaimAll()
	for _,listing in ipairs(SELLPAGE.listings) do
		if(listing.purchased) then
			MarketApi.Claim(listing, function()
				SELLPAGE.RemoveListingRow(listing.id);
			end);
		end
	end
end

function SELLPAGE.UpdateListings()
	--GetMyListings();
	Component.GetWidget("refresh_listings_btn"):GetChild("icon"):ParamTo("tint", "#00AAFF", 0.15);
	MarketApi.GetMyListings(SELLPAGE.OnGetListings);
end

function SELLPAGE.OnGetListings(resp, err)
	Component.GetWidget("refresh_listings_btn"):GetChild("icon"):ParamTo("tint", "#FFFFFF", 0.15);
	if(err) then
		
	else
		SELLPAGE.listings = resp;
		SELLPAGE.UpdateListingDisplay();
	end
end

function SELLPAGE.UpdateListingDisplay()
	SELLPAGE.UpdateListingsTitle();
	SELLPAGE.w_TABLE:ClearRows();
	for _,listing in ipairs(SELLPAGE.listings) do
		SELLPAGE.AddListingRow(listing);
	end
end

function SELLPAGE.UpdateListingsTitle()
	Component.GetWidget("myListingsTitle"):SetText("My Listings ("..#SELLPAGE.listings.." slots used)");
end

function SELLPAGE.AddListingRow(listing, add)
	if(add) then
		table.insert(SELLPAGE.listings, listing);
	end

	local rowData = {
		default = listing,
		item_sdb_id = listing,
		["title.en"] = listing,
		price_cy = listing.price_cy,
		price_per_unit = listing,
		quantity = listing.quantity,
		expires_at = listing.expires_at,
		action_btn = listing,
	};
	
	for k, v in pairs(listing.stats) do
		rowData[k] = v;
	end
	
	local ROW = SELLPAGE.w_TABLE:AddRow({height=60, vpadding = 0}, rowData, BP_ROW);
	ROW.WIDGET:GetChild("bg"):SetParam("tint", qColor(listing.rarity));
	
	ROW.ROW:AddHandler("OnMouseEnter", function() setBoxStats(listing); Tooltip.Show(STAT_BOX); end);
	ROW.ROW:AddHandler("OnMouseLeave", function() Tooltip.Show(nil); end);
	
	SELLPAGE.UpdateListingsTitle();
end

function SELLPAGE.RemoveListingRow(id)
	
	for i, listing in ipairs(SELLPAGE.listings) do
		if(listing.id == id) then
			table.remove(SELLPAGE.listings, i);
		end
	end

	for _,GROUP in ipairs(SELLPAGE.w_TABLE.ROWS) do
		if(GROUP and GROUP.data and GROUP.data.default.id == id) then
			GROUP:Remove();
		end
	end
	SELLPAGE.UpdateListingsTitle();
end

-- ------------------------------------------
-- List Form
-- ------------------------------------------

function SELLPAGE.ShowListingConfirmation(sellData)
	local BOX = ModalBox.Create("buyConfirmation",
	{
		{title = "List", align = "center", color="#00FF00", func = SELLPAGE.ListItem, args = sellData},
		{title = "Cancel", align = "center", color="#FF0000"}
	});
	
	BOX:SetDims({width=400, height=230});
	
	BOX:SetTitle("Listing Confirmation!");
	local ITEM = BOX.FOSTER_WIDGET:GetChild("item");
	
	local ItemInfo = Game.GetItemInfoByType(sellData.item.item_sdb_id);
	
	local icon = ITEM:GetChild("icon");
	icon:SetUrl(ItemInfo.web_icon);
	
	local label = ITEM:GetChild("label");
	
	LIB_ITEMS.GetNameTextFormat({
		name = sellData.item.name,
		rarity = sellData.item.rarity,
	}, {quality=sellData.item.quality}):ApplyTo(label);
	
	--label:SetText(sellData.item.name);
	--label:SetTextColor(qColor(sellData.item.rarity));
	
	local desc = BOX.FOSTER_WIDGET:GetChild("description_text");
	desc:SetText("This confirmation is shown because the listing fee exceeds "..io_ListingPriceWarning.."cy.");
	desc:SetTextColor("#CC3232");
	
	local Cy = BOX.FOSTER_WIDGET:GetChild("crystite");
	local CyPPU = BOX.FOSTER_WIDGET:GetChild("cy_ppu");
	local CyDelta = BOX.FOSTER_WIDGET:GetChild("cy_delta");
	local CyLeft = BOX.FOSTER_WIDGET:GetChild("cy_left");
	
	local ListingFee = MarketApi.GetListingFee(sellData.price);
	
	local CYCount = Player.GetItemCount(10);
	Cy:SetText(comma_value(CYCount));
	CyPPU:SetText("Listing fee");
	CyDelta:SetText("-"..comma_value(tostring(ListingFee)));
	CyLeft:SetText(comma_value(CYCount-ListingFee));

	ITEM:BindEvent("OnMouseEnter", function() setBoxStats(SELLPAGE.FormatItemToMarketListing(sellData.item)); Tooltip.Show(STAT_BOX); end);
	ITEM:BindEvent("OnMouseLeave", function() Tooltip.Show(nil); end);
end

function SELLPAGE.InitListForm()
	local LIST_BTN = SELLPAGE.W_LIST_BTN;
	SELLPAGE.LIST_BTN_PLATE = HoloPlate.Create(LIST_BTN:GetChild("skin"));
	local PLATE = SELLPAGE.LIST_BTN_PLATE;
	
	LIST_BTN:BindEvent("OnMouseEnter", function()
		PLATE.INNER:ParamTo("exposure", -0.1, 0.1);
		PLATE.SHADE:ParamTo("exposure", -0.4, 0.1);
	end);
	LIST_BTN:BindEvent("OnMouseLeave", function()
		PLATE.INNER:ParamTo("exposure", -0.3, 0.1);
		PLATE.SHADE:ParamTo("exposure", -0.6, 0.1);
	end);
	
	LIST_BTN:BindEvent("OnMouseDown", function()
		PLATE.INNER:ParamTo("exposure", -0.3, 0.1);
		PLATE.SHADE:ParamTo("exposure", -0.8, 0.1);
	end)
	LIST_BTN:BindEvent("OnMouseUp", function()
		PLATE.INNER:ParamTo("exposure", -0.1, 0.1);
		PLATE.SHADE:ParamTo("exposure", -0.4, 0.1);
		if(SELLPAGE.selectedItem) then
			local sellData = {
				 price = tonumber(SELLPAGE.W_PRICE_INPUT:GetText()),
				 quantity = tonumber(SELLPAGE.W_QUANTITY_INPUT:GetText()),
				 item = SELLPAGE.selectedItem,
			 };
			 local listingFee = MarketApi.GetListingFee(sellData.price);
			if(listingFee >= io_ListingPriceWarning) then
				SELLPAGE.ShowListingConfirmation(sellData);
			else
				SELLPAGE.ListItem(sellData);
			end
		end
	end)
	
	PLATE:SetColor("#00FF00");
	
	local SIMILAR_BTN = Component.GetWidget("check_similar_button");
	local SIM_PLATE = HoloPlate.Create(SIMILAR_BTN:GetChild("skin"));
	
	SIM_PLATE:SetColor("#0E7192");
	
	SIMILAR_BTN:BindEvent("OnMouseEnter", function()
		SIM_PLATE.INNER:ParamTo("exposure", -0.1, 0.1);
		SIM_PLATE.SHADE:ParamTo("exposure", -0.4, 0.1);
	end);
	SIMILAR_BTN:BindEvent("OnMouseLeave", function()
		SIM_PLATE.INNER:ParamTo("exposure", -0.3, 0.1);
		SIM_PLATE.SHADE:ParamTo("exposure", -0.6, 0.1);
	end);
	
	SIMILAR_BTN:BindEvent("OnMouseDown", function()
		SIM_PLATE.INNER:ParamTo("exposure", -0.3, 0.1);
		SIM_PLATE.SHADE:ParamTo("exposure", -0.8, 0.1);
	end)
	SIMILAR_BTN:BindEvent("OnMouseUp", function()
		SIM_PLATE.INNER:ParamTo("exposure", -0.1, 0.1);
		SIM_PLATE.SHADE:ParamTo("exposure", -0.4, 0.1);
		if(SELLPAGE.selectedItem) then
			BUYPAGE.SearchForSimilarItems(SELLPAGE.FormatItemToMarketListing(SELLPAGE.selectedItem));
		end
	end)
end

function SELLPAGE.ListItem(sellData)
	local LIST_BTN = SELLPAGE.W_LIST_BTN;
	if(sellData.item) then
		 LIST_BTN:GetChild("label"):SetText("Listing...");
		 MarketApi.Sell(sellData, function(args, err)
			LIST_BTN:GetChild("label"):SetText("List Item");
			if(args) then
				if(sellData.item.quantity <= sellData.quantity) then
					Component.GetWidget("ListForm"):ParamTo("alpha", 0, 0.15);
				end
				sellData.item.quantity = sellData.item.quantity - sellData.quantity;
				local QUANTITY_TEXT = Component.GetWidget("list_quantity_text");
				QUANTITY_TEXT:SetText("Quantity ("..sellData.item.quantity..")");
			else
				warn(tostring(err));
			end
			SELLPAGE.OnItemListed(args, err);
		 end);
	end
	return true;
end

function SELLPAGE.FindItem(listing)
	
	--out(listing);
	if(listing.item_guid and listing.item_guid ~= "" and listing.stats.quality and listing.stats.quality > 0) then
		for _,item in ipairs(SELLPAGE.items) do
			if(tonumber(item.item_id) == tonumber(listing.item_guid)) then
				--out("#1 found item: "..listing.item_guid);
				return item;
			end
		end
	elseif(listing.resource_type) then
		for _,resource in ipairs(SELLPAGE.resources) do
			--out(resource.resource_type.."=="..listing.resource_type)
			if(resource.resource_type == listing.resource_type) then
				--out("#2 found resource: "..resource.resource_type);
				return resource;
			end
		end
	else
		for _,item in ipairs(SELLPAGE.items) do
			if(tonumber(item.item_sdb_id) == tonumber(listing.item_sdb_id)) then
				--out("#2 found resource: "..item.item_sdb_id);
				return item;
			end
		end
	end
	return nil;
end

function SELLPAGE.SelectItem(item, options)
	local itemInfo = Game.GetItemInfoByType(item.item_sdb_id);
	local LIST_FORM = Component.GetWidget("ListForm");
	local ITEM_INFO = LIST_FORM:GetChild("ItemInfo");
	local TITLE = LIST_FORM:GetChild("ItemInfo.title");
	local DESCRIPTION = LIST_FORM:GetChild("ItemInfo.description");
	local ICON = LIST_FORM:GetChild("ItemInfo.icon");
	
	--TextFormat doesnt clean up correctly worked around it temporarily by replacing the whole textWidget
	if(TITLE) then
		TextFormat.Clear(TITLE);
		Component.RemoveWidget(TITLE);
	end
	TITLE = Component.CreateWidget([[
		<Text name="title" dimensions="top:0; width:100%; height:40;" style="font:Demi_13; wrap:true; color:#00EEEE; halign:center; valign:top; alpha:1.0" key="{Placeholder}"/>
	]], ITEM_INFO);
	
	LIB_ITEMS.GetNameTextFormat({
		name = item.name,
		rarity = item.rarity,
	}, {quality=item.quality}):ApplyTo(TITLE);
	
	DESCRIPTION:SetText(itemInfo.description);
	ICON:SetUrl(itemInfo.web_icon);
	
	local QUANTITY_TEXT = Component.GetWidget("list_quantity_text");
	QUANTITY_TEXT:SetText("Quantity ("..item.quantity..")");
	
	SELLPAGE.selectedItem = item;
	LIST_FORM:ParamTo("alpha", 1, 0.15);
	
	local quantity = 1;
	local price = "";
	
	if(options and options.quantity) then
		if(item.quantity >= options.quantity) then
			quantity = options.quantity;
		else
			quantity = item.quantity;
		end
	end
	
	if(options and options.price) then
		price = options.price;
	end

	
	SELLPAGE.W_QUANTITY_INPUT:SetText(quantity);
	SELLPAGE.W_PRICE_INPUT:SetText(price);
	SELLPAGE.W_PROFIT_INPUT:SetText("");
	SELLPAGE.W_PPU_INPUT:SetText("");
	local W_LISTINGFEE = Component.GetWidget("ListingFee");
	local W_REAPINGFEE = Component.GetWidget("ReapingFee");
	
	W_LISTINGFEE:SetText("0");
	W_REAPINGFEE:SetText("0");
	
	if(options) then
		SELLPAGE_OnPriceInput({user=true});
	end
	
	ITEM_INFO:BindEvent("OnMouseEnter", function() setBoxStats(SELLPAGE.FormatItemToMarketListing(item)); Tooltip.Show(STAT_BOX); end);
	ITEM_INFO:BindEvent("OnMouseLeave", function() Tooltip.Show(nil); end);
end

function SELLPAGE.SetListingStatus(txt, color)
	SELLPAGE.W_LIST_ERROR:ParamTo("alpha", 1.0, 0.15);
	SELLPAGE.W_LIST_ERROR:SetText(txt);
	SELLPAGE.W_LIST_ERROR:SetTextColor(color or "#FFFFFF");
	if(SELLPAGE.cb_ListingStatus) then
		cancel_callback(SELLPAGE.cb_ListingStatus);
		SELLPAGE.cb_ListingStatus = nil;
	end
	
	SELLPAGE.cb_ListingStatus = callback(function()
		SELLPAGE.W_LIST_ERROR:ParamTo("alpha", 0.0, 0.3);
	end, nil, 5);
end

function SELLPAGE.SearchAndSelectItem(listing)
	local item = SELLPAGE.FindItem(listing);
	if(item) then
		SELLPAGE.SelectItem(item, {quantity=listing.quantity, price=listing.price_cy});
	else
		out("Cant find item!");
	end
end

function SELLPAGE.UpdateFeesAndProfit(ignoreProfits)
	local price = tonumber(SELLPAGE.W_PRICE_INPUT:GetText():gsub(',', ''));
	local listingFee = MarketApi.GetListingFee(price);
	local reapingFee = MarketApi.GetReapingFee(price);
	local W_LISTINGFEE = Component.GetWidget("ListingFee");
	local W_REAPINGFEE = Component.GetWidget("ReapingFee");
	
	W_LISTINGFEE:SetText("-"..comma_value(listingFee));
	W_REAPINGFEE:SetText("-"..comma_value(reapingFee));
	if not ignoreProfits then
		SELLPAGE.W_PROFIT_INPUT:SetText(price-listingFee-reapingFee);
	end
end

-- ------------------------------------------
-- List Form Input Listeners
-- ------------------------------------------

function SELLPAGE_OnQuantityInput(args)
	if(args.user) then
		local WIDGET = Component.GetWidget("QuantityInput");
		local txt = WIDGET:GetText():gsub(',', '');
		local Quantity = tonumber(WIDGET:GetText():gsub(',', ''));
		if(Quantity < 1 and txt ~= "") then
			WIDGET:SetText(1);
			Quantity = 1;
		elseif(Quantity > SELLPAGE.selectedItem.quantity) then
			WIDGET:SetText(SELLPAGE.selectedItem.quantity);
			Quantity = SELLPAGE.selectedItem.quantity;
		end
		local PPU = tonumber(SELLPAGE.W_PPU_INPUT:GetText():gsub(',', ''));
		SELLPAGE.W_PRICE_INPUT:SetText(Quantity*PPU);
		SELLPAGE.UpdateFeesAndProfit();
	end
end

function SELLPAGE_OnQuantityLostFocus(args)
	local Quantity = tonumber(SELLPAGE.W_QUANTITY_INPUT:GetText():gsub(',', ''));
	if(Quantity < 1) then
		Quantity = 1;
		SELLPAGE.W_QUANTITY_INPUT:SetText(1);
		local PPU = tonumber(SELLPAGE.W_PPU_INPUT:GetText():gsub(',', ''));
		SELLPAGE.W_PRICE_INPUT:SetText(Quantity*PPU);
		SELLPAGE.UpdateFeesAndProfit();
	end
end

function SELLPAGE_OnPriceInput(args)
	if(args.user) then
		local Price = tonumber(SELLPAGE.W_PRICE_INPUT:GetText():gsub(',', ''));
		local Quantity = tonumber(SELLPAGE.W_QUANTITY_INPUT:GetText():gsub(',', ''));
		SELLPAGE.W_PPU_INPUT:SetText(Price/Quantity);
		SELLPAGE.UpdateFeesAndProfit();
	end
end

function SELLPAGE_OnPPUInput(args)
	if(args.user) then
		local ppu_txt = SELLPAGE.W_PPU_INPUT:GetText():gsub(',', '');
		local PPU = tonumber(ppu_txt);
		local Quantity = tonumber(SELLPAGE.W_QUANTITY_INPUT:GetText():gsub(',', ''));
		SELLPAGE.W_PRICE_INPUT:SetText(PPU*Quantity);
		SELLPAGE.UpdateFeesAndProfit();
	end
end

function SELLPAGE_OnProfitInput(args)
	if(args.user) then
		local Profit = tonumber(SELLPAGE.W_PROFIT_INPUT:GetText():gsub(',', ''));
		local Quantity = tonumber(SELLPAGE.W_QUANTITY_INPUT:GetText():gsub(',', ''));
		--todo make this formula more accurate
		local Price = math.floor((1000*Profit+2998) / 930 + 9);
		SELLPAGE.W_PRICE_INPUT:SetText(Price);
		SELLPAGE.W_PPU_INPUT:SetText(Price/Quantity);
		SELLPAGE.UpdateFeesAndProfit(true);
	end
end
