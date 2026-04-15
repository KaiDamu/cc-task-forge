---- ==== === ==== ----
---- ==== SYS ==== ----
---- ==== === ==== ----

function tf.at.sys.init()
    tf.periChat = tf.peri.objByType(tf.peri.type.CHAT_BOX)
    if not tf.periChat then
        return "A required Chat Box is not connected!"
    end
    return nil
end

function tf.at.sys.free()
    tf.periChat = nil
end

---- ==== === ==== ----
---- ==== CMD ==== ----
---- ==== === ==== ----

tf.info.cmd.dbg = {
    desc = "Toggle debug mode (more verbose logging)."
}
function tf.at.cmd.dbg()
    tf.cfg.dat["isDbg"] = not tf.cfg.dat["isDbg"]
    tf.cfg.save()
    tf.chat.send("Debug mode " .. (tf.cfg.dat["isDbg"] and "enabled" or "disabled"))
end

tf.info.cmd.reboot = {
    desc = "Reboot all connected computers (including this one)."
}
function tf.at.cmd.reboot()
    tf.net.send("reboot", {}, tf.net.BROADCAST_CH)
    tf.at.msg.reboot({})
end

tf.info.cmd.locate = {
    desc = "Locate this computer using GPS."
}
function tf.at.cmd.locate()
    tf.net.send("gps_pos_req", {}, tf.net.BROADCAST_CH)

    local posResList = tf.evt.waitForMsgs("gps_pos_res", 4, 3.0)
    if #posResList < 4 then
        tf.chat.send("Not enough position responses received for trilateration (need 4, got " .. #posResList .. ")")
        return
    end

    local points = {}
    local radii = {}
    for i = 1, 4 do
        points[i] = vector.new(posResList[i][3], posResList[i][4], posResList[i][5])
        radii[i] = posResList[i][2]
    end

    local pos = tf.math.trilaterate4(points[1], radii[1], points[2], radii[2], points[3], radii[3], points[4], radii[4])
    if pos then
        tf.chat.send("My position is: " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
    else
        tf.chat.send("Failed to trilaterate position - no solution found")
    end
end

tf.info.cmd.ping = {
    desc = "Ping all connected computers to see who's online."
}
function tf.at.cmd.ping()
    tf.net.send("ping", {}, tf.net.BROADCAST_CH)
    local pongs = tf.evt.waitForMsgs("pong", tf.math.HUGE, 1.5)
    tf.chat.send("Online devices: " .. (#pongs + 1))
end

tf.info.cmd.log = {
    params = {
        { name = "act", type = tf.type.STR, picks = { "save", "test" } }
    },
    desc = "Log (log.txt) management commands."
}
function tf.at.cmd.log(params)
    if params[1] == "save" then
        tf.log.save()
        tf.chat.send("Log saved")
    elseif params[1] == "test" then
        tf.log.write("This is a test log entry.")
        tf.chat.send("Test log entry created")
    else
        tf.chat.send("Unknown log command!")
    end
end

tf.info.cmd.perilabel = {
    params = {
        { name = "peri_label", type = tf.type.LABEL_EX },
        { name = "peri_name",  type = tf.type.STR,     picks = { "*", "clear" }, defa = "" }
    },
    desc = "Link a peripheral name to a computer's peripheral label (or clear it). Or get the linked peripheral name.",
    examples = { "perilabel chester:so me_bridge_3" }
}
function tf.at.cmd.perilabel(params)
    local pcLabel, pcLabelSub, periLabel = params[1][1], params[1][2], params[1][3]
    local periName = params[2]
    local netCh = tf.net.labelToCh(tf.pc.labelDatToM(pcLabel, pcLabelSub))
    tf.net.send("label_upd", { periLabel, periName }, netCh)
end

tf.info.cmd.posdef = {
    params = {
        { name = "pc", type = tf.type.LABEL_M },
        { name = "x",  type = tf.type.INT },
        { name = "y",  type = tf.type.INT },
        { name = "z",  type = tf.type.INT }
    },
    desc = "Define a computer's position in the world (for example, for GPS)."
}
function tf.at.cmd.posdef(params)
    local pcLabel, pcLabelSub = params[1][1], params[1][2]
    local posX, posY, posZ = params[2], params[3], params[4]
    local netCh = tf.net.labelToCh(tf.pc.labelDatToM(pcLabel, pcLabelSub))
    tf.net.send("pos_upd", { posX, posY, posZ }, netCh)
end

tf.info.cmd.so = {
    params = {
        { name = "filter", type = tf.type.STR, picks = { "*", "/damaged", "/enchanted" } },
        { name = "cnt",    type = tf.type.INT, defa = 1 }
    },
    desc = "Export items using the default storage output peripheral. Optionally filter and specify count.",
    examples = { "so diamond_sword 3" }
}
function tf.at.cmd.so(params)
    tf.net.send("so", { params[1], params[2] })
end

tf.info.cmd.undress = {
    params = {
        { name = "player", type = tf.type.STR }
    },
    desc = "Undress an unlucky player by taking all their armor.",
    examples = { "undress KaiDamu" }
}
function tf.at.cmd.undress(params)
    tf.net.send("undress", { params[1] })
end

tf.info.cmd.disenchant = {
    params = {
        { name = "cnt", type = tf.type.INT }
    },
    desc = "Export items with enchantments (together with books) to the disenchanting inventory."
}
function tf.at.cmd.disenchant(params)
    tf.net.send("disenchant", { params[1] })
end

tf.info.cmd.random = {
    params = {
        { name = "mode", type = tf.type.STR, picks = { "color" } },
        { name = "cnt",  type = tf.type.INT, defa = 1 }
    },
    desc = "Generate random data. Mode specifies what kind of data, with optional count parameter.",
    examples = { "random color 3" }
}
function tf.at.cmd.random(params)
    if params[1] == "color" then
        local cnt = params[2]
        local COLORS = {
            "black", "red", "green", "brown", "blue", "purple", "cyan", "light_gray", "gray", "pink", "lime", "yellow",
            "light_blue", "magenta", "orange", "white"
        }
        local result = "Random colors:"
        for i = 1, cnt do
            local color = COLORS[math.random(1, #COLORS)]
            result = result .. " " .. color
        end
        tf.chat.send(result)
    else
        tf.chat.send("Unknown mode!")
    end
end

tf.info.cmd.hello = {
    desc = "Just say hi to the sender."
}
function tf.at.cmd.hello(params, sender)
    tf.chat.send("Hi " .. sender .. "!")
end

tf.info.cmd.help = {
    params = {
        { name = "mode", type = tf.type.STR, picks = { "list", "cmd" } },
        { name = "name", type = tf.type.STR, defa = "" }
    },
    desc = "Get help: With 'list' mode, list all commands. With 'cmd' mode, get detailed info about a specific command."
}
function tf.at.cmd.help(params)
    if params[1] == "cmd" then
        tf.chat.send(tf.cmdHelpStr(params[2]))
    elseif params[1] == "list" then
        local cmdList = "Commands:"
        local sortedCmds = {}
        for cmdName, _ in pairs(tf.info.cmd) do
            table.insert(sortedCmds, cmdName)
        end
        table.sort(sortedCmds)
        for _, cmdName in ipairs(sortedCmds) do
            cmdList = cmdList .. " " .. cmdName
        end
        tf.chat.send(cmdList)
    else
        tf.chat.send("Unknown help mode!")
    end
end

---- ==== === ==== ----
---- ==== MSG ==== ----
---- ==== === ==== ----

function tf.at.msg.chat_send(dat, senderCh)
    tf.chat.sendAs(dat[1], tf.net.chToLabel(senderCh, true))
end

function tf.at.msg.con_send(dat, senderCh)
    print("<" .. tf.net.chToLabel(senderCh, true) .. "> " .. dat[1])
end

function tf.at.msg.pc_init(dat, senderCh)
    local labelM = tf.pc.labelDatToM(dat[1], dat[2])
    tf.net.labelToChCache[labelM] = senderCh
    tf.net.chToLabelCache[senderCh] = labelM
    tf.net.send("pc_accept", {}, senderCh)
end
