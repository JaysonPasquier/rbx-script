-- Game Data Scanner for Roblox
-- This script scans the entire game and sends all object paths to Pastebin
-- Place this as a ServerScript in ServerScriptService

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- VPS CONFIGURATION
-- Your VPS details
local VPS_IP = "194.164.89.41"
local VPS_ENDPOINT = "http://194.164.89.41/vps-data-saver.php"

-- Function to create GUI display for mobile users
local function createURLDisplay(url)
    -- Create GUI for all players
    for _, player in pairs(Players:GetPlayers()) do
        local playerGui = player:WaitForChild("PlayerGui")

        -- Create ScreenGui
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "PastebinURLDisplay"
        screenGui.Parent = playerGui

        -- Create main frame
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.8, 0, 0.6, 0)
        frame.Position = UDim2.new(0.1, 0, 0.2, 0)
        frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui

        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame

        -- Create title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0.15, 0)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "🎉 Game Data Scanned Successfully!"
        title.TextColor3 = Color3.new(1, 1, 1)
        title.TextScaled = true
        title.Font = Enum.Font.SourceSansBold
        title.Parent = frame

        -- Create URL label
        local urlLabel = Instance.new("TextLabel")
        urlLabel.Size = UDim2.new(1, -20, 0.4, 0)
        urlLabel.Position = UDim2.new(0, 10, 0.2, 0)
        urlLabel.BackgroundTransparency = 1
        urlLabel.Text = "📋 Pastebin URL:\n" .. url
        urlLabel.TextColor3 = Color3.new(0.7, 0.9, 1)
        urlLabel.TextScaled = true
        urlLabel.Font = Enum.Font.SourceSans
        urlLabel.TextWrapped = true
        urlLabel.Parent = frame

        -- Create instructions
        local instructions = Instance.new("TextLabel")
        instructions.Size = UDim2.new(1, -20, 0.25, 0)
        instructions.Position = UDim2.new(0, 10, 0.65, 0)
        instructions.BackgroundTransparency = 1
        instructions.Text = "📱 Instructions:\n1. Copy the URL above\n2. Open it in your browser\n3. Copy the data to your base-data.txt file"
        instructions.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        instructions.TextScaled = true
        instructions.Font = Enum.Font.SourceSans
        instructions.TextWrapped = true
        instructions.Parent = frame

        -- Create close button
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0.3, 0, 0.1, 0)
        closeButton.Position = UDim2.new(0.35, 0, 0.9, 0)
        closeButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
        closeButton.Text = "Close"
        closeButton.TextColor3 = Color3.new(1, 1, 1)
        closeButton.TextScaled = true
        closeButton.Font = Enum.Font.SourceSansBold
        closeButton.Parent = frame

        -- Add corner to button
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 5)
        buttonCorner.Parent = closeButton

        -- Close button functionality
        closeButton.MouseButton1Click:Connect(function()
            screenGui:Destroy()
        end)

        -- Auto-close after 30 seconds
        game:GetService("Debris"):AddItem(screenGui, 30)
    end
end

-- Function to recursively scan all objects in the game
local function scanObject(obj, path, depth)
    local data = {}
    local indent = string.rep("  ", depth)

    -- Add current object info
    local objInfo = indent .. "[" .. obj.ClassName .. "] " .. obj.Name .. " (" .. path .. ")"
    table.insert(data, objInfo)

    -- Add object properties for important objects
    if obj.ClassName == "Part" or obj.ClassName == "Model" or obj.ClassName == "Script" or obj.ClassName == "LocalScript" then
        table.insert(data, indent .. "  Properties:")

        if obj.ClassName == "Part" then
            table.insert(data, indent .. "    Size: " .. tostring(obj.Size))
            table.insert(data, indent .. "    Position: " .. tostring(obj.Position))
            table.insert(data, indent .. "    Material: " .. tostring(obj.Material))
        elseif obj.ClassName == "Model" then
            table.insert(data, indent .. "    PrimaryPart: " .. (obj.PrimaryPart and obj.PrimaryPart.Name or "None"))
        elseif obj.ClassName == "Script" or obj.ClassName == "LocalScript" then
            table.insert(data, indent .. "    Enabled: " .. tostring(obj.Enabled))
            table.insert(data, indent .. "    RunContext: " .. tostring(obj.RunContext))

            -- Get script content
            local success, scriptContent = pcall(function()
                return obj.Source
            end)

            if success and scriptContent and scriptContent ~= "" then
                table.insert(data, indent .. "    Script Content:")
                local lines = string.split(scriptContent, "\n")
                for i, line in pairs(lines) do
                    table.insert(data, indent .. "      " .. i .. ": " .. line)
                end
            else
                table.insert(data, indent .. "    Script Content: [Empty or Error]")
            end
        end
    end

    -- Recursively scan children
    for _, child in pairs(obj:GetChildren()) do
        local childPath = path .. "." .. child.Name
        local childData = scanObject(child, childPath, depth + 1)
        for _, line in pairs(childData) do
            table.insert(data, line)
        end
    end

    return data
