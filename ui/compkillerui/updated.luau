loadstring([[getgenv().LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(func) return func end]])()

--[[
    Initiate
]]

local cloneref = cloneref or function(ref) return ref end;
local players = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage')) 
local collectionService = cloneref(game:GetService('CollectionService')) 
local httpService = cloneref(game:GetService('HttpService'))
local tweenService = cloneref(game:GetService('TweenService'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = players.LocalPlayer
local camera = workspace.CurrentCamera

local function run(func)
    local suc, err = pcall(func)
    if not suc then
        task.spawn(error, err)
    end
end

local void = function() end
local Loaded = false
local isPremium = true

local guilib = loadstring(game:HttpGet('https://raw.githubusercontent.com/Maxlasertech/Alchemy/main/ui/compkillerui/updated.luau'))() --> using latest version of modded compkiller ui
local Flags = guilib.Flags

local notify = guilib.newNotify()

local window = guilib.new({
    Name = 'ALCHEMY',
    Logo = 'rbxassetid://84221975933832',
    Keybind = 'RightControl',
	TextSize = 15,
})

guilib:ChangeHighlightColor(Color3.fromRGB(0, 255, 110))

local Watermark = window:Watermark()
Watermark:AddText({Icon = 'user', Text = lplr.Name})
Watermark:AddText({Icon = 'clock', Text = guilib:GetDate()})

local Time = Watermark:AddText({Icon = 'timer', Text = 'N/A'})

task.spawn(function()
	repeat
        Time:SetText(guilib:GetTimeNow())
        task.wait(1)
    until false
end)

window:Update({ExpireDate = (isPremium and 'PREMIUM') or 'FREEMIUM'})

local categories = setmetatable({}, {
    __newindex = function(self, index, value)
        rawset(self, index, window[value[3] or 'DrawContainerTab'](window, {
            Name = index,
            Icon = value[1],
            Type = value[2],
            EnableScrolling = true
        }))

        return rawget(self, index)
    end
})

window:DrawCategory({
    Name = 'Main'
})

categories.Combat = {'swords', 'Double'}
categories.Player = {'person-standing', 'Double'}
categories.Render = {'eye', 'Double'}
categories.Utility = {'refresh-cw', 'Double'}

window:DrawCategory({
    Name = 'Fun'
})

categories.World = {'earth', 'Single'}
categories.Minigames = {'gamepad', 'Single'}

window:DrawCategory({
    Name = 'GUI'
})

categories.Settings = {'settings-3', 'Double', 'DrawTab'}

--[[
    Bedwars Initiate
]]

local Features = setmetatable({}, {
    __index = function(self, index)
        self[index] = {
            Enabled = false,
            Storage = {},
            Value = 0,
            Clean = function(self, con)
                table.insert(self.Storage, con)
            end
        }

        return self[index]
    end
})

--getrawmetatable(Features):__index('GUI') im just overcomplicating things, lmao
Features.GUI.Enabled = true

local disconnectMaid = function(con)
    if typeof(con) == 'RBXScriptSignal' or typeof(con) == 'RBXScriptConnection' then
        pcall(con.Disconnect, con)
    elseif typeof(con) == 'Instance' then
        pcall(con.Destroy, con)
    elseif typeof(con) == 'thread' then
        pcall(task.cancel, con)
    elseif typeof(con) == 'function' then
        pcall(con)
    end
end

run(function()
    task.spawn(function()
        repeat
            for _, v in Features do
                if not v.Enabled and #v.Storage > 0 then
                    for __, con in v.Storage do
                        disconnectMaid(con)
                    end
                    table.clear(v.Storage)
                end
            end
            task.wait()
        until false
    end)
end)

local bedwars, store = {
    matchState = 0,
    inventories = {}
}
local LastTarget = tick()

local entitylib = {}
local predictionlib = loadstring(game:HttpGet('https://raw.githubusercontent.com/new-qwertyui/CatV5/main/libraries/prediction.lua'))()

run(function()
    local RaycastFilter = RaycastParams.new()
    RaycastFilter.FilterType = Enum.RaycastFilterType.Exclude
    RaycastFilter.RespectCanCollide = true

    function entitylib:Wall(Data)
        if Data.Filter and typeof(Data.Filter) == 'table' then
            local Pre = {camera, lplr.Character}

            for _, v in Data.Filter do
                table.insert(Pre, v)
            end

            RaycastFilter.FilterDescendantsInstances = Pre
        else
            RaycastFilter.FilterDescendantsInstances = {camera, lplr.Character}
        end

        return workspace:Raycast(Data.Origin, (Data.Position - Data.Origin), RaycastFilter)
    end

    function entitylib:isAlive(player)
        if not Loaded then
            return false
        end
        
        player = player or lplr

        local success, result = pcall(function()
            return player.Character.PrimaryPart ~= nil and player.Character.Humanoid.Health > 0
        end)

        return success and result or false
    end

    function entitylib:EntityMouse(Data)
        Data.Origin = Data.Origin or inputService:GetMouseLocation()

        local Entities = {}

        if self:isAlive() then
            if Data.Players then
                for _, v in players:GetPlayers() do
                    if v ~= lplr and entitylib:isAlive(v) then
                        if not Data.Team or v.Team ~= lplr.Team then
                            local pos, canSee = workspace.CurrentCamera:WorldToScreenPoint(v.Character.PrimaryPart.Position)
                            
                            if canSee then
                                local magnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(Data.Origin.X, Data.Origin.Y)).Magnitude

                                if magnitude <= Data.Range then
                                    if not Data.Wallcheck or not entitylib:Wall({Origin = lplr.Character.PrimaryPart.Position, Position = v.Character.PrimaryPart.Position}) then
                                        table.insert(Entities, v)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if Data.NPCs then
                for _, v in collectionService:GetTagged('entity') do
                    if not players:FindFirstChild(v.Name) and v.PrimaryPart then
                        local pos, canSee = workspace.CurrentCamera:WorldToScreenPoint(v.PrimaryPart.Position)
                            
                        if canSee then
                            local magnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(Data.Origin.X, Data.Origin.Y)).Magnitude

                            if magnitude <= Data.Range then
                                if not Data.Wallcheck or not entitylib:Wall({Origin = Data.Origin, Position = v.PrimaryPart.Position}) then
                                    table.insert(Entities, {
                                        Character = setmetatable({
                                            RootPart = v.PrimaryPart,
                                            Head = v.PrimaryPart
                                        }, {
                                            __index = function(__, index)
                                                return v[index]
                                            end
                                        })
                                    })
                                    break
                                end
                            end
                        end
                    end
                end
            end

            table.sort(Entities, function(a, b)
                return (lplr.Character.PrimaryPart.Position - a.Character.PrimaryPart.Position).Magnitude <= (lplr.Character.PrimaryPart.Position - b.Character.PrimaryPart.Position).Magnitude
            end)
        end

        return Entities[1]
    end

    function entitylib:AllPosition(Data)
        Data.Origin = Data.Origin or lplr.Character.PrimaryPart.Position

        local Entities = {}

        if self:isAlive() then
            if Data.Players then
                for _, v in players:GetPlayers() do
                    if v ~= lplr and entitylib:isAlive(v) then
                        if not Data.Team or v.Team ~= lplr.Team then
                            local magnitude = (Data.Origin - v.Character.PrimaryPart.Position).Magnitude

                            if magnitude <= Data.Range then
                                if not Data.Wallcheck or not entitylib:Wall({Origin = Data.Origin, Position = v.Character.PrimaryPart.Position}) then
                                    table.insert(Entities, v)
                                end
                            end
                        end
                    end
                end
            end

            if Data.NPCs then
                for _, v in collectionService:GetTagged('entity') do
                    if not players:FindFirstChild(v.Name) and v and v.Parent and v.PrimaryPart then
                        local magnitude = (Data.Origin - v.PrimaryPart.Position).Magnitude

                        if magnitude <= Data.Range then
                            if not Data.Wallcheck or not entitylib:Wall({Origin = Data.Origin, Position = v.PrimaryPart.Position}) then
                                table.insert(Entities, setmetatable({
                                    Character = v,
                                }, {__index = function(self, index)
                                    return v[index]
                                end}))
                            end
                        end
                    end
                end
            end
        end

        return Entities
    end
end)

local function switchTool(tool, cooldown, visualize)
    local slot = nil

    if visualize then
        for i, v in bedwars.Inventory.Hotbars do
			if v.item and v.item.tool == tool then 
				slot = i
                break
			end
		end    
    end

    if not cooldown then
        if slot then
            store:dispatch({
                type = 'InventorySelectHotbarSlot',
                slot = slot - 1
            })
        else
            bedwars.Client:Get('SetInvItem'):CallServer({
                hand = tool
            })
        end
    else
        task.spawn(function()
            if slot then
                store:dispatch({
				    type = 'InventorySelectHotbarSlot',
                    slot = slot - 1
                })
            else
                bedwars.Client:Get('SetInvItem'):CallServer({
                    hand = tool
                })
            end
        end)
        task.wait(cooldown)
    end
end

local Boost = 0

local function getAdditonalSpeed(bool)
    local multi, increase, modifiers = 0, true, bedwars.SprintController:getMovementStatusModifier():getModifiers()

    for v in modifiers do
        local val = v.constantSpeedMultiplier and v.constantSpeedMultiplier or 0
        if val and val > math.max(multi, 1) then
            increase = false
            multi = val - (0.06 * math.round(val))
        end
    end

    for v in modifiers do
        multi += math.max((v.moveSpeedMultiplier or 0) - 1, 0)
    end

    if multi > 0 and increase then
        multi += 0.16 + (0.02 * math.round(multi))
    end

    return ((bool and 1 or 20) + Boost) * (multi + 1)
end

local AirTime = tick()
local Params

