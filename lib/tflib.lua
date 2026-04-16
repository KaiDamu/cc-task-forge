tf = tf or {}

tf.info = {
    cmd = {}
}

tf.at = {
    sys = {},
    cmd = {},
    msg = {
        pc_label_req = function(dat, senderCh)
            if dat[1] then
                if dat[2] ~= tf.pc.label or dat[3] ~= tf.pc.labelSub then
                    return
                end
            end
            tf.net.send("pc_label_res", { tf.pc.label, tf.pc.labelSub }, senderCh)
        end,
        ping_req = function(dat, senderCh)
            tf.net.send("ping_res", {}, senderCh)
        end,
        cmd_run = function(dat)
            tf.at.cmd[dat[1]](dat[2], dat[3])
        end,
        reboot = function()
            os.reboot()
        end
    }
}

tf.queue = {
    new = function()
        return { first = 1, last = 0 }
    end,
    add = function(queue, val)
        queue.last = queue.last + 1
        queue[queue.last] = val
    end,
    get = function(queue)
        if queue.first > queue.last then
            return nil
        end
        local val = queue[queue.first]
        queue[queue.first] = nil
        queue.first = queue.first + 1
        return val
    end
}

tf.type = {
    INT = 1,
    FLOAT = 2,
    STR = 3,
    LABEL_M = 4,
    LABEL_EX = 5
}
tf.type.toStr = {
    [tf.type.INT] = "int",
    [tf.type.FLOAT] = "float",
    [tf.type.STR] = "str",
    [tf.type.LABEL_M] = "label_m",
    [tf.type.LABEL_EX] = "label_ex"
}

function tf.type.castStrict(val, type_)
    if type_ == tf.type.INT then
        local num = tonumber(val)
        if num and math.floor(num) == num then
            return num
        else
            return nil
        end
    elseif type_ == tf.type.FLOAT then
        return tonumber(val)
    elseif type_ == tf.type.STR then
        return tostring(val)
    elseif type_ == tf.type.LABEL_M then
        local label, labelSub, labelObj = tf.pc.labelExToDat(tostring(val))
        if label and labelSub and not labelObj then
            return { label, labelSub }
        else
            return nil
        end
    elseif type_ == tf.type.LABEL_EX then
        local label, labelSub, labelObj = tf.pc.labelExToDat(tostring(val))
        if label and labelSub and labelObj then
            return { label, labelSub, labelObj }
        else
            return nil
        end
    else
        return nil
    end
end

tf.sides = {
    ABS = { "top", "bottom", "north", "south", "west", "east" },
    REL = { "top", "bottom", "front", "back", "left", "right" }
}

tf.slot = {
    BOOTS = 100,
    LEGGINGS = 101,
    CHESTPLATE = 102,
    HELMET = 103,
    OFFHAND = 40
}

tf.slots = {
    ARMOR = { tf.slot.BOOTS, tf.slot.LEGGINGS, tf.slot.CHESTPLATE, tf.slot.HELMET }
}

tf.peri = {
    type = {
        MODEM_WIRED = "!modem_wired",
        MODEM_WIRELESS = "!modem_wireless",
        CHAT_BOX = "chat_box",
        ME_BRIDGE = "me_bridge",
        PLAYER_DET = "player_detector",
        INV_MGR = "inventory_manager",
        SPEAKER = "speaker"
    }
}

function tf.peri.type.get(nameOrObj)
    if not nameOrObj then
        return nil
    end
    local type_ = peripheral.getType(nameOrObj)
    if type_ == "modem" then
        if peripheral.call(nameOrObj, "isWireless") then
            type_ = tf.peri.type.MODEM_WIRELESS
        else
            type_ = tf.peri.type.MODEM_WIRED
        end
    end
    return type_
end

function tf.peri.namesByType(type_)
    local ret = {}
    local names = peripheral.getNames()
    for i = 1, #names do
        if tf.peri.type.get(names[i]) == type_ then
            table.insert(ret, names[i])
        end
    end
    return ret
end

