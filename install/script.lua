-- Hook os.pullEventRaw and prevent it from being modified
local osPullEventRawOriginal = os.pullEventRaw
os.pullEventRaw = function(filter)
    local evt = { osPullEventRawOriginal(filter) }
    return table.unpack(evt)
end
setmetatable(os, {
    __newindex = function(_, key, val)
        if key == "pullEventRaw" then
            error("Modification of os.pullEventRaw is not allowed!")
        else
            rawset(_, key, val)
        end
    end
})

-- Set up the terminal and print the header
term.clear()
term.setCursorPos(1, 1)
print("=== [Task Forge] ===")

-- Function to download a file from GitHub or use the existing version if unchanged
local function downloadOrUseExisting(url, path, canBeCustomPc)
    local response = http.get(url)
    if response then
        local newContent = response.readAll()
        response.close()

        if fs.exists(path) then
            local file = fs.open(path, "r")
            if file then
                local existingContent = file.readAll()
                file.close()

                if existingContent == newContent then
                    print("[UP-TO-DATE] " .. path)
                    return false
                end
            end
        end

        local file = fs.open(path, "w")
        if file then
            file.write(newContent)
            file.close()
            print("[UPDATED] " .. path)
            return true
        else
            error("Failed to open file for writing: " .. path)
        end
    else
        if fs.exists(path) then
            if canBeCustomPc then
                print("[LOCAL] Using existing custom computer")
            else
                print("[LOCAL] Failed to download " .. url .. ", using existing file: " .. path)
            end
            return false
        else
            if canBeCustomPc then
                print("\n=== This will be your custom computer ===")
                print("=== Press Enter to create... ===")
                read()

                local file = fs.open(path, "w")
                if file then
                    file.close()
                    print("[CREATED] " .. path)
                    return true
                else
                    error("Failed to open file for writing: " .. path)
                end
            else
                error("[ERROR] Failed to download " .. url .. " and no existing file found: " .. path)
            end
        end
    end
end

-- Base URL for GitHub repository
local githubBase = "https://raw.githubusercontent.com/KaiDamu/cc-task-forge/refs/heads/main/"

-- File paths and URLs
local files = {
    { url = githubBase .. "install/script.lua", path = "startup.lua" },
    { url = githubBase .. "lib/tflib.lua",      path = "tflib.lua" },
    {}
}

-- Download required files or use existing ones
print("\n=== Updating Files ===")
if downloadOrUseExisting(files[1].url, files[1].path) then
    print("\n=== Boot sector updated! ===")
    print("=== Rebooting in 5 seconds... ===")
    sleep(5)
    os.reboot()
end
downloadOrUseExisting(files[2].url, files[2].path)

-- Load the main library into the global environment
assert(loadfile(files[2].path))()

-- Load the configuration and set the PC label from it
tf.cfg.load()
tf.pc.label = tf.cfg.dat["pc_label"]
tf.pc.labelSub = tf.cfg.dat["pc_label_sub"]
if not tf.pc.label or not tf.pc.labelSub then
    print("\n=== Enter a label for this computer: ===")
    local label = read()
    tf.cfg.dat["pc_label"] = label
    local labelSub = nil
    if label == "main" then
        labelSub = 1
    else
        print("\n=== Enter " .. label .. " instance number: ===")
        labelSub = tonumber(read()) or 1
    end
    tf.cfg.dat["pc_label_sub"] = labelSub
    tf.cfg.save()
    tf.pc.label = label
    tf.pc.labelSub = labelSub or 1
end

-- Determine which computer's code to run based on the label
files[3] = { url = githubBase .. "pc/" .. tf.pc.label .. ".lua", path = "pc.lua" }
downloadOrUseExisting(files[3].url, files[3].path, true)

-- Add the computer's code to the global environment
print("\n=== Running " .. tf.pc.label .. " ===")
assert(loadfile(files[3].path))()

-- Start the main event loop
tf.main.run()