run(function()
    local Knit

    for _ = 1, 7 do
        local success = pcall(function()
            Knit = require(replicatedStorage.rbxts_include.node_modules['@easy-games'].knit.src).KnitClient
        end)

        if not success then
            task.wait(0.5)
        end
    end

    local BlockController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out).BlockEngine

    bedwars = setmetatable({
        -- table --
        Zap = require(lplr.PlayerScripts.TS.lib.network),
        Client = require(replicatedStorage.TS.remotes).default.Client,
        ItemMeta = require(replicatedStorage.TS.item['item-meta']).items,
        BlockPlacer = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.client.placement['block-placer']).BlockPlacer,
        KnockbackUtil = require(replicatedStorage.TS.damage['knockback-util']).KnockbackUtil,
        ProjectileMeta = require(replicatedStorage.TS.projectile['projectile-meta']).ProjectileMeta,
        BlockController = {},
        -- metatable --
        Inventory = setmetatable({
            All = {}
        }, {
            __index = function(self, index)
                index = index:lower()

                if entitylib:isAlive() then
                    if index == 'hand' then
                        local hand = lplr.Character.HandInvItem.Value

                        return {
                            tool = hand,
                            amount = hand and hand:GetAttribute('Amount') or 0
                        }
                    else
                        local item = lplr.Character.InventoryFolder.Value:FindFirstChild(index)  
                        
                        if item then
                            return {
                                tool = item,
                                amount = item:GetAttribute('Amount')
                            }
                        end
                    end
                end
            end
        }),
        Events = setmetatable({}, {
            __index = function(self, index)
                rawset(self, index, Instance.new('BindableEvent'))
                return rawget(self, index)
            end
        }),
        -- functions --
        HasItemType = function(self, tool, itemtype)
            local Meta = self.ItemMeta[tool.Name]

            return Meta and rawget(Meta, itemtype), Meta
        end,
        getBestItemType = function(self, itemtype, index)
            local item, damage = nil, math.huge

            for i, v in self.ItemMeta do
                if self:HasItemType({Name =  i}, itemtype) then
                    local tool = bedwars.Inventory[i]

                    if tool and v[itemtype][index] and v[itemtype][index] < damage then
                        item, damage = tool, v[itemtype][index]
                    end
                end
            end

            return item, damage
        end,
    }, {
        __index = function(self, index)
            rawset(self, index, Knit.Controllers[index])
            return rawget(self, index)
        end
    })

    local BlockPlacer = bedwars.BlockPlacer.new(bedwars.BlockEngine, 'bedrock')

    function bedwars.BlockController:placeBlock(Data)
        BlockPlacer.blockType = Data.Tool.Name
        return BlockPlacer:placeBlock(BlockController:getBlockPosition(Data.Position))
    end

    function bedwars.BlockController:hasBlock(Data)
		local round = BlockController:getBlockPosition(Data.Position)

		return BlockController:getStore():getBlockAt(round), round
	end

    store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
    
    Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.RespectCanCollide = true

    task.spawn(function()
        repeat
            task.wait()

            if not entitylib:isAlive() then
                AirTime = tick()
                continue
            end

            local root = lplr.Character.PrimaryPart

            Params.FilterDescendantsInstances = {lplr.Character, camera}
            Params.CollisionGroup = root.CollisionGroup

            local ray = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), Params)
            
            if ray then
                AirTime = tick()
            end
        until not Features.GUI.Enabled
    end)

    Features.GUI:Clean(store.changed:connect(function(new, old)
        if new.Inventory ~= old.Inventory then 
            bedwars.Inventory.Hotbars = new.Inventory.observedInventory.hotbar or {}
            bedwars.Inventory.All = new.Inventory.observedInventory.inventory and new.Inventory.observedInventory.inventory.items or {}
        end
    end))

    Features.GUI:Clean(bedwars.Zap.EntityDamageEventZap.On(function(...)
        bedwars.Events.EntityDamaged:Fire({
            entityInstance = ...,
            damage = select(2, ...),
            damageType = select(3, ...),
            fromPosition = select(4, ...),
            fromEntity = select(5, ...),
            knockbackMultiplier = select(6, ...),
            knockbackId = select(7, ...),
            disableDamageHighlight = select(13, ...)
        })
    end))
end)

local LastDamaged = tick()
Features.GUI:Clean(bedwars.Events.EntityDamaged.Event:Connect(function(Data)
    if tick() > (LastDamaged or 0) then
        local player = Data.entityInstance and players:GetPlayerFromCharacter(Data.entityInstance)
        if player and player == lplr and (Data.knockbackMultiplier and Data.knockbackMultiplier.horizontal and Data.knockbackMultiplier.horizontal > 0 or players:GetPlayerFromCharacter(Data.fromEntity) ~= nil) then
            local knockbackBoost = bedwars.KnockbackUtil.calculateKnockbackVelocity(Vector3.one, 1, {
                vertical = 0,
                horizontal = Data.knockbackMultiplier and Data.knockbackMultiplier.horizontal
            }).Magnitude * 0.9

            local secs = Data.knockbackMultiplier and Data.knockbackMultiplier.horizontal or 1

            if secs then
                secs /= 1.5
            end
            
            Boost = knockbackBoost
            LastDamaged = tick() + (lplr:GetNetworkPing() + (secs / 1.4))

            task.delay(secs, function()
                Boost = 0
            end)
        end
    end
end))

--[[
    Modules
]]

--[[
    Combat
]]

--[[local Dumps = {}

for category, draw in categories do
    category = category:lower()

    if draw.DrawTab then
        Dumps[category] = {}

        local old; old = hookfunction(draw.DrawTab, function(...)
            local result = old(...)
            local moduleName = select(2, ...).Name:lower():gsub('[^%w%s%p]', '')

            if not Dumps[category][moduleName] then
                Dumps[category][moduleName] = {}
            end

            local sec; sec = hookfunction(result.DrawSection, function(...)
                local res = sec(...)

                for _, func in res do
                    if typeof(func) == 'function' then
                        local call; call = hookfunction(func, function(...)
                            local Args, NewRes = select(2, ...), call(...)

                            Dumps[category][moduleName][Args.Name:lower()] = Args.Name

                            return NewRes
                        end)
                    end
                end

                return res
            end)

            return result
        end)
    elseif draw.DrawSection then
        Dumps[category] = {}

        local sec; sec = hookfunction(draw.DrawSection, function(...)
            local res = sec(...)

            local moduleName = select(2, ...).Name:lower():gsub('[^%w%s%p]', '')

            if not Dumps[category][moduleName] then
                Dumps[category][moduleName] = {}
            end

            for _, func in res do
                if typeof(func) == 'function' then
                    local call; call = hookfunction(func, function(...)
                        local Args, NewRes = select(2, ...), call(...)

                        Dumps[category][moduleName][Args.Name:lower()] = Args.Name

                        return NewRes
                    end)
                end
            end

            return res
        end)
    end
end   
getgenv().Dumps = Dumps]]
 
local Texts = {}

for category, draw in categories do -- If you dont wanna use the categories, then you can store all ur tabs in a table so this works
    category = category:lower()

    if draw.DrawTab then
        Texts[category] = {}

        local old; old = hookfunction(draw.DrawTab, function(...)
            local result = old(...)
            local moduleName = select(2, ...).Name:lower():gsub('[^%w%s%p]', '')

            if not Texts[category][moduleName] then
                Texts[category][moduleName] = {}
            end

            local sec; sec = hookfunction(result.DrawSection, function(...)
                local res = sec(...)

                for _, func in res do
                    if typeof(func) == 'function' then
                        local call; call = hookfunction(func, function(...)
                            local Args, NewRes = select(2, ...), call(...)

                            Texts[category][moduleName][Args.Name:lower()] = NewRes

                            return NewRes
                        end)
                    end
                end

                return res
            end)

            return result
        end)
    elseif draw.DrawSection then
        Texts[category] = {}

        local sec; sec = hookfunction(draw.DrawSection, function(...)
            local res = sec(...)

            local moduleName = select(2, ...).Name:lower():gsub('[^%w%s%p]', '')

            if not Texts[category][moduleName] then
                Texts[category][moduleName] = {}
            end

            for _, func in res do
                if typeof(func) == 'function' then
                    local call; call = hookfunction(func, function(...)
                        local Args, NewRes = select(2, ...), call(...)

                        Texts[category][moduleName][Args.Name:lower()] = NewRes

                        return NewRes
                    end)
                end
            end

            return res
        end)
    end
end    

run(function()
    local AutoAim = categories.Combat:DrawTab({
        Name = 'Aim Assist',
        Type = 'Double'
    });

    local General = AutoAim:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local Targets = AutoAim:DrawSection({
        Name = 'Misc',
        Position = 'right'
    })

    local function wrapAngle(num)
        num = num % math.pi
        num -= num >= (math.pi / 2) and math.pi or 0
        num += num < -(math.pi / 2) and math.pi or 0
        return num
    end

    local FOVCircle = Drawing.new('Circle')
	FOVCircle.Filled = false
    FOVCircle.Position = window.Root.AbsoluteSize / 2
    FOVCircle.NumSides = 100
    FOVCircle.Transparency = 1

    Features.GUI:Clean(function()
        FOVCircle.Visible = false
    end)

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'AutoAim',
        Function = function(call)
            Features.AimAssist.Enabled = call
            if call then
                Features.AimAssist:Clean(runService.PreRender:Connect(function(delta)
                    if not Loaded then
                        return
                    end

                    if (not Flags.AutoAimMouse:GetValue() or inputService:IsMouseButtonPressed(0)) and entitylib:isAlive() then
                        local Target = entitylib:EntityMouse({
                            Range = Flags.AutoAimFOVRadius:GetValue(),
                            Players = Flags.AutoAimIncludePlayers:GetValue(),
                            NPCs = Flags.AutoAimIncludeNPCs:GetValue(),
                            Wallcheck = Flags.AutoAimWallCheck:GetValue(),
                            Team = Flags.AutoAimTeamsCheck:GetValue()
                        })

                        if Target then
                            local facing = camera.CFrame.LookVector
                            local new = (Target.Character[Flags.AutoAimPart:GetValue()].Position - camera.CFrame.Position).Unit
                            new = new == new and new or Vector3.zero
                            
                            if new ~= Vector3.zero then                                 
                                local diffYaw = wrapAngle(math.atan2(facing.X, facing.Z) - math.atan2(new.X, new.Z))
                                local diffPitch = math.asin(facing.Y) - math.asin(new.Y)
                                local angle = Vector2.new(diffYaw, diffPitch) // ((Vector2.new(1, 0.77) * math.rad(0.5)) * UserSettings():GetService('UserGameSettings').MouseSensitivity)
                                
                                angle *= math.min(Flags.AutoAimSpeed:GetValue() * delta, 1)
                                mousemoverel(angle.X, angle.Y)
                            end
                        end
                    end
                end))
            end
        end
    })

    Targets:CreateToggle({
        Name = 'Require mouse down',
        Flag = 'AutoAimMouse',
        Function = void
    })

    General:CreateSlider({
        Name = 'Aim FOV',
        Flag = 'AutoAimFOV',
        Min = 1,
        Max = 360,
        Suffix = {Text = ' degrees'},
        Default = 90,
        Function = void
    })

    General:CreateSlider({
        Name = 'Aim Speed',
        Flag = 'AutoAimSpeed',
        Min = 1,
        Max = 100,
        Suffix = {Text = '%'},
        Default = 50,
        Function = void
    })

    --[[
        Targets
    ]]

    Targets:CreateDropdown({
        Name = 'Target Part',
        Flag = 'AutoAimPart',
        List = {'UpperTorso', 'PrimaryPart', 'Head'},
        Default = 'Head'
    })

    Targets:CreateToggle({
        Name = 'Include NPCs',
        Flag = 'AutoAimIncludeNPCs',
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Include Players',
        Flag = 'AutoAimIncludePlayers',
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Wall Check',
        Flag = 'AutoAimWallCheck',
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Teams Check',
        Flag = 'AutoAimTeamsCheck',
        Function = void
    })

    local FOV = Targets:CreateToggle({
        Name = 'Show FOV',
        Flag = 'AutoAimShowFOV',
        Function = function(val)
            FOVCircle.Visible = val
        end
    })

    --[[
        FOV options
    ]]

    local Option = FOV.Link

    Option:AddColorPicker({
        Name = 'FOV Color',
        Flag = 'AutoAimFOVColor',
        Default = Color3.fromRGB(0, 255, 140),
        Function = function(color)
            FOVCircle.Color = color
        end
    })

    Targets:AddSlider({
        Name = 'FOV Thickness',
        Flag = 'AutoAimFOVThickness',
        Min = 1,
        Max = 10,
        Default = 2,
        Function = function(val)
            FOVCircle.Thickness = val
        end
    })

    Targets:AddSlider({
        Name = 'FOV Sides',
        Flag = 'AutoAimFOVSides',
        Min = 3,
        Max = 100,
        Default = 100,
        Function = function(val)
            FOVCircle.NumSides = val
        end
    })

    Targets:AddSlider({
        Name = 'FOV Transparency',
        Flag = 'AutoAimFOVTransparency',
        Min = 0,
        Max = 1,
        Default = 0,
        Function = function(val)
            FOVCircle.Transparency = 1
        end
    })

    Targets:AddSlider({
        Name = 'FOV Radius',
        Flag = 'AutoAimFOVRadius',
        Min = 10,
        Max = 500,
        Default = 400,
        Function = function(val)
            FOVCircle.Radius = val
        end
    })
    
