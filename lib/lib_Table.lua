-- ------------------------------------------
-- lib_Table
--   by: Thehink
-- ------------------------------------------
-- WIP TODO:
-- complete more features

--]]


if Table then
	-- only include once
	return nil
end

require "lib/lib_RowScroller";
require "lib/lib_EventDispatcher";
require "lib/lib_TextFormat";
require "lib/lib_HoloPlate";
require "lib/lib_Colors";


Table = {};
Table.Blueprints = {};

local PRIVATE = {};
local API = {};
local ROWAPI = {};

local Table_MT = {__index = function(self, key) return API[key] end}
local TableRow_MT = {__index = function(self, key) return ROWAPI[key] end}

local SCROLLER_EVENTS = {"OnScroll", "OnScrollTo", "OnScrollHeightChanged", "OnSliderShow"};
local ROW_EVENTS = {"OnMouseDown", "OnMouseUp", "OnMouseEnter", "OnMouseLeave", "OnScoped", "OnRemoved"};
local EVENT_DISPATCHER_DELEGATE_METHODS = {"AddHandler", "DispatchEvent", "RemoveHandler", "HasHandler"};

local HeaderHeight = 30;

local BP_TABLE = [[<Group dimensions="dock:fill">
<Group name="Body" dimensions="top:30; width:100%; height:100%-30;">
	<Group name="Rows" dimensions="dock:fill">
	</Group>
</Group>

<Group name="Header_Row" dimensions="top:0; width:100%; height:30;">
	<StillArt name="BackPlate" dimensions="dock:fill" style="texture:colors; region:black; shadow:1; alpha:1.0;"/>
	<Group name="Header_Cells" dimensions="dock:fill">
	</Group>
</Group>

</Group>]];

local BP_HEADER_CELL = [[<Group dimensions="width:100%; height:40;">
	<FocusBox name="header_cell" dimensions="dock:fill;">
		<Border name="bgbtn" class="SmallBorders" dimensions="dock:fill" style="alpha:0.5; padding:5; tint:#11AAFF"/>
		<Text name="label" dimensions="center-x:50%; center-y:50%; width:100%; height:100%;" style="wrap:true; font:Narrow_11; halign:center; valign:center" key="{Add}"/>
		<StillArt name="arrow" dimensions="height:10; width:10; right: 100%-7;" style="texture:arrows; region:up; alpha:0.0;"/>
		<FocusBox name="focusBox" dimensions="dock:fill" class="ui_button" style="tint:#11AAFF"/>
	</FocusBox>
</Group>]];

local BP_ROW_CELL = [[<Group dimensions="dock:fill">
<Text name="label" key="{Label}" dimensions="height:100%; width:100%;" style="wrap:true; font:UbuntuBold_13; halign:left; valign:center; color:#00AAFF;"/>
</Group>]];

local BP_REMOVE_BUTTON = [[<FocusBox name="remove" class="ui_button" dimensions="right:100%; top:0; width:13; height:13;">
			<Border class="SmallBorders" dimensions="dock:fill" style="alpha:0.5; padding:5"/>
			<StillArt name="X" dimensions="center-x:50%; center-y:50%; width:100%-2; height:100%-2" style="texture:Window; region:X; tint:#B82F06; cursor:sys_hand;"/>
</FocusBox>]];

-- ------------------------------------------
-- API
-- ------------------------------------------

function Table.Create(PARENT, hdr)
	--[[
	
	hdr = {
		{title="Type", name="type", width=5, sort=true, sortFunc = func},
		{title="Title",  name="name", width=20, sort=true, sortFunc = func},
	};
	
	]]

	local W_TABLE = Component.CreateWidget(BP_TABLE, PARENT);
	local W_HEADER = W_TABLE:GetChild("Header_Row");
	
	W_HEADER:SetDims({height=HeaderHeight});
	
	local W_BODY = W_TABLE:GetChild("Body");
	local TBL = {
		GROUP = W_TABLE,
		HEADER = W_HEADER,
		BODY = W_BODY,
		HeaderData = hdr,
		ROWS = {},
		HEADER_CELLS = {},
		SCROLLER = RowScroller.Create(W_BODY:GetChild("Rows")),
		sortAsc = true,
		currentSortCell = nil,
		totalWidth = 0,
		Count = 1,
	};
	TBL.SCROLLER:SetSlider(RowScroller.SLIDER_DEFAULT);
	
	TBL.DISPATCHER = EventDispatcher.Create(TBL)
	TBL.DISPATCHER:Delegate(TBL)
	
	setmetatable(TBL, Table_MT);
	
	
	if(hdr) then
		TBL:SetHeaders(hdr);
	end
	
	return TBL;
end

function Table.CreateCellBlueprint(name, BP, func, destroy)
	BP = '<Group name="'..name..'" dimensions="height:100%; width:100%;">'..BP..'</Group>';
	Table.Blueprints[name] = {blueprint= BP, populate=func, destroy=destroy};
	return Table.Blueprints[name];
end

function Table.GetBlueprint(name)
	return Table.Blueprints[name];
end

-- ------------------------------------------
--  TABLE API
-- ------------------------------------------

