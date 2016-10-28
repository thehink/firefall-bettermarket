BUYPAGE = {
	w_SEARCH_INPUT = Component.GetWidget("SearchInput"),
	--
	w_CATEGORY_CHOICE = Component.GetWidget("CategoryChoice"),
	w_CATEGORY_CHILDREN = Component.GetWidget("CategoryChildren"),
	CATCHOICE = nil,
	CAT_CHILDREN = {},
	--
	w_FILTER_CHOICE = Component.GetWidget("FilterChoice"),
	FILTERS = {},
	FILTER_CHOICE = nil,
	FILTER_SCROLLER = nil,
	AddedFilters = {},
	FilterCount = 0,
	--
	w_SEARCH_MSG = Component.GetWidget("SearchError"),
	w_PAGE_BUTTONS = Component.GetWidget("PageButtons"),
	w_TABLE = nil,
	customHeaders = {},
	firstLoad = true,
	filterArgs = {
		categories = {0},
	},
	--//Constraints
	LoadoutList = {},
	URL_BF_CONSTRAINTS = {},
	w_FRAME_CHOICE = nil,
	w_ITEM_CHOICE = nil,
	ProgressionConstants = nil,
	--Constraints//
}

function BUYPAGE.initBuyPage()
	BUYPAGE.HideSearchError();
	DISPATCHER:AddHandler("OnReady", BUYPAGE.OnReady);
	DISPATCHER:AddHandler("OnBuyPage", BUYPAGE.OnSetBuyPage);
end

function BUYPAGE.OnReady()
	BUYPAGE.initCategories();
	BUYPAGE.initFilters();
	BUYPAGE.initSearch();
	BUYPAGE.initNav();
	BUYPAGE.initConstraints();
	BUYPAGE.firstLoad = false;
	
	DISPATCHER:AddHandler("OnResolutionChanged", BUYPAGE.OnResolutionChanged);
end

function BUYPAGE.OnResolutionChanged()
	callback(function()
		BUYPAGE.w_TABLE:ReorderHeader();
		BUYPAGE.w_TABLE:UpdateSize();
	end, nil, 0.1);
end

function BUYPAGE.OnSetBuyPage()
	BUYPAGE.w_SEARCH_INPUT:SetFocus();
end

BUYPAGE.currentSearchData = nil;

BUYPAGE.BP_ROW = [[
<Group name="row" dimensions="width:100%; height:60;">
	<Border name="bg" dimensions="height:100%-4; width:100%-10;" class="BlueBackDrop" style="tint:#00FF00; alpha: 0.2"/>
	<Border dimensions="height:100%-6; width:100%-12; center-x:50%; center-y: 50%;" class="BlueBackDrop" style="tint:#000000; alpha: 0.5"/>
</Group>
]]

-- ------------------------------------------
-- Buy Confirmation
-- ------------------------------------------

function BUYPAGE.ShowBuyConfirmation(GROUP, listing)
	local BOX = ModalBox.Create("buyConfirmation",
	{
		{title = "Buy", align = "center", color="#00FF00", func = BUYPAGE.BuyListing, args = {GROUP = GROUP, listing=listing}},
		{title = "Buy & Select...", align = "center", color="#00FF00", func = BUYPAGE.RelistListing, args = {GROUP = GROUP, listing=listing}},
		{title = "Cancel", align = "center", color="#FF0000"}
	});
	
	BOX:SetDims({width=500, height=300});
	
	BOX:SetTitle("Purchase Confirmation");
	local ITEM = BOX.FOSTER_WIDGET:GetChild("item");
	
	local ItemInfo = Game.GetItemInfoByType(listing.item_sdb_id);
	
	local icon = ITEM:GetChild("icon");
	icon:SetUrl(ItemInfo.web_icon);
	
	local label = ITEM:GetChild("label");
	
	LIB_ITEMS.GetNameTextFormat({
		name = listing.title,
		rarity = listing.rarity,
	}, {quality=listing.stats.quality}):ApplyTo(label);
	
	--label:SetText(listing.title);
	--label:SetTextColor(qColor(listing.rarity));
	
	local desc = BOX.FOSTER_WIDGET:GetChild("description_text");
	desc:SetText(ItemInfo.description);
	
	local Cy = BOX.FOSTER_WIDGET:GetChild("crystite");
	local CyPPU = BOX.FOSTER_WIDGET:GetChild("cy_ppu");
	local CyDelta = BOX.FOSTER_WIDGET:GetChild("cy_delta");
	local CyLeft = BOX.FOSTER_WIDGET:GetChild("cy_left");
	
	local CYCount = Player.GetItemCount(10);
	Cy:SetText(comma_value(CYCount));
	CyPPU:SetText("("..comma_value(tostring(listing.price_per_unit)).." cy/u)");
	CyDelta:SetText("-"..comma_value(tostring(listing.price_cy)));
	CyLeft:SetText(comma_value(CYCount-listing.price_cy));
	

	ITEM:BindEvent("OnMouseEnter", function() setBoxStats(listing); Tooltip.Show(STAT_BOX); end);
	ITEM:BindEvent("OnMouseLeave", function() Tooltip.Show(nil); end);
end

function BUYPAGE.RelistListing(args)
	SELLPAGE.selectItemOnInventoryChange = args.listing;
	
	args.GROUP:Disable(true);
	args.GROUP.TEXT:SetText("Buying");
	
	MarketApi.Buy(args.listing, function(resp, err)
		BUYPAGE.OnBuyResponse(args, resp, err);
		SetSellPage();
	end);
	return true;