end)

run(function()  
    local Killaura = categories.Combat:DrawTab({
        Name = 'Killaura',
        Type = 'Double'
    });

    local General = Killaura:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local Targets = Killaura:DrawSection({
        Name = 'Target Settings',
        Position = 'right'
    })

    local function getSword()
        if not Loaded then
            return
        end
        
        if not entitylib:isAlive() then
            return
        end

        if Flags.KillauraHandCheck:GetValue() then
            if bedwars.Inventory.hand.tool and bedwars:HasItemType(bedwars.Inventory.hand.tool, 'sword') then
                return bedwars.Inventory.hand
            else
                return
            end
        end

        return bedwars:getBestItemType('sword', 'damage')
    end

    local function getValue(val)
        return {value = val}
    end

    local lastSwing = tick()

    local TargetBox = Instance.new('Part')
    TargetBox.Size = Vector3.new(3, 5, 3)
    TargetBox.Anchored = true
    TargetBox.CanCollide = false
    TargetBox.Material = Enum.Material.Neon
    TargetBox.CanTouch = false
    TargetBox.CanQuery = false

    local OldC0 = nil

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'Killaura',
        Function = function(call)
            Features.Killaura.Enabled = call
            if call then
                task.spawn(function()
                    local started, armC0, AnimTween, first = false

                    pcall(function()
                        OldC0 = camera.Viewmodel.RightHand.RightWrist.C0
                    end)

                    repeat
                        if LastTarget > (tick() + 0.45) then
                            if not armC0 then
                                armC0 = camera.Viewmodel.RightHand.RightWrist.C0
                            end
                            local first = not started
                            started = true

                            for _, v in {
                                {CFrame = CFrame.new(-0.17, -0.14, -0.12) * CFrame.Angles(math.rad(-53), math.rad(50), math.rad(-64)), Time = 0.1},
                                {CFrame = CFrame.new(-0.55, -0.59, -0.1) * CFrame.Angles(math.rad(-161), math.rad(54), math.rad(-6)), Time = 0.08},
                                {CFrame = CFrame.new(-0.62, -0.68, -0.07) * CFrame.Angles(math.rad(-167), math.rad(47), math.rad(-1)), Time = 0.03},
                                {CFrame = CFrame.new(-0.56, -0.86, 0.23) * CFrame.Angles(math.rad(-167), math.rad(49), math.rad(-1)), Time = 0.03}
                            } do
                                AnimTween = tweenService:Create(camera.Viewmodel.RightHand.RightWrist, TweenInfo.new(first and 0.1 or v.Time / 0.8, Enum.EasingStyle.Linear), {
                                    C0 = armC0 * v.CFrame
                                })
                                AnimTween:Play()
                                AnimTween.Completed:Wait()
                                first = false
                                if (not Flags.KillauraAnimation:GetValue()) or (tick() > LastTarget) then break end
                            end
                        elseif started then
                            started = false
                            AnimTween = tweenService:Create(camera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
                                C0 = armC0
                            })
                            AnimTween:Play()
                        end

                        task.wait(0.05)
                    until (not Features.Killaura.Enabled) or (not Flags.KillauraAnimation:GetValue())
                end)

                repeat
                    local sword = getSword()

                    TargetBox.Transparency = Flags.KillauraShowTarget:GetValue() and Flags.KillauraShowTargetColor:GetValue().ColorPicker.Transparency or 1
                    TargetBox.Color = Flags.KillauraShowTargetColor:GetValue().ColorPicker.Color
                    TargetBox.Parent = LastTarget > tick() and workspace or replicatedStorage

                    if sword then
                        local ents = entitylib:AllPosition({
                            Players = Flags.KillauraIncludePlayers:GetValue(),
                            NPCs = Flags.KillauraIncludeNPCs:GetValue(),
                            Range = Flags.KillauraRange:GetValue(),
                            Wallcheck = Flags.KillauraWallCheck:GetValue(),
                            Team = Flags.KillauraTeamsCheck:GetValue()
                        })
                        
                        for _, v in ents do
                            if not entitylib:isAlive() then
                                break
                            end

                            if bedwars.Inventory.hand.tool ~= sword.tool then
                                switchTool(sword.tool, 0.05, Flags.KillauraVisualizeAutoSwitch:GetValue())
                            end

                            local targetpos, selfpos = v.Character.PrimaryPart.Position, lplr.Character.PrimaryPart.Position
                            local mag = (targetpos - selfpos).Magnitude
                            local dir = CFrame.lookAt(selfpos, targetpos).LookVector

                            if Flags.KillauraSwing:GetValue() and (tick() - lastSwing) >= Flags.KillauraSwingTime:GetValue() then
                                bedwars.SwordController:playSwordEffect(bedwars.ItemMeta[sword.tool.Name], false)
                                lastSwing = tick()
                            end

                            TargetBox.Parent = workspace
                            TargetBox.Position = targetpos
                            LastTarget = tick() + 0.5

                            bedwars.Client:Get('SwordHit'):SendToServer({
                                chargedAttack = {
                                    chargeRatio = 1
                                },
                                entityInstance = v.Character,
                                validate = {
                                    raycast = {},
                                    targetPosition = getValue(targetpos),
                                    selfPosition = getValue(selfpos + dir * math.max(mag - 14.399, 0))
                                },
                                weapon = sword.tool
                            })
                            
                            task.wait(0.1 / Flags.KillauraAPS:GetValue())
                        end
                    end
                    task.wait()
                until not Features.Killaura.Enabled
            else
                TargetBox.Parent = replicatedStorage
                
                tweenService:Create(camera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
                    C0 = OldC0
                }):Play()

                OldC0 = nil;
            end
        end
    })

    General:CreateToggle({
        Name = 'Swing Sword',
        Default = true,
        Flag = 'KillauraSwing',
        Function = void
    })

    General:CreateToggle({
        Name = 'Custom Animation',
        Flag = 'KillauraAnimation',
        Function = void
    })

    General:CreateToggle({
        Name = 'Visualize Auto Switch',
        Flag = 'KillauraVisualizeAutoSwitch',
        Function = void
    })

    General:CreateToggle({
        Name = 'Hand Check',
        Flag = 'KillauraHandCheck',
        Function = void
    })

    General:CreateSlider({
        Name = 'Swing Time',
        Flag = 'KillauraSwingTime',
        Min = 0,
        Max = 1,
        Round = 2,
        Default = 0.11,
        Suffix = {Text = 's'},
        Function = void
    })
    
    General:CreateSlider({
        Name = 'Targets Per Second',
        Flag = 'KillauraAPS',
        Min = 1,
        Round = 1,
        Max = 20,
        Suffix = {Text = ' per secs'},
        Default = 10,
        Function = void
    })

    --[[
        Targets
    ]]

    Targets:CreateSlider({
        Name = 'Attack Range',
        Flag = 'KillauraRange',
        Suffix = {Text = ' studs'},
        Round = 1,  
        Min = 1,
        Max = 30,
        Default = 30,
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Include NPCs',
        Flag = 'KillauraIncludeNPCs',
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Include Players',
        Flag = 'KillauraIncludePlayers',
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Wall Check',
        Flag = 'KillauraWallCheck',
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Teams Check',
        Flag = 'KillauraTeamsCheck',
        Function = void
    })
    
    local ShowTarget = Targets:CreateToggle({
        Name = 'Visualize Target',
        Flag = 'KillauraShowTarget',
        Function = void
    })

    --[[
        Show Target options
    ]]

    local Option = ShowTarget.Link

    Option:AddColorPicker({
        Name = 'Target Color',
        Flag = 'KillauraShowTargetColor',
        Default = Color3.new(1, 0, 0),
        Function = void
    })
end)

run(function()
    local Reach = categories.Combat:DrawTab({
        Name = 'Reach',
        Type = 'Single'
    });

    local General = Reach:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'Reach',
        Function = function(call)
            bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = call and Flags.HitboxSize:GetValue() or 14.4
        end
    })


    General:CreateSlider({
        Name = 'Range',
        Flag = 'HitboxSize',
        Min = 1,
        Max = 26,
        Default = 18,
        Round = 2,
        Function = void
    })
end)

--[[
    Player
]]

run(function()
    local Speed = categories.Player:DrawTab({
        Name = 'Speed',
        Type = 'Double'
    });

    local General = Speed:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local Options = Speed:DrawSection({
        Name = 'Options',
        Position = 'right'
    })

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'Speed',
        Function = function(call)
            Features.Speed.Enabled = call
            if call then
                Features.Speed:Clean(runService.PreSimulation:Connect(function(delta)
                    if not Loaded then
                        return
                    end

                    if entitylib:isAlive() and not Features.Flight.Enabled and not Flags.LongFly:GetValue() then
                        local velo = Vector3.new(0, lplr.Character.PrimaryPart.AssemblyLinearVelocity.Y, 0)
                        local jump = Flags.SpeedAutoJump:GetValue() and (Flags.SpeedAlwaysJump:GetValue() or LastTarget > tick()) and lplr.Character.Humanoid.FloorMaterial ~= Enum.Material.Air
                        local speed = Flags.SpeedAdditional:GetValue() and getAdditonalSpeed(Flags.SpeedMode:GetValue() == 'Velocity' and true or false) or 20

                        if jump then
                            if Flags.SpeedJumpMode:GetValue() == 'Velocity' then
                                velo += Vector3.new(0, 2.5, 0)
                            else
                                lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                            end
                        end

                        velo += (lplr.Character.Humanoid.MoveDirection * (Flags.SpeedMode:GetValue() == 'Velocity' and Flags.SpeedValue:GetValue() or speed))
                        lplr.Character.PrimaryPart.AssemblyLinearVelocity = velo
                        
                        if Flags.SpeedMode:GetValue() == 'CFrame' then
                            lplr.Character.PrimaryPart.CFrame += (lplr.Character.Humanoid.MoveDirection * math.max(Flags.SpeedValue:GetValue() - speed, 0) * delta)
                        end
                    end
                end))
            end
        end
    })

    General:CreateToggle({
        Name = 'Auto Jump',
        Flag = 'SpeedAutoJump',
        Default = true
    })

    General:CreateToggle({
        Name = 'Always Jump',
        Flag = 'SpeedAlwaysJump'
    })

    General:CreateToggle({
        Name = 'Use Additional Speed',
        Flag = 'SpeedAdditional'
    })

    --[[
        Options
    ]]

    Options:CreateDropdown({
        Name = 'Speed Mode',
        Flag = 'SpeedMode',
        List = {'CFrame', 'Velocity'},
        Default = 'CFrame'
    })

    Options:CreateDropdown({
        Name = 'Jump Mode',
        Flag = 'SpeedJumpMode',
        List = {'Velocity', 'Humanoid'},
        Default = 'Humanoid'
    })

    Options:CreateSlider({
        Name = 'Speed',
        Min = 0,
        Flag = 'SpeedValue',
        Max = 23,
        Default = 23,
        Suffix = {Text = ' studs'},
        Round = 1,
        Function = function() end
    })
