local bindings = require('otouto.bindings')
local utilities = require('otouto.utilities')
local autils = require('otouto.autils')

local P = {}

function P:init(bot)
    self.triggers = utilities.triggers(bot.info.username, bot.config.cmd_pat)
        :t('ban', true).table
    self.command = 'ban'
    self.doc = "Bans a user or users from the group. Targets can be unbanned \z
with /unban. A reason can be given on a new line. Example:\
    /ban @examplus 5551234\
    Bad jokes."

    self.privilege = 2
    self.administration = true
    self.targeting = true
end

function P:action(bot, msg, group)
    local admin = group.data.admin
    local targets, output, reason = autils.targets(bot, msg)
    local banned_users = utilities.new_set()

    for target in pairs(targets) do
        local name = utilities.lookup_name(bot, target)
        if autils.rank(bot, target, msg.chat.id) >= 2 then
            table.insert(output, name .. ' is too privileged to be banned.')
        elseif admin.bans[target] then
            table.insert(output, name .. ' is already banned.')
        else
            bindings.kickChatMember{
                chat_id = msg.chat.id,
                user_id = target
            }
            admin.bans[target] = true
            banned_users:add(target)
            table.insert(output, name .. ' has been banned.')
        end
    end

    utilities.send_reply(msg, table.concat(output, '\n'), 'html')
    if #banned_users > 0 then
        autils.log(bot, {
            chat_id = msg.chat.id,
            targets = banned_users,
            action = 'Banned',
            source_user = msg.from,
            reason = reason
        })
    end
end

return P
