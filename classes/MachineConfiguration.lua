local modFolder = g_currentModDirectory

---@class MachineConfiguration
---@field object table
---@field name string
---@field filePath string
---@field terraformNodes table<number, number>
---@field collisionNodes table<number, number>
---@field paintNodes table<number, number>
---@field i3dNode number
---@field rootNode number
---@field availableModes table<number, number>
---@field availableModeByIndex table<number, boolean>
---@field availableModeByName table<string, boolean>
MachineConfiguration = {}
local MachineConfiguration_mt = Class(MachineConfiguration)

function MachineConfiguration.new(object, name, filePath, mt)
    ---@type MachineConfiguration
    local self = setmetatable( {}, mt or MachineConfiguration_mt)

    self.object = object
    self.name = name
    self.filePath = filePath

    self.terraformNodes = {}
    self.collisionNodes = {}
    self.paintNodes = {}

    self.availableModes = {}
    self.availableModeByIndex = {}
    self.availableModeByName = {}

    return self
end

function MachineConfiguration.getXMLFilePath(name, typeName)
    if not typeName then
        Logging.warning('MachineConfiguration.getXMLFilePath: typeName is nil')
        return
    end

    local fileName = typeName .. '_' .. name .. '.xml'
    -- Logging.info('Looking for ' .. fileName)
    local filePath = g_modSettingsDirectory .. 'TerraFarm/configurations/' .. fileName

    if not fileExists(filePath) then
        filePath = modFolder .. 'configurations/' .. fileName
        if not fileExists(filePath) then
            return
        end
    end

    return filePath
end

function MachineConfiguration:save()
    -- TODO: later.. LOW PRIO
end

function MachineConfiguration:load()
    local xmlFile = loadXMLFile(self.name .. '_config', self.filePath)
    if xmlFile == nil or xmlFile == 0 then
        Logging.warning('MachineConfiguration: Failed to read configuration file - ' .. self.filePath)
        return false
    end

    if not self:loadRootNode(xmlFile) then
        return false
    end

    self:loadTerraformNodes(xmlFile)
    self:loadCollisionNodes(xmlFile)
    self:loadPaintNodes(xmlFile)
    self:loadSettings(xmlFile)

    delete(xmlFile)

    return true
end

function MachineConfiguration:loadRootNode(xmlFile)
    local nodePath = getXMLString(xmlFile, 'configuration.i3d#rootNodePath')
    self.i3dNode = I3DUtil.indexToObject(self.object.components,nodePath, self.object.i3dMappings)

    if not self.i3dNode then
        Logging.error('MachineConfiguration: Failed to find i3d from configuration - ' .. tostring(nodePath))
        Logging.info(self.filePath)
        return
    end

    self.rootNode = createTransformGroup('terraformRootNode')
    link(self.i3dNode, self.rootNode)

    setTranslation(self.rootNode,
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d#x'), 0),
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d#y'), 0),
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d#z'), 0)
    )

    return true
end

function MachineConfiguration:loadTerraformNodes(xmlFile)
    local parentNode = createTransformGroup('terraformNodes')
    link(self.rootNode, parentNode)

    setTranslation(parentNode,
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d.terraformNodes#x'), 0),
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d.terraformNodes#y'), 0),
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d.terraformNodes#z'), 0)
    )

    local i = 0
    while true do
        local key = string.format('configuration.i3d.terraformNodes.node(%d)', i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local node = createTransformGroup('terraformNode' .. i)
        link(parentNode, node)
        setTranslation(node,
            Utils.getNoNil(getXMLFloat(xmlFile, key .. '#x'), 0),
            Utils.getNoNil(getXMLFloat(xmlFile, key .. '#y'), 0),
            Utils.getNoNil(getXMLFloat(xmlFile, key .. '#z'), 0)
        )
        table.insert(self.terraformNodes, node)
        i = i + 1
    end
end

function MachineConfiguration:loadCollisionNodes(xmlFile)
    local parentNode = createTransformGroup('collisionNodes')
    link(self.rootNode, parentNode)

    setTranslation(parentNode,
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d.collisionNodes#x'), 0),
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d.collisionNodes#y'), 0),
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d.collisionNodes#z'), 0)
    )

    local i = 0
    while true do
        local key = string.format('configuration.i3d.collisionNodes.node(%d)', i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local node = createTransformGroup('collisionNode' .. i)
        link(parentNode, node)
        setTranslation(node,
            Utils.getNoNil(getXMLFloat(xmlFile, key .. '#x'), 0),
            Utils.getNoNil(getXMLFloat(xmlFile, key .. '#y'), 0),
            Utils.getNoNil(getXMLFloat(xmlFile, key .. '#z'), 0)
        )
        table.insert(self.collisionNodes, node)
        i = i + 1
    end
end

function MachineConfiguration:loadPaintNodes(xmlFile)
    local parentNode = createTransformGroup('paintNodes')
    link(self.rootNode, parentNode)

    setTranslation(parentNode,
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d.paintNodes#x'), 0),
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d.paintNodes#y'), 0),
        Utils.getNoNil(getXMLFloat(xmlFile, 'configuration.i3d.paintNodes#z'), 0)
    )

    local i = 0
    while true do
        local key = string.format('configuration.i3d.paintNodes.node(%d)', i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local node = createTransformGroup('paintNode' .. i)
        link(parentNode, node)
        setTranslation(node,
            Utils.getNoNil(getXMLFloat(xmlFile, key .. '#x'), 0),
            Utils.getNoNil(getXMLFloat(xmlFile, key .. '#y'), 0),
            Utils.getNoNil(getXMLFloat(xmlFile, key .. '#z'), 0)
        )
        table.insert(self.paintNodes, node)
        i = i + 1
    end
end

function MachineConfiguration:loadSettings(xmlFile)
    self.terraformStrength = getXMLFloat(xmlFile, 'configuration.setttings.terraformStrength')
    self.terraformRadius = getXMLFloat(xmlFile, 'configuration.setttings.terraformRadius')
    self.terraformPaintRadius = getXMLFloat(xmlFile, 'configuration.setttings.terraformPaintRadius')
    self.terraformSmoothStrength = getXMLFloat(xmlFile, 'configuration.setttings.terraformSmoothStrength')
    self.terraformSmoothRadius = getXMLFloat(xmlFile, 'configuration.setttings.terraformSmoothRadius')
    self.terraformFlattenStrength = getXMLFloat(xmlFile, 'configuration.setttings.terraformFlattenStrength')
    self.terraformFlattenRadius = getXMLFloat(xmlFile, 'configuration.setttings.terraformFlattenRadius')
    self.volumeFillRatio = getXMLFloat(xmlFile, 'configuration.setttings.volumeFillRatio')

    local i = 0
    while true do
        local key = string.format('configuration.settings.availableModes.mode(%d)', i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local modeName = getXMLString(xmlFile, key)
        if modeName then
            local mode = g_terraFarm.NAME_TO_MODE[modeName]
            if mode then
                table.insert(self.availableModes, mode)
                self.availableModeByIndex[mode] = true
                self.availableModeByName[modeName] = true
            else
                Logging.warning('MachineConfiguration.loadSettings: unknown mode - ' .. tostring(mode))
            end
        end
        i = i + 1
    end
end