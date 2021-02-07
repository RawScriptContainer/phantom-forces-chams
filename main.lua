if (not (syn and syn.protect_gui)) and (not get_hidden_gui) then
    return
end

local maid = loadstring(game:HttpGet('https://raw.githubusercontent.com/Quenty/NevermoreEngine/version2/Modules/Shared/Events/Maid.lua'))()
local signal = loadstring(game:HttpGet('https://raw.githubusercontent.com/Quenty/NevermoreEngine/version2/Modules/Shared/Events/Signal.lua'))()
local library = loadstring(game:HttpGet('https://pastebin.com/raw/edJT9EGX'))()

local replication, camera, setlookvector; do
    for _, tbl in next, getgc(true) do
        if type(tbl) ~= 'table' then 
            if type(tbl) == 'function' and getinfo(tbl).name == 'setlookvector' then
                setlookvector = tbl;
            end

            continue 
        end


        if rawget(tbl, 'removecharacterhash') then
            replication = tbl;
        end

        if rawget(tbl, 'setmenufov') then
            camera = tbl;
        end


        if (replication and camera) then break end
    end

    if (not replication) or (not camera) then 
        return
    end
end

local function create(class, properties)
    local object = Instance.new(class)

    for property, value in next, properties do
        if property == 'Parent' then
            continue
        end

        if typeof(value) == "Instance" then
            if type(property) == 'string' then
                object[property] = value;
            else
                val.Parent = object;
            end

            continue
        end

        object[property] = value;
    end

    object.Parent = properties.Parent;
    return object;
end

local folder = create('Folder', {
    Name = 'Adornments',
});

if (syn and syn.protect_gui) then
    syn.protect_gui(folder);
    folder.Parent = game:GetService('CoreGui')
elseif get_hidden_gui then
    folder.Parent = get_hidden_gui();
else
    return client:Kick('Failed to protect instances')
end

local playerMaids = {}
local playerCharacters = {};

local players = game:GetService('Players');
local client = players.LocalPlayer;

local userInputService = game:GetService('UserInputService')
local runService = game:GetService("RunService")

local characterList = getupvalue(replication.getplayerhit, 1)

local characterAdded = signal.new()
local transparencyChanged = signal.new();
local chamStateChanged = signal.new();
local teamStateChanged = signal.new();
local colorChanged = signal.new();

characterAdded:Connect(function(player, character) 
    local maid = playerMaids[player]
    local chams = {}

    local label = Drawing.new('Text')
    label.Text = player.Name;
    label.Size = 18
    label.Outline = true;
    label.Center = true;
    label.Color = Color3.new(1, 1, 1)

    if Drawing.Fonts then
        label.Font = Drawing.Fonts.Monospace;
    end
    
    label.Transparency = 1;
    label.Visible = false;

    local head = character:WaitForChild('Head')
    local root = character:WaitForChild('HumanoidRootPart')
    local team = player.Team
    local isSameTeam = (client.Team == team);
    local color = (isSameTeam and library.flags.allyColor or library.flags.enemyColor)

    playerCharacters[player] = character;

    local isVisible = library.flags.chams
    if (not library.flags.showTeam) and isSameTeam then
        isVisible = false;
    end


    for _, part in next, character:GetChildren() do
        if part:IsA('BasePart') and part.Transparency ~= 1 then
            chams[#chams + 1] = create('BoxHandleAdornment', {
                Name = 'Cham',
                Adornee = part,

                AlwaysOnTop = true,
                Color3 = (color or player.TeamColor.Color),
                Size = (part.Size + Vector3.new(0.5, 0.5, 0.5)),
                Transparency = (library.flags.chamsTransparency or 0),
                Visible = isVisible,

                ZIndex = 10;
                Parent = folder,
            })
        end
    end

    maid:DoCleaning()
    maid:GiveTask(chamStateChanged:Connect(function(state)
        for _, part in next, chams do
            part.Visible = state;
        end
    end))

    maid:GiveTask(runService.Heartbeat:connect(function()
        local isVisible = library.flags.showNames
        if (not library.flags.showTeam) and isSameTeam then
            isVisible = false;
        end

        if isVisible and head then
            local vector, visible = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
            if visible then
                local cRoot = client.Character and client.Character:FindFirstChild('Torso')

                if cRoot and library.flags.showDistance then
                    local distance = math.floor((root.Position - cRoot.Position).magnitude)
                    label.Text = (player.Name .. '\n' .. distance .. 'm')
                else
                    label.Text = player.Name
                end
                
                label.Position = Vector2.new(vector.X, vector.Y - 20)
                label.Visible = true;
                return;
            end
        end

        label.Visible = false;
    end))

    maid:GiveTask(colorChanged:Connect(function()
        for _, part in next, chams do
            part.Color3 = (color or player.TeamColor.Color)
        end
    end))

    maid:GiveTask(teamStateChanged:Connect(function(state) 
        -- recalculating for if localplayer changes team :D
        team = player.Team
        isSameTeam = (client.Team == team);
        color = (isSameTeam and library.flags.allyColor or library.flags.enemyColor)
    
        local isVisible = library.flags.chams
        if (not library.flags.showTeam) and isSameTeam then
            isVisible = false;
        end

        for _, part in next, chams do
            part.Visible = isVisible
            part.Color3 = (color or player.TeamColor.Color)
        end
    end))

    maid:GiveTask(transparencyChanged:Connect(function(new)
        for _, part in next, chams do
            part.Transparency = new;
        end
    end))

    maid:GiveTask(player:GetPropertyChangedSignal('Team'):connect(function()
        teamStateChanged:Fire(library.flags.showTeams)
    end))

    maid:GiveTask(character:GetPropertyChangedSignal('Parent'):connect(function()
        if (not character.Parent) then
            maid:DoCleaning()
        end
    end))

    maid:GiveTask(function()
        playerCharacters[player] = nil;
        
        if currentTarget then

        end

        for i = #chams, 1, -1 do
            local part = table.remove(chams, i)
            if typeof(part) == 'Instance' then
                part:Destroy()
            end
        end

        label.Visible = false;
        label:Remove()
        label = nil;
    end)
