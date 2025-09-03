-- Game Data Scanner for Roblox
-- This script scans the entire game and sends all object paths to Pastebin
-- Place this as a ServerScript in ServerScriptService

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- PASTEBIN API CONFIGURATION
-- Get your API key from: https://pastebin.com/doc_api
local PASTEBIN_API_KEY = "6A7xLcFEjNECEk00xc7OzvA6tWxuinhr" -- Replace with your actual API key
local PASTEBIN_API_URL = "https://pastebin.com/api/api_post.php"

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

-- Function to send data to Pastebin
local function sendToPastebin(data)
    local success, result = pcall(function()
        local postData = {
            api_dev_key = PASTEBIN_API_KEY,
            api_option = "paste",
            api_paste_code = table.concat(data, "\n"),
            api_paste_name = "Roblox Game Data - " .. os.date("%Y-%m-%d %H:%M:%S"),
            api_paste_format = "lua",
            api_paste_private = "1", -- Unlisted paste
            api_paste_expire_date = "1M" -- Expires in 1 month
        }

        local response = HttpService:PostAsync(PASTEBIN_API_URL, HttpService:UrlEncode(postData))
        return response
    end)

    if success then
        print("✅ Data successfully sent to Pastebin!")
        print("📋 Pastebin URL: " .. result)
        print("🔗 Copy this URL and open it in your browser to get the data")
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
