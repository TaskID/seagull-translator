util.require_natives(1640181023)
util.ensure_package_is_installed("lib/lunajson")
lunajson = require("lunajson")

_natives_PLAYER = PLAYER
_natives_NETWORK = NETWORK
_natives_ENTITY = ENTITY
_natives_VEHICLE = VEHICLE
_natives_HUD = HUD
_natives_MISC = MISC
_natives_SYSTEM = SYSTEM

function msg(msg, bitflag)
    util.toast(msg, bitflag or TOAST_ALL)
end

-- CHANGE KEY AND REGION HERE
-- Microsoft Azure Translation Service
-- https://portal.azure.com/#blade/Microsoft_Azure_ProjectOxford/CognitiveServicesHub/TextTranslation

Subscription_Key = "YOUR_KEY_HERE"
Subscription_Region = "YOUR_REGION_HERE"



-- SCRIPT - NO CHANGES REQUIRED FOR CONFIGURATION

languageTo = 'en'
languageSendAs = 'en'

msg("Seagull Translator Script loaded.")

menu.divider(menu.my_root(), "Seagull Translator")

messages = menu.list(menu.my_root(), "Chat Messages", {"translatelist"}, "A list of all received chat messages. To translate a message, select it and press enter. The description of the action will be updated with the translated message. The source language is automatically recognised.\nTo clear the message history, just restart the script.")
menu.action(menu.my_root(), "Send Translated Message", {"translatesend", "st"}, "Sends the given message in the language set in \"Translate sent to\".", function(on_click)
    menu.show_command_box_click_based(on_click, "st ")
end, function(message)
    async_http.init("api.cognitive.microsofttranslator.com", "/translate?api-version=3.0&to=" .. languageSendAs, function(res)
        json = lunajson.decode(res)
        if(json[1] == nil) then
            msg('Invalid result! Wrong api/location key or language code?')
            return
        end
        local from = json[1].detectedLanguage.language
        local text = json[1].translations[1].text

        chat.send_message(text, false, true, true)
        msg('Original (' .. from .. '): ' .. message .. '\nTranslated (' .. languageSendAs .. '): ' .. text)
    end, function()
        msg('Request failed!')
    end)
    async_http.set_post("application/json", '[{"text": "' .. message .. '"}]')
    async_http.add_header("Ocp-Apim-Subscription-Key", Subscription_Key)
    async_http.add_header("Ocp-Apim-Subscription-Region", Subscription_Region)
    async_http.dispatch()
end)

menu.divider(menu.my_root(), "Settings")


local translateto = nil
translateto = menu.text_input(menu.my_root(), "Translate to", {"translateto"}, 'The ISO 639-1 language code of the language to translate to.', function(s)
    if not (s:len() == 2) then
        msg('Invalid ISO 639-1 code (must be exactly two characters)')
        menu.trigger_command(translateto, languageTo)
        return
    end
    languageTo = s:lower()
end, "en")


local translatesend = nil
translatesend = menu.text_input(menu.my_root(), "Translate sent to", {"translatesentto"}, 'The ISO 639-1 language code of the language to translate to when sending a message using the translatesend/st command.', function(s)
    if not (s:len() == 2) then
        msg('Invalid ISO 639-1 code (must be exactly two characters)')
        menu.trigger_command(translatesend, languageSendAs)
        return
    end
    languageSendAs = s:lower()
end, "en")


menu.hyperlink(menu.my_root(), "Wikipedia ISO 639-1 Codes", "https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes", "")


chat.on_message(function(packet_sender, message_sender, message_text, is_team_chat)
    local spoofer = ''
    if not packet_sender == message_sender then
        spoofer = ' (Spoofer: ' .. pname(packet_sender) .. ')'
    end
    local desc = "[" .. os.date("%X") .. "] " .. pname(message_sender) .. spoofer .. "\n" .. message_text
    local display_message_text = ''
    if message_text:len() + pname(message_sender):len() > 44 then
        display_message_text = message_text:sub(1, 32) .. '...'
    else
        display_message_text = message_text
    end
    local action = nil
    action = menu.action(messages, pname(message_sender) .. ": " .. display_message_text, {}, desc, function()
        translate(message_text, action, desc)
    end)
end)

function translate(message, action, desc)
    async_http.init("api.cognitive.microsofttranslator.com", "/translate?api-version=3.0&to=" .. languageTo, function(res)
        json = lunajson.decode(res)
        if(json[1] == nil) then
            msg('Invalid result! Wrong api/location key or language code?')
            return
        end
        local from = json[1].detectedLanguage.language
        local text = json[1].translations[1].text

        menu.set_help_text(action, desc .. '\n\nTranslated from ' .. from:upper() .. ' to ' .. languageTo:upper() .. ':\n' .. text)
    end, function()
        msg('Request failed!')
    end)
    async_http.set_post("application/json", '[{"text": "' .. message .. '"}]')
    async_http.add_header("Ocp-Apim-Subscription-Key", Subscription_Key)
    async_http.add_header("Ocp-Apim-Subscription-Region", Subscription_Region)
    async_http.dispatch()
end

function pname(player_id)
    return PLAYER.GET_PLAYER_NAME(player_id)
end

while true do
    util.yield()
end