end)

run(function()
    local Flight = categories.Player:DrawTab({
        Name = 'Flight',
        Type = 'Single'
    });

    local General = Flight:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local up, down = false, false

    local KeyModes = {
        {
            Enum.KeyCode.Space,
            Enum.KeyCode.LeftShift
        },
        {
            Enum.KeyCode.Space,
            Enum.KeyCode.LeftControl
        }
    }
    local keyMode = 1

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'Flight',
        Function = function(call)
            Features.Flight.Enabled = call
            if call then
                Features.Flight:Clean(runService.PreSimulation:Connect(function(delta)
                    if not Loaded then
                        return
                    end

                    if entitylib:isAlive() and not Flags.LongFly:GetValue() then
                        local velo = Vector3.zero
                        local speed = Flags.SpeedAdditional:GetValue() and getAdditonalSpeed(Flags.SpeedMode:GetValue() == 'Velocity' and true or false) or 20
                        local vertical = Vector3.new(0, up and Flags.FlyVerticalSpeed:GetValue() or down and -Flags.FlyVerticalSpeed:GetValue() or 0, 0)

                        if Flags.FlyVerticalMode:GetValue() == 'Velocity' then
                            velo += vertical
                        else
                            lplr.Character.PrimaryPart.CFrame += (vertical / 100)
                        end

                        velo += (lplr.Character.Humanoid.MoveDirection * (Flags.FlySpeedMode:GetValue() == 'Velocity' and (Flags.FlySpeed:GetValue() + speed) or speed))
                        lplr.Character.PrimaryPart.AssemblyLinearVelocity = velo
                        
                        if Flags.FlySpeedMode:GetValue() == 'CFrame' then
                            lplr.Character.PrimaryPart.CFrame += (lplr.Character.Humanoid.MoveDirection * math.max(Flags.FlySpeed:GetValue() - speed, 0) * delta)
                        end
                    end
                end))
                
                repeat
                    if Flags.FlightTP:GetValue() then
                        local Old = entitylib:isAlive() and lplr.Character.PrimaryPart.CFrame

                        if Old then
                            if (tick() - AirTime) >= 1.5 then
                                local ray = workspace:Raycast(lplr.Character.PrimaryPart.Position, Vector3.new(0, -1000, 0), Params)

                                if ray then
                                    lplr.Character.PrimaryPart.CFrame = CFrame.new(ray.Position + Vector3.new(0, 2.5, 0))
                                    task.wait(0.1)
                                    lplr.Character.PrimaryPart.CFrame = Old
                                end
                            end
                        end
                    end
                    task.wait()
                until not Features.Flight.Enabled
            end
        end
    })

    --[[
        Options
    ]]

    General:CreateToggle({
        Name = 'TP Down',
        Flag = 'FlightTP',
        Default = true
    })

    General:AddKeybind({
        Name = 'Keybind',
        Flag = 'FlyBind',
        Callback = function()
            Flags.Flight:SetValue(not Features.Flight.Enabled)
        end
    })

    General:CreateDropdown({
        Name = 'Speed Mode',
        List = {'CFrame', 'Velocity'},
        Flag = 'FlySpeedMode',
        Default = 'CFrame'
    })

    General:CreateDropdown({
        Name = 'Vertical Mode',
        List = {'Velocity', 'CFrame'},
        Flag = 'FlyVerticalMode',
        Default = 'CFrame'
    })

    General:CreateSlider({
        Name = 'Vertical Speed',
        Min = 0,
        Flag = 'FlyVerticalSpeed',
        Suffix = {Text = ' studs'},
        Max = 200,
        Default = 83,
        Round = 1,
        Function = function() end
    })

    General:CreateSlider({
        Name = 'Speed',
        Min = 0,
        Max = 23,
        Flag = 'FlySpeed',
        Suffix = {Text = ' studs'},
        Default = 23,
        Round = 1,
        Function = function() end
    })

    inputService.InputBegan:Connect(function(input)
        if not inputService:GetFocusedTextBox() then
            if input.KeyCode == KeyModes[keyMode][1] then
                up = true
            end

            if input.KeyCode == KeyModes[keyMode][2] then
                down = true
            end
        end
    end)

   inputService.InputEnded:Connect(function(input)
        if not inputService:GetFocusedTextBox() then
            if input.KeyCode == KeyModes[keyMode][1] then
                up = false
            end

            if input.KeyCode == KeyModes[keyMode][2] then
                down = false
            end
        end
    end)
end)

run(function()
    local Scaffold = categories.Player:DrawTab({
        Name = 'Scaffold',
        Type = 'Double'
    });

    local General = Scaffold:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local Options = Scaffold:DrawSection({
        Name = 'Options',
        Position = 'right'
    })

    local LastPlace = tick()

    local function getBlock()
        if not Loaded then
            return
        end

        if not entitylib:isAlive() then
            return
        end

        if Flags.ScaffoldLimit:GetValue() then
            if bedwars.Inventory.hand.tool and bedwars.ItemMeta[bedwars.Inventory.hand.tool.Name].block then
                return bedwars.Inventory.hand
            end

            return
        end

        local Tool = bedwars:getBestItemType('block', 'health')

        if Tool then
            return Tool
        end
    end

    local function roundToGrid(vec)
        return Vector3.new(math.round(vec.X / 3) * 3, math.round(vec.Y / 3) * 3, math.round(vec.Z / 3) * 3)
    end

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'Scaffold',
        Function = function(call)
            Features.Scaffold.Enabled = call
            if call then
                repeat
                    local Block = getBlock()

                    local GoingDown, GoingUp = false, false

                    if Block then
                        local velo = lplr.Character.PrimaryPart.AssemblyLinearVelocity
                        
                        if Flags.ScaffoldTower:GetValue() and inputService:IsKeyDown(Enum.KeyCode.Space) then
                            lplr.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(velo.X, 66, velo.Z)
                            GoingUp = true
                        elseif Flags.ScaffoldDown:GetValue() and inputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                            lplr.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(velo.X, -66, velo.Z)
                            GoingDown = true
                        end
                    end

                    if (tick() - LastPlace) >= (1 / Flags.ScaffoldCPS:GetValue()) and Block then
                        for i = 1, Flags.ScaffoldExpand:GetValue() do
                            local pos = roundToGrid(lplr.Character.PrimaryPart.Position - Vector3.new(0, lplr.Character.Humanoid.HipHeight + (GoingDown and 4.5 or GoingUp and 0 or 1.5), 0) + lplr.Character.Humanoid.MoveDirection * (i * 3))

                            local has, newpos = bedwars.BlockController:hasBlock({Position = pos}) 

                            if not has then
                                if Flags.ScaffoldSwitch:GetValue() and (not bedwars.Inventory.hand or bedwars.Inventory.hand.tool ~= Block.tool) then
                                    switchTool(Block.tool, 0.01, Flags.ScaffoldVisualSwitch:GetValue())    
                                end 

                                bedwars.BlockController:placeBlock({
                                    Tool = Block.tool,
                                    Position = newpos * 3
                                })
                            end
                        end
                        
                        LastPlace = tick()
                    end
                    
                    task.wait()
                until not Features.Scaffold.Enabled
            end
        end 
    })

    General:AddKeybind({
        Name = 'Keybind',
        Flag = 'ScaffoldBind',
        Callback = function()
            Flags.Scaffold:SetValue(not Features.Scaffold.Enabled)
        end
    })

    General:CreateToggle({
        Name = 'Hand Check',
        Flag = 'ScaffoldLimit'
    })

    General:CreateToggle({
        Name = 'Auto Switch',
        Flag = 'ScaffoldSwitch'
    })

    Options:CreateToggle({
        Name = 'Visualize Switch',
        Flag = 'ScaffoldVisualSwitch'
    })

    Options:CreateToggle({
        Name = 'Tower',
        Flag = 'ScaffoldTower'
    })

    Options:CreateToggle({
        Name = 'Downwards',
        Flag = 'ScaffoldDown'
    })

    Options:CreateSlider({
        Name = 'Expand',
        Flag = 'ScaffoldExpand',
        Min = 1,
        Max = 7,
        Suffix = {Text = ' studs'},
        Default = 4
    })

    Options:CreateSlider({
        Name = 'Place CPS',
        Flag = 'ScaffoldCPS',
        Min = 1,
        Max = 12,
        Default = 12,
        Suffix = {Text = ' c/s'}
    })
end)

run(function()
    local AutoSprint = categories.Player:DrawTab({
        Name = 'Auto Sprint',
        Type = 'Single'
    });

    local Old

    AutoSprint:DrawSection({
        Name = 'General',
        Position = 'left'
    }):CreateToggle({
        Name = 'Enable',
        Flag = 'AutoSprint',
        Function = function(call)
            Features.Sprint.Enabled = call
            if call then
                Old = bedwars.SprintController.stopSprinting

                bedwars.SprintController:startSprinting()
                bedwars.SprintController.stopSprinting = void
            else
                bedwars.SprintController.stopSprinting = Old
                bedwars.SprintController.stopSprinting = nil
            end
        end
    })
end)

--[[
    Render
]]