local COMMON_METHODS = {
	"GetDims", "SetDims", "MoveTo", "QueueMove", "FinishMove",
	"GetParam", "SetParam", "ParamTo", "CycleParam", "QueueParam", "FinishParam",
	"Show", "Hide",	"IsVisible", "GetBounds",
};
for _, method_name in pairs(COMMON_METHODS) do
	API[method_name] = function(TBL, ...)
		return TBL.GROUP[method_name](TBL.GROUP, ...);
	end
end

function API.SetHeaders(self, hdr)

	local currentSortName = nil;
	if(self.currentSortCell) then
		currentSortName = self.currentSortCell.data.name;
	end

	self.HeaderData = hdr;
	for i = #self.HEADER_CELLS, 1, -1 do
		local GROUP = self.HEADER_CELLS[i];
		Component.RemoveWidget(GROUP.WIDGET);
		table.remove(self.HEADER_CELLS, i);
	end

	
	for _,v in pairs(hdr) do
		self:AddHeaderCell(v);
	end
	
	self:ReorderHeader();
	
	if(currentSortName) then
		self.currentSortCell = nil;
		self:SortBy(currentSortName, self.sortAsc);
	end
end

function API.ReorderHeader(self)
	local leftOffset = 0;
	local rightOffset = 0;
	local totalWidth = 0;
	for _,GROUP in pairs(self.HEADER_CELLS) do
		totalWidth = totalWidth + GROUP.data.width;
	end

	self.totalWidth = totalWidth;
	local headerWidth = self.HEADER:GetBounds().width;
	
	for i,GROUP in ipairs(self.HEADER_CELLS) do
		GROUP.index = i;
		local newWidth = GROUP.data.width;
		if(totalWidth > headerWidth) then
			newWidth = headerWidth*GROUP.data.width/totalWidth;
		end
		
		GROUP.newWidth = newWidth;
		
		local offset = "left: "..leftOffset;
		if(GROUP.data.align == "right") then
			offset = "right: 100%-"..rightOffset;
			rightOffset = rightOffset + newWidth;
		else
			leftOffset = leftOffset + newWidth;
		end
		
		GROUP.WIDGET:SetDims(offset.."; width:"..newWidth.."; height:"..HeaderHeight..";");
		
		for _,ROW in ipairs(self.ROWS) do
			local CELL = ROW.CELLS[i];
			if(CELL and CELL.data.name == GROUP.data.name) then
				CELL.WIDGET:SetDims(offset.."; width:"..newWidth.."; height:_");
			end
		end
	end
end

function API.AddHeaderCell(self, v, index)
	local GROUP = {};
	GROUP.data = v;
	GROUP.WIDGET = Component.CreateWidget(BP_HEADER_CELL, self.HEADER);
	
	local HeaderCell = GROUP.WIDGET:GetChild("header_cell");
	HeaderCell:GetChild("label"):SetText(v.title or "");
	
	if(type(v.onClick) == "function") then
		HeaderCell:BindEvent("OnMouseDown", function()
			v.onClick(GROUP);
		end);
		
		local CBTN2 = HeaderCell:GetChild("bgbtn");
		HeaderCell:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("exposure", 1, 0.15); end);
		HeaderCell:BindEvent("OnMouseLeave", function() CBTN2:ParamTo("exposure", 0, 0.15); end);
	elseif(v.sort) then
		HeaderCell:GetChild("label"):SetDims("center-x:50%-5; center-y:50%; width:100%; height:100%;");
		HeaderCell:BindEvent("OnMouseDown", function()
			if(type(v.sortFunc) == "function") then
				if(self.currentSortCell == GROUP) then
					if(self.sortAsc) then
						self.sortAsc = false;
					else
						self.sortAsc = true;
					end
				end
				self:SortBy(v.name, self.sortAsc);
			end
		end);
		
		local CBTN2 = HeaderCell:GetChild("bgbtn");
		HeaderCell:BindEvent("OnMouseEnter", function() CBTN2:ParamTo("exposure", 1, 0.15); end);
		HeaderCell:BindEvent("OnMouseLeave", function() CBTN2:ParamTo("exposure", 0, 0.15); end);
		
		
		if(v.removeAble) then
			local RBUTTON = Component.CreateWidget(BP_REMOVE_BUTTON, GROUP.WIDGET);
			RBUTTON:BindEvent("OnMouseDown", function()
				if(type(v.removeFunc) == "function") then
					v.removeFunc(GROUP);
				end
			end);
			
			local RBG = RBUTTON:GetChild("X");
			RBUTTON:BindEvent("OnMouseEnter", function() RBG:ParamTo("exposure", 1, 0.15); end);
			RBUTTON:BindEvent("OnMouseLeave", function() RBG:ParamTo("exposure", 0, 0.15); end);
		end
	end
	
	if(index) then
		table.insert(self.HEADER_CELLS, index, GROUP);
	else
		table.insert(self.HEADER_CELLS, GROUP);
	end
	self:ReorderHeader();
end

