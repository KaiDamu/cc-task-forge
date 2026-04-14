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

-- Load the tflib library and set it as a global variable
_G.tf = assert(loadfile(files[2].path))()

-- Load the configuration and set the PC label from it
tf.cfgLoad()
tf.pcLabelSet(tf.cfg["pc_label"], tf.cfg["pc_label_sub"])
if not tf.pcLabel or not tf.pcLabelSub then
    print("\n=== Enter a label for this computer: ===")
    local label = read()
    tf.cfg["pc_label"] = label
    local labelSub = nil
    if label == "main" then
        labelSub = 1
    else
        print("\n=== Enter " .. label .. " instance number: ===")
        labelSub = tonumber(read()) or 1
    end
    tf.cfg["pc_label_sub"] = labelSub
    tf.cfgSave()
    tf.pcLabelSet(label, labelSub)
end

-- Determine which computer's code to run based on the label
files[3] = { url = githubBase .. "pc/" .. tf.pcLabel .. ".lua", path = "pc.lua" }
downloadOrUseExisting(files[3].url, files[3].path, true)

-- Add the computer's code to the global environment
print("\n=== Running " .. tf.pcLabel .. " ===")
assert(loadfile(files[3].path))()

-- Main event loop
local function main()
    local initErr = tf.init(tf.pcLabel, tf.pcLabelSub)
    if initErr then
        error(initErr)
    end

    while true do
        local evt = tf.evtWait()
        local evtFn = "evtProc_" .. evt[1] .. "_" .. evt[2]
        if type(_G[evtFn]) == "function" then
            _G[evtFn](evt[3])
        end
    end

    tf.free()
end

-- Start the main event loop
main()
