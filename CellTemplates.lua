require "./lib/lib_Table";

Table.CreateCellBlueprint("type", [[
<FocusBox name="button" dimensions="width:45; height:45; center-y:50%; center-x:50%;" class="ui_button">
	<Border name="bgbtn" class="SmallBorders" dimensions="dock:fill" style="alpha:0.0; padding:5; tint:#11AAFF"/>
	<WebImage name="Icon" dimensions="dock:fill" style="fixed-bounds:true; valign:center; halign:center; shadow:1.0; cursor:sys_hand;"/>
</FocusBox>
]], function(WIDGET, listing)
		local INGAME_HOST = System.GetOperatorSetting("ingame_host");
		local icon_url = INGAME_HOST.."/assets/items/64/"..listing.icon..".png";
		WIDGET:GetChild("button.Icon"):SetUrl(icon_url);
		
		local BTN = WIDGET:GetChild("button");
		BTN:BindEvent("OnMouseDown", function()
			BUYPAGE.SearchForSimilarItems(listing);
		end);
		local CBTN2 = BTN:GetChild("bgbtn");
		BTN:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("alpha", 0.3, 0.15); end);
		BTN:BindEvent("OnMouseLeave", function() CBTN2:ParamTo("alpha", 0, 0.15); end);
end);

Table.CreateCellBlueprint("title", [[
	<Text name="title" dimensions="left:10; height:100%; width:100%-5;" class="LeftText" style="wrap:true; font:Demi_10;"/>
]], function(WIDGET, data)
	local TXT = WIDGET:GetChild("title");
	if(data.title == "") then
		data.title = Game.GetItemInfoByType(data.item_sdb_id).name;
	end
	if(data.stats.quality and data.stats.quality > 0 and not string.find(data.title, "Q") and not string.find(data.title, "CY")) then
		data.title = data.title.."^Q";
	end
	
	LIB_ITEMS.GetNameTextFormat({
		name = data.title,
		rarity = data.rarity,
	}, {quality=data.stats.quality}):ApplyTo(TXT);
	
	--TXT:SetText(Game.GetItemInfoByType(data.item_sdb_id).name);
	--TXT:SetTextColor(qColor(data.rarity));
end);


Table.CreateCellBlueprint("quality", [[
	<Text name="quality" dimensions="left:5; height:100%; width:100%-5;" class="CenterText" style="font:Demi_10;"/>
]], function(WIDGET, quality)
	local TXT = WIDGET:GetChild("quality");
	TXT:SetText(quality);
	TXT:SetTextColor(qColor(quality));
end);

Table.CreateCellBlueprint("number", [[
	<Text name="number" dimensions="left:5; height:100%; width:100%-5;" class="LeftText" style="font:Demi_10;"/>
]], function(WIDGET, num)
	local TXT = WIDGET:GetChild("number");
	TXT:SetText(tostring(comma_value(round(tonumber(num),2))));
end);

Table.CreateCellBlueprint("price_cy", [[
	<Text name="number" dimensions="left:5; height:100%; width:100%-5;" class="LeftText" style="font:Demi_10;"/>
]], function(WIDGET, num)
	local TXT = WIDGET:GetChild("number");
	TXT:SetText(comma_value(num));
end);

Table.CreateCellBlueprint("price_per_unit", [[
	<Text name="number" dimensions="left:5; height:100%; width:100%-5;" class="LeftText" style="wrap:true; font:Demi_10;"/>
]], function(WIDGET, listing)
	local TXT = WIDGET:GetChild("number");
	if(listing.quantity > 1) then
		TXT:SetText(""..comma_value(round(listing.price_per_unit, 3)).." cy/u");
	end
end);

