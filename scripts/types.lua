---@meta

---@class Theme
---@field id string
---@field name string
---@field xmlFilename string

---@alias Position number[]

---@class DrivableVehicle : Vehicle, Drivable

---@class FillUnitVehicle : Vehicle, FillUnit

---@class MachineType
---@field id string
---@field name string
---@field useDischargeable boolean
---@field useDrivingDirection boolean
---@field useFillUnit boolean
---@field useLeveler boolean
---@field useShovel boolean

---@class TerrainLayer
---@field id number
---@field name string
---@field title string

---@class FillUnitObject
---@field fillUnitIndex number
---@field capacity number
---@field fillLevel number
---@field fillType number
---@field lastValidFillType number

---@class SavegameObject
---@field key string
---@field xmlFile XMLFile

---@class Mod
---@field id number
---@field title string
---@field version string
---@field modName string
---@field modDir string

---@class SpecializationProperties
---@field actionEvents table
---@field dirtyFlagEffect number
---@field machineTypeId string
---@field machineType MachineType
---@field isExternal boolean
---@field xmlFilenameConfig string | nil -- Only used if isExternal is true
---@field state MachineState
---@field surveyorId string | nil
---@field terrainLayerId number
---@field fillUnitIndex number | nil
---@field fillUnit FillUnitObject | nil
---@field fillTypeIndex number
---@field fillType FillTypeObject
---@field fillUnitSource FillUnitSourceType
---@field requireTurnedOn boolean
---@field requirePoweredOn boolean
---@field hasAttachable boolean
---@field hasDischargeable boolean
---@field hasDrivable boolean
---@field hasFillUnit boolean
---@field hasEnterable boolean
---@field hasLeveler boolean
---@field hasMotorized boolean
---@field hasShovel boolean
---@field hasTurnOnVehicle boolean
---@field enabled boolean
---@field resourcesEnabled boolean
---@field active boolean
---@field inputMode MachineMode
---@field modesInput MachineMode[]
---@field outputMode MachineMode
---@field modesOutput MachineMode[]
---@field effectAnimationNodes table
---@field effects Effect[]
---@field sample SampleObject | nil
---@field playSound boolean
---@field turnOffSoundTimer number | nil
---@field isEffectActive boolean
---@field isEffectActiveSent boolean
---@field lastEffect Effect | nil
---@field stopEffectTime number | nil
---@field effectTurnOffThreshold number
---@field stateObjectChanges table | nil
---
---@field dischargeNode DischargeNode | nil
---@field levelerNode LevelerNode | nil
---@field shovelNode ShovelNode | nil
---@field workArea MachineWorkArea
---@field updateInterval number
---@field lastIntervalUpdate number

---@class AttachableSpecialization
---@field attacherJoint table
---@field inputAttacherJoints table
---@field brakeForce number
---@field maxBrakeForce number
---@field loweredBrakeForce number
---@field maxBrakeForceMass number
---@field airConsumerUsage number
---@field allowFoldingWhileAttached boolean
---@field allowFoldingWhileLowered boolean
---@field blockFoliageDestruction boolean
---@field requiresExternalPower boolean
---@field attachToPowerWarning boolean
---@field updateWheels boolean
---@field updateSteeringAxleAngle boolean
---@field isSelected boolean
---@field attachTime number
---@field steeringAxleAngle number
---@field steeringAxleTargetAngle number
---@field detachingInProgress boolean
---@field supportAnimations table
---@field toolCameras table
---@field isHardAttached boolean
---@field isAdditionalAttachment boolean


---@class DischargeableSpecialization
---@field currentDischargeState number
---@field dischargeNodes DischargeNode[]
---@field fillUnitDischargeNodeMapping table<number, DischargeNode>
---@field dischargNodeMapping table<number, DischargeNode>
---@field triggerToDischargeNode table<number, DischargeNode>
---@field activationTriggerToDischargeNode table<number, DischargeNode>
---@field requiresTipOcclusionArea boolean
---@field consumePower boolean
---@field stopDischargeOnDeactivate boolean
---@field dischargedLiters number

---@class DischargeNode
---@field node number
---@field fillUnitIndex number
---@field unloadInfoIndex number
---@field stopDischargeOnEmpty boolean
---@field canDischargeToGround boolean
---@field canDischargeToObject boolean
---@field canStartDischargeAutomatically boolean
---@field canStartGroundDischargeAutomatically boolean
---@field stopDischargeIfNotPossible boolean
---@field canDischargeToGroundAnywhere boolean
---@field emptySpeed number
---@field effectTurnOffThreshold number
---@field lineOffset number
---@field litersToDrop number
---@field toolType number
---@field info DischargeNodeInfo
---@field raycast DischargeNodeRaycast
---@field maxDistance number
---@field dischargeObject any
---@field dischargeHitObject any
---@field dischargeHitObjectUnitIndex number | nil
---@field dischargeHitTerrain boolean
---@field dischargeShape number | nil
---@field dischargeDistance number
---@field dischargeDistanceSent number
---@field dischargeFillUnitIndex number
---@field dischargeHit boolean
---@field trigger DischargeNodeTrigger
---@field activationTrigger DischargeNodeActivationTrigger
---@field fillTypeConverter table | nil
---@field distanceObjectChanges table | nil
---@field stateObjectChanges table | nil
---@field nodeActiveObjectChanges table | nil
---@field effects table
---@field sentHitDistance number
---@field isEffectActive boolean
---@field isEffectActiveSent boolean
---@field lastEffect table | nil

