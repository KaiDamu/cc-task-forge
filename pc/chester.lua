function onEvt.msg.so(evtParams)
    local ME_BRIDGE_NAME = "so"
    local meBridge = tf.periObjByLabel(ME_BRIDGE_NAME)
    if not meBridge then
        tf.chatSend("ME Bridge with label '" .. ME_BRIDGE_NAME .. "' not found!")
        return
    end

    if evtParams[3] and evtParams[3]:sub(1, 1) == "/" then
        if evtParams[3] == "/damaged" then
            local itemsTab = meBridge.getItems()
            local allCnt = 0
            local outCnt = 0
            for key, val in pairs(itemsTab) do
                if val.components["minecraft:damage"] and val.components["minecraft:damage"] > 0 then
                    allCnt = allCnt + val.count
                    outCnt = outCnt + meBridge.exportItem(val, "front")
                end
            end
            if allCnt == 0 then
                tf.chatSend("No damaged items found")
            else
                tf.chatSend(outCnt .. " damaged items exported")
            end
        elseif evtParams[3] == "/enchanted" then
            local itemsTab = meBridge.getItems()
            local allCnt = 0
            local outCnt = 0
            for key, val in pairs(itemsTab) do
                if val.components["minecraft:enchantments"] then
                    allCnt = allCnt + val.count
                    outCnt = outCnt + meBridge.exportItem(val, "front")
                end
            end
            if allCnt == 0 then
                tf.chatSend("No enchanted items found")
            else
                tf.chatSend(outCnt .. " enchanted items exported")
            end
        end
    else
        local name_ = evtParams[3] or ""
        local cnt = tonumber(evtParams[4]) or 1
        local outCnt = meBridge.exportItem({ name = name_, count = cnt }, "front")
        if outCnt == cnt then
            tf.chatSend("All items exported")
        elseif outCnt == 0 then
            tf.chatSend("No items exported!")
        else
            tf.chatSend("Only " .. outCnt .. "/" .. cnt .. " items exported!")
        end
    end
end

function onEvt.msg.undress(evtParams)
    local player = evtParams[3] or "(nameless)"
    local invMgr = tf.periObjByType(tf.PERI_TYPE_INV_MGR, player)

    if invMgr then
        local wearCnt = 0
        local wearDat = invMgr.getArmor()
        for _, wearPiece in ipairs(wearDat) do
            if wearPiece.count ~= 0 then
                wearCnt = wearCnt + 1
            end
        end
        local removedCnt = 0
        for _, slot in ipairs(tf.SLOTS_ARMOR) do
            removedCnt = removedCnt + invMgr.removeItemFromPlayer("front", { fromSlot = slot, count = 1 })
        end
        if wearCnt == 0 then
            tf.chatSend(player .. " is already naked :D")
        elseif removedCnt ~= wearCnt then
            tf.chatSend("Failed to undress " .. player .. " -_-")
        else
            tf.chatSend("Stripped " .. player .. " :3")
        end
    else
        tf.chatSend("Unable to reach " .. player .. "!")
    end
end

function onEvt.msg.disenchant(evtParams)
    local ME_BRIDGE_NAME = "disenchant"
    local meBridge = tf.periObjByLabel(ME_BRIDGE_NAME)
    if not meBridge then
        tf.chatSend("ME Bridge with label '" .. ME_BRIDGE_NAME .. "' not found!")
        return
    end

    local reqCnt = tonumber(evtParams[3]) or 1
    local curCnt = 0
    local itemsTab = meBridge.getItems()

    tf.chatSend("Disenchant export started...")

    for key, val in pairs(itemsTab) do
        if val.components["minecraft:enchantments"] then
            if curCnt >= reqCnt then
                break
            end
            curCnt = curCnt + val.count
            meBridge.exportItem(val, "front")
            meBridge.exportItem({ name = "book", count = val.count * 3 }, "front")
        end
    end

    tf.chatSend("Disenchant export ended")
end

function onEvt.msg.label_upd(evtParams)
    local periLabel, periName = evtParams[3], evtParams[4]
    if not tf.cfg["labels"] then
        tf.cfg["labels"] = {}
    end
    tf.cfg["labels"][periLabel] = periName
    tf.cfgSave()
    tf.chatSend("Label '" .. periLabel .. "' set to '" .. (periName or "(cleared)") .. "'")
end