end

-- Function to manually encode URL parameters
local function urlEncode(str)
    if str == nil then return "" end
    str = tostring(str)
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w %-%_%.%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    str = string.gsub(str, " ", "+")
    return str
end

-- Function to send data to VPS
local function sendToVPS(data)
    local success, result = pcall(function()
        local gameData = table.concat(data, "\n")
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")

        print("📤 Sending data to VPS...")
        print("📊 Data size: " .. #gameData .. " characters")

        -- Prepare JSON data
        local jsonData = {
            game_name = game.Name,
            game_data = gameData,
            timestamp = timestamp
        }

        -- Send to VPS
        local response = request({
            Url = VPS_ENDPOINT,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(jsonData)
        })

                if response and response.Body then
            print("📡 VPS Response: " .. tostring(response.Body))

            local success, responseData = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if success and responseData then
                if responseData.success then
                    return responseData.viewer_url
                else
                    return "Error: " .. (responseData.error or "Unknown error")
                end
            else
                return "Error: Invalid JSON response - " .. tostring(response.Body)
            end
        else
            return "Error: No response from VPS - " .. tostring(response)
        end
    end)

    if success then
        print("✅ Data successfully sent to VPS!")
        print("📋 VPS URL: " .. result)
        print("🔗 Copy this URL and open it in your browser to view all your game data")

        -- Create GUI to display URL on screen (for mobile users)
        createURLDisplay(result)

        return result
    else
        warn("❌ Failed to send data to VPS: " .. tostring(result))
        return nil
    end
end

-- Main function to scan the game
local function scanGame()
    print("🔍 Starting game scan...")

    local allData = {}

    -- Add header
    table.insert(allData, "=== ROBLOX GAME DATA SCAN ===")
    table.insert(allData, "Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(allData, "Game: " .. game.Name)
    table.insert(allData, "")

    -- Scan main game services
    local servicesToScan = {
        "Workspace",
        "ServerStorage",
        "ReplicatedStorage",
        "StarterGui",
        "StarterPlayer",
        "StarterPack",
        "Lighting",
        "SoundService",
        "TweenService",
        "RunService",
        "UserInputService",
        "Players",
        "Teams",
        "BadgeService",
        "MarketplaceService",
        "DataStoreService",
        "MessagingService",
        "TextService",
        "ContextActionService",
        "GuiService",
        "HttpService",
        "InsertService",
        "PathfindingService",
        "PhysicsService",
        "ReplicatedFirst",
        "ServerScriptService",
        "StarterGui",
        "StarterPlayerScripts",
        "StarterPack"
    }

    for _, serviceName in pairs(servicesToScan) do
        local service = game:GetService(serviceName)
        if service then
            table.insert(allData, "=== " .. serviceName .. " ===")
            local serviceData = scanObject(service, serviceName, 0)
            for _, line in pairs(serviceData) do
                table.insert(allData, line)
            end
            table.insert(allData, "")
        end
    end

    -- Scan any other top-level objects
    table.insert(allData, "=== OTHER TOP-LEVEL OBJECTS ===")
    for _, obj in pairs(game:GetChildren()) do
        local found = false
        for _, serviceName in pairs(servicesToScan) do
            if obj.Name == serviceName then
                found = true
                break
            end
        end
        if not found then
            local objData = scanObject(obj, obj.Name, 0)
            for _, line in pairs(objData) do
                table.insert(allData, line)
            end
        end
    end

        print("📊 Scan complete! Found " .. #allData .. " lines of data")
    print("📤 Sending to VPS...")

    -- Send to VPS
    local vpsUrl = sendToVPS(allData)

    if vpsUrl then
        print("🎉 SUCCESS! Your game data is now available at:")
        print("🔗 " .. vpsUrl)
        print("📋 Copy this URL and open it in your browser to view all your game data")
        print("💾 You can view, download, or copy any of your saved game data files")
    else
        print("❌ Failed to send data to VPS. Check your VPS connection.")
    end
end

-- Check if VPS is configured
if VPS_IP == "YOUR_VPS_IP_HERE" then
    warn("⚠️  WARNING: Please set your VPS IP in the script!")
    warn("🔧 Replace 'YOUR_VPS_IP_HERE' with your actual VPS IP")
    return
end

-- Start the scan
scanGame()