function tf.peri.objByName(name)
    if name then
        return peripheral.wrap(name)
    else
        return nil
    end
end

function tf.peri.objByType(type_, which)
    local names = tf.peri.namesByType(type_)
    if #names == 0 then
        return nil
    end
    if which then
        if type_ == tf.peri.type.INV_MGR then
            for i = 1, #names do
                if peripheral.call(names[i], "getOwner") == which then
                    return tf.peri.objByName(names[i])
                end
            end
            return nil
        end
    end
    return tf.peri.objByName(names[1])
end

function tf.peri.objByLabel(label)
    if not tf.cfg.dat["peri_labels"] then
        tf.cfg.dat["peri_labels"] = {}
        tf.cfg.save()
    end
    return tf.peri.objByName(tf.cfg.dat["peri_labels"][label])
end

function tf.peri.objFind(label, type_, which, name)
    local peri = nil
    if label then
        peri = tf.peri.objByLabel(label)
        if peri and (not type_ or tf.peri.type.get(peri) == type_) then
            return peri
        end
    end
    if name then
        peri = tf.peri.objByName(name)
        if peri then
            return peri
        end
    end
    if type_ then
        peri = tf.peri.objByType(type_, which)
        if peri then
            return peri
        end
    end
    return nil
end

tf.chat = {
    CMD_PRE = ".",
    SEND_CD = 0.25,
    lastSendTime = 0.0
}

function tf.chat.sendAs(msg, sender, range)
    if not tf.periChat then
        if tf.pc.netCh == tf.net.mainCh or sender ~= tf.pc.name or range then
            error("Chat not initialized")
        else
            tf.net.send("chat_send", { msg }, tf.net.mainCh)
            return
        end
    end
    sender = sender or "UNKNOWN"
    if tf.time.game() - tf.chat.lastSendTime < tf.chat.SEND_CD then
        sleep(tf.chat.SEND_CD - (tf.time.game() - tf.chat.lastSendTime))
    end
    while not tf.periChat.sendMessage(msg, sender, "<>", nil, range) do
        sleep(0.05)
    end
    tf.chat.lastSendTime = tf.time.game()
end

function tf.chat.send(msg, range)
    tf.chat.sendAs(msg, tf.pc.name, range)
end

tf.net = {
    BROADCAST_CH = 15305,
    MSG_HDR = 47619,
    peri = nil,
    mainCh = nil,
    labelToChCache = {},
    chToLabelCache = {}
}

function tf.net.labelToCh(pcLabelM)
    local pcNetCh = tf.net.labelToChCache[pcLabelM]
    if not pcNetCh then
        local label, labelSub = tf.pc.labelMToDat(pcLabelM)
        tf.net.send("pc_label_req", { true, label, labelSub }, tf.net.BROADCAST_CH)
        local pcLabelRes = tf.evt.waitForMsgs("pc_label_res")[1]
        local senderNetCh = pcLabelRes[1]
        local senderLabel, senderLabelSub = pcLabelRes[3], pcLabelRes[4]
        if senderLabel == label and senderLabelSub == labelSub then
            pcNetCh = senderNetCh
            tf.net.labelToChCache[pcLabelM] = pcNetCh
            tf.net.chToLabelCache[pcNetCh] = pcLabelM
        end
    end
    return pcNetCh
end

function tf.net.chToLabel(pcNetCh, doFancy)
    local pcLabelM = tf.net.chToLabelCache[pcNetCh]
    if not pcLabelM then
        tf.net.send("pc_label_req", { false }, pcNetCh)
        local pcLabelRes = tf.evt.waitForMsgs("pc_label_res")[1]
        local senderNetCh = pcLabelRes[1]
        if senderNetCh == pcNetCh then
            pcLabelM = tf.pc.labelDatToM(pcLabelRes[3], pcLabelRes[4])
            tf.net.labelToChCache[pcLabelM] = pcNetCh
            tf.net.chToLabelCache[pcNetCh] = pcLabelM
        end
    end
    if doFancy and pcLabelM then
        local label, labelSub = tf.pc.labelMToDat(pcLabelM)
        pcLabelM = tf.str.toTitle(label)
        if labelSub > 1 then
            pcLabelM = pcLabelM .. ":" .. tostring(labelSub)
        end
    end
    return pcLabelM