function API.RemoveHeaderCell(self, index)
	local GROUP = self.HEADER_CELLS[index];
	if(GROUP) then
		if(self.currentSortCell == GROUP) then
			self.currentSortCell = nil;
		end
		Component.RemoveWidget(GROUP.WIDGET);
		table.remove(self.HEADER_CELLS, index);
	end
	self:ReorderHeader();
end

function API.SortBy(self, column, sortAsc, visualOnly)
	for _,v in pairs(self.HEADER_CELLS) do
		if(v.data.name == column) then
			if(type(v.data.sortFunc) == "function") then
				if(self.currentSortCell) then
					local Arrow = self.currentSortCell.WIDGET:GetChild("header_cell"):GetChild("arrow");
					Arrow:SetParam("alpha", 0);
				end
				
				local Arrow = v.WIDGET:GetChild("header_cell"):GetChild("arrow");
				
				local region = "down";
				if(sortAsc) then
					region = "up";
				end
				
				Arrow:SetRegion(region);
				Arrow:SetParam("alpha", 1);
			
				self.sortAsc = sortAsc;
				self.currentSortCell = v;
				if not visualOnly then
					v.data.sortFunc(column, sortAsc);
				end
			end
			return true;
		end
	end
end

function API.AddRow(self, dims, data, WIDGET)
	local GROUP = {};
	GROUP.height = dims.height or 50;
	GROUP.vpadding = dims.vpadding or 0;
	GROUP.id = tonumber("534534"..self.Count);
	GROUP.ROW = self.SCROLLER:AddRow(GROUP.id);
	GROUP.data = data;
	GROUP.CELLS = {};
	GROUP.PARENT = self;
	self.Count = self.Count + 1;
	
	if(not Component.IsWidget(WIDGET)) then
		GROUP.WIDGET = Component.CreateWidget(WIDGET or [[<Group name="row" dimensions="width:100%; height:50;"></Group>]], GROUP.ROW.SCROLLER.ROWS.GROUP);
	end
	
	GROUP.WIDGET:SetDims("width:100%; height:"..GROUP.height..";");
	
	local leftOffset = 0;
	local rightOffset = 0;
	for i, GR in ipairs(self.HEADER_CELLS) do
		local v = GR.data;
		local blueprint = Table.GetBlueprint(v.blueprint) or Table.GetBlueprint("default");
		local CELL = Component.CreateWidget(blueprint.blueprint, GROUP.WIDGET);
		local POP_DATA = blueprint.populate(CELL, data[v.name], v.format, GROUP);
		
		local newWidth = GR.newWidth;
		local offset = "left: "..leftOffset;
		if(v.align == "right") then
			offset = "right: 100%-"..rightOffset;
			rightOffset = rightOffset + newWidth;
		else
			leftOffset = leftOffset + newWidth;
		end
		
		local G_CELL = {
			data = v,
			WIDGET = CELL,
		};
		
		if(blueprint.destroy) then
			G_CELL.RemoveFunc = function()
				blueprint.destroy(CELL, POP_DATA, data[v.name]);
			end
		end
		
		if(CELL) then
			CELL:SetDims(offset.."; width:"..newWidth.."; height:_");
			table.insert(GROUP.CELLS, G_CELL);
		end
	end
	
	
	setmetatable(GROUP, TableRow_MT);
	
	GROUP.ROW:SetWidget(GROUP.WIDGET);
	GROUP.ROW:UpdateSize({height=GROUP.height + GROUP.vpadding - 2});
	table.insert(self.ROWS, GROUP);
	return GROUP;
end

function API.ClearRows(self)
	for i = #self.ROWS, 1, -1 do
		self:RemoveRowAt(i);
	end
end

function API.RemoveRowAt(self, index)
	local GROUP = self.ROWS[index];
	self:RemoveRow(GROUP);
end

function API.RemoveRow(self, GROUP)
	if(GROUP) then
		for _,CELL in ipairs(GROUP.CELLS) do
			if(CELL.RemoveFunc) then
				CELL.RemoveFunc();
			end
		end
	
		if(GROUP.ROW.Remove) then
			GROUP.ROW:Remove();
		end
		
		for k,v in pairs(GROUP) do
			--GROUP[k] = nil;
		end
		
		--setmetatable(GROUP, nil);
		
		for i,ROW in ipairs(self.ROWS) do
			if(GROUP.id == ROW.id) then
				table.remove(self.ROWS, i);
			end
		end
		GROUP = nil;
	end
end

function API.Destroy(self)
	self.SCROLLER:Destroy();
	Componenent.RemoveWidget(self.GROUP);
end

function API.UpdateSize(self)
	self.SCROLLER:UpdateSize();
end

function ROWAPI.Remove(self)
	self.PARENT:RemoveRow(self);
end

--create default blueprint
Table.CreateCellBlueprint("default", [[
	<Text name="label" key="{Label}" dimensions="height:100%; width:100%;" style="wrap:true; font:UbuntuBold_11; halign:center; valign:center; color:#00AAFF;"/>
]], function(WIDGET, data, format)
	if(format and type(data) == "number") then
		WIDGET:GetChild("label"):SetText(string.format(format, data));
	else
		WIDGET:GetChild("label"):SetText(tostring(data or ""));
	end
end);