run(function()
    local ESPInstances = {}

    local function espAdded(v)
        v.NameDisplayDistance = 0

        local square = Drawing.new('Square')
        square.Transparency = 1
        square.ZIndex = 2
        square.Filled = false
        square.Thickness = 1

        local border = Drawing.new('Square')
        border.Transparency = 0.35
        border.ZIndex = 1
        border.Thickness = 1
        border.Filled = false
        border.Color = Color3.new()

        local border2 = Drawing.new('Square')
        border2.Transparency = 0.35
        border2.ZIndex = 1
        border2.Thickness = 1
        border2.Filled = false
        border2.Color = Color3.new()

        local healthLine = Drawing.new('Line')
        healthLine.Thickness = 2
        healthLine.ZIndex = 2
        healthLine.Color = Color3.fromHSV(math.clamp(100 / 100, 0, 1) / 2.5, 0.89, 0.75)

        local healthBorder = Drawing.new('Line')
        healthBorder.Thickness = 4
        healthBorder.Transparency = 1
        healthBorder.ZIndex = 1
        healthBorder.Color = Color3.new()

        local drop = Drawing.new('Text')
        drop.Color = Color3.new()
        drop.ZIndex = 1
        drop.Center = true
        drop.Font = 2
        drop.Size = 17

        local text = Drawing.new('Text')
        text.ZIndex = 2
        text.Color = Color3.new(1, 1, 1)
        text.Center = true
        text.Size = 17
        text.Font = 2

        table.insert(ESPInstances, {
            square = square,
            border = border,
            border2 = border2,
            healthLine = healthLine,
            healthBorder = healthBorder,
            plr = v,
            drop = drop,
            text = text,
            Hip = 0
        })
    end

    local function updateESP(drawing, index)
        drawing.plr.NameDisplayDistance = 0
        
        local square = drawing.square
        local border = drawing.border
        local border2 = drawing.border2
        local healthLine = drawing.healthLine
        local healthBorder = drawing.healthBorder
        local drop = drawing.drop
        local text = drawing.text
        local extrawidth = drawing.ExtraWidth or 0

        if entitylib:isAlive(drawing.plr) then
            local pos, vis = camera:WorldToViewportPoint(drawing.plr.Character.PrimaryPart.Position - Vector3.new(0, 0.5, 0))

            local maxhp = drawing.plr.Character.Humanoid.MaxHealth
            local hp = drawing.plr.Character.Humanoid.Health

            local pass = true

            if Flags.ESPTeamsCheck:GetValue() and lplr.Team == drawing.plr.Team then
                pass = false
            end

            if pass and (Flags.ESPWallCheck:GetValue() and entitylib:Wall({
                Origin = lplr.Character.PrimaryPart.Position,
                Position = drawing.plr.Character.PrimaryPart.Position
            })) then
                pass = false
            end

            for i, obj in drawing do
                if (not table.find({'healthBorder', 'healthLine', 'square', 'border', 'border2', 'text', 'drop'}, i) or not vis) and typeof(obj) ~= 'Instance' and typeof(obj) ~= 'number' then
                    obj.Visible = pass and vis or false
                end 
            end
            
            local ShowName = Flags.ESPNames:GetValue()
            local UseDisplay = Flags.ESPUseDisplayNames:GetValue()
            local ShowDistance = Flags.ESPShowDistance:GetValue()
            local ShowHealth = Flags.ESPHealth:GetValue()
            local ShowBox = Flags.ESPBoxes:GetValue()

            local BorderOpacity = Flags.ESPBoxesColor:GetValue().ColorPicker.Transparency

            local UserOpacity = Flags.ESPNamesColor:GetValue().ColorPicker.Transparency

            local Background = Flags.ESPBackgroundColor:GetValue().ColorPicker.Color
            local BackgroundOpa = Flags.ESPBackgroundColor:GetValue().ColorPicker.Transparency

            drawing.text.Visible = (ShowName or ShowDistance) and vis or false
            drawing.drop.Visible = (ShowName or ShowDistance) and vis or false

            drawing.text.Text = `{ShowName and (UseDisplay and drawing.plr.DisplayName or drawing.plr.Name) or ''} {ShowDistance and '['.. math.floor((lplr.Character.PrimaryPart.Position - drawing.plr.Character.HumanoidRootPart.Position).Magnitude).. ']' or ''}`
            drawing.drop.Text = drawing.text.Text

            healthLine.Visible = ShowHealth and vis or false
            healthBorder.Visible = ShowHealth and vis or false
            square.Visible = ShowBox and vis or false
            border.Visible = ShowBox and vis or false
            border2.Visible = ShowBox and vis or false

            if vis then
                local topPos = camera:WorldToViewportPoint((CFrame.lookAlong(drawing.plr.Character.HumanoidRootPart.Position - Vector3.new(0, 0.5, 0), camera.CFrame.LookVector) * CFrame.new(2, 2.2, 0)).Position)
                local bottomPos = camera:WorldToViewportPoint((CFrame.lookAlong(drawing.plr.Character.HumanoidRootPart.Position - Vector3.new(0, 0.5, 0), camera.CFrame.LookVector) * CFrame.new(-2, -2.3 - 1, 0)).Position)
                local sizex, sizey = (topPos.X + extrawidth) - bottomPos.X - 10, (topPos.Y - bottomPos.Y + (drawing.Hip or 0))
                local posx, posy = (pos.X - sizex / 2),  ((pos.Y - sizey / 2))
                square.Position = Vector2.new(posx, posy) // 1
                square.Size = Vector2.new(sizex, sizey) // 1
                square.Transparency = BorderOpacity

                if border then
                    border.Position = Vector2.new(posx - 1, posy + 1) // 1
                    border.Size = Vector2.new(sizex + 2, sizey - 2) // 1
                    border.Transparency = BorderOpacity
                    border2.Position = Vector2.new(posx + 1, posy - 1) // 1
                    border2.Size = Vector2.new(sizex - 2, sizey + 2) // 1
                    border2.Filled = true
                    border2.Color = Background
                    border2.Transparency = BackgroundOpa
                end

                if healthLine then
                    local healthposy = sizey * math.clamp(hp / maxhp, 0, 1)
                    healthLine.Color = Color3.fromHSV(math.clamp(hp / maxhp, 0, 1) / 2.5, 0.89, 0.75)
                    healthLine.From = Vector2.new(posx - 6, posy + (sizey - (sizey - healthposy))) // 1
                    healthLine.To = Vector2.new(posx - 6, posy) // 1
                    healthBorder.From = Vector2.new(posx - 6, posy + 1) // 1
                    healthBorder.To = Vector2.new(posx - 6, (posy + sizey) - 1) // 1
                end

                if text then
                    text.Position = Vector2.new(posx + (sizex / 2) + 4, posy + (sizey - 28)) // 1
                    text.Transparency = UserOpacity
                    drop.Position = text.Position + Vector2.new(0.5, 0.5)
                    drop.Transparency = UserOpacity
                end
            end
        else
            for i, obj in drawing do
                if typeof(obj) ~= 'Instance' and typeof(obj) ~= 'number' then
                    obj.Visible = false
                end 
            end
        end
    end

    local ESP = categories.Render:DrawTab({
        Name = 'ESP',
        Type = 'Double'
    });

    local General = ESP:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local Targets = ESP:DrawSection({
        Name = 'Target Options',
        Position = 'right'
    })

    local Connections = {}

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'ESP',
        Function = function(call)
            if call then
                table.insert(Connections, players.PlayerAdded:Connect(espAdded))
                
                for _, v in players:GetPlayers() do
                    task.spawn(espAdded, v)
                end

                table.insert(Connections, runService.PreRender:Connect(function()
                    for i,v in ESPInstances do
                        v.square.Color = Flags.ESPBoxesColor:GetValue().ColorPicker.Color
                        v.text.Color = Flags.ESPNamesColor:GetValue().ColorPicker.Color
                        
                        task.spawn(updateESP, v, i)
                    end
                end))
            else
                for _, v in Connections do
                    v:Disconnect()
                end
                for _, tab in ESPInstances do
                    for __, v in tab do
                        pcall(function()
                            v.Visible = false
                            v:Destroy()
                        end)
                    end
                    tab.plr.NameDisplayDistance = 5
                end
                table.clear(Connections)
                table.clear(ESPInstances)
            end
        end
    }).Link:AddColorPicker({
        Name = 'FOV Color',
        Flag = 'ESPBackgroundColor',
        Default = Color3.new(1, 1, 1),
        Function = function(...)

        end
    })

    General:CreateToggle({
        Name = 'Show Names',
        Flag = 'ESPNames',
        Function = void
    }).Link:AddColorPicker({
        Name = 'Text Color',
        Flag = 'ESPNamesColor',
        Default = Color3.fromRGB(0, 255, 140),
        Function = void
    })

    General:CreateToggle({
        Name = 'Use Display Names',
        Flag = 'ESPUseDisplayNames',
        Function = void
    })

    General:CreateToggle({
        Name = 'Show Boxes',
        Flag = 'ESPBoxes',
        Function = void
    }).Link:AddColorPicker({
        Name = 'FOV Color',
        Flag = 'ESPBoxesColor',
        Default = Color3.new(1, 1, 1),
        Function = function(...)

        end
    })

    General:CreateToggle({
        Name = 'Show Health',
        Flag = 'ESPHealth',
        Function = void
    })

    --[[
        Options
    ]]

    Targets:CreateToggle({
        Name = 'Teams Check',
        Flag = 'ESPTeamsCheck',
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Wall Check',
        Flag = 'ESPWallCheck',
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Show Distance',
        Flag = 'ESPShowDistance',
        Function = void
    })
    
    Targets:CreateToggle({
        Name = 'Show Tracers',
        Flag = 'ESPShowTracers',
        Function = void
    })
end)