end

function BUYPAGE.BuyListing(args)
--[[
	args.GROUP.PLATE:SetColor("#AAAAAA");
	args.GROUP.BTN:GetChild("label"):SetText("Buying...");
	
	args.GROUP.BTN:BindEvent("OnMouseEnter", nil);
	args.GROUP.BTN:BindEvent("OnMouseLeave", nil);
	args.GROUP.BTN:BindEvent("OnMouseDown", nil);
	args.GROUP.BTN:BindEvent("OnMouseUp", nil);
	]]
	
	args.GROUP:Disable(true);
	args.GROUP.TEXT:SetText("Buying");
	
	MarketApi.Buy(args.listing, function(resp, err)
		BUYPAGE.OnBuyResponse(args, resp, err);
	end);
	
	return true;
end

function BUYPAGE.OnBuyResponse(args, resp, err)
	if(err)	then
		args.GROUP.TEXT:SetText("Error");
	else
		if(args.GROUP and Component.IsWidget(args.GROUP.TEXT)) then
			args.GROUP.TEXT:SetText("Bought");
		end
	end
end


-- ------------------------------------------
-- SEARCH Functions
-- ------------------------------------------

function OnSearchSubmit()
	BUYPAGE.Search();
end

function BUYPAGE.Search(page)
	BUYPAGE.filterArgs.filters = {};
	for _, v in pairs(BUYPAGE.AddedFilters) do
		local WRAPPER = v.filterWidget:GetChild("wrapper"):GetChild("wr2");
		local filter = {
			name = v.Filter.name,
		};
		if(v.Filter.type=="single") then
			filter.value = WRAPPER:GetChild("value"):GetText();
		else
			filter.min = tonumber(WRAPPER:GetChild("min"):GetText());
			filter.max = tonumber(WRAPPER:GetChild("max"):GetText());
		end
		
		table.insert(BUYPAGE.filterArgs.filters, filter);
	end
	
	BUYPAGE.filterArgs.string = BUYPAGE.w_SEARCH_INPUT:GetText();
	BUYPAGE.filterArgs.page = page or 1;
	
	BUYPAGE.pushCurrentState();
	MarketApi.SearchListings(BUYPAGE.filterArgs, BUYPAGE.OnSearchComplete, BUYPAGE.OnSearchError);
end

function BUYPAGE.SearchForSimilarItems(listing)
	BUYPAGE.w_SEARCH_INPUT:SetText("");
	BUYPAGE.ClearFilters();
	BUYPAGE.AddFilter({title="Item Type ID", name="item_sdb_id", type="single"}, {value=listing.item_sdb_id});
	if(listing.stats.quality and listing.resource_type) then
		BUYPAGE.AddFilter({title="Quality", name="stat_quality", type="range"}, {min=listing.stats.quality-40, max=listing.stats.quality+40});
	elseif(listing.stats.quality > 0) then
		BUYPAGE.AddFilter({title="Quality", name="stat_quality", type="range"}, {min=listing.stats.quality-100, max=listing.stats.quality+100});
	end
	BUYPAGE.Search();
	SetBuyPage();
end

function BUYPAGE.OnSearchComplete(args)
	if(not BUYPAGE.currentSearchData or BUYPAGE.currentSearchData.page ~= args.page) then
		BUYPAGE.navFiltersChanged()
	end
	BUYPAGE.currentSearchData = args;
	BUYPAGE.UpdateResults();
end

function BUYPAGE.OnSearchError(err)
	BUYPAGE.w_TABLE:ClearRows();
	BUYPAGE.SetSearchError(err);
end

-- ------------------------------------------
-- SEARCH RESULTS
-- ------------------------------------------

function BUYPAGE.SetSearchError(err)
	BUYPAGE.w_SEARCH_MSG:GetChild("wr.title"):SetText("Search Error, Status: "..err.status);
	BUYPAGE.w_SEARCH_MSG:GetChild("wr.label"):SetText(err.data.message);
	BUYPAGE.w_SEARCH_MSG:Show();
end

function BUYPAGE.HideSearchError()
	BUYPAGE.w_SEARCH_MSG:Hide();
end

function BUYPAGE.UpdateResults()
	BUYPAGE.HideSearchError();
	BUYPAGE.w_TABLE:ClearRows();
	for _,listing in ipairs(BUYPAGE.currentSearchData.listings) do
		local rowData = {
			default = listing,
			item_sdb_id = listing,
			["title.en"] = listing,
			price_cy = listing.price_cy,
			price_per_unit = listing,
			quantity = listing.quantity,
			expires_at = listing.expires_at,
			buy = listing,
		};
		
		for k, v in pairs(listing.stats) do
			rowData[k] = v;
		end
		
		local ROW = BUYPAGE.w_TABLE:AddRow({height=60, vpadding = 0}, rowData, BUYPAGE.BP_ROW);
		ROW.WIDGET:GetChild("bg"):SetParam("tint", qColor(listing.rarity));
		
		ROW.ROW:AddHandler("OnMouseEnter", function() setBoxStats(listing); Tooltip.Show(STAT_BOX); end);
		ROW.ROW:AddHandler("OnMouseLeave", function() Tooltip.Show(nil); end);
	end
	BUYPAGE.UpdatePaging();
end

