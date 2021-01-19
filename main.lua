if (not (syn and syn.protect_gui)) and (not get_hidden_gui) then
    return
end

local maid = loadstring(game:HttpGet('https://raw.githubusercontent.com/Quenty/NevermoreEngine/version2/Modules/Shared/Events/Maid.lua'))()
local signal = loadstring(game:HttpGet('https://raw.githubusercontent.com/Quenty/NevermoreEngine/version2/Modules/Shared/Events/Signal.lua'))()
local library = loadstring(game:HttpGet('https://pastebin.com/raw/edJT9EGX'))()

local replication; do
    for _, tbl in next, getgc(true) do
        if type(tbl) ~= 'table' then continue end

        if rawget(tbl, 'removecharacterhash') then
            replication = tbl;
            break
        end
    end

    if (not replication) then 
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
local players = game:GetService('Players');
local runService = game:GetService('RunService');
local client = players.LocalPlayer;

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
    local team = player.Team
    local isSameTeam = (client.Team == team);
    local color = (isSameTeam and library.flags.allyColor or library.flags.enemyColor)

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

    maid:GiveTask(character.AncestryChanged:connect(function(_, new)
        if new == nil then
            maid:DoCleaning()
        end
    end))

    maid:GiveTask(function()
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

local window = library:CreateWindow('Phantom Forces');
local folder = window:AddFolder('Toggles') do
    folder:AddToggle({
        text = 'Names', 
        flag = 'showNames', 
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
    folder:AddLabel({text = 'Scripting: wally'})
    folder:AddLabel({text = 'Interface - Jan'})
    folder:AddLabel({text = 'Libraries - Quenty'})
end

library:Init()
