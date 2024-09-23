---@class TerrainLayerListItem
---@field id number
---@field name string

---@class SelectTerrainLayerDialog : MessageDialog
---@field list SmoothListElement
---@field superClass fun(): MessageDialog
SelectTerrainLayerDialog = {}

SelectTerrainLayerDialog.CLASS_NAME = 'SelectTerrainLayerDialog'
SelectTerrainLayerDialog.XML_FILENAME = g_currentModDirectory .. 'xml/gui/dialogs/SelectTerrainLayerDialog.xml'

SelectTerrainLayerDialog.CONTROLS = {
    'list',
}

local SelectTerrainLayerDialog_mt = Class(SelectTerrainLayerDialog, MessageDialog)

---@return SelectTerrainLayerDialog
---@nodiscard
function SelectTerrainLayerDialog.new()
    ---@type SelectTerrainLayerDialog
    local self = MessageDialog.new(nil, SelectTerrainLayerDialog_mt)

    self:registerControls(SelectTerrainLayerDialog.CONTROLS)

    return self
end

function SelectTerrainLayerDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[SelectTerrainLayerDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function SelectTerrainLayerDialog:load()
    g_gui:loadGui(SelectTerrainLayerDialog.XML_FILENAME, SelectTerrainLayerDialog.CLASS_NAME, self)
end

function SelectTerrainLayerDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

---@param fn function | nil
---@param target any
function SelectTerrainLayerDialog:setSelectCallback(fn, target)
    self.selectCallbackFunction = fn
    self.selectCallbackTarget = target
end

---@param selectTerrainLayerId number | nil
function SelectTerrainLayerDialog:show(selectTerrainLayerId)
    g_gui:showDialog(SelectTerrainLayerDialog.CLASS_NAME)

    self:setSelectedItem(selectTerrainLayerId)
end

function SelectTerrainLayerDialog:onOpen()
    self:superClass().onOpen(self)

    self.list:reloadData()
end

---@param terrainLayerId number | nil
function SelectTerrainLayerDialog:setSelectedItem(terrainLayerId)
    if terrainLayerId ~= nil then
        for index, item in ipairs(g_resources.terrainLayers) do
            if item.id == terrainLayerId then
                self.list:setSelectedIndex(index)
                return
            end
        end
    end

    self.list:setSelectedIndex(1)
end

function SelectTerrainLayerDialog:getNumberOfItemsInSection()
    return #g_resources.terrainLayers
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectTerrainLayerDialog:populateCellForItemInSection(list, section, index, cell)
    local item = g_resources.terrainLayers[index]

    if item ~= nil then
        cell:getAttribute('image'):setTerrainLayer(g_currentMission.terrainRootNode, item.id)
        cell:getAttribute('name'):setText(item.title)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function SelectTerrainLayerDialog:onItemDoubleClick(list, section, index, cell)
    self:sendCallback(index)
end

function SelectTerrainLayerDialog:onClickApply()
    self:sendCallback(self.list:getSelectedIndexInSection())
end

---@param index number | nil
function SelectTerrainLayerDialog:sendCallback(index)
    local item = g_resources.terrainLayers[index]

    self:close()

    if self.selectCallbackFunction ~= nil then
        if self.selectCallbackTarget ~= nil then
            self.selectCallbackFunction(self.selectCallbackTarget, item and item.id)
        else
            self.selectCallbackFunction(item and item.id)
        end
    end
end

function SelectTerrainLayerDialog:onClickBack(forceBack, usedMenuButton)
    if (self.isCloseAllowed or forceBack) and not usedMenuButton then
        self:sendCallback()

        return false
    else
        return true
    end
end
