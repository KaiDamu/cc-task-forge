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

    local posResList = tf.evt.waitForMsgs("gps_pos_res", 4, tf.time.WAIT_STD)
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
    tf.net.send("ping_req", {}, tf.net.BROADCAST_CH)
    local pingResList = tf.evt.waitForMsgs("ping_res", tf.math.HUGE, tf.time.WAIT_STD)
    local msg = "Online devices: " .. (#pingResList + 1) .. " - "
    local labels = { "Main" }
    for _, res in ipairs(pingResList) do
        local label = tf.net.chToLabel(res[1], true)
        table.insert(labels, label)
    end
    table.sort(labels)
    msg = msg .. table.concat(labels, ", ")
    tf.chat.send(msg)
end

tf.info.cmd.log = {
    args = {
        { name = "act", type = tf.type.STR, picks = { "save", "test" } }
    },
    desc = "Log (log.txt) management commands."
}
function tf.at.cmd.log(args)
    if args[1] == "save" then
        tf.log.save()
        tf.chat.send("Log saved")
    elseif args[1] == "test" then
        tf.log.write("This is a test log entry.")
        tf.chat.send("Test log entry created")
    end
end

tf.info.cmd.perilabel = {
    args = {
        { name = "peri_label", type = tf.type.LABEL_EX },
        { name = "peri_name",  type = tf.type.STR,     picks = { "*", "clear" }, defa = "" }
    },
    desc = "Link a peripheral name to a computer's peripheral label (or clear it). Or get the linked peripheral name.",
    examples = { "perilabel chester:so me_bridge_3" }
}
function tf.at.cmd.perilabel(args)
    local pcLabel, pcLabelSub, periLabel = args[1][1], args[1][2], args[1][3]
    local periName = args[2]
    local netCh = tf.net.labelToCh(tf.pc.labelDatToM(pcLabel, pcLabelSub))
    tf.net.send("cfg_peri_label", { periLabel, periName }, netCh)
end

tf.info.cmd.posdef = {
    args = {
        { name = "pc", type = tf.type.LABEL_M },
        { name = "x",  type = tf.type.INT },
        { name = "y",  type = tf.type.INT },
        { name = "z",  type = tf.type.INT }
    },
    desc = "Define a computer's position in the world (for example, for GPS)."
}
function tf.at.cmd.posdef(args)
    local pcLabel, pcLabelSub = args[1][1], args[1][2]
    local posX, posY, posZ = args[2], args[3], args[4]
    local netCh = tf.net.labelToCh(tf.pc.labelDatToM(pcLabel, pcLabelSub))
    tf.net.send("cfg_pos", { posX, posY, posZ }, netCh)
end

tf.info.cmd.random = {
    args = {
        { name = "mode", type = tf.type.STR, picks = { "color" } },
        { name = "cnt",  type = tf.type.INT, defa = 1 }
    },
    desc = "Generate random data. Mode specifies what kind of data, with optional count parameter.",
    examples = { "random color 3" }
}
function tf.at.cmd.random(args)
    if args[1] == "color" then
        local cnt = args[2]
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
    end
end

tf.info.cmd.help = {
    args = {
        { name = "mode", type = tf.type.STR, picks = { "list", "for", "topic" } },
        { name = "name", type = tf.type.STR, defa = "" }
    },
    desc =
    "Get info: List all commands & topics with 'list'. Get detailed command info with 'for <command>'. Get topic info with 'topic <name>'."
}
function tf.at.cmd.help(args)
    if args[1] == "for" then
        tf.chat.send(tf.cmdHelpStr(args[2]))
    elseif args[1] == "topic" then
        tf.chat.send("Topics are coming soon!")
    elseif args[1] == "list" then
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
    end
end

---- ==== === ==== ----
---- ==== MSG ==== ----
---- ==== === ==== ----

function tf.at.msg.pc_connect_req(dat, senderCh)
    local labelM = tf.pc.labelDatToM(dat[1], dat[2])
    tf.net.labelToChCache[labelM] = senderCh
    tf.net.chToLabelCache[senderCh] = labelM
    tf.net.send("pc_connect_res", {}, senderCh)
end

function tf.at.msg.chat_send(dat, senderCh)
    tf.chat.sendAs(dat[1], tf.net.chToLabel(senderCh, true))
end

function tf.at.msg.con_send(dat, senderCh)
    print("<" .. tf.net.chToLabel(senderCh, true) .. "> " .. dat[1])
end

function tf.at.msg.cmds_register(dat, senderCh)
    for cmdName, cmdDef in pairs(dat[1]) do
        if tf.info.cmd[cmdName] then
            if table.isSame(tf.info.cmd[cmdName].args, cmdDef.args) and table.isSame(tf.info.cmd[cmdName].desc, cmdDef.desc) then
                local isChIncluded = false
                for _, ch in ipairs(tf.info.cmd[cmdName].senderChs) do
                    if ch == senderCh then
                        isChIncluded = true
                        break
                    end
                end
                if not isChIncluded then
                    table.insert(tf.info.cmd[cmdName].senderChs, senderCh)
                end
            else
                tf.chat.send("'" ..
                    tf.net.chToLabel(senderCh, true) ..
                    "' tried to redefine existing command '" .. cmdName .. "'! Ignoring this new definition...")
            end
        else
            tf.info.cmd[cmdName] = cmdDef
            tf.info.cmd[cmdName].senderChs = { senderCh }
            tf.at.cmd[cmdName] = function(args, sender, cmdName)
                local chReqList = {}
                if tf.info.cmd[cmdName].dstArgI then
                    local dstArg = args[tf.info.cmd[cmdName].dstArgI]
                    local ch = tf.net.labelToCh(tf.pc.labelDatToM(dstArg[1], dstArg[2]))
                    if table.contains(tf.info.cmd[cmdName].senderChs, ch) then
                        tf.net.send("cmd_run_req", { args, sender, cmdName }, ch)
                        table.insert(chReqList, ch)
                    else
                        tf.chat.send("Invalid destination set for command '" .. cmdName .. "'!")
                        return
                    end
                else
                    for _, ch in ipairs(tf.info.cmd[cmdName].senderChs) do
                        tf.net.send("cmd_run_req", { args, sender, cmdName }, ch)
                        table.insert(chReqList, ch)
                    end
                end

                local cmdRunRes = tf.evt.waitForMsgs("cmd_run_res", #chReqList, tf.time.WAIT_STD)
                if #cmdRunRes ~= #chReqList then
                    local chDelList = {}
                    for _, chReq in ipairs(chReqList) do
                        local isChIncluded = false
                        for _, res in ipairs(cmdRunRes) do
                            if res[1] == chReq then
                                isChIncluded = true
                                break
                            end
                        end
                        if not isChIncluded then
                            table.insert(chDelList, chReq)
                        end
                    end

                    for _, chDel in ipairs(chDelList) do
                        for i = #tf.info.cmd[cmdName].senderChs, 1, -1 do
                            if tf.info.cmd[cmdName].senderChs[i] == chDel then
                                table.remove(tf.info.cmd[cmdName].senderChs, i)
                                break
                            end
                        end
                    end

                    if #tf.info.cmd[cmdName].senderChs == 0 then
                        tf.info.cmd[cmdName] = nil
                        tf.at.cmd[cmdName] = nil
                        tf.chat.send("Command '" .. cmdName .. "' is no longer available!")
                    else
                        if #cmdRunRes > 0 then
                            tf.chat.send("Command '" .. cmdName .. "' was ran by less computers than expected!")
                        else
                            tf.chat.send("Command '" .. cmdName .. "' was not ran by the destination computer!")
                        end
                    end
                end
            end
        end
    end
end