-- ------------------------------------------
-- NAVIGATION
-- ------------------------------------------
BUYPAGE.history = {};
BUYPAGE.history_index = 0;
BUYPAGE.filtersChanged = false;
function BUYPAGE.initNav()
	local BACK_BTN = Component.GetWidget("back_button");
	local REFRESH_BTN = Component.GetWidget("refresh_button");
	local FORWARD_BTN = Component.GetWidget("forward_button");
	
	BACK_BTN:BindEvent("OnMouseDown", BUYPAGE.goBack);
	local CBTN1 = BACK_BTN:GetChild("bgbtn");
	BACK_BTN:BindEvent("OnMouseEnter", function() CBTN1:ParamTo("exposure", 1, 0.15); end);
	BACK_BTN:BindEvent("OnMouseLeave", function() CBTN1:ParamTo("exposure", 0, 0.15); end);
	
	REFRESH_BTN:BindEvent("OnMouseDown", BUYPAGE.Refresh);
	local CBTN2 = REFRESH_BTN:GetChild("bgbtn");
	REFRESH_BTN:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("exposure", 1, 0.15); end);
	REFRESH_BTN:BindEvent("OnMouseLeave", function() CBTN2:ParamTo("exposure", 0, 0.15); end);
	
	FORWARD_BTN:BindEvent("OnMouseDown", BUYPAGE.goForward);
	local CBTN3 = FORWARD_BTN:GetChild("bgbtn");
	FORWARD_BTN:BindEvent("OnMouseEnter", function() CBTN3:ParamTo("exposure", 1, 0.15); end);
	FORWARD_BTN:BindEvent("OnMouseLeave", function() CBTN3:ParamTo("exposure", 0, 0.15); end);
end

function BUYPAGE.navFiltersChanged()
	if not BUYPAGE.filtersChanged then
		BUYPAGE.filtersChanged = true;
	end
end

function BUYPAGE.Refresh()
	if(BUYPAGE.currentSearchData) then
		BUYPAGE.Search(BUYPAGE.currentSearchData.page);
	else
		BUYPAGE.Search();
	end
end

--push current state to history
function BUYPAGE.pushCurrentState()
	if not BUYPAGE.filtersChanged then
		return nil;
	end

	--delete every histories above this index if there is any
	if(BUYPAGE.history_index and BUYPAGE.history_index > -1) then
		for i = #BUYPAGE.history, BUYPAGE.history_index+1, -1 do
			table.remove(BUYPAGE.history, i);
		end
	end

	local filters = {};
	for _,GROUP in pairs(BUYPAGE.AddedFilters) do
		local filter = GROUP.Filter;
		local data = {};
		if(filter.type=="single") then
			data.value = GROUP.filterWidget:GetChild("wrapper.wr2.value"):GetText();
		else
			data.min = GROUP.filterWidget:GetChild("wrapper.wr2.min"):GetText();
			data.max = GROUP.filterWidget:GetChild("wrapper.wr2.max"):GetText();
		end
		table.insert(filters, {filter = filter, data=data});
	end
	
	local cats = {};
	
	table.insert(cats, BUYPAGE.CATCHOICE:GetSelected().index);
	for _, CAT in ipairs(BUYPAGE.CAT_CHILDREN) do
		table.insert(cats, CAT.CHOICE:GetSelected().index);
	end

	local search_str = BUYPAGE.w_SEARCH_INPUT:GetText();
	
	local page = 1;
	local sort = nil;
	if(BUYPAGE.filterArgs) then
		page = BUYPAGE.filterArgs.page or 1;
		sort= BUYPAGE.filterArgs.sort;
	end
	--out("SAVE:"..tostring({filters = filters, page=page, sort = sort, categories=cats, string = search_str}));
	table.insert(BUYPAGE.history, {filters = filters, page=page, sort = sort, categories=cats, string = search_str})
	BUYPAGE.history_index = #BUYPAGE.history;
end

function BUYPAGE.goForward()
	BUYPAGE.loadHistory(BUYPAGE.history_index + 1);
end

function BUYPAGE.goBack()
	BUYPAGE.loadHistory(BUYPAGE.history_index - 1);
end