run(function()
    local ItemESP = categories.Render:DrawTab({
        Name = 'Item ESP',
        Type = 'Double'
    });

    local General = ItemESP:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local Targets = ItemESP:DrawSection({
        Name = 'Misc',
        Position = 'right'
    })

    local Drawings = {}

    local function MakeDrawing()
        local drop = Drawing.new('Text')
        drop.Color = Color3.new()
        drop.ZIndex = 1
        drop.Center = true
        drop.Font = 2
        drop.Size = 17

        local text = Drawing.new('Text')
        text.ZIndex = 2
        text.Color = Color3.new(1, 1, 1)
        text.Center = true
        text.Size = 17
        text.Font = 2

        local tab = {
            Text = text,
            Shadow = drop
        }

        table.insert(Drawings, tab)

        return tab
    end
    
    local Callbacks = {
        ['All Items'] = function()
            return true
        end,
        Utilities = function(item)
            return item.Name == 'shears' or item.Name:find('pickaxe')
        end,
        Projectiles = function(item)
            return bedwars:HasItemType(item, 'projectileSource')
        end,
        Weapons = function(item)
            return bedwars:HasItemType(item, 'sword') or item.Name == 'raven'
        end,
        Consumables = function(item)
            return bedwars:HasItemType(item, 'consumable')
        end,
        Blocks = function(item)
            return bedwars:HasItemType(item, 'block')
        end
    }

    local function HasType(item, checktype)
        return Callbacks[checktype](item)
    end

    local function ValidateItem(item)
        for i, v in Flags.ItemESPFilter:GetValue() do
            if v then
                local t = HasType(item, i)
                
                if t then
                    return t
                end
            end
        end
    end

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'ItemESP',
        Function = function(call)
            Features.ItemESP.Enabled = call

            if call then
                local Entities, Clock = {}, 0;

                repeat
                    task.spawn(function()
                        if (tick() - Clock) >= 0.5 then
                            Clock = tick()

                            local selfpos = lplr.Character.PrimaryPart.Position
                            local Temp, Old = {}, table.clone(Entities)

                            if Flags.ItemESPIncludeChestItems:GetValue() then                                
                                for _, v in collectionService:GetTagged('chest') do
                                    local offset = Vector3.zero
                                    local addition = {}
                                    
                                    if v:FindFirstChild('ChestFolderValue') and (selfpos - v.Position).Magnitude <= Flags.ItemESPRange:GetValue() then
                                        for __, v2 in v.ChestFolderValue.Value:GetChildren() do
                                            if v2:IsA('Accessory') and ValidateItem(v2) then
                                                if addition[v2.Name] then
                                                    Temp[addition[v2.Name]].Amount += 1
                                                else
                                                    local Draw = MakeDrawing()

                                                    table.insert(Temp, {
                                                        Name = bedwars.ItemMeta[v2.Name] and bedwars.ItemMeta[v2.Name].displayName or v2.Name,
                                                        Position = v.Position + offset,
                                                        Drawing = Draw,
                                                        Amount = 1
                                                    })

                                                    addition[v2.Name] = #Temp

                                                    offset += Vector3.new(0, 3, 0)
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            if Flags.ItemESPIncludeDroppedItems:GetValue() then
                                for _, v in collectionService:GetTagged('ItemDrop') do
                                    if (selfpos - v.Position).Magnitude <= Flags.ItemESPRange:GetValue() then
                                        if ValidateItem(v) then
                                            local Draw = MakeDrawing()

                                            table.insert(Temp, {
                                                Name = v.Name,
                                                Position = v.Position,
                                                Drawing = Draw,
                                                Amount = v:GetAttribute('Amount')
                                            })
                                        end
                                    end
                                end
                            end

                            Entities = {}

                            for i = 1, 2 do
                                task.wait()
                            end

                            for _, v in Old do -- clear tables
                                for _, v2 in v.Drawing do
                                    v2.Visible = false
                                end
                            end

                            Entities = Temp
                        end
                    end)

                    for _, v in Entities do
                        local pos, vis = camera:WorldToViewportPoint(v.Position - Vector3.new(0, 0.5, 0))

                        v.Drawing.Text.Visible = vis
                        v.Drawing.Shadow.Visible = vis
                        
                        local topPos = camera:WorldToViewportPoint((CFrame.lookAlong(v.Position - Vector3.new(0, 0.5, 0), camera.CFrame.LookVector) * CFrame.new(2, 2.2, 0)).Position)
                        local bottomPos = camera:WorldToViewportPoint((CFrame.lookAlong(v.Position - Vector3.new(0, 0.5, 0), camera.CFrame.LookVector) * CFrame.new(-2, -2.3 - 1, 0)).Position)
                        local sizex, sizey = topPos.X - bottomPos.X - 10, (topPos.Y - bottomPos.Y)
                        local posx, posy = (pos.X - sizex / 2),  ((pos.Y - sizey / 2))
                        
                        local Text = `{Flags.ItemESPAmounts:GetValue() and tostring(v.Amount) or ''} {Flags.ItemESPNames:GetValue() and v.Name.. (v.Amount > 1 and 's' or '') or ''}`

                        if Flags.ItemESPShowDistance:GetValue() then
                            Text = `{Text} [{math.floor((lplr.Character.PrimaryPart.Position - v.Position).Magnitude)}]`
                        end

                        v.Drawing.Text.Text = Text
                        v.Drawing.Text.Position = Vector2.new(posx + (sizex / 2) + 4, posy + (sizey - 28)) // 1
                        v.Drawing.Text.Transparency = 0

                        v.Drawing.Shadow.Text = Text
                        v.Drawing.Shadow.Position = v.Drawing.Text.Position + Vector2.new(0.5, 0.5)
                        v.Drawing.Shadow.Transparency = 0
                    end
                    task.wait()
                until not Features.ItemESP.Enabled
            else
                for _, v in Drawings do
                    v.Drawing.Text.Visible = false
                    v.Drawing.Shadow.Visible = false
                end

                Drawings = {}
            end
        end
    })

    General:CreateToggle({
        Name = 'Show Names',
        Flag = 'ItemESPNames',
        Function = void
    })
    
    General:CreateToggle({
        Name = 'Show Amounts',
        Flag = 'ItemESPAmounts',
        Function = void
    })

    General:CreateSlider({
        Name = 'Range',
        Flag = 'ItemESPRange',
        Min = 1,
        Max = 1000,
        Suffix = {Text = ' studs'},
        Default = 300,
        Function = void
    })

    Targets:CreateDropdown({
        Name = 'Item Filter',
        Flag = 'ItemESPFilter',
        List = {
            'All Items',
            'Weapons',
            'Blocks',
            'Utilities',
            'Consumables',
            'Projectiles'
        },
        Multi = true,
        Default = {'All Items'},
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Show Distance',
        Flag = 'ItemESPShowDistance',
        Function = void
    })

    Targets:CreateToggle({
        Name = 'Include dropped items',
        Default = true,
        Flag = 'ItemESPIncludeDroppedItems',
        Function = void
    })
    
    Targets:CreateToggle({
        Name = 'Include chest items',
        Default = true,
        Flag = 'ItemESPIncludeChestItems',
        Function = void
    })
end)

--[[
    Utility
]]

run(function()
    local BowAura = categories.Utility:DrawTab({
        Name = 'Bow Aura',
        Type = 'Single'
    });

    local General = BowAura:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local Options = BowAura:DrawSection({
        Name = 'Options',
        Position = 'left'
    })

    local FireDelays = {}

    local function getAmmo(check)
        for _, item in bedwars.Inventory.All do
            if check.ammoItemTypes and table.find(check.ammoItemTypes, item.itemType) then
                return item.itemType
            end
        end
    end

    local function getProjectiles()
        local items = {}
        for _, item in bedwars.Inventory.All do
            if tick() > (FireDelays[item] or 0) then
                local proj = bedwars.ItemMeta[item.itemType].projectileSource
                local ammo = proj and getAmmo(proj)

                if ammo then
                    print(bedwars.ProjectileMeta[proj.projectileType(ammo)].launchVelocity, item.tool.Name)
                end

                if 
                    ammo 
                    and (
                        not Flags.BowAuraFast:GetValue() 
                        or bedwars.ProjectileMeta[proj.projectileType(ammo)].launchVelocity < 120
                    ) 
                    and (
                        not Flags.BowAuraSlow:GetValue() 
                        or bedwars.ProjectileMeta[proj.projectileType(ammo)].launchVelocity > 100
                    ) 
                then
                    table.insert(items, {
                        item,
                        ammo,
                        proj.projectileType(ammo),
                        proj
                    })
                end
            end
        end
        return items
    end
    
    local bowcons = {
        RelZ = 0,
        CameraMultiplier = 10,
        RelX = 0.8,
        RelY = -0.6,
        YTargetOffset = 0.05,
        BeamGrowthMultiplier = 0.08
    }   
    
    local shootRem = replicatedStorage.rbxts_include.node_modules['@rbxts'].net.out._NetManaged.ProjectileFire

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'BowAura',
        Function = function(call)
            Features.BowAura.Enabled = call
            
            if call then
                repeat
                    if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 0.3 then
                        local projectiles = getProjectiles()

                        if #projectiles > 0 then
                            local ents = entitylib:AllPosition({
                                Players = Flags.BowAuraIncludePlayers:GetValue(),
                                NPCs = Flags.BowAuraIncludeNPCs:GetValue(),
                                Range = Flags.BowAuraRange:GetValue(),
                                Wallcheck = Flags.BowAuraWallCheck:GetValue(),
                                Team = Flags.BowAuraTeamsCheck:GetValue()
                            })

                            for i = 1, #projectiles do
                                if not ents[i] then
                                    break
                                end

                                if not entitylib:isAlive() then
                                    return
                                end

                                local ent = ents[i]
                                local selfpos = lplr.Character.PrimaryPart.Position

                                local item, ammo, projectile, itemMeta = unpack(projectiles[i])
                                local projmeta = bedwars.ProjectileMeta[projectile]

                                if ent and ent.Character.PrimaryPart then
                                    local washolding = bedwars.Inventory.hand.tool == item.tool

                                    switchTool(item.tool, 0.05)

                                    local targetpos = predictionlib.SolveTrajectory(
                                        selfpos, 
                                        projmeta.launchVelocity, 
                                        projmeta.gravitationalAcceleration,
                                        ent.Character.PrimaryPart.Position, 
                                        ent.Character.PrimaryPart.Velocity, 
                                        workspace.Gravity, 
                                        ent.Character.Humanoid.HipHeight, 
                                        ent.Character.Humanoid.Jump and 42.6 or nil, nil, nil, 
                                        lplr:GetNetworkPing()
                                    ) or ent.Character.PrimaryPart.Position

                                    task.spawn(function()
                                        local dir, id = CFrame.lookAt(selfpos, targetpos).LookVector, httpService:GenerateGUID(true)
                                        local shootPosition = (CFrame.new(selfpos, targetpos) * CFrame.new(Vector3.new(-bowcons.RelX, -bowcons.RelY, -bowcons.RelZ))).Position
                                        local res = shootRem:InvokeServer(
                                            item.tool, 
                                            ammo, 
                                            projectile, 
                                            shootPosition, 
                                            selfpos, 
                                            dir * projmeta.launchVelocity, 
                                            id, 
                                            {
                                                drawDurationSeconds = 1, 
                                                shotId = httpService:GenerateGUID(false)
                                            }, 
                                            workspace:GetServerTimeNow() - 0.045
                                        )
                                        
                                        if not res then
                                            FireDelays[item.itemType] = tick()
                                        else
                                            FireDelays[item.itemType] = tick() + itemMeta.fireDelaySec

                                            local shoot = itemMeta.launchSound
                                            
                                            shoot = shoot and shoot[math.random(1, #shoot)] 

                                            if shoot then
                                                --bedwars.SoundManager:playSound(shoot)
                                            end
                                        end
                                    end)

                                    FireDelays[item.itemType] = tick() + itemMeta.fireDelaySec
                                    
                                    if not washolding then
                                        task.wait(0.05)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                until not Features.BowAura.Enabled
            end
        end
    })

    General:CreateToggle({
        Name = 'Exclude Slow Projectiles',
        Flag = 'BowAuraSlow',
        Default = true
    })

    General:CreateToggle({
        Name = 'Exclude Fast Projectiles',
        Flag = 'BowAuraFast'
    })

    General:CreateSlider({
        Name = 'Range',
        Min = 1,
        Max = 150,
        Default = 150,
        Suffix = {Text = ' studs'},
        Round = 1,
        Flag = 'BowAuraRange'
    })

    --[[
        Options
    ]]

    Options:CreateToggle({
        Name = 'Include NPCs',
        Flag = 'BowAuraIncludeNPCs',
        Function = void
    })

    Options:CreateToggle({
        Name = 'Include Players',
        Flag = 'BowAuraIncludePlayers',
        Function = void
    })

    Options:CreateToggle({
        Name = 'Wall Check',
        Flag = 'BowAuraWallCheck',
        Function = void
    })

    Options:CreateToggle({
        Name = 'Teams Check',
        Flag = 'BowAuraTeamsCheck',
        Function = void
    })
    
    local ShowTarget = Options:CreateToggle({
        Name = 'Visualize Target',
        Flag = 'BowAuraShowTarget',
        Function = void
    })

    --[[
        Show Target options
    ]]

    local Option = ShowTarget.Link

    Option:AddColorPicker({
        Name = 'Target Color',
        Flag = 'BowAuraShowTargetColor',
        Default = Color3.new(1, 0, 0),
        Function = void
    })
end)

