--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

function better_commands.error(str)
    if not str or str == "" then return str end
    return minetest.colorize("red", minetest.strip_colors(str))
end

---Registers an ACOVG command
---@param name string The name of the command (/<name>)
---@param def betterCommandDef The command definition
function better_commands.register_command(name, def)
    better_commands.commands[name] = def
    def.real_func = def.func
    def.func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        local success, message, count
        if context then
            success, message, count  = def.real_func(name,param,context)
        else
            success, message, count = false, better_commands.error(S("Missing context")), 0
        end
        if message then
            if minetest.settings:get_bool("better_commands.send_command_feedback", true) then
                minetest.chat_send_player(name, message)
                if success then -- Only broadcast successful commands to others
                    for _, player in ipairs(minetest.get_connected_players()) do
                        local player_name = player:get_player_name()
                        if player_name ~= name then
                            minetest.chat_send_player(player_name, minetest.colorize("#aaaaaa", string.format(
                                "[%s: %s]",
                                context and context.origin or S("???"),
                                minetest.strip_colors(message)
                            )))
                        end
                    end
                end
            end
        end
        return success, "", count --don't actually send messages
    end
end

---Registers an alias for an ACOVG command
---@param new string The name of the alias
---@param old string The original command
function better_commands.register_command_alias(new, old)
    better_commands.commands[new] = better_commands.commands[old]
end

-- Register commands last (so overriding works properly)
minetest.register_on_mods_loaded(function()
    for name, def in pairs(better_commands.commands) do
        if minetest.registered_chatcommands[name] then
            if better_commands.settings.override then
                minetest.log("action", "[Better Commands] Overriding "..name)
                better_commands.old_commands[name] = minetest.registered_chatcommands[name]
                minetest.unregister_chatcommand(name, def)
            else
                minetest.log("action", "[Better Commands] Not registering "..name.." as it already exists.")
                return
            end
        end
        minetest.register_chatcommand(name, def)
        -- Since this is in an on_mods_loaded function, mod_origin is "??" by default
        ---@diagnostic disable-next-line: inject-field
        minetest.registered_chatcommands[name].mod_origin = "better_commands"
    end
end)