Table.CreateCellBlueprint("buy_btn", [[
	<FocusBox name="buy_button" dimensions="center-x:50%; center-y:50%; width:100%-20; height:32"  >
		<Choice name="ActionChoice" dimensions="dock:fill"/>
		<Group name="skin" dimensions="dock:fill"/>
		<Text name="label" dimensions="center-x:50%; center-y:50%; width:100%; height:100%;" style="font:Wide_11B; halign:center; valign:center"/>
	</FocusBox>
]], function(WIDGET, data, format, GROUP)

	local CHOICE = DropDownList.Create(WIDGET:GetChild("buy_button.ActionChoice"), "Demi_10");
	CHOICE:BindOnSelect(OnSelectAction);

	if(SELLPAGE.IsListingMine(data.id)) then
		if(data.purchased) then
			CHOICE:AddItem("Sold", "nothing");
			CHOICE:TintPlate("#00FF00");
			CHOICE:AddItem("Claim", {action="reap", WIDGET=CHOICE, listing=data, ROW=GROUP});
			if(SELLPAGE.FindItem(data)) then
				CHOICE:AddItem("List again...", {action="reap_list_again", WIDGET=CHOICE, listing=data, ROW=GROUP});
			end
		else
			local deltaSeconds = timeParser(data.expires_at);

			if(deltaSeconds > 0) then
				CHOICE:TintPlate("#FF0000");
				CHOICE:AddItem("Expired", "nothing");
				CHOICE:AddItem("Remove", {action="cancel", WIDGET=CHOICE, listing=data, ROW=GROUP});
			else
				CHOICE:AddItem("Action", "nothing");
				CHOICE:AddItem("Cancel", {action="cancel", WIDGET=CHOICE, listing=data, ROW=GROUP});
			end

			if(SELLPAGE.FindItem(data)) then
				CHOICE:AddItem("List more...", {action="list_more", WIDGET=CHOICE, listing=data, ROW=GROUP});
			end
			CHOICE:AddItem("Relist", {action="relist", WIDGET=CHOICE, listing=data, ROW=GROUP});
		end
	else
		if(data.price_cy <= Player.GetItemCount(10)) then
			CHOICE:TintPlate("#00FF00");
			CHOICE:AddItem("Action", "nothing");
			CHOICE:AddItem("Buy", {action="buy_item", WIDGET=CHOICE, listing=data, ROW=GROUP});
			CHOICE:AddItem("Relist", {action="buy_item", WIDGET=CHOICE, listing=data, ROW=GROUP});
			if(SELLPAGE.FindItem(data)) then
				CHOICE:AddItem("List...", {action="list_more", WIDGET=CHOICE, listing=data, ROW=GROUP});
			end
		else
			CHOICE:TintPlate("#FF0000");
			CHOICE:AddItem("Not Affordable", "nothing");
		end
	--[[
		WIDGET:GetChild("buy_button.label"):SetText("Buy");
		local PLATE = HoloPlate.Create(WIDGET:GetChild("buy_button.skin"));
		local BTN = WIDGET:GetChild("buy_button");
		if(data.price_cy <= Player.GetItemCount(10)) then
			BTN:BindEvent("OnMouseEnter", function()
				PLATE.INNER:ParamTo("exposure", -0.1, 0.1);
				PLATE.SHADE:ParamTo("exposure", -0.4, 0.1);
			end);
			BTN:BindEvent("OnMouseLeave", function()
				PLATE.INNER:ParamTo("exposure", -0.3, 0.1);
				PLATE.SHADE:ParamTo("exposure", -0.6, 0.1);
			end);
			
			BTN:BindEvent("OnMouseDown", function()
				PLATE.INNER:ParamTo("exposure", -0.3, 0.1);
				PLATE.SHADE:ParamTo("exposure", -0.8, 0.1);
			end)
			BTN:BindEvent("OnMouseUp", function()
				PLATE.INNER:ParamTo("exposure", -0.1, 0.1);
				PLATE.SHADE:ParamTo("exposure", -0.4, 0.1);
				ShowBuyConfirmation({WIDGET=WIDGET, PLATE=PLATE, BTN=BTN}, data);
			end)
			
			PLATE:SetColor("#0E7192");
			WIDGET:GetChild("buy_button"):SetCursor("sys_hand");
		else
			PLATE:SetColor("#FF0000");
		end]]
	end
	
	return CHOICE;
end, function(CELL, CHOICE, data)
	Component.RemoveWidget(CHOICE.GROUP);
	if(CHOICE.FRAME) then
		Component.RemoveFrame(CHOICE.FRAME);
	end
end);

Table.CreateCellBlueprint("expires_at", [[
	<Text name="number" dimensions="left:5; height:100%; width:100%-5;" class="LeftText" style="font:Narrow_10;"/>
]], function(WIDGET, date)
	local TXT = WIDGET:GetChild("number");
	
	
	local GROUP = {};
	
	GROUP.CYCLE = Callback2.CreateCycle(function()
		local deltaSeconds = timeParser(date);
		local text = timeCountDown(deltaSeconds);
		TXT:SetText(text);
		if(deltaSeconds > 0) then
			TXT:SetTextColor("#FF0000");
		elseif(deltaSeconds > -3600) then
			TXT:SetTextColor("#FFA812");
		end
	end);
	GROUP.CYCLE:Run(1);
	return GROUP;
	
end, function(CELL, GROUP, data)
	GROUP.CYCLE:Stop();
end);