run(function()
    local ChestSteal = categories.Utility:DrawTab({
        Name = 'Loot Aura',
        Type = 'Double'
    });

    local General = ChestSteal:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local Options = ChestSteal:DrawSection({
        Name = 'Options',
        Position = 'right'
    })

    local function LootChest(chest, lootTable)
        bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(chest)

        for _, v in lootTable do
            task.spawn(pcall, function()
                bedwars.Client:GetNamespace('Inventory'):Get('ChestGetItem'):CallServer(chest, v)
            end)
            task.wait(Flags.AutoLootDelay:GetValue())
        end
        
        bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(nil)

        return true
    end

    local TargetBox = Instance.new('Part')
    TargetBox.Size = Vector3.one * 0.7
    TargetBox.Anchored = true
    TargetBox.CanCollide = false
    TargetBox.CanTouch = false
    TargetBox.CanQuery = false

    local Highlight = Instance.new('Highlight', TargetBox)


    General:CreateToggle({
        Name = 'Enable',
        Flag = 'AutoLoot',
        Function = function(call)
            Features.AutoLoot.Enabled = call
            if call then
                local Delays = {}

                repeat
                    if entitylib:isAlive() then
                        for _, v in collectionService:GetTagged('chest') do
                            if (lplr.Character.PrimaryPart.Position - v.Position).Magnitude <= Flags.AutoLootRange:GetValue() and #v.ChestFolderValue.Value:GetChildren() > 1 then
                                local lootTable = not Flags.AutoLootOrder.Value and v.ChestFolderValue.Value:GetChildren() or nil

                                if not lootTable then
                                    local Index = #v.ChestFolderValue.Value:GetChildren()

                                    for i, v2 in v.ChestFolderValue.Value:GetChildren() do
                                        lootTable[Index - i] = v2
                                    end
                                end

                                local HighData = Flags.AutoLootHighlightColor:GetValue().ColorPicker

                                Highlight.FillTransparency = HighData.Transparency
                                Highlight.OutlineTransparency = HighData.Transparency
                                Highlight.FillColor = HighData.Color
                                Highlight.OutlineColor = HighData.Color
                                
                                if Flags.AutoLootVisualHighlight:GetValue() then
                                    TargetBox.Parent = workspace
                                    TargetBox.CFrame = v.CFrame
                                end

                                if LootChest(v.ChestFolderValue.Value, lootTable) then
                                    Delays[v] = tick() + 1
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                    TargetBox.Parent = replicatedStorage
                until not Features.AutoLoot.Enabled
            end
        end
    })

    General:CreateSlider({
        Name = 'Radius',
        Min = 1,
        Max = 19,
        Default = 19,
        Round = 1,
        Flag = 'AutoLootRange'
    })

    --[[
        Options
    ]]

    Options:CreateToggle({
        Name = 'Randomize Order',
        Default = true,
        Flag = 'AutoLootOrder'
    })
        
    Options:CreateToggle({
        Name = 'Visualize Chest',
        Flag = 'AutoLootVisualHighlight',
        Default = true
    }).Link:AddColorPicker({
        Name = 'Color',
        Default = Color3.fromRGB(0, 255, 110),
        Flag = 'AutoLootHighlightColor'
    })

    Options:CreateSlider({
        Name = 'Loot Delay',
        Min = 0,
        Max = 1,
        Suffix = {Text = 's'},
        Default = 0.01,
        Round = 2,
        Flag = 'AutoLootDelay'
    })
end)

run(function()
    local AutoEat = categories.Utility:DrawTab({
        Name = 'Auto Eat',
        Type = 'Double'
    });

    local General = AutoEat:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local Options = AutoEat:DrawSection({
        Name = 'Options',
        Position = 'right'
    })

    local function isConsumable()

    end

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'AutoEat',
        Function = function(call)
            Features.AutoEat.Enabled = call

            if call then
                local Ratelimit = {}

                repeat
                    if entitylib:isAlive() then
                        if Flags.AutoEatHandCheck:GetValue() then
                            local success, Meta = bedwars.Inventory.hand.tool and bedwars:HasItemType(bedwars.Inventory.hand.tool, 'consumable') or nil

                            if success then
                                if Flags.AutoEatSync:GetValue() then
                                    task.wait(Meta.consumable.consumeTime)
                                end
                                
                                bedwars.Client:Get('ConsumeItem'):CallServerAsync({
                                    item = bedwars.Inventory.hand.tool
                                }):andThen(function(suc)
                                    if suc and Flags.AutoEatNotify:GetValue() then
                                        notify.new({
                                            Icon = 'rbxassetid://84221975933832',
                                            Content = `Consumed item {bedwars.Inventory.hand.tool.Name}`,
                                            Duration = 5
                                        })
                                    end 
                                end)
                            end 
                        else
                            for i, v in bedwars.Inventory.All do
                                local success, Meta = v.tool and bedwars:HasItemType(v.tool, 'consumable')
                                
                                if success and tick() > (Ratelimit[v.tool] or 0) then
                                    if Flags.AutoEatSync:GetValue() then
                                        task.wait(Meta.consumable.consumeTime)
                                    end

                                    if Flags.AutoEatSwitch:GetValue() then
                                        switchTool(v.tool, 0.05, Flags.AutoSwitchVisual:GetValue()) 
                                    end
                                   
                                    bedwars.Client:Get('ConsumeItem'):CallServerAsync({
                                        item = v.tool
                                    }):andThen(function(suc)
                                        if suc and Flags.AutoEatNotify:GetValue() then
                                            notify.new({
                                                Icon = 'rbxassetid://84221975933832',
                                                Content = `Consumed item {v.tool.Name}`,
                                                Duration = 5
                                            })
                                        elseif not suc then
                                            Ratelimit[v.tool] = tick() + 1
                                        end 
                                    end)
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                until not Features.AutoEat.Enabled
            end
        end
    })

    General:CreateToggle({
        Name = 'Auto Switch',
        Flag = 'AutoEatSwitch'
    })

    General:CreateToggle({
        Name = 'Visualize Switch',
        Flag = 'AutoSwitchVisual',
        Default = true
    })

    General:CreateToggle({
        Name = 'Hand Check',
        Flag = 'AutoEatHandCheck'
    })

    Options:CreateToggle({
        Name = 'Ignore Healing',
        Flag = 'AutoEatHealing'
    })

    Options:CreateToggle({
        Name = 'Ignore Speed',
        Flag = 'AutoEatHealing'
    })

    Options:CreateToggle({
        Name = 'Notify after eaten',
        Flag = 'AutoEatNotify'
    })

    Options:CreateToggle({
        Name = 'Sync eat time',
        Flag = 'AutoEatSync'
    })

    Options:CreateSlider({
        Name = 'Delay',
        Min = 0,
        Max = 2,
        Default = 0.1,
        Suffix = {Text = 's'},
        Flag = 'AutoEatDelay'
    })
end)

--[[
    World
]]

run(function()
    local Pickup = categories.World:DrawTab({
        Name = 'Fast Pickup',
        Type = 'Single'
    });

    local General = Pickup:DrawSection({
        Name = 'General',
        Position = 'left'
    });

    local Drops = {}
    
    General:CreateToggle({
        Name = 'Enable',
        Flag = 'Pickup',
        Function = function(call)
            Features.Pickup.Enabled = call

            if call then
                repeat
                    for _, v in collectionService:GetTagged('ItemDrop') do
                        if not entitylib:isAlive() then
                            break
                        end

                        if (lplr.Character.PrimaryPart.Position - v.Position).Magnitude <= Flags.PickupRange:GetValue() then
                            Drops[v] = tick() + 1

                            task.spawn(function()
                                local Name, Amount = v.Name, v:GetAttribute('Amount')

                                bedwars.Client:Get('PickupItemDrop'):CallServerAsync({
                                    itemDrop = v
                                }):andThen(function(suc)
                                    if suc then
                                        Drops[v] = tick()
                                        if Flags.PickupNotify:GetValue() then
                                            notify.new({
                                                Icon = 'rbxassetid://84221975933832',
                                                Content = `Picked up {Amount} {Name}{Amount >= 2 and 's' or ''}`,
                                                Duration = 5
                                            }) 
                                        end
                                    end
                                end)
                            end)
                        end
                    end
                    task.wait(0.1)
                until not Features.Pickup.Enabled
            end
        end
    })

    General:CreateToggle({
        Name = 'Notify on pickup',
        Default = true,
        Flag = 'PickupNotify'
    })

    General:CreateSlider({
        Name = 'Delay',
        Min = 0,
        Max = 1,
        Flag = 'PickupDelay',
        Default = 0,
        Round = 2,
        Suffix = {Text = 's'}
    })

    General:CreateSlider({
        Name = 'Range',
        Min = 1,
        Max = 15,
        Flag = 'PickupRange',
        Default = 15,
        Suffix = {Text = ' studs'}
    })
end)

run(function()
    local Nuker = categories.World:DrawTab({
        Name = 'Bed Nuker',
        Type = 'Single'
    });

    local General = Nuker:DrawSection({
        Name = 'General',
        Position = 'left'
    });

    local rayCheck = RaycastParams.new()
    rayCheck.FilterType = Enum.RaycastFilterType.Exclude
    rayCheck.RespectCanCollide = true

    local function getData(blockType)
        if not Loaded then
            return
        end
        
        if Flags.NukerLimit:GetValue() then
            if bedwars.Inventory.hand.tool and bedwars:HasItemType(bedwars.Inventory.hand.tool, 'breakBlock') then
                return bedwars.Inventory.hand
            end

            return
        end

        return  blockType and bedwars:getBestItemType('breakBlock', blockType) or bedwars:getBestItemType('breakBlock', 'stone')
    end

    local function getBed()
        for _, v in collectionService:GetTagged('bed') do
            if (lplr.Character.PrimaryPart.Position - v.Position).Magnitude <= Flags.NukerRange:GetValue() and not v:GetAttribute('Team'..(lplr:GetAttribute('Team') or -1)..'NoBreak') then
                return v
            end
        end
	end

    local BreakBlock = replicatedStorage.rbxts_include.node_modules['@easy-games']['block-engine'].node_modules['@rbxts'].net.out._NetManaged.DamageBlock

    General:CreateToggle({
        Name = 'Enable',
        Flag = 'BedNuker',
        Function = function(call)
            Features.BedNuker.Enabled = call

            if call then
                repeat
                    if entitylib:isAlive() and getData() then
                        local root = lplr.Character.PrimaryPart
                        
                        rayCheck.FilterDescendantsInstances = {lplr.Character}
                        rayCheck.CollisionGroup = root.CollisionGroup
                        
                        local bed = getBed()

                        if bed then
                            local solutions = {}

                            for _, v in {CFrame.new(), CFrame.new(0, 0, 3)} do
                                local ray = workspace:Raycast((bed.CFrame * v).Position + Vector3.new(0, 50, 0), Vector3.new(0, -150, 0), rayCheck)

                                if ray then
                                    table.insert(solutions, ray)
                                end
                            end

                            local best, mag = nil, 9e9
                            
                            for _, v in solutions do
                                local newmag = (bed.Position - v.Position).Magnitude

                                if newmag <= mag then
                                    mag = newmag
                                    best = v
                                end
                            end

                            if best and mag <= Flags.NukerRange:GetValue() then
                                local tool = getData(best.Instance.Name == 'bed' and 'wood' or bedwars.ItemMeta[best.Instance.Name] and bedwars.ItemMeta[best.Instance.Name].block and bedwars.ItemMeta[best.Instance.Name].block.breakType or nil)

                                if tool or not Flags.NukerPrio:GetValue() then
                                    if Flags.NukerPrio:GetValue() then
                                        switchTool(tool.tool, 0.05, Flags.NukerVisual:GetValue())
                                    end
                                    
                                    BreakBlock:InvokeServer({
                                        blockRef = {
                                            blockPosition = ({bedwars.BlockController:hasBlock({Position = best.Instance.Position})})[2]
                                        },
                                        hitPosition = best.Position,
                                        hitNormal = Vector3.FromNormalId(Enum.NormalId.Top)
                                    })

                                    task.wait(0.25)
                                end
                            end
                        end
                    end
                    task.wait()
                until not Features.BedNuker.Enabled
            end
        end
    })

    General:CreateToggle({
        Name = 'Use priority tools',
        Flag = 'NukerPrio',
        Function = void
    })

    General:CreateToggle({
        Name = 'Visualize Switch',
        Flag = 'NukerVisual'
    })

    General:CreateToggle({
        Name = 'Hand Check',
        Flag = 'NukerLimit',
        Function = void
    })

    General:CreateSlider({
        Name = 'Range',
        Min = 1,
        Max = 30,
        Default = 30,
        Suffix = {Text = ' studs'},
        Flag = 'NukerRange'
    })
end)

