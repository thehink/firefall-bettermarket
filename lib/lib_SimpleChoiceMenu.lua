-- ------------------------------------------
-- lib_SimpleChoiceMenu
--   by: Thehink
-- ------------------------------------------
-- Created this lib just to fill one purpose for now
-- WIP TODO:
-- C

--]]

if(SMenu) then
	return nil;
end

SMenu = {};

local ITEM_COLOR_HIGHLIGHT = "#505050"
local ITEM_COLOR_DEFAULT = "#000000"

local PRIVATE = {};
local API = {};

local SMenu_MT = {__index = function(self, key) return API[key] end}

PRIVATE.cb_FocusCallback = nil;

local bp_MENU = [[
		<Group dimensions="width:100%; height:100%;" style="">
			<Border name="backdrop" dimensions="top:0; width:100%; height:100%;" class="RoundedBorders" style="alpha:0.8; padding:6; tint:#0E0E0E" />
			<Group name="FilterList" dimensions="top:0; width:100%; height:100%; right:100%;" style="vpadding:0"/>
		</Group>
	]];
	

function SMenu.Create(PARENT, Callback)
	local WIDGET = Component.CreateWidget(bp_MENU, PARENT);
	local GROUP = {
		WIDGET = WIDGET,
		ITEMS = {},
		height = 0,
		width = 0,
		size = 24,
		Callback = Callback,
	}
	setmetatable(GROUP, SMenu_MT);
	return GROUP;
end

function API.AddItem(self, name, data)
	local ITEM = Component.CreateWidget([[
		<FocusBox dimensions="left:0; top:0; width:190; height:20" class="ui_button">
			<Border name="background" dimensions="top:1; bottom:100%-1; left:0; right:100%;" class="RoundedBorders" style="alpha:0.8; padding:6; tint:#000000;" />
			<Text name="text" dimensions="left:3; right: 100%; top:0; bottom:100%" style="font:UbuntuMedium_9; halign:left; valign:center; wrap:false; clip:true; cursor:sys_hand; eatsmice:false" key="{Empty Field}" />
		</FocusBox>
	]], self.WIDGET:GetChild("FilterList"));
	ITEM:GetChild("text"):SetText(name or "NO_NAME");
	
	local BACKGROUND = ITEM:GetChild("background");
	ITEM:GetChild("text"):SetText(name);

	ITEM:BindEvent("OnMouseEnter", function()
		BACKGROUND:ParamTo("exposure", 0.35, 0.05)
		BACKGROUND:ParamTo("tint", ITEM_COLOR_HIGHLIGHT, 0.2)
		BACKGROUND:ParamTo("alpha", 1, 0.05)
		PRIVATE.SetFocus(self, true);
	end)
	ITEM:BindEvent("OnMouseLeave", function()
		BACKGROUND:ParamTo("exposure", 0, 0.05)
		BACKGROUND:ParamTo("tint", ITEM_COLOR_DEFAULT, 0.2)
		BACKGROUND:ParamTo("alpha", 0.8, 0.05)
		PRIVATE.SetFocus(self, false);
	end)
	ITEM:BindEvent("OnMouseDown", function()
		BACKGROUND:ParamTo("exposure", -0.3, 0.05)
	end)
	ITEM:BindEvent("OnMouseUp", function()
		BACKGROUND:ParamTo("exposure", 0.35, 0.05)
		BACKGROUND:ParamTo("alpha", 0.8, 0.05)
		if(type(self.Callback)=="function") then
			self.Callback(data);
		end
		self:Destroy();
	end)
	
	
	local GROUP = {
		WIDGET = ITEM,
	}
	
	self.height = (#self.ITEMS % self.size) * 20;
	self.width = math.floor(#self.ITEMS/self.size) * 190;
	
	ITEM:SetDims("left:"..self.width.."; top:"..self.height.."; width:190; height:20");

	self.WIDGET:SetDims("width:"..(self.width+190).."; height:"..self.height.."; right:100%; top:0;");
	--self.WIDGET:GetChild("backdrop"):SetDims("top:50%-20; left:50%-400; width:"..(self.width + 190).."; height:"..(self.size*20));
	
	table.insert(self.ITEMS, GROUP);
end

function API.ClearItems(self)
	for i = #self.ITEMS, 1, -1 do
		local GROUP = self.ITEMS[i];
		Component.RemoveWidget(GROUP.WIDGET);
		table.remove(self.ITEMS, i);
	end
end

function API.Destroy(self)
	Component.RemoveWidget(self.WIDGET);
end

function PRIVATE.SetFocus(self, focus)
	if(focus) then
		if(PRIVATE.cb_FocusCallback) then
			cancel_callback(PRIVATE.cb_FocusCallback);
			PRIVATE.cb_FocusCallback = nil;
		end
	else
		PRIVATE.cb_FocusCallback = callback(API.Destroy, self, 0.3);
	end
end