end)

for _, player in next, players:GetPlayers() do
    playerMaids[player] = maid.new()
end

players.PlayerAdded:Connect(function(player)
    playerMaids[player] = maid.new()
end)

players.PlayerRemoving:Connect(function(player)
    if playerMaids[player] then
        playerMaids[player]:DoCleaning()
    end

    playerMaids[player] = nil;
end)

for _, team in next, workspace.Players:GetChildren() do
    team.ChildAdded:Connect(function(model)
        if (model == client.Character) then
            return
        end

        local player;

        while true do
            runService.Heartbeat:wait()
            player = characterList[model]
            
            if player then break end
            if (not model.Parent) then break end
        end

        if (not player) then return end
        characterAdded:Fire(player, model)
    end)

    for _, model in next, team:GetChildren() do
        if model == client.Character then
            continue
        end

        coroutine.wrap(function()
            local player;

            local start = tick();
            while true do
                runService.Heartbeat:wait()
                player = characterList[model]

                if player then break end
            end
              
            if (not player) then return end
            characterAdded:Fire(player, model)
        end)()
    end
end

-- forces chams to refresh if client changes teams (e.g. in a vip server)
client:GetPropertyChangedSignal('Team'):connect(function()
    teamStateChanged:Fire(library.flags.showTeams)
end)

