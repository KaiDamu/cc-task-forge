function evtProc_sys_init(evtParams)
    tf.periChat = tf.periObjByType(tf.PERI_TYPE_CHAT_BOX)
    if not tf.periChat then
        return "A required Chat Box is not connected!"
    end
    return nil
end

function evtProc_sys_free(evtParams)
    tf.periChat = nil
end

function evtProc_cmd_dbg(evtParams)
    tf.cfg["isDbg"] = not tf.cfg["isDbg"]
    tf.cfgSave()
    tf.chatSend("Debug mode " .. (tf.cfg["isDbg"] and "enabled" or "disabled"))
end

function evtProc_cmd_reboot(evtParams)
    tf.nmsgSend("reboot", {}, tf.NET_CH_BROADCAST)
    evtProc_nmsg_reboot({})
end

function evtProc_cmd_locate(evtParams)
    tf.nmsgSend("gps_pos_req", {}, tf.NET_CH_BROADCAST)

    local posResList = tf.evtWaitForNmsgs("gps_pos_res", 4, 3.0)
    if #posResList < 4 then
        tf.chatSend("Not enough position responses received for trilateration (need 4, got " .. #posResList .. ")")
        return
    end

    local points = {}
    local radii = {}
    for i = 1, 4 do
        points[i] = vector.new(posResList[i][3], posResList[i][4], posResList[i][5])
        radii[i] = posResList[i][2]
    end

    local pos = tf.trilaterate4(points[1], radii[1], points[2], radii[2], points[3], radii[3], points[4], radii[4])
    if pos then
        tf.chatSend("My position is: " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
    else
        tf.chatSend("Failed to trilaterate position - no solution found")
    end
end

function evtProc_cmd_ping(evtParams)
    tf.nmsgSend("ping", {}, tf.NET_CH_BROADCAST)
    local pongs = tf.evtWaitForNmsgs("pong", tf.HUGE, 1.5)
    tf.chatSend("Online devices: " .. (#pongs + 1))
end

function evtProc_cmd_label(evtParams)
    if evtParams[2] == "set" then
        local pcLabel, pcLabelSub, periLabel = tf.labelExToLabelDat(evtParams[3])
        local periName = evtParams[4]
        if pcLabel and pcLabelSub and periLabel then
            local netCh = tf.pcLabelMToNetCh(tf.labelDatTolabelM(pcLabel, pcLabelSub))
            tf.nmsgSend("label_upd", { periLabel, periName }, netCh)
        else
            tf.chatSend("Usage: label set <pc_label:peri_label> [peri_name - omit to clear]")
        end
    end
end

function evtProc_cmd_pos(evtParams)
    if evtParams[2] == "set" then
        local pcLabel, pcLabelSub = tf.labelExToLabelDat(evtParams[3])
        local posX, posY, posZ = tonumber(evtParams[4]), tonumber(evtParams[5]), tonumber(evtParams[6])
        if pcLabel and pcLabelSub and posX and posY and posZ then
            local netCh = tf.pcLabelMToNetCh(tf.labelDatTolabelM(pcLabel, pcLabelSub))
            tf.nmsgSend("pos_upd", { posX, posY, posZ }, netCh)
        else
            tf.chatSend("Usage: pos set <pc_label> <x> <y> <z>")
        end
    end
end

function evtProc_cmd_so(evtParams)
    tf.nmsgSend("so", { evtParams[2], evtParams[3] })
end

function evtProc_cmd_undress(evtParams)
    tf.nmsgSend("undress", { evtParams[2] })
end

function evtProc_cmd_disenchant(evtParams)
    tf.nmsgSend("disenchant", { evtParams[2] })
end

function evtProc_cmd_random(evtParams)
    if evtParams[2] == "color" then
        local cnt = tonumber(evtParams[3]) or 1
        local COLORS = {
            "black", "red", "green", "brown", "blue", "purple", "cyan", "light_gray", "gray", "pink", "lime", "yellow",
            "light_blue", "magenta", "orange", "white"
        }
        local result = "Random colors:"
        for i = 1, cnt do
            local color = COLORS[math.random(1, #COLORS)]
            result = result .. " " .. color
        end
        tf.chatSend(result)
    end
end

function evtProc_cmd_hello(evtParams)
    tf.chatSend("Hi " .. evtParams[1] .. "!")
end

function evtProc_nmsg_chat_send(evtParams)
    tf.chatSendAs(evtParams[3], tf.pcNetChToLabelM(evtParams[1], true))
end

function evtProc_nmsg_con_send(evtParams)
    print("<" .. tf.pcNetChToLabelM(evtParams[1], true) .. "> " .. evtParams[3])
end

function evtProc_nmsg_pc_init(evtParams)
    local senderNetCh = evtParams[1]
    local labelM = tf.labelDatTolabelM(evtParams[3], evtParams[4])
    tf.pcLabelMToNetChTab[labelM] = senderNetCh
    tf.pcNetChToLabelMTab[senderNetCh] = labelM
    tf.nmsgSend("pc_accept", {}, senderNetCh)
end