---@class DischargeNodeInfo
---@field node number
---@field width number
---@field length number
---@field zOffset number
---@field yOffset number
---@field limitToGround boolean
---@field useRaycastHitPosition boolean

---@class DischargeNodeRaycast
---@field node number | nil
---@field useWorldNegYDirection boolean
---@field yOffset number

---@class DischargeNodeTrigger
---@field node number | nil
---@field objects table
---@field numObjects number

---@class DischargeNodeActivationTrigger
---@field node number | nil
---@field objects table
---@field numObjects number

---@class ShovelSpecialization
---@field ignoreFillUnitFillType boolean
---@field useSpeedLimit boolean
---@field shovelNodes ShovelNode[]
---@field shovelDischargeInfo ShovelDischargeInfo
---@field effectDirtyFlag number
---@field loadingFillType number
---@field lastValidFillType number
---@field smoothAccumulation number

---@class ShovelDischargeInfo
---@field dischargeNodeIndex number
---@field node number | nil
---@field minSpeedAngle number -- nil if node is nil
---@field maxSpeedAngle number -- nil if node is nil

---@class ShovelNode
---@field node number
---@field fillUnitIndex number
---@field loadInfoIndex number
---@field width number
---@field length number
---@field yOffset number
---@field zOffset number
---@field needsMovement boolean
---@field lastPosition number[]
---@field fillLitersPerSecond number
---@field maxPickupAngle number | nil
---@field needsAttacherVehicle boolean
---@field resetFillLevel boolean
---@field ignoreFillLevel boolean
---@field ignoreFarmlandState boolean
---@field allowsSmoothing boolean
---@field smoothGroundRadius number
---@field smoothOverlap number

---@class LevelerSpecialization
---@field pickUpDirection number
---@field maxFillLevelPerMS number
---@field fillUnitIndex number | nil
---@field nodes LevelerNode[]
---@field litersToPickup number
---@field smoothAccumulation number
---@field lastFillLevelMoved number
---@field lastFillLevelMovedPct number
---@field lastFillLevelMovedTarget number
---@field lastFillLevelMovedBuffer number
---@field lastFillLevelMovedBufferTime number
---@field lastFillLevelMovedBufferTimer number
---@field forceNode number | nil
---@field forceDirNode number | nil
---@field maxForce number
---@field lastForce number
---@field forceDir number
---@field ignoreFarmlandState boolean
---@field dirtyFlag number

---@class LevelerNode
---@field node number
---@field referenceFrame number -- parent transform group node
---@field zOffset number
---@field yOffset number
---@field width number
---@field halfWidth number
---@field minDropWidth number
---@field halfMinDropWidth number
---@field maxDropWidth number
---@field halfMaxDropWidth number
---@field minDropDirOffset number
---@field maxDropDirOffset number
---@field numHeightLimitChecks number
---@field alignToWorldY boolean
---@field occlusionAreas table
---@field allowsSmoothing boolean
---@field smoothGroundRadius number
---@field smoothOverlap number
---@field smoothDirection number
---@field lineOffsetPickUp number | nil
---@field lineOffsetDrop number | nil
---@field lastPickUp number
---@field lastDrop number
---@field lastDrop2 number
---@field lineOffsetDrop2 number
---@field fillUnitIndex number
---@field vehicle Vehicle
---@field onLevelerRaycastCallback function -- Leveler.onLevelerRaycastCallback

---@class FillUnitSpecialization
---@field fillUnits FillUnitItem[]
---@field exactFillRootNodeToFillUnit table<number, FillUnitItem>
---@field exactFillRootNodeToExtraDistance table<number, number>
---@field hasExactFillRootNodes boolean
---@field activeAlarmTriggers table
---@field fillTrigger FillUnitTrigger
---@field unloading FillUnitUnloading[] | nil
---@field isInfoDirty boolean
---@field fillUnitInfos table
---@field dirtyFlag number

---@class FillUnitUnloading
---@field node number
---@field width number
---@field offset number

---@class FillUnitInfo
---@field precision number
---@field fillLevel number
---@field title string
---@field unit string

---@class FillUnitTrigger
---@field triggers table
---@field activatable FillActivatable
---@field isFilling boolean
---@field currentTrigger number | nil
---@field selectedTrigger number | nil
---@field litersPerSecond number
---@field consumePtoPower boolean

---@class FillUnitItem
---@field fillUnitIndex number
---@field capacity number
---@field fillLevel number
---@field fillType number
---@field lastValidFillType number

---@class FoldableSpecialization
---@field turnOnFoldDirection number
---@field negDirectionText string
---@field posDirectionText string
---@field foldingParts table
---@field foldMoveDirection number
