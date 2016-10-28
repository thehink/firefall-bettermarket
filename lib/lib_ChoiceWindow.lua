require "./lib/lib_ModalBox";

if(ChoiceWindow) then
	return nil;
end

local ITEM_COLOR_HIGHLIGHT = "#505050"
local ITEM_COLOR_DEFAULT = "#000000"

ChoiceWindow = {};
local PRIVATE = {};
local API = {};

local ChoiceWindow_MT = {__index = function(self, key) return API[key] end}

PRIVATE.bp_ChoiceList = [[
	<Group name="wrapper" dimensions="dock:fill">
		<Group name="SearchWrapper" dimensions="left:5; top:5; width:180; height:32;" style="">
			<Border dimensions="dock:fill" class="BlueBackDrop"  style="alpha:0.5; padding:5;" />
			<Border dimensions="height:100%-4; width:100%-4;" class="SolidBackDrop" />
			<TextInput name="SearchInput" dimensions="dock:fill" class="Chat, #TextInput" style="alpha:1.0; valign:center; wrap:false; maxlen:256; texture:colors; region:transparent;">
				<Events>
				</Events>
			</TextInput>
		</Group>
		<Group name="ChoiceList" dimensions="dock:fill">
			
		</Group>
	</Group>
]];

PRIVATE.bp_ListItem = [[
	<FocusBox dimensions="left:0; top:0; width:190; height:20" class="ui_button">
		<Border name="background" dimensions="top:1; bottom:100%-1; left:0; right:100%;" class="RoundedBorders" style="alpha:0.8; padding:6; tint:#000000;" />
		<Text name="text" dimensions="left:3; right: 100%; top:0; bottom:100%" style="font:Narrow_10; halign:left; valign:center; wrap:false; clip:true; cursor:sys_hand; eatsmice:false" key="{Empty Field}" />
	</FocusBox>
]]

function PRIVATE.Create(cb, options)
	options = options or {};
	local MBOX = ModalBox.Create(PRIVATE.bp_ChoiceList, {});

	local WIDGET = MBOX.FOSTER_WIDGET;
	local SEARCH_INPUT = WIDGET:GetChild("SearchWrapper.SearchInput");
	
	local GROUP = {
		BOX = MBOX,
		WIDGET = WIDGET,
		SEARCH_INPUT = SEARCH_INPUT,
		LIST = WIDGET:GetChild("ChoiceList"),
		ITEMS = {},
		MaxHeight = options.MaxHeight or 600,
		callback = cb,
		height = 0,
		width = 0,
	};

	setmetatable(GROUP, ChoiceWindow_MT);
	
	local timeCreated = tonumber(System.GetLocalUnixTime());
	local unfocused = false;
	
	SEARCH_INPUT:BindEvent("OnTextChange", function() GROUP:Filter(); end);
	SEARCH_INPUT:BindEvent("OnSubmit", function() GROUP:SelectFirst(); end);
	SEARCH_INPUT:BindEvent("OnLostFocus", function(args)
		--fix for bug causing the textinput to unfocus by itself
		local elapsedTime = tonumber(System.GetElapsedUnixTime(timeCreated));
		if(elapsedTime < 10 and not unfocused) then
			unfocused = true;
			SEARCH_INPUT:SetFocus();
		end
	end);
	
	SEARCH_INPUT:SetFocus();
	
	return GROUP;
end

ChoiceWindow.Create = function(WIDGET, buttons)
	local GROUP = PRIVATE.Create(WIDGET, buttons);
	return GROUP;
end


function API.AddItem(self, name, value)
	local WIDGET = Component.CreateWidget(PRIVATE.bp_ListItem, self.LIST);
	WIDGET:GetChild("text"):SetText(name);
	local BACKGROUND = WIDGET:GetChild("background");
	
	
	WIDGET:BindEvent("OnMouseEnter", function()
		BACKGROUND:ParamTo("exposure", 0.35, 0.05)
		BACKGROUND:ParamTo("tint", ITEM_COLOR_HIGHLIGHT, 0.2)
		BACKGROUND:ParamTo("alpha", 1, 0.05)
	end)
	WIDGET:BindEvent("OnMouseLeave", function()
		BACKGROUND:ParamTo("exposure", 0, 0.05)
		BACKGROUND:ParamTo("tint", ITEM_COLOR_DEFAULT, 0.2)
		BACKGROUND:ParamTo("alpha", 0.8, 0.05)
	end)
	WIDGET:BindEvent("OnMouseDown", function()
		BACKGROUND:ParamTo("exposure", -0.3, 0.05)
	end)
	WIDGET:BindEvent("OnMouseUp", function()
		BACKGROUND:ParamTo("exposure", 0.35, 0.05)
		BACKGROUND:ParamTo("alpha", 0.8, 0.05)
		if(type(self.callback)=="function") then
			self.callback(value);
		end
		self:Destroy();
	end)
	
	
	local GROUP = {
		WIDGET = WIDGET,
		name = name,
		value = value,
	}
	
	
	table.insert(self.ITEMS, GROUP);
	self:UpdateList();
end

function API.UpdateList(self)
	
	local ItemHeight = 20;
	
	local Rows = self.MaxHeight/ItemHeight;
	local column = 1;
	local row = 1;

	local OffsetTop = 40;
	
	local searchText = self.SEARCH_INPUT:GetText();
	
	for i,GROUP in ipairs(self.ITEMS) do
		if(searchText == "" or string.find(GROUP.name:lower(), searchText:lower())) then
			GROUP.WIDGET:Show(true);
			local top = OffsetTop % self.MaxHeight;
			local left = math.floor(OffsetTop/self.MaxHeight) * 190;
			--self.width = math.floor(#self.ITEMS/self.size) * 190;
			GROUP.WIDGET:SetDims("left:"..left.."; top:"..top.."; width:190; height:20");
			OffsetTop = OffsetTop + ItemHeight;
		else
			GROUP.WIDGET:Hide(true);
		end
	end
	self.BOX:SetDims({
		height = self.MaxHeight,
		width = math.floor((#self.ITEMS * ItemHeight + 40)/self.MaxHeight + 1) * 190,
	});
end

function API.ClearList(self)
	
end

function API.SetTitle(self, title, color)
	self.BOX:SetTitle(title, color);
end

function API.Filter(self)
	self:UpdateList();
end

function API.SelectFirst(self)
	local searchText = self.SEARCH_INPUT:GetText();
	
	for i,GROUP in ipairs(self.ITEMS) do
		if(searchText == "" or string.find(GROUP.name:lower(), searchText:lower())) then
			if(type(self.callback)=="function") then
				self.callback(GROUP.value);
				self:Destroy();
			end
			return;
		end
	end
end

function API.Destroy(self)
	self.BOX:Close();
	self = nil;
end