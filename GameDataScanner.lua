-- Game Data Scanner for Roblox
-- This script scans the entire game and sends all object paths to Pastebin
-- Place this as a ServerScript in ServerScriptService

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- PASTEBIN API CONFIGURATION
-- Get your API key from: https://pastebin.com/doc_api
local PASTEBIN_API_KEY = "6A7xLcFEjNECEk00xc7OzvA6tWxuinhr" -- Replace with your actual API key
local PASTEBIN_API_URL = "https://pastebin.com/api/api_post.php"

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

-- Function to send data to Pastebin in chunks
local function sendToPastebin(data)
    local success, result = pcall(function()
        local pasteContent = table.concat(data, "\n")
        local pasteName = "Roblox Game Data - " .. os.date("%Y-%m-%d %H:%M:%S")

        -- Check if content is too large (Pastebin limit is ~512KB)
        if #pasteContent > 500000 then -- 500KB limit
            -- Split into multiple pastes
            local chunks = {}
            local chunkSize = 10000 -- 10k lines per chunk
            local totalChunks = math.ceil(#data / chunkSize)

            print("📊 Data too large! Splitting into " .. totalChunks .. " chunks...")

            for i = 1, totalChunks do
                local startIndex = (i - 1) * chunkSize + 1
                local endIndex = math.min(i * chunkSize, #data)
                local chunk = {}

                for j = startIndex, endIndex do
                    table.insert(chunk, data[j])
                end

                local chunkContent = table.concat(chunk, "\n")
                local chunkName = pasteName .. " (Part " .. i .. "/" .. totalChunks .. ")"

                -- Send each chunk
                local chunkBody = "api_dev_key=" .. urlEncode(PASTEBIN_API_KEY) ..
                                "&api_option=paste" ..
                                "&api_paste_code=" .. urlEncode(chunkContent) ..
                                "&api_paste_name=" .. urlEncode(chunkName) ..
                                "&api_paste_format=lua" ..
                                "&api_paste_private=1" ..
                                "&api_paste_expire_date=1M"

                local response = request({
                    Url = PASTEBIN_API_URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/x-www-form-urlencoded"
                    },
                    Body = chunkBody
                })

                if response.Body and response.Body:find("pastebin.com") then
                    table.insert(chunks, response.Body)
                    print("✅ Chunk " .. i .. "/" .. totalChunks .. " uploaded: " .. response.Body)
                else
                    warn("❌ Failed to upload chunk " .. i)
                end

                -- Small delay between requests
                wait(1)
            end

            -- Return the first chunk URL with info about others
            if #chunks > 0 then
                local result = "Multiple pastes created:\n"
                for i, url in pairs(chunks) do
                    result = result .. "Part " .. i .. ": " .. url .. "\n"
                end
                return result
            else
                return "Failed to create any pastes"
            end
        else
            -- Single paste for smaller content
            local postBody = "api_dev_key=" .. urlEncode(PASTEBIN_API_KEY) ..
                            "&api_option=paste" ..
                            "&api_paste_code=" .. urlEncode(pasteContent) ..
                            "&api_paste_name=" .. urlEncode(pasteName) ..
                            "&api_paste_format=lua" ..
                            "&api_paste_private=1" ..
                            "&api_paste_expire_date=1M"

            local response = request({
                Url = PASTEBIN_API_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/x-www-form-urlencoded"
                },
                Body = postBody
            })

            return response.Body
        end
    end)

    if success then
        print("✅ Data successfully sent to Pastebin!")
        print("📋 Pastebin URL(s): " .. result)
        print("🔗 Copy the URL(s) and open in your browser to get the data")

        -- Create GUI to display URL on screen (for mobile users)
        createURLDisplay(result)

        return result
    else
        warn("❌ Failed to send data to Pastebin: " .. tostring(result))
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
    print("📤 Sending to Pastebin...")

    -- Send to Pastebin
    local pastebinUrl = sendToPastebin(allData)

    if pastebinUrl then
        print("🎉 SUCCESS! Your game data is now available at:")
        print("🔗 " .. pastebinUrl)
        print("📋 Copy this URL and open it in your browser to get all the data")
        print("💾 You can then copy the data and paste it into your base-data.txt file")
    else
        print("❌ Failed to send data to Pastebin. Check your API key and internet connection.")
    end
end

-- Check if API key is set
if PASTEBIN_API_KEY == "YOUR_PASTEBIN_API_KEY_HERE" then
    warn("⚠️  WARNING: Please set your Pastebin API key in the script!")
    warn("📝 Get your API key from: https://pastebin.com/doc_api")
    warn("🔧 Replace 'YOUR_PASTEBIN_API_KEY_HERE' with your actual API key")
    return
end

-- Start the scan
scanGame()