--load history based on index
function BUYPAGE.loadHistory(index)
	if(index and index > -1 and index <= #BUYPAGE.history) then
		BUYPAGE.history_index = index;
		local data = BUYPAGE.history[index];
		BUYPAGE.ClearFilters();
		if(data) then
			for _,filter in ipairs(data.filters) do
				BUYPAGE.AddFilter(filter.filter, filter.data);
			end

			BUYPAGE.filterArgs.sort = data.sort;
			
			local sortAsc = true;
			if(BUYPAGE.filterArgs.sort.method=="desc") then
				sortAsc = false;
			end
			
			--visual change only
			BUYPAGE.w_TABLE:SortBy(BUYPAGE.filterArgs.sort.name, sortAsc, true);
			
			--out("LOAD:"..tostring(data));
			if(data.categories) then
				BUYPAGE.CATCHOICE:SetSelectedByIndex(data.categories[1]);
				for i = 2, #data.categories do
					local catIndex = data.categories[i];
					BUYPAGE.CAT_CHILDREN[#BUYPAGE.CAT_CHILDREN].CHOICE:SetSelectedByIndex(catIndex or 1);
				end
			else
				BUYPAGE.CATCHOICE:SetSelectedByIndex(1);
			end
			
			BUYPAGE.w_SEARCH_INPUT:SetText(data.string or "");
			BUYPAGE.filtersChanged = false;
			BUYPAGE.Search(data.page);
		else
			BUYPAGE.CATCHOICE:SetSelectedByIndex(1);
			BUYPAGE.w_SEARCH_INPUT:SetText("");
			BUYPAGE.filtersChanged = false;
			BUYPAGE.Search();
		end
	end
end

-- ------------------------------------------
-- PAGING RESULTS
-- ------------------------------------------

function BUYPAGE.UpdatePaging()
	for i = BUYPAGE.w_PAGE_BUTTONS:GetChildCount(), 1, -1 do
		Component.RemoveWidget(BUYPAGE.w_PAGE_BUTTONS:GetChild(i))
	end
	
	local offsetLeft = 0;
	
	local Show = 5; -- * 2
	
	if(BUYPAGE.currentSearchData.page > 1) then
		BUYPAGE.AddPageButton(BUYPAGE.w_PAGE_BUTTONS, "1", BUYPAGE.Search, 1);
		BUYPAGE.AddPageButton(BUYPAGE.w_PAGE_BUTTONS, "<", BUYPAGE.Search, BUYPAGE.currentSearchData.page-1);
	end
	
	for i=math.max(1, BUYPAGE.currentSearchData.page-Show), math.min(BUYPAGE.currentSearchData.page + Show, BUYPAGE.currentSearchData.pages) do
		BUYPAGE.AddPageButton(BUYPAGE.w_PAGE_BUTTONS, i, BUYPAGE.Search, i, i==BUYPAGE.currentSearchData.page);
	end
	
	if(BUYPAGE.currentSearchData.page < BUYPAGE.currentSearchData.pages) then
		BUYPAGE.AddPageButton(BUYPAGE.w_PAGE_BUTTONS, ">", BUYPAGE.Search, BUYPAGE.currentSearchData.page+1);
		BUYPAGE.AddPageButton(BUYPAGE.w_PAGE_BUTTONS, BUYPAGE.currentSearchData.pages, BUYPAGE.Search, BUYPAGE.currentSearchData.pages);
	end
	
end

function BUYPAGE.AddPageButton(PARENT, txt, func, args, disabled)
	local WIDGET = Component.CreateWidget("PageButton", PARENT);
	
	local GROUP = {
		WIDGET = WIDGET,
		PLATE = HoloPlate.Create(WIDGET:GetChild("page_btn.skin")),
	};
	
	WIDGET:GetChild("page_btn.text"):SetText(txt or "");
	
	local PAGE_BTN = WIDGET:GetChild("page_btn");
	if not disabled then
		PAGE_BTN:BindEvent("OnMouseEnter", function()
			GROUP.PLATE.INNER:ParamTo("exposure", -0.1, 0.1)
			GROUP.PLATE.SHADE:ParamTo("exposure", -0.4, 0.1)
		end);
		PAGE_BTN:BindEvent("OnMouseLeave", function()
			GROUP.PLATE.INNER:ParamTo("exposure", -0.3, 0.1)
			GROUP.PLATE.SHADE:ParamTo("exposure", -0.6, 0.1)
		end);
		PAGE_BTN:BindEvent("OnMouseDown", function()
			GROUP.PLATE.INNER:ParamTo("exposure", -0.3, 0.1);
			GROUP.PLATE.SHADE:ParamTo("exposure", -0.8, 0.1);
		end)
		PAGE_BTN:BindEvent("OnMouseUp", function()
			GROUP.PLATE.INNER:ParamTo("exposure", -0.1, 0.1);
			GROUP.PLATE.SHADE:ParamTo("exposure", -0.4, 0.1);
			if(type(func)=="function") then
				func(args);
			end
		end)
	end
	
	if disabled then
		GROUP.PLATE:SetColor("#A0A0A0");
		PAGE_BTN:SetCursor("sys_arrow");
	else 
		GROUP.PLATE:SetColor("#0E7192");
		PAGE_BTN:SetCursor("sys_hand");
	end
		
	
	local LeftOffset = 38*PARENT:GetChildCount();
	WIDGET:SetDims("width:35; height:35; left:"..LeftOffset);
	PARENT:SetDims("center-x:50%; height:100%; width:"..(LeftOffset+2*38));
	
	return GROUP;
end


-- ------------------------------------------
-- SEARCH UI
-- ------------------------------------------

function BUYPAGE.sortTest(name, sortAsc)
	BUYPAGE.filterArgs.sort = {name=name};
	if(sortAsc) then
		BUYPAGE.filterArgs.sort.method = "asc";
	else
		BUYPAGE.filterArgs.sort.method = "desc";
	end
	BUYPAGE.Search(BUYPAGE.filterArgs.page);
end

function BUYPAGE.initSearch()
	local SEARCH_BTN = Component.GetWidget("search_button");
	SEARCH_BTN:BindEvent("OnMouseDown", function()
		BUYPAGE.Search();
	end);
	local CBTN2 = SEARCH_BTN:GetChild("bgbtn");
	SEARCH_BTN:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("exposure", 1, 0.15); end);
	SEARCH_BTN:BindEvent("OnMouseLeave", function() CBTN2:ParamTo("exposure", 0, 0.15); end);
	
	BUYPAGE.w_TABLE = Table.Create(Component.GetWidget("item_list"));
	BUYPAGE.UpdateHeaders();
	BUYPAGE.w_TABLE:SortBy("price_per_unit", true);
end

function BUYPAGE.UpdateHeaders()
	local HeaderData = {
		{title="Type", name="item_sdb_id", blueprint="type", width=70, sort=true, sortFunc = BUYPAGE.sortTest},
		{title="Title",  name="title.en", blueprint="title", width=350, sort=true, sortFunc = BUYPAGE.sortTest},
		{title="Quality",  name="quality", blueprint="quality", width=90, sort=true, sortFunc = BUYPAGE.sortTest},
		{title="Quantity",  name="quantity", blueprint="number", width=100, sort=true, sortFunc = BUYPAGE.sortTest},
		{title="Price",  name="price_cy", blueprint="price_cy", width=90, sort=true, sortFunc = BUYPAGE.sortTest},
		{title="PPU",  name="price_per_unit", blueprint="price_per_unit", width=90, sort=true, sortFunc = BUYPAGE.sortTest},
		{title="+",  name="add_header_cell", width=40, onClick=BUYPAGE.AddHeaderCellMenu},
		{title="Buy",  name="buy", blueprint="buy_btn", width=120, align="right"},
	}
	
	BUYPAGE.w_TABLE:SetHeaders(HeaderData);
end

function BUYPAGE.AddHeaderCellMenu(GROUP)
	--local MENU = SMenu.Create(BUYPAGE.w_TABLE.HEADER, BUYPAGE.AddHeaderCell);
	
	local MENU = ChoiceWindow.Create(BUYPAGE.AddHeaderCell);
	MENU:SetTitle("Select sort variable...");
	
	local predefinedHeaders = {
		type = true,
		name = true,
		stat_quality = true,
		quantity = true,
		price = true,
		price_per_unit = true,
	};
	
	local count = 0;
	for _, sort_var in pairs(sort_variables) do
		if not predefinedHeaders[sort_var.name] and not BUYPAGE.customHeaders[sort_var.name]  then
			MENU:AddItem(sort_var.title, sort_var);
			count = count + 1;
		end
	end
	
	if(count==0) then
		MENU:Destroy();
	end
end

function BUYPAGE.AddHeaderCell(data)
	BUYPAGE.customHeaders[data.name] = true;
	BUYPAGE.w_TABLE:AddHeaderCell({title=data.title,  name=data.name, width=7*#data.title+50, format=data.format, blueprint = data.blueprint, sort=true, sortFunc = BUYPAGE.sortTest, removeAble = true, removeFunc = BUYPAGE.RemoveHeaderCell}, #BUYPAGE.w_TABLE.HEADER_CELLS-1);
	BUYPAGE.UpdateResults();
end

function BUYPAGE.RemoveHeaderCell(GROUP)
	BUYPAGE.customHeaders[GROUP.data.name] = false;
	BUYPAGE.w_TABLE:RemoveHeaderCell(GROUP.index);
	BUYPAGE.UpdateResults();
end

-- ------------------------------------------
-- CONSTRAINTS
-- ------------------------------------------

function BUYPAGE.initConstraints()
	BUYPAGE.ProgressionConstants = Game.GetProgressionUnlocks();
	BUYPAGE.w_FRAME_CHOICE = DropDownList.Create(Component.GetWidget("FrameChoice"), "Demi_10");
	BUYPAGE.w_ITEM_CHOICE = DropDownList.Create(Component.GetWidget("ExcludeChoice"), "Demi_10");

	BUYPAGE.w_FRAME_CHOICE:BindOnSelect(BUYPAGE.OnFrameChoice)
	BUYPAGE.w_ITEM_CHOICE:BindOnSelect(BUYPAGE.OnItemChoice)
	
	local BUTTON = Component.GetWidget("calc_constraints");
	BUTTON:BindEvent("OnMouseDown", function()
		local selectedId = BUYPAGE.w_FRAME_CHOICE:GetSelected();
		local constraints = {mass=0, power=0, cpu = 0};

		if(selectedId ~= "none") then
			local selectedItemId = BUYPAGE.w_ITEM_CHOICE:GetSelected();
			local selectedFrame = BUYPAGE.LoadoutList[tostring(selectedId)];
			local constraintLevels = selectedFrame.constraints;
			
			constraints = Game.GetItemInfoByType(selectedFrame.sdb_id).base_constraints;
			
			for level,progression in ipairs(BUYPAGE.ProgressionConstants) do
				for k,v in pairs(progression.add) do
					if(constraintLevels[k] >= level) then
						constraints[k] = constraints[k] + v;
					end
				end
			end
			--bah doesnt match
			for _,item in ipairs(selectedFrame.equipped) do
				if tonumber(item.itemId) ~= tonumber(selectedItemId) then
					for k,v in pairs(item.constraints) do
						constraints[k] = constraints[k] + v;
					end
				end
			end
			
			BUYPAGE.AddFilter({title="Mass", name="stat_mass", type="range"}, {min=0, max=math.floor(constraints.mass)});
			BUYPAGE.AddFilter({title="Power", name="stat_power", type="range"}, {min=0, max=math.floor(constraints.power)});
			BUYPAGE.AddFilter({title="CPU", name="stat_cpu", type="range"}, {min=0, max=math.floor(constraints.cpu)});
			BUYPAGE.Search();
		else
			BUYPAGE.AddFilter({title="Mass", name="stat_mass", type="range"});
			BUYPAGE.AddFilter({title="Power", name="stat_power", type="range"});
			BUYPAGE.AddFilter({title="CPU", name="stat_cpu", type="range"});
		end
	end);
	local CBTN2 = BUTTON:GetChild("bgbtn");
	BUTTON:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("exposure", 1, 0.15); end);
	BUTTON:BindEvent("OnMouseLeave", function() CBTN2:ParamTo("exposure", 0, 0.15); end);
	
	url = WebCache.MakeUrl("garage_slot", Player.GetCharacterId());
	WebCache.Subscribe(url, BUYPAGE.OnGarageSlotsResponse, true);
	BUYPAGE.RefreshLoadouts();
end

function BUYPAGE.OnFrameChoice()
	local selected = BUYPAGE.w_FRAME_CHOICE:GetSelected();
	--log(tostring(BUYPAGE.LoadoutList[selected]));
	BUYPAGE.w_ITEM_CHOICE:ClearItems();
	if(BUYPAGE.LoadoutList[selected]) then
		BUYPAGE.w_ITEM_CHOICE:AddItem("Replace item", "none");
		for _,item in ipairs(BUYPAGE.LoadoutList[selected].equipped) do
			BUYPAGE.w_ITEM_CHOICE:AddItem(item.name, item.itemId);
		end
	end
end

function BUYPAGE.OnItemChoice()
	local selectedItem = BUYPAGE.w_ITEM_CHOICE:GetSelected();
	local selectedFrame = BUYPAGE.LoadoutList[BUYPAGE.w_FRAME_CHOICE:GetSelected()];

end

function BUYPAGE.RefreshLoadouts()
	BUYPAGE.w_FRAME_CHOICE:ClearItems();
	BUYPAGE.w_FRAME_CHOICE:AddItem("Battleframes", "none");
	for k,loadout in ipairs(Player.GetLoadoutList()) do
		local loadout_id = tostring(loadout.id);
		local url = BUYPAGE.URL_BF_CONSTRAINTS[loadout_id];
		
		if not BUYPAGE.LoadoutList[loadout_id] then
			BUYPAGE.LoadoutList[loadout_id] = {};
		end
		
		BUYPAGE.LoadoutList[loadout_id].sdb_id = loadout.item_types.chassis;
		
		if (url) then
			-- update using cache
			WebCache.QuickUpdate(url);
		else
			-- subscribe
			local chassis_id = tostring(loadout.item_types.chassis);
			url = WebCache.MakeUrl("constraint_levels", Player.GetCharacterId(), chassis_id);
			BUYPAGE.URL_BF_CONSTRAINTS[loadout_id] = url;
			WebCache.Subscribe(url, 
			function(args)
				if args then
					args.loadout_id = tostring(loadout_id);
					args.battleframe = tostring(loadout.item_types.chassis),
					BUYPAGE.OnConstraintResponse(args)
				end
			end, true);
		end

		BUYPAGE.w_FRAME_CHOICE:AddItem(loadout.name, loadout_id);
	end
end

function BUYPAGE.OnGarageSlotsResponse(args, err)
	for _,v in pairs(args) do
		if(v.unlocked == true) then
			local id = tostring(v.id);
			if not BUYPAGE.LoadoutList[id] then
				BUYPAGE.LoadoutList[id] = {};
			end
			BUYPAGE.LoadoutList[id].name = v.name;
			BUYPAGE.LoadoutList[id].equipped = {};
			for _,slot in pairs(v.equipped_slots) do
				if(slot.item_guid ~= 0 and Player.GetItemInfo(slot.item_guid)) then
					local item = Player.GetItemInfo(slot.item_guid);
					if(item) then
						item.allocated_power = slot.allocated_power;
						table.insert(BUYPAGE.LoadoutList[id].equipped, item);
					end
				elseif(slot.sdb_id ~= 0 and (slot.slot_type_id == 1 or slot.item_guid ~= 0) and slot.slot_type_id ~= 11 --[[ and slot.slot_type_id ~= 2]]) then
						local itemInfo = Game.GetItemInfoByType(slot.sdb_id);
						itemInfo.itemId = tonumber(itemInfo.itemTypeId);
						table.insert(BUYPAGE.LoadoutList[id].equipped, itemInfo);
				end
			end
		end
	end
end

function BUYPAGE.OnConstraintResponse(args)
	if not BUYPAGE.LoadoutList[args.loadout_id] then
		BUYPAGE.LoadoutList[args.loadout_id] = {};
	end
	BUYPAGE.LoadoutList[args.loadout_id].constraints = args;
end

-- ------------------------------------------
-- FILTERS
-- ------------------------------------------

function BUYPAGE.initFilters()
	


	--BUYPAGE.FILTER_CHOICE = DropDownList.Create(BUYPAGE.w_FILTER_CHOICE, "Demi_10");
	--BUYPAGE.FILTER_CHOICE:SetListMaxSize(10);
	--BUYPAGE.CATCHOICE:BindOnSelect(OnFilterSelect)
	--for _, filter in ipairs(filters) do
	--	BUYPAGE.FILTER_CHOICE:AddItem(filter.title, filter);
	--end
	
	local BUTTON = Component.GetWidget("add_quality_filter");
	BUTTON:BindEvent("OnMouseDown", function()
		BUYPAGE.AddFilter({title="Quality", name="stat_quality", type="range"});
	end);
	local CBTN2 = BUTTON:GetChild("bgbtn");
	BUTTON:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("exposure", 1, 0.15); end);
	BUTTON:BindEvent("OnMouseLeave", function() CBTN2:ParamTo("exposure", 0, 0.15); end);
	BUTTON = nil;
	
	BUTTON = Component.GetWidget("add_price_filter");
	BUTTON:BindEvent("OnMouseDown", function()
		BUYPAGE.AddFilter({title="Price", name="price", type="range"}, {max=Player.GetItemCount(10)});
		BUYPAGE.Search(BUYPAGE.currentSearchData.page);
	end);
	local CBTN2 = BUTTON:GetChild("bgbtn");
	BUTTON:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("exposure", 1, 0.15); end);
	BUTTON:BindEvent("OnMouseLeave", function() CBTN2:ParamTo("exposure", 0, 0.15); end);
	BUTTON = nil;
	
	BUTTON = Component.GetWidget("add_filter_btn");
	BUTTON:BindEvent("OnMouseDown", function()
		local CW = ChoiceWindow.Create(BUYPAGE.AddFilter);
		CW:SetTitle("Select Filter...");
		for _, filter in ipairs(filters) do
			if not BUYPAGE.AddedFilters[filter.name] then
				CW:AddItem(filter.title, filter);
			end
		end
	end);
	local CBTN2 = BUTTON:GetChild("bgbtn");
	BUTTON:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("exposure", 1, 0.15); end);
	BUTTON:BindEvent("OnMouseLeave", function() CBTN2:ParamTo("exposure", 0, 0.15); end);
	
	local FILTER_LIST_WIDGET = Component.GetWidget("filter_list");
	BUYPAGE.FILTER_SCROLLER = RowScroller.Create(FILTER_LIST_WIDGET);
	BUYPAGE.FILTER_SCROLLER:SetSlider(RowScroller.SLIDER_DEFAULT);
