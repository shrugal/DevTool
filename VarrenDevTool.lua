local VarrenDevToolLinkedList = { size = 0; first = nil, last = nil }

function VarrenDevToolLinkedList:GetInfoAtPosition(position)
    if self.size < position or self.first == nil then
        return nil
    end

    local node = self.first
    while position > 1 do
        node = node.next
        position = position - 1
    end

    return node
end

function VarrenDevToolLinkedList:AddNodeAfter(node, prevNode)
    local tempNext = node.next
    node.next = prevNode
    prevNode.next = tempNext
    self.size = self.size + 1;
end

function VarrenDevToolLinkedList:AddNodesAfter(nodeList, parentNode)
    local tempNext = parentNode.next
    local currNode = parentNode;

    for _, node in pairs(nodeList) do
        currNode.next = node
        currNode = node
        self.size = self.size + 1;
    end

    currNode.next = tempNext

    if tempNext == nil then
        self.last = currNode
    end
end

function VarrenDevToolLinkedList:AddNode(data, dataName)
    local node = self:NewNode(data, dataName)

    if self.first == nil then
        self.first = node
        self.last = node
    else
        if self.last ~= nil then
            self.last.next = node
        end
        self.last = node
    end

    self.size = self.size + 1;
end

function VarrenDevToolLinkedList:NewNode(data, dataName, padding, parent)
    return {
        name = dataName,
        value = data,
        next = nil,
        padding = padding == nil and 0 or padding,
        parent = parent
    }
end

function VarrenDevToolLinkedList:RemoveChildNodes(node)
    local currNode = node

    while true do

        currNode = currNode.next

        if currNode == nil then
            node.next = nil
            self.last = node
            break
        end

        if currNode.padding <= node.padding then
            node.next = currNode
            break
        end

        self.size = self.size - 1
    end
end

function VarrenDevToolLinkedList:Clear()
    self.size = 0
    self.first = nil
    self.last = nil
end

local pairs, tostring, type, print, string, getmetatable, table,pcall =  pairs, tostring, type, print, string, getmetatable, table,pcall
local HybridScrollFrame_CreateButtons, HybridScrollFrame_GetOffset, HybridScrollFrame_Update = HybridScrollFrame_CreateButtons,HybridScrollFrame_GetOffset, HybridScrollFrame_Update

function VarrenDevTool_ExpandCell(info)

    local nodeList = {}
    local padding = info.padding + 1
    local couner = 0
    for k, v in pairs(info.value) do
        if type(v) ~= "userdata" then

            nodeList[couner] = VarrenDevToolLinkedList:NewNode(v, tostring(k), padding, info)
        else
            local mt = getmetatable(info.value)
            if mt then
                nodeList[couner] = VarrenDevToolLinkedList:NewNode(mt.__index, "$metatable", padding, info)
            end
        end
        couner = couner + 1
    end

    table.sort(nodeList, function(a, b)
        return a.name < b.name
    end)

    VarrenDevToolLinkedList:AddNodesAfter(nodeList, info)
    info.expanded = true
    VarrenDevTool_ScrollBar_Update()
end

function VarrenDevTool_ColapseCell(info)
    VarrenDevToolLinkedList:RemoveChildNodes(info)
    info.expanded = nil
    print("size: " .. VarrenDevToolLinkedList.size)
    VarrenDevTool_ScrollBar_Update()
end

function VarrenDevTool_AddData(data, dataName)
    VarrenDevToolLinkedList:AddNode(data, dataName)
    VarrenDevTool_ScrollBar_Update()
end

function VarrenDevTool_ClearData()
    VarrenDevToolLinkedList:Clear()
    VarrenDevTool_ScrollBar_Update()
end

