

if (ModalBox) then
	-- only include once
	return;
end


require "string"

ModalBox = {};
local PRIVATE = {};
local API = {};

local ModalBox_MT = {__index = function(self, key) return API[key] end}

PRIVATE.bp_Button = [[
	<FocusBox name="btn" class="ui_button" dimensions="width:_; height:100%-8; center-y:50%;">
		<Group name="skin" dimensions="dock:fill"/>
		<Text name="text" dimensions="dock:fill" style="font:UbuntuMedium_11; halign:center; valign:center; wrap:false; clip:true; cursor:sys_hand; eatsmice:false" />
	</FocusBox>
]]
PRIVATE.bp_BG = [[
<FocusBox dimensions="dock:fill">
	<Border name="bgbtn" class="SmallBorders" dimensions="dock:fill" style="alpha:0.6; padding:5; tint:#000000; shadow:1"/>
</FocusBox>
]];
PRIVATE.bp_Frame = [[
<Group name="Window" dimensions="width:50%; height:55%; center-x:50%; center-y: 50%;">
	<Group name="header" dimensions="width:100%; top:0; bottom:40;">
		<Border class="SmallBorders" dimensions="dock:fill" style="alpha:1.0; padding:5; tint:#111111; shadow:1"/>
		<Text name="title" key="{Title}" dimensions="top:0; left:4; width:100%-35; height:100%" style="font:Demi_15; halign:left; valign:center; shadow:0; color:PanelTitle" />
		<FocusBox name="CloseBTN" dimensions="right:100%-4; center-y:50%; width:26; height:26;">
			<Border class="SmallBorders" dimensions="dock:fill" style="alpha:0.5; padding:5"/>
			<StillArt name="X" dimensions="center-x:50%; center-y:50%; width:100%-10; height:100%-10" style="texture:Window; region:X; tint:#B82F06; cursor:sys_hand;"/>
		</FocusBox>
	</Group>
	<Group name="body" dimensions="width:100%; top:40; bottom:100%-40;">
		<Border class="SmallBorders" dimensions="dock:fill" style="alpha:1.0; padding:5; tint:#111111; shadow:1"/>
	</Group>
	<Group name="footer" dimensions="width:100%; top:100%-40; bottom:100%;">
		<Border class="SmallBorders" dimensions="dock:fill" style="alpha:1.0; padding:5; tint:#111111; shadow:1"/>
		<Group name="buttons" dimensions="dock:fill">
		</Group>
	</Group>
</Group>
]]

ModalBox.Create = function(WIDGET, buttons)
	local BOX = PRIVATE.Create(WIDGET, buttons);
	return BOX;
end

PRIVATE.Create = function(WIDGET, buttons)
	local MB_FRAME = Component.CreateFrame("PanelFrame");
	MB_FRAME:SetDepth(-100);
	MB_FRAME:Show(true)
	MB_FRAME:SetDims("width:100%; height:100%;");
	local BG = Component.CreateWidget(PRIVATE.bp_BG, MB_FRAME);
	local WINDOW = Component.CreateWidget(PRIVATE.bp_Frame, MB_FRAME);
	local WIDGET = Component.CreateWidget(WIDGET, WINDOW:GetChild("body"));
		  
	WIDGET:SetDims("height:_; width:_; center-x: 50%; center-y:50%;");
	
	local BTN_GROUP = WINDOW:GetChild("footer.buttons");
	
	local left = 5;
	local right = 5;
	local center = 0;
	
	local w_BUTTONS = {};
	
	local GROUP = {
		BG = BG,
		FRAME = MB_FRAME,
		WINDOW = WINDOW,
		BUTTONS = w_BUTTONS,
		FOSTER_WIDGET = WIDGET,
	};
	
	BG:BindEvent("OnMouseDown", function()
		GROUP:Close();
	end);
	
	local CLOSE_BTN = WINDOW:GetChild("header.CloseBTN");
	CLOSE_BTN:BindEvent("OnMouseUp", function()
		GROUP:Close();
	end);
	local CBTN1 = CLOSE_BTN:GetChild("X");
	CLOSE_BTN:BindEvent("OnMouseEnter", function() CBTN1:ParamTo("exposure", 1, 0.15); end);
	CLOSE_BTN:BindEvent("OnMouseLeave", function() CBTN1:ParamTo("exposure", 0, 0.15); end);
	
	for _,v in ipairs(buttons) do
		local BUTTON = Component.CreateWidget(PRIVATE.bp_Button, BTN_GROUP);
		BUTTON:GetChild("text"):SetText(v.title);
		local width = #v.title * 8 + 10;
		if(width < 80) then
			width = 80;
		end
		if(v.align == "left") then
			BUTTON:SetDims("width:"..width.."; height:100%-8; center-y:50%; left:"..left);
			left = left + width + 5;
		else
			BUTTON:SetDims("width:"..width.."; height:100%-8; center-y:50%; right:100%-"..right);
			right = right + width + 5;
		end
		
		
		local PLATE = HoloPlate.Create(BUTTON:GetChild("skin"));
		if(v.color) then
			PLATE:SetColor(v.color);
		end
		
		BUTTON:BindEvent("OnMouseEnter", function()
			PLATE.INNER:ParamTo("exposure", -0.1, 0.1)
			PLATE.SHADE:ParamTo("exposure", -0.4, 0.1)
		end);
		BUTTON:BindEvent("OnMouseLeave", function()
			PLATE.INNER:ParamTo("exposure", -0.3, 0.1)
			PLATE.SHADE:ParamTo("exposure", -0.6, 0.1)
		end);
		BUTTON:BindEvent("OnMouseDown", function()
			PLATE.INNER:ParamTo("exposure", -0.3, 0.1);
			PLATE.SHADE:ParamTo("exposure", -0.8, 0.1);
		end)
		BUTTON:BindEvent("OnMouseUp", function()
			PLATE.INNER:ParamTo("exposure", -0.1, 0.1);
			PLATE.SHADE:ParamTo("exposure", -0.4, 0.1);
			if(type(v.func)=="function") then
				if(v.func(v.args)) then
					GROUP:Close();
				end;
			else
				GROUP:Close();
			end
		end)
		table.insert(w_BUTTONS, BUTTON);
	end
	
	setmetatable(GROUP, ModalBox_MT);
	
	return GROUP;
end

function API.SetDims(self, args)
	self.WINDOW:SetDims("width:"..(args.width or "50%").."; height:"..((args.height or "50%")+80).."; center-x:50%; center-y: 50%;");
end

function API.SetTitle(self, title, color)
	local W_TITLE = self.WINDOW:GetChild("header.title");
	if(title) then
		W_TITLE:SetText(title);
	end
	if(color) then
		W_TITLE:SetTextColor(color);
	end
end

function API.Close(self)
	Component.RemoveFrame(self.FRAME);
	self = nil;
end