--[[ aimbot ]] 
local circle; do
    -- i know some of this code is a bit ugly or inefficient but oh well

    local partList = {
        'Head', 
        'Torso', 
        'Left Arm', 
        'Right Arm', 
        'Left Leg', 
        'Right Leg', 
    }

    circle = Drawing.new('Circle');
    circle.Thickness = 2
    circle.Transparency = 1;
    circle.Visible = false;
    circle.NumSides = 24;

    local function selectAimbotTarget()
        local found = nil;
        local dist = math.huge;

        local cursor = userInputService:GetMouseLocation()
        local part = library.flags.aimPart or 'Head'
        if (part == 'Random') then
            part = partList[math.random(#partList)]
        end

        local cPos = circle.Position;
        local cRad = circle.Radius;

        for player, character in next, playerCharacters do
            if player.Team == client.Team then continue end
            if (not character:IsDescendantOf(workspace)) then continue end

            local part = character:FindFirstChild(part)
            if (not part) then continue end

            local vector, visible = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
            if (not visible) then continue end

            local v2 = Vector2.new(vector.X, vector.Y)
            local mDist = math.floor((cursor - v2).magnitude) 

            if library.flags.useFovCircle then
                -- this for some reason works better than a magnitude check (probably some stupid circle math idk)

                local left = (cPos.X - cRad)
                local right = (cPos.X + cRad)
                local top = (cPos.Y - cRad)
                local bottom = (cPos.Y + cRad)

                if not ((v2.X <= right and v2.X >= left) and (v2.Y <= bottom and v2.Y >= top)) then
                    continue
                end
            end

            if mDist < dist then
                dist = mDist
                final = part;
            end
        end

        return final
    end

    local currentTarget;
    runService.RenderStepped:connect(function()
        circle.Position = userInputService:GetMouseLocation()
    end)

    runService.Heartbeat:connect(function()
        if library.flags.aimbotEnabled and library.flags._holdingAimbotBind and client.Character then
            if (not currentTarget) then
                currentTarget = selectAimbotTarget()
            elseif currentTarget and (not currentTarget.Parent) then
                currentTarget = nil;
                return
            end

            if (not currentTarget) or (not currentTarget:IsDescendantOf(workspace)) then return end

            -- setlookvector(camera, camera.cframe:lerp(CFrame.lookAt(camera.cframe.p, currentTarget.Position), 1/sens).lookVector)

            local cursor = userInputService:GetMouseLocation()
            local position, visible = workspace.CurrentCamera:WorldToViewportPoint(currentTarget.Position)

            if (not visible) then 
                currentTarget = nil
                return
            end

            local mPosition = Vector2.new(position.X, position.Y);
            local relative = (mPosition - cursor)
            
            local sens = library.flags.aimbotSmoothing or 1
            mousemoverel(relative.X/sens, relative.Y/sens)
        end 
    end)

    userInputService.InputEnded:connect(function(key, gpe)
        if (not library._aimbotBindOption) then return end
        
        local bind = library._aimbotBindOption.key 
        if (key.UserInputType.Name == bind or key.KeyCode.Name == bind) then
            currentTarget = nil;
        end
    end)
end

local window = library:CreateWindow('Phantom Forces');
local folder = window:AddFolder('Aimbot') do

    folder:AddToggle({
        text = 'Enabled',
        flag = 'aimbotEnabled',
    })

    folder:AddSlider({
        text = 'Sensitivity',
        flag = 'aimbotSmoothing',
        min = 1, 
        max = 10,
        float = 0.1,
    })

    library._aimbotBindOption = folder:AddBind({
        text = 'Keybind',
        flag = 'aimbotBind',
        key = Enum.UserInputType.MouseButton2,
        hold = true,
        callback = function(value)
            library.flags._holdingAimbotBind = (not value)
        end,
    })

    folder:AddList({
        text = 'Aimbot part',
        flag = 'aimPart',
        values = {
            'Head', 
            'Torso', 
            'Left Arm', 
            'Right Arm', 
            'Left Leg', 
            'Right Leg', 
            'Random',
        }
    })

    folder:AddToggle({
        text = 'FOV Circle',
        flag = 'useFovCircle',
        callback = function(state)
            circle.Visible = state
        end
    })

    folder:AddSlider({
        text = 'Radius',
        min = 1,
        max = 100,
        flag = 'fovCircleRadius',
        callback = function(value)
            circle.Radius = value
        end,
    })

    folder:AddColor({
        text = 'Color',
        callback = function(color)
            circle.Color = color;
        end
    })
end

local folder = window:AddFolder('Visuals') do
    folder:AddToggle({
        text = 'Names', 
        flag = 'showNames', 
    })

    folder:AddToggle({
        text = 'Distance', 
        flag = 'showDistance', 
    })

    folder:AddToggle({
        text = 'Chams', 
        flag = 'chams', 
        callback = function(state)
            chamStateChanged:Fire(state)
        end
    })

    folder:AddToggle({
        text = 'Show Teammates',
        flag = 'showTeam',
        callback = function(state)
            teamStateChanged:Fire(state)
        end,
    })

    folder:AddSlider({
        text = 'Transparency',
        flag = 'chamsTransparency',
        min = 0,
        max = 1,
        float = 0.1,
        callback = function(value)
            transparencyChanged:Fire(value)
        end
    })

    folder:AddColor({
        text = 'Ally Color',
        flag = 'allyColor',
        color = Color3.fromRGB(0, 255, 140),
        callback = function(color)
            colorChanged:Fire()
        end,
    })

    folder:AddColor({
        text = 'Enemy Color',
        flag = 'enemyColor',
        color = Color3.fromRGB(255, 50, 50),
        callback = function(color)
            colorChanged:Fire()
        end,
    })
end

local folder = window:AddFolder('Credits') do
    folder:AddLabel({text = 'Scripting - wally'})
    folder:AddLabel({text = 'Interface - Jan'})
    folder:AddLabel({text = 'Libraries - Quenty'})
    folder:AddLabel({text = 'egg salad is rly fat'})
end

library:Init()