end

function tf.net.send(msgName, msgDat, ch)
    if not tf.net.peri then
        error("Network not initialized")
    end
    msgDat = msgDat or {}
    ch = ch or tf.net.BROADCAST_CH
    tf.net.peri.transmit(ch, tf.pc.netCh, { tf.net.MSG_HDR, msgName, msgDat })
    tf.dbg.print("Nmsg sent: " .. msgName .. " to ch " .. tostring(ch))
end

tf.db = {
    save = function(db, name)
        local file = fs.open(name .. ".txt", "w")
        if file then
            file.write(textutils.serialize(db))
            file.close()
        else
            error("Failed to open file for writing: " .. name .. ".txt")
        end
    end,
    load = function(name)
        local file = fs.open(name .. ".txt", "r")
        if file then
            local db = textutils.unserialize(file.readAll())
            file.close()
            return db
        else
            return {} -- Return empty table if file doesn't exist
        end
    end
}

tf.cfg = {
    dat = nil,
    save = function()
        tf.db.save(tf.cfg.dat, "cfg")
    end,
    load = function()
        tf.cfg.dat = tf.db.load("cfg")
    end
}

tf.log = {
    file = nil,
    save = function()
        if tf.log.file then
            tf.log.file.flush()
        end
    end,
    load = function()
        if not tf.log.file then
            tf.log.file = fs.open("log.txt", "a")
            if not tf.log.file then
                error("Failed to open log.txt")
            end
        end
    end,
    write = function(msg)
        tf.log.load()
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        tf.log.file.writeLine("[" .. timestamp .. "] " .. msg)
    end
}

tf.pc = {
    id = os.getComputerID(),
    label = nil,
    labelSub = nil,
    name = "PC",
    netCh = tf.net.BROADCAST_CH + os.getComputerID() + 1
}

function tf.pc.labelDatToM(label, labelSub)
    return label .. ":" .. tostring(labelSub)
end

function tf.pc.labelMToDat(labelM)
    local parts = tf.str.split(labelM, ":")
    if #parts ~= 2 then
        return nil, nil
    end
    local label = parts[1]
    local labelSub = tonumber(parts[2])
    return label, labelSub
end

function tf.pc.labelExToDat(labelEx)
    local parts = tf.str.split(labelEx, ":")
    local label, labelSub, labelObj = nil, 1, nil
    if #parts > 0 and #parts < 4 then
        label = parts[1]
        if #parts == 2 then
            local num = tonumber(parts[2])
            if num then
                labelSub = num
            else
                labelObj = parts[2]
            end
        elseif #parts == 3 then
            labelSub = tonumber(parts[2]) or 1
            labelObj = parts[3]
        end
    end
    return label, labelSub, labelObj
end

tf.evt = {
    prioQueue = tf.queue.new()
}

