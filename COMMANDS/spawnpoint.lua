local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("spawnpoint", {
    description = S("Sets players' spawnpoints"),
    privs = {server = true},
    params = "[targets]",
    func = function (name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, S("Missing context"), 0 end
        if not context.executor then return false, S("Missing executor"), 0 end
        local split_param, err = better_commands.parse_params(param)
        if err then return false, err, 0 end
        local selector = split_param[1]
        if not selector then
            if context.executor.is_player and context.executor:is_player() then
                better_commands.spawnpoints[context.executor:get_player_name()] = context.executor:get_pos()
                return true, S("Spawn point set"), 1
            else
                return false, S("Non-player entities are not supported by this command")
            end
        else
            local targets, err = better_commands.parse_selector(selector, context)
            if err or not targets then return false, err, 0 end
            local last
            local count = 0
            for _, target in ipairs(targets) do
                if target.is_player and target:is_player() then
                    better_commands.spawnpoints[target:get_player_name()] = target:get_pos()
                    count = count + 1
                    last = better_commands.get_entity_name(target)
                end
            end
            if count < 1 then
                return false, S("No matching players found."), 0
            elseif count == 1 then
                return true, S("Set spawn point for @1", last), 1
            else
                return true, S("Set spawn point for @1 players", count), count
            end
        end
    end
})