function VarrenDevTool_ScrollBar_Update()

    local scrollFrame = VarrenDevToolScrollFrame

    local buttons = scrollFrame.buttons;
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local totalRowsCount = VarrenDevToolLinkedList.size
    local lineplusoffset; -- an index into our data calculated from the scroll offset

    local nodeInfo = VarrenDevToolLinkedList:GetInfoAtPosition(offset)
    for k, view in pairs(buttons) do

        lineplusoffset = k + offset;
        -- print("ok: " .. lineplusoffset .. "  " .. offset .. "  " .. k .. " " .. (nodeInfo ~= nil and nodeInfo.name or "nil"))
        if lineplusoffset <= totalRowsCount then
            VarrenDevTool_UpdateListItem(view, nodeInfo, lineplusoffset)
            nodeInfo = nodeInfo.next
            view:Show();
        else
            view:Hide();
        end
    end

    HybridScrollFrame_Update(scrollFrame, totalRowsCount * buttons[1]:GetHeight(), scrollFrame:GetHeight());

end



function VarrenDevTool_UpdateListItem(node, info, id)
    local nameButton = node.nameButton;
    local typeButton = node.typeButton
    local valueButton = node.valueButton
    local rowNumberButton = node.rowNumberButton

    local value = info.value
    local name = info.name
    local padding = info.padding

    nameButton:SetPoint("LEFT", node.typeButton, "RIGHT", 20 * padding, 0)

    local valueType = type(value)

    valueButton:SetText(tostring(value))
    nameButton:SetText(tostring(name))
    typeButton:SetText(valueType)
    rowNumberButton:SetText(tostring(id))

    local color = "VarrenDevToolBaseFont"
    if valueType == "table" then
        if name ~= "$metatable" then
            if value.GetObjectType then
                if value.IsForbidden and value:IsForbidden() then
                else
                    valueButton:SetText(value:GetObjectType() .. "  " .. tostring(value))
                end
            end
            color = "VarrenDevToolTableFont";
        else
            color = "VarrenDevToolMetatableFont";
        end
        local resultStringName = tostring(name)
        local MAX_STRING_SIZE = 60
        if #resultStringName >= MAX_STRING_SIZE then
            resultStringName = string.sub(resultStringName, 0, MAX_STRING_SIZE) .. "..."
        end

        local function tablelength(T)
            local count = 0
            for _ in pairs(T) do count = count + 1 end
            return count
        end

        nameButton:SetText(resultStringName .. "   (" .. tablelength(value) .. ") ");

    elseif valueType == "userdata" then
        color = "VarrenDevToolTableFont";
    elseif valueType == "string" then
        valueButton:SetText(string.gsub(string.gsub(tostring(value), "|n", ""), "\n", ""))
        color = "VarrenDevToolStringFont";
    elseif valueType == "number" then
        color = "VarrenDevToolNumberFont";
    elseif valueType == "function" then
        color = "VarrenDevToolFunctionFont";
    end



    node.nameButton:SetNormalFontObject(color);
    node.typeButton:SetNormalFontObject(color)
    node.valueButton:SetNormalFontObject(color)
    node.rowNumberButton:SetNormalFontObject(color)

    if valueType == "table" then
        nameButton:SetScript("OnMouseUp", function(self, button, down)
            print("click")
            if info.expanded then
                VarrenDevTool_ColapseCell(info)
            else
                VarrenDevTool_ExpandCell(info)
            end
        end)
    elseif valueType == "function" then
        nameButton:SetScript("OnMouseUp", function(self, button, down)
            print("click")
            VarrenDevTool_TryCallFunction(info)
        end)
    else
        nameButton:SetScript("OnMouseUp", nil)
    end
end

function VarrenDevTool_TryCallFunction(info)
    local value = info.value

    local ok, result = pcall(value)
    if ok then
        local resultType = type(result)
        local additionalInfo = ""
        if resultType == "string" or resultType == "number" then
            additionalInfo = tostring(result)
        end

        print("returns:  " .. resultType .. " " .. additionalInfo)
    else
        local parent = info.parent
        if parent then
            if parent.name == "$metatable" then
                parent = parent.parent
                print("found metatable" ..  info.name)
            end

            local ok, result = pcall(parent.value[info.name], parent.value)
            local resultType = type(result)
            local additionalInfo = tostring(result)

            print(parent.name ..":".. info.name .."() returns: " .. additionalInfo.. "  ("..resultType ..")" )
        end
    end
end


function DEBUG(self, text)
    if self.debug then
        print(text);
    end
end