function tf.evt._wait(doSkipQueue)
    if not doSkipQueue then
        local queuedEvt = tf.queue.get(tf.evt.prioQueue)
        if queuedEvt then
            return queuedEvt
        end
    end
    if not tf.net.peri then
        error("Network not initialized")
    end
    while true do
        local evtDat = { os.pullEvent() }
        if evtDat[1] == "chat" and evtDat[3]:sub(1, #tf.chat.CMD_PRE) == tf.chat.CMD_PRE and #evtDat[3] > #tf.chat.CMD_PRE then
            local args = tf.list.byArgs(evtDat[3]:sub(#tf.chat.CMD_PRE + 1))
            return { "cmd", args[1], { evtDat[2], table.unpack(args, 2) } }                           -- {"cmd", cmd, {sender, cmdArgs...}}
        elseif evtDat[1] == "modem_message" and evtDat[5][1] == tf.net.MSG_HDR then
            return { "msg", evtDat[5][2], { evtDat[4], evtDat[6] or 0, table.unpack(evtDat[5][3]) } } -- {"msg", msg, {senderNetCh, dist, msgDat...}}
        elseif evtDat[1] == "timer" then
            return { "timer", evtDat[2] }                                                             -- {"timer", timerId}
        end
        tf.dbg.print("Event ignored: " .. evtDat[1])
    end
end

function tf.evt.wait(doSkipQueue)
    local evt = tf.evt._wait(doSkipQueue)
    tf.dbg.print("Event received: " .. evt[1] .. " " .. evt[2])
    return evt
end

function tf.evt.waitForMsgs(msgName, cntMax, timeout)
    cntMax = cntMax or 1
    timeout = timeout or tf.math.HUGE
    local collectedMsgs = {}
    local timerId = os.startTimer(timeout)

    while #collectedMsgs < cntMax do
        local evt = tf.evt.wait(true) -- Skip queue to prioritize new events

        local isAdded = false
        if evt[1] == "msg" then
            local msgName_, msgParams = evt[2], evt[3]
            if msgName_ == msgName then
                table.insert(collectedMsgs, msgParams)
                isAdded = true
            end
        elseif evt[1] == "timer" and evt[2] == timerId then
            break -- Timeout reached
        end

        if not isAdded then
            tf.queue.add(tf.evt.prioQueue, evt) -- Queue non-matching events for later retrieval
        end
    end

    return collectedMsgs
end

tf.con = {
    col = term.getTextColor()
}

function tf.con.writeCol(msg, col)
    if col ~= tf.con.col then
        term.setTextColor(col)
    end
    print(msg)
    if col ~= tf.con.col then
        term.setTextColor(tf.con.col)
    end
end

tf.dbg = {
    print = function(msg)
        if tf.cfg.dat["isDbg"] then
            print("[DBG] " .. msg)
        end
    end,
    chat = function(msg)
        if tf.cfg.dat["isDbg"] then
            tf.chat.send("[DBG] " .. msg)
        end
    end
}

tf.math = {
    HUGE = 2147483647
}

function tf.math.trilaterate4(p1, r1, p2, r2, p3, r3, p4, r4)
    local function trilaterate3(p1_, r1_, p2_, r2_, p3_, r3_)
        local ex = (p2_ - p1_):normalize()
        local i = ex:dot(p3_ - p1_)
        local tmp = (p3_ - p1_) - ex * i
        local ey = tmp:normalize()
        local ez = ex:cross(ey)
        local d = (p2_ - p1_):length()
        local j = ey:dot(p3_ - p1_)
        local x = (r1_ ^ 2 - r2_ ^ 2 + d ^ 2) / (2 * d)
        local y = (r1_ ^ 2 - r3_ ^ 2 + i ^ 2 + j ^ 2 - 2 * i * x) / (2 * j)
        local z2 = r1_ ^ 2 - x ^ 2 - y ^ 2
        if z2 < 0 then
            return nil, nil
        end
        local z = math.sqrt(z2)
        local res1 = p1_ + ex * x + ey * y + ez * z
        local res2 = p1_ + ex * x + ey * y - ez * z
        return res1, res2
    end

    local res1, res2 = trilaterate3(p1, r1, p2, r2, p3, r3)
    if not res1 then
        return nil
    end

    local function err(p)
        return math.abs((p - p4):length() ^ 2 - r4 ^ 2)
    end
    if err(res1) < err(res2) then
        return res1
    else
        return res2
    end
end

tf.time = {
    WAIT_STD = 1.5,
    WAIT_BROADCAST = 5.0
}

function tf.time.game()
    return os.epoch("ingame") / 1000.0
end

tf.main = {}

function tf.main.init(label, labelSub)
    tf.net.peri = tf.peri.objByType(tf.peri.type.MODEM_WIRELESS)
    if not tf.net.peri then
        tf.con.writeCol("Connect an Ender Modem...", colors.red)
        while not tf.net.peri do
            sleep(1.0)
            tf.net.peri = tf.peri.objByType(tf.peri.type.MODEM_WIRELESS)
        end
    end
    tf.net.peri.open(tf.net.BROADCAST_CH)
    tf.net.peri.open(tf.pc.netCh)

    local name = tf.str.toTitle(label)
    tf.pc.label = label
    tf.pc.labelSub = labelSub or 1
    tf.pc.name = name

    -- Calculate required argument counts for commands based on their definitions
    for evtName, evtDef in pairs(tf.info.cmd) do
        local argReqCnt_ = 0
        if evtDef.args then
            for _, arg in ipairs(evtDef.args) do
                if not arg.defa then
                    argReqCnt_ = argReqCnt_ + 1
                end
            end
        end
        tf.info.cmd[evtName].argReqCnt = argReqCnt_
    end

    tf.net.send("pc_init", { tf.pc.label, tf.pc.labelSub }, tf.net.BROADCAST_CH)
    if tf.pc.label == "main" then
        tf.net.mainCh = tf.pc.netCh
    else
        local pcAccept = tf.evt.waitForMsgs("pc_accept", 1, tf.time.WAIT_STD)[1]
        if not pcAccept then
            print("Waiting for main to accept connection...")
        end
        while not pcAccept do
            tf.net.send("pc_init", { tf.pc.label, tf.pc.labelSub }, tf.net.BROADCAST_CH)
            pcAccept = tf.evt.waitForMsgs("pc_accept", 1, tf.time.WAIT_BROADCAST)[1]
        end
        tf.net.mainCh = pcAccept[1]
        tf.net.send("cmds_register", { tf.info.cmd }, tf.net.mainCh)
    end

    tf.con.writeCol(tf.str.toTitle(tf.pc.labelDatToM(tf.pc.label, tf.pc.labelSub)) .. " online!", colors.green)

    if tf.at.sys.init then
        local sysInitResult = tf.at.sys.init({})
        if sysInitResult then
            return sysInitResult
        end
    end

    return nil
end

function tf.main.free()
    if tf.at.sys.free then
        tf.at.sys.free({})
    end
    tf.net.peri.close(tf.pc.netCh)
    tf.net.peri.close(tf.net.BROADCAST_CH)
    tf.net.peri = nil
end

function tf.main.evtProc(evt)
    local evtType, evtName, evtParams = evt[1], evt[2], evt[3]
    local evtFnTab = tf.at[evtType]
    if not evtFnTab then
        return
    end
    local evtFn = tf.if_(type(evtFnTab[evtName]) == "function", evtFnTab[evtName], nil)
    if evtType == "cmd" then
        local cmdDef = tf.info.cmd[evtName]

        if evtFn then
            if cmdDef then
            else
                tf.chat.send("Command '" ..
                    evtName .. "' is not defined yet! Define tf.info.cmd." .. evtName .. " = {...}")
                return
            end
        else
            if cmdDef then
                tf.chat.send("Command '" ..
                    evtName .. "' is not implemented yet! Define function tf.at.cmd." .. evtName .. "(...)")
            else
                tf.chat.send("Unknown command '" .. evtName .. "'! Use command 'help' for more info")
            end
            return
        end

        if (#evtParams - 1) >= cmdDef.argReqCnt then
            local args = { table.unpack(evtParams, 2) }
            local sender = evtParams[1]

            local isArgErr = false
            for i, argDef in ipairs(cmdDef.args or {}) do
                args[i] = tf.type.castStrict(args[i] or argDef.defa, argDef.type)
                if not args[i] then
                    isArgErr = true
                elseif argDef.picks and not table.contains(argDef.picks, args[i]) and not table.contains(argDef.picks, "*") then
                    isArgErr = true
                end
                if isArgErr then
                    tf.chat.send("Parameter named '" .. argDef.name .. "' is invalid!")
                    break
                end
            end

            if isArgErr then
                tf.chat.send(tf.cmdHelpStr(evtName))
            else
                evtFn(args, sender, evtName)
            end
        else
            tf.chat.send(tf.cmdHelpStr(evtName))
        end
    elseif evtType == "msg" then
        if evtFn then
            local senderCh, dist = evtParams[1], evtParams[2]
            local dat = { table.unpack(evtParams, 3) }
            evtFn(dat, senderCh, dist)
        end
    else
        if evtFn then
            evtFn(evtParams)
        end
    end
end

function tf.main.run()
    local initErr = tf.main.init(tf.pc.label, tf.pc.labelSub)
    if initErr then
        error(initErr)
    end

    while true do
        local evt = tf.evt.wait()
        tf.main.evtProc(evt)
    end

    tf.main.free()
end

tf.str = {}

function tf.str.byArr(arr)
    local ret = "{"
    for i = 1, #arr do
        if i > 1 then
            ret = ret .. ", "
        end
        ret = ret .. tostring(arr[i])
    end
    return ret .. "}"
end

function tf.str.byTab(tab, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    local lines = {}
    for key, val in pairs(tab) do
        if type(val) == "table" then
            table.insert(lines, indentStr .. tostring(key) .. ":")
            table.insert(lines, tf.str.byTab(val, indent + 1))
        else
            table.insert(lines, indentStr .. tostring(key) .. ": " .. tostring(val))
        end
    end
    return table.concat(lines, "\n")
end

function tf.str.split(str, c)
    if not str then
        return {}
    end
    local result = {}
    for part in str:gmatch("[^" .. c .. "]+") do
        table.insert(result, part)
    end
    return result
end

function tf.str.toTitle(str)
    return str:gsub("_", " "):gsub("(%a)(%a*)", function(first, rest) return first:upper() .. rest:lower() end)
end

function tf.str.toSnake(str)
    return str:gsub("%s+", "_"):lower()
end

tf.list = {}

function tf.list.fnNames(obj)
    local ret = {}
    if type(obj) == "table" then
        for key, val in pairs(obj) do
            if type(val) == "function" then
                table.insert(ret, key)
            end
        end
    end
    return ret
end

function tf.list.byArgs(argsStr)
    local args = {}
    for arg in argsStr:gmatch("%S+") do
        table.insert(args, arg)
    end
    return args
end

function tf.if_(cond, trueVal, falseVal)
    if cond then
        return trueVal
    else
        return falseVal
    end
end

function tf.booln(val)
    if val then
        return 1
    else
        return 0
    end
end

function tf.len(obj)
    local len = #obj or 0
    if len == 0 then
        for _ in pairs(obj) do
            len = len + 1
        end
    end
    return len
end

function tf.cmdHelpStr(cmdName)
    if not tf.info.cmd[cmdName] then
        return "No help available for unknown command '" .. cmdName .. "'!"
    end
    local infoMsg = "Usage: " .. cmdName
    if tf.info.cmd[cmdName].args then
        for _, arg in ipairs(tf.info.cmd[cmdName].args) do
            local enclose = { " <", ">" }
            if arg.defa then
                enclose = { " [", "]" }
            end
            infoMsg = infoMsg .. enclose[1] .. arg.name .. ": " .. tf.type.toStr[arg.type]
            if arg.picks then
                infoMsg = infoMsg .. " (" .. table.concat(arg.picks, " | ") .. ")"
            end
            if arg.defa and arg.defa ~= "" then
                infoMsg = infoMsg .. " =" .. tostring(arg.defa)
            end
            infoMsg = infoMsg .. enclose[2]
        end
    end
    if tf.info.cmd[cmdName].desc then
        infoMsg = infoMsg .. " - " .. tf.info.cmd[cmdName].desc
    end
    if tf.info.cmd[cmdName].examples and #tf.info.cmd[cmdName].examples > 0 then
        infoMsg = infoMsg .. " - Example: " .. tf.info.cmd[cmdName].examples[1]
    end
    return infoMsg
end

table.contains = table.contains or function(tab, val)
    for _, val_ in pairs(tab) do
        if val_ == val then
            return true
        end
    end
    return false
end