run(function()
    local LongFlight = categories.World:DrawTab({
        Name = 'Long Flight',
        Type = 'Single'
    })

    local General = LongFlight:DrawSection({
        Name = 'General',
        Position = 'left'
    })

    local Connection
    
    local Toggle
    
    Toggle = General:CreateToggle({
        Name = 'Enable',
        Flag = 'LongFly',
        Function = function(call)
            if call then
                local Jump = tick()
                local Dir, Once = nil, false

                local tool = bedwars.Inventory.fireball

                if tool then
                    switchTool(tool.tool, 0.05)

                    if replicatedStorage.rbxts_include.node_modules['@rbxts'].net.out._NetManaged.ProjectileFire:InvokeServer(
                        tool.tool, 
                        tool.tool.Name, 
                        tool.tool.Name, 
                        lplr.Character.PrimaryPart.Position + Vector3.new(0, 1, 0), 
                        lplr.Character.PrimaryPart.Position, 
                        Vector3.new(0, -1, 0) * 56, 
                        httpService:GenerateGUID(true), 
                        {
                            drawDurationSeconds = 1, 
                            shotId = httpService:GenerateGUID(false)
                        }, 
                        workspace:GetServerTimeNow() - 0.045
                    ) then
                        Jump = tick() + 2
                        task.delay(2.5, function()
                            Once = true
                        end)
                    end
                end

                repeat
                    if not entitylib:isAlive() then
                        break
                    end

                    if not Dir then
                        Dir = lplr.Character.PrimaryPart.CFrame.LookVector
                    end

                    
                    local velo = Vector3.zero
                    local dir = tick() > Jump and Vector3.zero or Dir

                    velo += (dir * 20)
                    lplr.Character.PrimaryPart.AssemblyLinearVelocity = velo
                    lplr.Character.PrimaryPart.CFrame += (dir * math.max(Flags.LongFlySpeed:GetValue() - 20, 0) * runService.PreSimulation:Wait())

                    if tick() > Jump and Once then
                        break
                    end
                    task.wait()
                until not Toggle:GetValue()

                if Toggle:GetValue() then
                    Toggle:SetValue(false)
                end
            else
                if Connection then
                    Connection:Disconnect()
                    Connection = nil
                end
            end
        end
    })
    
    --[[
        Options
    ]]

    General:AddKeybind({
        Name = 'Keybind',
        Flag = 'LongFlyBind',
        Callback = function()
            Toggle:SetValue(not Toggle:GetValue())
        end
    })

    General:CreateSlider({
        Name = 'Speed',
        Min = 1,
        Max = 83,
        Default = 83,
        Round = 1,
        Flag = 'LongFlySpeed',
    })
end)

--[[
    Minigames
]]

run(function()
    local KeepSprint = categories.Minigames:DrawTab({
        Name = 'Keep Sprint',
        Type = 'Single'
    });

    KeepSprint:DrawSection({
        Name = 'General',
        Position = 'left'
    }):CreateToggle({
        Name = 'Enable',
        Flag = 'KeepSprint',
        Function = function(call)
            debug.setconstant(bedwars.SprintController.startSprinting, 5, call and 'blockSprinting' or 'blockSprint')
			--bedwars.SprintController:stopSprinting()
        end
    })
end)

run(function()
    local rayCheck = RaycastParams.new()
    rayCheck.FilterType = Enum.RaycastFilterType.Exclude
    rayCheck.RespectCanCollide = true

    local NoFall = categories.Minigames:DrawTab({
        Name = 'No Fall',
        Type = 'Single'
    });

    NoFall:DrawSection({
        Name = 'General',
        Position = 'left'
    }):CreateToggle({
        Name = 'Enable',
        Flag = 'NoFall',
        Function = function(call)
            Features.NoFall.Enabled = call

            if call then
                local tracked, extraGravity = 0, 0

                Features.NoFall:Clean(runService.PreSimulation:Connect(function(dt)
                    if not Loaded then
                        return
                    end

                    if entitylib:isAlive() then
                        local root = lplr.Character.PrimaryPart
                        if root.AssemblyLinearVelocity.Y < -85 then
                            rayCheck.FilterDescendantsInstances = {lplr.Character, camera}
                            rayCheck.CollisionGroup = root.CollisionGroup

                            local rootSize = root.Size.Y / 2.5 + lplr.Character.Humanoid.HipHeight
                            local ray = workspace:Blockcast(root.CFrame, Vector3.new(3, 3, 3), Vector3.new(0, -rootSize, 0), rayCheck)
                            if not ray then
                                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, -86, root.AssemblyLinearVelocity.Z)
                                root.CFrame = root.CFrame + Vector3.new(0, extraGravity * dt, 0)
                                extraGravity = extraGravity + -workspace.Gravity * dt
                            end
                        else
                            extraGravity = 0
                        end
                    end
                end))
            end
        end
    })
end)

--[[
    GUI SETTINGS
]]

run(function() --> Settings
    local Settings = categories.Settings:DrawSection({
        Name = 'UI Settings'
    });

    Settings:AddButton({
        Name = 'Unload',
        Callback = function()
            Loaded = false

            for _, v in Features do
                v.Enabled = false
            end

            window.Root:Destroy()
        end
    })

    Settings:AddToggle({
        Name = 'Alway Show Frame',
        Default = inputService.TouchEnabled,
        Callback = function(v)
            window.AlwayShowTab = v;
        end,
    });

    Settings:AddColorPicker({
        Name = 'Highlight',
        Default = guilib.Colors.Highlight,
        Callback = function(v)
            guilib.Colors.Highlight = v;
            guilib:RefreshCurrentColor();
        end,
    });

    Settings:AddColorPicker({
        Name = 'Toggle Color',
        Default = guilib.Colors.Toggle,
        Callback = function(v)
            guilib.Colors.Toggle = v;
            
            guilib:RefreshCurrentColor(v);
        end,
    });

    Settings:AddColorPicker({
        Name = 'Drop Color',
        Default = guilib.Colors.DropColor,
        Callback = function(v)
            guilib.Colors.DropColor = v;

            guilib:RefreshCurrentColor(v);
        end,
    });

    Settings:AddColorPicker({
        Name = 'Risky',
        Default = guilib.Colors.Risky,
        Callback = function(v)
            guilib.Colors.Risky = v;

            guilib:RefreshCurrentColor(v);
        end,
    });

    Settings:AddColorPicker({
        Name = 'Mouse Enter',
        Default = guilib.Colors.MouseEnter,
        Callback = function(v)
            guilib.Colors.MouseEnter = v;

            guilib:RefreshCurrentColor(v);
        end,
    });

    Settings:AddColorPicker({
        Name = 'Block Color',
        Default = guilib.Colors.BlockColor,
        Callback = function(v)
            guilib.Colors.BlockColor = v;

            guilib:RefreshCurrentColor(v);
        end,
    });

    Settings:AddColorPicker({
        Name = 'Background Color',
        Default = guilib.Colors.BGDBColor,
        Callback = function(v)
            guilib.Colors.BGDBColor = v;

            guilib:RefreshCurrentColor(v);
        end,
    });

    Settings:AddColorPicker({
        Name = 'Block Background Color',
        Default = guilib.Colors.BlockBackground,
        Callback = function(v)
            guilib.Colors.BlockBackground = v;

            guilib:RefreshCurrentColor(v);
        end,
    });

    Settings:AddColorPicker({
        Name = 'Stroke Color',
        Default = guilib.Colors.StrokeColor,
        Callback = function(v)
            guilib.Colors.StrokeColor = v;

            guilib:RefreshCurrentColor(v);
        end,
    });

    Settings:AddColorPicker({
        Name = 'High Stroke Color',
        Default = guilib.Colors.HighStrokeColor,
        Callback = function(v)
            guilib.Colors.HighStrokeColor = v;

            guilib:RefreshCurrentColor(v);
        end,
    });

    Settings:AddColorPicker({
        Name = 'Switch Color',
        Default = guilib.Colors.SwitchColor,
        Callback = function(v)
            guilib.Colors.SwitchColor = v;

            guilib:RefreshCurrentColor(v);
        end,
    });

    Settings:AddColorPicker({
        Name = 'Line Color',
        Default = guilib.Colors.LineColor,
        Callback = function(v)
            guilib.Colors.LineColor = v;

            guilib:RefreshCurrentColor(v);
        end,
    });
end)

run(function() -- LANGUAGE MANAGER
    local fetchLink = 'https://raw.githubusercontent.com/x2neptunereal/Alchemy-Languages/main/bedwars' -- Change from bedwars to the game name when ur adding this to another game

    categories.Settings:DrawSection({
        Name = 'UI Language',
        Position = 'right'
    }):AddDropdown({
        Name = 'Text Language',
        List = {'English', 'Russian'},
        Default = 'English',
        Flag = 'UILanguage',
        Function = function(val)
            if val then
                local json = game:HttpGet(`{fetchLink}/{val:lower()}.json`)

                if json then
                    local suc, compiled = pcall(function()
                        return httpService:JSONDecode(json)
                    end)

                    if suc and compiled then
                        for Tab, v1 in Texts do
                            for Module, v2 in v1 do
                                for Option, v3 in v2 do
                                    pcall(function()
                                        v3:SetText(compiled.data[Tab][Module][Option])
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    })
end)

Loaded = true

run(function() 
    local ConfigManager = guilib:ConfigManager({
        Directory = 'alchemyhub_neta/bedwars',
        Author = lplr.Name
    });

    local ConfigUI = window:DrawConfig({
        Name = 'Config',
        Icon = 'folder',
        Author = lplr.Name,
        Config = ConfigManager
    });

    ConfigUI:Init();
end)
