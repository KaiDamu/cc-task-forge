function tf.at.msg.so(dat)
    local ME_BRIDGE_NAME = "so"
    local meBridge = tf.peri.objByLabel(ME_BRIDGE_NAME)
    if not meBridge then
        tf.chat.send("ME Bridge with label '" .. ME_BRIDGE_NAME .. "' not found!")
        return
    end

    if dat[1] and dat[1]:sub(1, 1) == "/" then
        if dat[1] == "/damaged" then
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
                tf.chat.send("No damaged items found")
            else
                tf.chat.send(outCnt .. " damaged items exported")
            end
        elseif dat[1] == "/enchanted" then
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
                tf.chat.send("No enchanted items found")
            else
                tf.chat.send(outCnt .. " enchanted items exported")
            end
        end
    else
        local name_ = dat[1] or ""
        local cnt = tonumber(dat[2]) or 1
        local outCnt = meBridge.exportItem({ name = name_, count = cnt }, "front")
        if outCnt == cnt then
            tf.chat.send("All items exported")
        elseif outCnt == 0 then
            tf.chat.send("No items exported!")
        else
            tf.chat.send("Only " .. outCnt .. "/" .. cnt .. " items exported!")
        end
    end
end

function tf.at.msg.undress(dat)
    local player = dat[1] or "(nameless)"
    local invMgr = tf.peri.objByType(tf.peri.type.INV_MGR, player)

    if invMgr then
        local wearCnt = 0
        local wearDat = invMgr.getArmor()
        for _, wearPiece in ipairs(wearDat) do
            if wearPiece.count ~= 0 then
                wearCnt = wearCnt + 1
            end
        end
        local removedCnt = 0
        for _, slot in ipairs(tf.slots.ARMOR) do
            removedCnt = removedCnt + invMgr.removeItemFromPlayer("front", { fromSlot = slot, count = 1 })
        end
        if wearCnt == 0 then
            tf.chat.send(player .. " is already naked :D")
        elseif removedCnt ~= wearCnt then
            tf.chat.send("Failed to undress " .. player .. " -_-")
        else
            tf.chat.send("Stripped " .. player .. " :3")
        end
    else
        tf.chat.send("Unable to reach " .. player .. "!")
    end
end

function tf.at.msg.disenchant(dat)
    local ME_BRIDGE_NAME = "disenchant"
    local meBridge = tf.peri.objByLabel(ME_BRIDGE_NAME)
    if not meBridge then
        tf.chat.send("ME Bridge with label '" .. ME_BRIDGE_NAME .. "' not found!")
        return
    end

    local reqCnt = tonumber(dat[1]) or 1
    local curCnt = 0
    local itemsTab = meBridge.getItems()

    tf.chat.send("Disenchant export started...")

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

    tf.chat.send("Disenchant export ended")
end

function tf.at.msg.label_upd(dat)
    local periLabel, periName = dat[1], dat[2]
    if not tf.cfg.dat["labels"] then
        tf.cfg.dat["labels"] = {}
    end
    tf.cfg.dat["labels"][periLabel] = periName
    tf.cfg.save()
    tf.chat.send("Label '" .. periLabel .. "' set to '" .. (periName or "(cleared)") .. "'")
end
