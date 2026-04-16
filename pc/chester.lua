tf.info.cmd.so = {
    args = {
        { name = "filter", type = tf.type.STR, picks = { "*", "/damaged", "/enchanted" } },
        { name = "cnt",    type = tf.type.INT, defa = 1 }
    },
    desc = "Export items using the default storage output peripheral. Optionally filter and specify count.",
    examples = { "so diamond_sword 3" }
}
function tf.at.cmd.so(args)
    local ME_BRIDGE_NAME = "so"
    local meBridge = tf.peri.objByLabel(ME_BRIDGE_NAME)
    if not meBridge then
        tf.chat.send("ME Bridge with label '" .. ME_BRIDGE_NAME .. "' not found!")
        return
    end

    if args[1] and args[1]:sub(1, 1) == "/" then
        if args[1] == "/damaged" then
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
        elseif args[1] == "/enchanted" then
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
        local name_ = args[1] or ""
        local cnt = tonumber(args[2]) or 1
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

tf.info.cmd.undress = {
    args = {
        { name = "player", type = tf.type.STR }
    },
    desc = "Undress an unlucky player by taking all their armor.",
    examples = { "undress KaiDamu" }
}
function tf.at.cmd.undress(args)
    local player = args[1] or "(nameless)"
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

tf.info.cmd.disenchant = {
    args = {
        { name = "cnt", type = tf.type.INT }
    },
    desc = "Export items with enchantments (together with books) to the disenchanting inventory."
}
function tf.at.cmd.disenchant(args)
    local ME_BRIDGE_NAME = "disenchant"
    local meBridge = tf.peri.objByLabel(ME_BRIDGE_NAME)
    if not meBridge then
        tf.chat.send("ME Bridge with label '" .. ME_BRIDGE_NAME .. "' not found!")
        return
    end

    local reqCnt = tonumber(args[1]) or 1
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

tf.info.cmd.hello = {
    desc = "Just say hi to the sender."
}
function tf.at.cmd.hello(args, sender)
    tf.chat.send("Hi " .. sender .. "!")
end

function tf.at.msg.cfg_peri_label(dat)
    local periLabel, periName = dat[1], dat[2]
    if not tf.cfg.dat["peri_labels"] then
        tf.cfg.dat["peri_labels"] = {}
    end
    tf.cfg.dat["peri_labels"][periLabel] = periName
    tf.cfg.save()
    tf.chat.send("Label '" .. periLabel .. "' set to '" .. (periName or "(cleared)") .. "'")
end