end

function BUYPAGE.UpdateFilters()
	--[[BUYPAGE.FILTER_CHOICE:ClearItems();
	for _, filter in ipairs(filters) do
		if not BUYPAGE.AddedFilters[filter.name] then
			BUYPAGE.FILTER_CHOICE:AddItem(filter.title, filter);
		end
	end]]
	BUYPAGE.navFiltersChanged();
end

function BUYPAGE.removeFilter(name)
	local GROUP = BUYPAGE.AddedFilters[name];
	if(GROUP) then
		GROUP.ROW:Remove();
		BUYPAGE.AddedFilters[name] = nil;
		BUYPAGE.UpdateFilters();
	end
end

function BUYPAGE.GetSelectedFilter()
	if(#BUYPAGE.FILTER_CHOICE.LIST_WIDGETS > 0) then
		return BUYPAGE.FILTER_CHOICE:GetSelected();
	else
		return false;
	end
end

function BUYPAGE.ClearFilters()
	for	k,GROUP in pairs(BUYPAGE.AddedFilters) do
		GROUP.ROW:Remove();
		BUYPAGE.AddedFilters[k] = nil;
	end
	BUYPAGE.UpdateFilters();
end

function BUYPAGE.AddFilter(filt, values)
	local filter = filt;-- or BUYPAGE.GetSelectedFilter();
	if(type(filter) == "table" and not BUYPAGE.AddedFilters[filter.name]) then
		local GROUP = {};
		GROUP.Filter = filter;
		BUYPAGE.FilterCount = BUYPAGE.FilterCount + 1;
		GROUP.ROW = BUYPAGE.FILTER_SCROLLER:AddRow(tonumber("123123"..BUYPAGE.FilterCount));
		if(filter.type=="single") then
			GROUP.filterWidget = Component.CreateWidget("singleFilter", GROUP.ROW.SCROLLER.HIDDEN_FOSTER);
		else
			GROUP.filterWidget = Component.CreateWidget("textFilter", GROUP.ROW.SCROLLER.HIDDEN_FOSTER);
		end
		local WRAPPER = GROUP.filterWidget:GetChild("wrapper");

		GROUP.filterWidget:GetChild("name"):SetText(tostring(GROUP.Filter.title).."");
		
		local REMOVE_BUTTON = WRAPPER:GetChild("remove_btn");
		REMOVE_BUTTON:BindEvent("OnMouseDown", function()
			BUYPAGE.removeFilter(filter.name);
		end);
		local CBTN1 = REMOVE_BUTTON:GetChild("X");
		REMOVE_BUTTON:BindEvent("OnMouseEnter", function() CBTN1:ParamTo("exposure", 1, 0.15); end);
		REMOVE_BUTTON:BindEvent("OnMouseLeave", function() CBTN1:ParamTo("exposure", 0, 0.15); end);
	
		GROUP.ROW:SetWidget(GROUP.filterWidget);
		GROUP.ROW:UpdateSize({height=65});
		BUYPAGE.AddedFilters[filter.name] = GROUP;
		
		if(values) then
			if(filter.type=="single") then
				WRAPPER:GetChild("wr2.value"):SetText(values.value or "");
			else
				WRAPPER:GetChild("wr2.min"):SetText(values.min or "");
				WRAPPER:GetChild("wr2.max"):SetText(values.max or "");
			end
		end
		
		BUYPAGE.UpdateFilters();
		
		--[[
		GROUP.SLIDERGROUP = Slider.Create(filterWidget:GetChild("wrapper"):GetChild("SliderGroup"), "adjuster")
		if(GROUP.Filter.type == "slider") then
			GROUP.Filter.inc = 1;
			local steps = ((GROUP.Filter.max - GROUP.Filter.min) / GROUP.Filter.inc)
			GROUP.SLIDERGROUP:SetSteps(steps)
			GROUP.SLIDERGROUP:SetScrollSteps(1)
			GROUP.SLIDERGROUP:SetJumpSteps(math.max(1, (steps+1)/10))
			GROUP.SLIDERGROUP:SetPercent(0);
		end]]
		--GROUP.SLIDERGROUP:BindEvent("OnStateChanged", Slider_OnChange)
		--GROUP.SLIDERGROUP:BindEvent("OnMouseEnter", Slider_OnMouseEnter)
		--GROUP.SLIDERGROUP:BindEvent("OnMouseLeave", Slider_OnMouseLeave)
	elseif(type(filter) == "table" and BUYPAGE.AddedFilters[filter.name] and values) then
		local GROUP = BUYPAGE.AddedFilters[filter.name];
		local WRAPPER = GROUP.filterWidget:GetChild("wrapper");
		if(filter.type=="single") then
			WRAPPER:GetChild("wr2.value"):SetText(values.value or "");
		else
			WRAPPER:GetChild("wr2.min"):SetText(values.min or "");
			WRAPPER:GetChild("wr2.max"):SetText(values.max or "");
		end
	end
end

-- ------------------------------------------
-- CATEGORIES
-- ------------------------------------------

function BUYPAGE.initCategories()
	BUYPAGE.CATCHOICE = DropDownList.Create(BUYPAGE.w_CATEGORY_CHOICE, "Demi_10");
	BUYPAGE.CATCHOICE:SetListMaxSize(10);
	BUYPAGE.CATCHOICE:BindOnSelect(BUYPAGE.OnCategorySelect)
	for i, category in ipairs(categories) do
		category.index = i;
		BUYPAGE.CATCHOICE:AddItem(category.name, category);
	end
end

function BUYPAGE.addChildrenCategory(cats, parent)
	local GROUP = {};
	GROUP.CHOICE_WIDGET = Component.CreateWidget([[<Choice name="Choice" dimensions="top:30; left:10; width:100%-20; height:30;"/>]], BUYPAGE.w_CATEGORY_CHILDREN);
	
	GROUP.level = #BUYPAGE.CAT_CHILDREN+1;
	GROUP.CHOICE = DropDownList.Create(GROUP.CHOICE_WIDGET, "Demi_10")
	GROUP.CHOICE:BindOnSelect(function()
		BUYPAGE.OnChildrenCategorySelect(GROUP);
	end)
	
	if parent then
		GROUP.CHOICE:AddItem("All", "not_selected");
	else
		BUYPAGE.filterArgs.categories = cats[1].ids;
		BUYPAGE.filterArgs.item_sdb_id = cats[1].item_sdb_id;
	end
	for i, category in ipairs(cats) do
		category.index = i;
		if(parent) then
			category.index = category.index + 1;
		end
		GROUP.CHOICE:AddItem(category.name, category);
	end
	table.insert(BUYPAGE.CAT_CHILDREN, GROUP);
end

function BUYPAGE.removeCategoryChildren(level)
	for i = #BUYPAGE.CAT_CHILDREN, level, -1 do
		local GROUP = BUYPAGE.CAT_CHILDREN[i];
		--GROUP.CHOICE:Destroy();  //undefined even though its listed in the usage list in lib_DropDownList
		Component.RemoveWidget(GROUP.CHOICE.GROUP);
		if(GROUP.CHOICE.FRAME) then
			Component.RemoveFrame(GROUP.CHOICE.FRAME);
		end
		Component.RemoveWidget(GROUP.CHOICE_WIDGET);
		GROUP.CHOICE = nil;
		table.remove(BUYPAGE.CAT_CHILDREN, i);
	end
end

function BUYPAGE.OnCategorySelect()
	BUYPAGE.removeCategoryChildren(1);
	local mainCategory = BUYPAGE.CATCHOICE:GetSelected();
	BUYPAGE.filterArgs.categories = mainCategory.ids;
	BUYPAGE.filterArgs.item_sdb_id = mainCategory.item_sdb_id;
	if(mainCategory.subcategories) then
		BUYPAGE.addChildrenCategory(mainCategory.subcategories, mainCategory.ids or mainCategory.item_sdb_id);
	end
	BUYPAGE.navFiltersChanged();
end

function BUYPAGE.OnChildrenCategorySelect(GROUP)
	BUYPAGE.removeCategoryChildren(GROUP.level + 1);
	local category = GROUP.CHOICE:GetSelected();
	if(type(category)=="table") then
		BUYPAGE.filterArgs.categories = category.ids;
		BUYPAGE.filterArgs.item_sdb_id = category.item_sdb_id;
		if(category.subcategories) then
			BUYPAGE.addChildrenCategory(category.subcategories, category.ids or category.item_sdb_id);
		end
	else
		--select parent category
		if(GROUP.level-1 > 0) then
			local selectedCat = BUYPAGE.CAT_CHILDREN[GROUP.level-1].CHOICE:GetSelected();
			BUYPAGE.filterArgs.categories = selectedCat.ids;
			BUYPAGE.filterArgs.item_sdb_id = selectedCat.item_sdb_id;
		else
			BUYPAGE.filterArgs.categories = BUYPAGE.CATCHOICE:GetSelected().ids;
			BUYPAGE.filterArgs.item_sdb_id = BUYPAGE.CATCHOICE:GetSelected().item_sdb_id;
		end
	end
	BUYPAGE.navFiltersChanged();
	--local CHOICE = BUYPAGE.CAT_CHILDREN[#BUYPAGE.CAT_CHILDREN]:GetSelected();
end

