if (not (syn and syn.protect_gui)) or (not get_hidden_gui) then
    return
end

local maid = loadstring(game:HttpGet('https://raw.githubusercontent.com/Quenty/NevermoreEngine/version2/Modules/Shared/Events/Maid.lua'))()
local signal = loadstring(game:HttpGet('https://raw.githubusercontent.com/Quenty/NevermoreEngine/version2/Modules/Shared/Events/Signal.lua'))()
local material = loadstring(game:HttpGet('https://raw.githubusercontent.com/Kinlei/MaterialLua/master/Module.lua'))()

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

shared.transparency = 0;
shared.chams = false;

characterAdded:Connect(function(player, character) 
    local maid = playerMaids[player]
    local chams = {}

    for _, part in next, character:GetChildren() do
        if part:IsA('BasePart') and part.Transparency ~= 1 then
            chams[#chams + 1] = create('BoxHandleAdornment', {
                Name = 'Cham',
                Adornee = part,

                AlwaysOnTop = true,
                Color3 = player.TeamColor.Color;
                Size = (part.Size + Vector3.new(0.5, 0.5, 0.5)),
                Transparency = (shared.transparency or 0),
                Visible = (shared.chams or false),

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

    maid:GiveTask(transparencyChanged:Connect(function(new)
        for _, part in next, chams do
            part.Transparency = new;
        end
    end))

    maid:GiveTask(function()
        for _, part in next, chams do
            part:Destroy()
        end
    end)

    maid:GiveTask(character.AncestryChanged:connect(function(_, new)
        if new == nil then
            maid:DoCleaning()
        end
    end))
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

        local start = tick();
        while true do
            runService.Heartbeat:wait()
            player = characterList[model]-- replication.getplayerhit(model:FindFirstChildOfClass('Part') or model)
            
            if player then break end
            if (tick() - start) > 5 then break end
        end

        if (not player) then return end

        characterAdded:Fire(player, model)
    end)

    for _, child in next, team:GetChildren() do
        if child == client.Character then
            continue
        end

        coroutine.wrap(function()
            local player;
            while true do
                runService.Heartbeat:wait()
                player = replication.getplayerhit(child:FindFirstChildOfClass('Part') or child)
                
                if player then break end
            end
    
            characterAdded:Fire(player, child)
        end)()
    end
end

local ui = material.Load({
    Title = 'Phantom Forces - Chams',
    Style = 3,
    SizeY = 175,
    Theme = 'Dark',
})

local tab = ui.New({
    Title = 'Main',
})

tab.Toggle({
    Text = 'Chams',
    Callback = function(state)
        shared.chams = state;
        chamStateChanged:Fire(state)
    end,
})

tab.Slider({
    Text = 'Transparency',
    Min = 0,
    Max = 10,
    Def = 0,
    Callback = function(new)
        shared.transparency = new/10
        transparencyChanged:Fire(shared.transparency)
    end,
})

tab.Button({
    Text = 'Credits',
    Menu = {
        Scripting = function()
            ui.Banner({
                Text = 'BigTimbob @ v3rmillion.net',
            })
        end,
        Libraries = function()
            ui.Banner({
                Text = 'Quenty - Nevermore Engine (Signal & Maids)',
            })
        end,
        Interface = function()
            ui.Banner({
                Text = 'aKinlei - Material Lua'
            })
        end,
    }
})
