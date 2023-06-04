--****************************************************************************
--**  File     :  lua/modules/ui/game/taunt.lua
--**  Author(s):  Chris blackwell
--**
--**  Summary  :  Taunt system
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local Prefs = import("/lua/user/prefs.lua")
local AIChatS = import("/lua/aichatsorian.lua")

local taunts = {
    {text = '<LOC XGG_MP1_010_010>[{i Hall}]: You will not stop the UEF!', bank = 'XGG', cue = 'XGG_Hall__04566'},
    {text = '<LOC XGG_MP1_020_010>[{i Hall}]: Humanity will be saved!', bank = 'XGG', cue = 'XGG_Hall__04567'},
    {text = '<LOC XGG_MP1_030_010>[{i Hall}]: You\'re not going to stop me.', bank = 'XGG', cue = 'XGG_Hall__04568'},
    {text = '<LOC XGG_MP1_040_010>[{i Hall}]: The gloves are coming off.', bank = 'XGG', cue = 'XGG_Hall__04569'},
    {text = '<LOC XGG_MP1_050_010>[{i Hall}]: You\'re in my way.', bank = 'XGG', cue = 'XGG_Hall__04570'},
    {text = '<LOC XGG_MP1_060_010>[{i Hall}]: Get out of here while you still can.', bank = 'XGG', cue = 'XGG_Hall__04571'},
    {text = '<LOC XGG_MP1_070_010>[{i Hall}]: I guess it\'s time to end this farce.', bank = 'XGG', cue = 'XGG_Hall__04572'},
    {text = '<LOC XGG_MP1_080_010>[{i Hall}]: You\'ve got no chance against me!', bank = 'XGG', cue = 'XGG_Hall__04573'},
    {text = '<LOC XGG_MP1_090_010>[{i Fletcher}]: This ain\'t gonna be much of a fight.', bank = 'XGG', cue = 'XGG_Fletcher_MP1_04574'},
    {text = '<LOC XGG_MP1_100_010>[{i Fletcher}]: You\'re not puttin\' up much of a fight.', bank = 'XGG', cue = 'XGG_Fletcher_MP1_04575'},
    {text = '<LOC XGG_MP1_110_010>[{i Fletcher}]: Do you have any idea of what you\'re doing?', bank = 'XGG', cue = 'XGG_Fletcher_MP1_04576'},
    {text = '<LOC XGG_MP1_120_010>[{i Fletcher}]: Not much on tactics, are ya?', bank = 'XGG', cue = 'XGG_Fletcher_MP1_04577'},
    {text = '<LOC XGG_MP1_130_010>[{i Fletcher}]: If you run now, I\'ll let ya go.', bank = 'XGG', cue = 'XGG_Fletcher_MP1_04578'},
    {text = '<LOC XGG_MP1_140_010>[{i Fletcher}]: You ain\'t too good at this, are you?', bank = 'XGG', cue = 'XGG_Fletcher_MP1_04579'},
    {text = '<LOC XGG_MP1_150_010>[{i Fletcher}]: Guess I got time to smack you around.', bank = 'XGG', cue = 'XGG_Fletcher_MP1_04580'},
    {text = '<LOC XGG_MP1_160_010>[{i Fletcher}]: I feel a bit bad, beatin\' up on you like this.', bank = 'XGG', cue = 'XGG_Fletcher_MP1_04581'},
    {text = '<LOC X01_M01_040_010>[{i Fletcher}]: A Cybran, huh? I thought you guys would be busy changing the water in Brackman\'s brain tank.', bank = 'X01_VO', cue = 'X01_Fletcher_M01_02877'},
    {text = '<LOC X01_M03_170_010>[{i Fletcher}]: That\'s what I love to see. Burn, baby, burn!', bank = 'X01_VO', cue = 'X01_Fletcher_M03_03701'},
    {text = '<LOC X05_M02_270_030>[{i Fletcher}]: Yeah, yeah. Give it a rest already.', bank = 'X05_VO', cue = 'X05_Fletcher_M02_04950'},
    {text = '<LOC X06_T01_587_010>[{i Fletcher}]: You can\'t stop me with that experimental! I\'ll destroy it first!', bank = 'X06_VO', cue = 'X06_Fletcher_T01_04805'},
    {text = '<LOC X06_T01_690_010>[{i Fletcher}]: You\'re a coward.', bank = 'X06_VO', cue = 'X06_Fletcher_T01_03030'},
    {text = '<LOC X06_T01_860_010>[{i Fletcher}]: There is no stopping me!', bank = 'X06_VO', cue = 'X06_Fletcher_T01_03047'},
    {text = '<LOC XGG_MP1_170_010>[{i Rhiza}]: Glory to the Princess!', bank = 'XGG', cue = 'XGG_Rhiza_MP1_04582'},
    {text = '<LOC XGG_MP1_180_010>[{i Rhiza}]: Glorious!', bank = 'XGG', cue = 'XGG_Rhiza_MP1_04583'},
    {text = '<LOC XGG_MP1_190_010>[{i Rhiza}]: I will not be stopped!', bank = 'XGG', cue = 'XGG_Rhiza_MP1_04584'},
    {text = '<LOC XGG_MP1_200_010>[{i Rhiza}]: All enemies of the Princess will be destroyed!', bank = 'XGG', cue = 'XGG_Rhiza_MP1_04585'},
    {text = '<LOC XGG_MP1_210_010>[{i Rhiza}]: I will hunt you to the ends of the galaxy!', bank = 'XGG', cue = 'XGG_Rhiza_MP1_04586'},
    {text = '<LOC XGG_MP1_220_010>[{i Rhiza}]: For the Aeon!', bank = 'XGG', cue = 'XGG_Rhiza_MP1_04587'},
    {text = '<LOC XGG_MP1_230_010>[{i Rhiza}]: Flee while you can!', bank = 'XGG', cue = 'XGG_Rhiza_MP1_04588'},
    {text = '<LOC XGG_MP1_240_010>[{i Rhiza}]: Behold the power of the Illuminate!', bank = 'XGG', cue = 'XGG_Rhiza_MP1_04589'},
    {text = '<LOC X06_T01_885_010>[{i Rhiza}]: Such a thing will not stop me!', bank = 'X06_VO', cue = 'X06_Rhiza_T01_04508'},
    {text = '<LOC X06_T01_887_010>[{i Rhiza}]: You mistake me if you think I will be cowed!', bank = 'X06_VO', cue = 'X06_Rhiza_T01_04510'},
    {text = '<LOC X06_T01_920_010>[{i Rhiza}]: Soon you will know my wrath!', bank = 'X06_VO', cue = 'X06_Rhiza_T01_03052'},
    {text = '<LOC XGG_MP1_250_010>[{i Kael}]: The Order will not be defeated!', bank = 'XGG', cue = 'XGG_Kael_MP1_04590'},
    {text = '<LOC XGG_MP1_260_010>[{i Kael}]: If you grovel, I may let you live.', bank = 'XGG', cue = 'XGG_Kael_MP1_04591'},
    {text = '<LOC XGG_MP1_270_010>[{i Kael}]: There will be nothing left of you when I am done.', bank = 'XGG', cue = 'XGG_Kael_MP1_04592'},
    {text = '<LOC XGG_MP1_280_010>[{i Kael}]: You\'re beginning to bore me.', bank = 'XGG', cue = 'XGG_Kael_MP1_04593'},
    {text = '<LOC XGG_MP1_290_010>[{i Kael}]: My time is wasted on you.', bank = 'XGG', cue = 'XGG_Kael_MP1_04594'},
    {text = '<LOC XGG_MP1_300_010>[{i Kael}]: Run while you can.', bank = 'XGG', cue = 'XGG_Kael_MP1_04595'},
    {text = '<LOC XGG_MP1_310_010>[{i Kael}]: It must be frustrating to be so completely overmatched.', bank = 'XGG', cue = 'XGG_Kael_MP1_04596'},
    {text = '<LOC XGG_MP1_320_010>[{i Kael}]: Beg for mercy.', bank = 'XGG', cue = 'XGG_Kael_MP1_04597'},
    {text = '<LOC X02_M02_060_020>[{i Celene}]: There is nothing here for you but death.', bank = 'X02_VO', cue = 'X02_Celene_M02_04277'},
    {text = '<LOC X02_T01_070_010>[{i Celene}]: Every day you grow weaker. Your end is drawing near.', bank = 'X02_VO', cue = 'X02_Celene_T01_04542'},
    {text = '<LOC X02_T01_090_010>[{i Celene}]: Nothing can save you now!', bank = 'X02_VO', cue = 'X02_Celene_T01_04544'},
    {text = '<LOC X02_T01_110_010>[{i Celene}]: There is nothing I enjoy more than hunting Cybrans.', bank = 'X02_VO', cue = 'X02_Celene_T01_04547'},
    {text = '<LOC X02_T01_150_010>[{i Celene}]: I will not be defeated by the likes of you!', bank = 'X02_VO', cue = 'X02_Celene_T01_04551'},
    {text = '<LOC X02_T01_001_010>[{i Celene}]: No, you may not have that experimental.', bank = 'X02_VO', cue = 'X02_Celene_T01_04782'},
    {text = '<LOC X01_T01_040_010>[{i Gari}]: Your tenacity is admirable, but the outcome of this battle was determined long ago.', bank = 'X01_VO', cue = 'X01_Gari_T01_04514'},
    {text = '<LOC X01_T01_060_010>[{i Gari}]: Now you will taste the fury of the Order of the Illuminate.', bank = 'X01_VO', cue = 'X01_Gari_T01_04516'},
    {text = '<LOC X01_T01_070_010>[{i Gari}]: You have nowhere to hide, nowhere to run.', bank = 'X01_VO', cue = 'X01_Gari_T01_04517'},
    {text = '<LOC X01_T01_100_010>[{i Gari}]: Not even your most powerful weapon can stand before me.', bank = 'X01_VO', cue = 'X01_Gari_T01_04520'},
    {text = '<LOC X01_T01_110_010>[{i Gari}]: Beg for mercy and perhaps I shall grant you an honorable death.', bank = 'X01_VO', cue = 'X01_Gari_T01_04521'},
    {text = '<LOC X01_T01_150_010>[{i Gari}]: You are an abomination. I will take great pleasure in exterminating you.', bank = 'X01_VO', cue = 'X01_Gari_T01_04525'},
    {text = '<LOC X01_T01_180_010>[{i Gari}]: The Order is eternal. There is no stopping us.', bank = 'X01_VO', cue = 'X01_Gari_T01_04529'},
    {text = '<LOC X06_T01_560_010>[{i Vendetta}]: Nice try.', bank = 'X06_VO', cue = 'X06_Vedetta_T01_03018'},
    {text = '<LOC X06_T01_570_010>[{i Vendetta}]: I am not defeated yet!', bank = 'X06_VO', cue = 'X06_Vedetta_T01_03019'},
    {text = '<LOC XGG_MP1_330_010>[{i Dostya}]: I have little to fear from the likes of you.', bank = 'XGG', cue = 'XGG_Dostya_MP1_04598'},
    {text = '<LOC XGG_MP1_340_010>[{i Dostya}]: Observe. You may learn something.', bank = 'XGG', cue = 'XGG_Dostya_MP1_04599'},
    {text = '<LOC XGG_MP1_350_010>[{i Dostya}]: I would flee, if I were you.', bank = 'XGG', cue = 'XGG_Dostya_MP1_04600'},
    {text = '<LOC XGG_MP1_360_010>[{i Dostya}]: You will be just another in my list of victories.', bank = 'XGG', cue = 'XGG_Dostya_MP1_04601'},
    {text = '<LOC XGG_MP1_370_010>[{i Dostya}]: You are not worth my time.', bank = 'XGG', cue = 'XGG_Dostya_MP1_04602'},
    {text = '<LOC XGG_MP1_380_010>[{i Dostya}]: Your defeat is without question.', bank = 'XGG', cue = 'XGG_Dostya_MP1_04603'},
    {text = '<LOC XGG_MP1_390_010>[{i Dostya}]: You seem to have courage. Intelligence seems to be lacking.', bank = 'XGG', cue = 'XGG_Dostya_MP1_04604'},
    {text = '<LOC XGG_MP1_400_010>[{i Dostya}]: I will destroy you.', bank = 'XGG', cue = 'XGG_Dostya_MP1_04605'},
    {text = '<LOC XGG_MP1_410_010>[{i Brackman}]: I\'m afraid there is no hope for you, oh yes.', bank = 'XGG', cue = 'XGG_Brackman_MP1_04606'},
    {text = '<LOC XGG_MP1_420_010>[{i Brackman}]: Well, at least you provided me with some amusement.', bank = 'XGG', cue = 'XGG_Brackman_MP1_04607'},
    {text = '<LOC XGG_MP1_430_010>[{i Brackman}]: Perhaps some remedial training is in order?', bank = 'XGG', cue = 'XGG_Brackman_MP1_04608'},
    {text = '<LOC XGG_MP1_440_010>[{i Brackman}]: Are you sure you want to do that?', bank = 'XGG', cue = 'XGG_Brackman_MP1_04609'},
    {text = '<LOC XGG_MP1_450_010>[{i Brackman}]: They do not call me a genius for nothing, you know.', bank = 'XGG', cue = 'XGG_Brackman_MP1_04610'},
    {text = '<LOC XGG_MP1_460_010>[{i Brackman}]: Defeating you is hardly worth the effort, oh yes.', bank = 'XGG', cue = 'XGG_Brackman_MP1_04611'},
    {text = '<LOC XGG_MP1_470_010>[{i Brackman}]: There is nothing you can do.', bank = 'XGG', cue = 'XGG_Brackman_MP1_04612'},
    {text = '<LOC XGG_MP1_480_010>[{i Brackman}]: At least you will not suffer long.', bank = 'XGG', cue = 'XGG_Brackman_MP1_04613'},
    {text = '<LOC XGG_MP1_490_010>[{i QAI}]: You will not prevail.', bank = 'XGG', cue = 'XGG_QAI_MP1_04614'},
    {text = '<LOC XGG_MP1_500_010>[{i QAI}]: Your destruction is 99% certain.', bank = 'XGG', cue = 'XGG_QAI_MP1_04615'},
    {text = '<LOC XGG_MP1_510_010>[{i QAI}]: I cannot be defeated.', bank = 'XGG', cue = 'XGG_QAI_MP1_04616'},
    {text = '<LOC XGG_MP1_520_010>[{i QAI}]: Your strategies are without merit.', bank = 'XGG', cue = 'XGG_QAI_MP1_04617'},
    {text = '<LOC XGG_MP1_530_010>[{i QAI}]: My victory is without question.', bank = 'XGG', cue = 'XGG_QAI_MP1_04618'},
    {text = '<LOC XGG_MP1_540_010>[{i QAI}]: Your defeat can be the only outcome.', bank = 'XGG', cue = 'XGG_QAI_MP1_04619'},
    {text = '<LOC XGG_MP1_550_010>[{i QAI}]: Your efforts are futile.', bank = 'XGG', cue = 'XGG_QAI_MP1_04620'},
    {text = '<LOC XGG_MP1_560_010>[{i QAI}]: Retreat is your only logical option.', bank = 'XGG', cue = 'XGG_QAI_MP1_04621'},
    {text = '<LOC X02_T01_220_010>[{i QAI}]: All calculations indicate that your demise is near.', bank = 'X02_VO', cue = 'X02_QAI_T01_04558'},
    {text = '<LOC X02_T01_280_010>[{i QAI}]: If you destroy this ACU, another shall rise in its place. I am endless.', bank = 'X02_VO', cue = 'X02_QAI_T01_04564'},
    {text = '<LOC X05_T01_080_010>[{i QAI}]: I have examined our previous battles and created the appropriate subroutines to counter your strategies. You cannot win.', bank = 'X05_VO', cue = 'X05_QAI_T01_04422'},
    {text = '<LOC XGG_MP1_570_010>[{i Hex5}]: You\'re screwed!', bank = 'XGG', cue = 'XGG_Hex5_MP1_04622'},
    {text = '<LOC XGG_MP1_580_010>[{i Hex5}]: I do make it look easy.', bank = 'XGG', cue = 'XGG_Hex5_MP1_04623'},
    {text = '<LOC XGG_MP1_590_010>[{i Hex5}]: You should probably run away now.', bank = 'XGG', cue = 'XGG_Hex5_MP1_04624'},
    {text = '<LOC XGG_MP1_600_010>[{i Hex5}]: A smoking crater is going to be all that\'s left of you.', bank = 'XGG', cue = 'XGG_Hex5_MP1_04625'},
    {text = '<LOC XGG_MP1_610_010>[{i Hex5}]: So, I guess failure runs in your family?', bank = 'XGG', cue = 'XGG_Hex5_MP1_04626'},
    {text = '<LOC XGG_MP1_620_010>[{i Hex5}]: Man, I\'m good at this!', bank = 'XGG', cue = 'XGG_Hex5_MP1_04627'},
    {text = '<LOC XGG_MP1_630_010>[{i Hex5}]: Goodbye!', bank = 'XGG', cue = 'XGG_Hex5_MP1_04628'},
    {text = '<LOC XGG_MP1_640_010>[{i Hex5}]: Don\'t worry, it\'ll be over soon.', bank = 'XGG', cue = 'XGG_Hex5_MP1_04629'},
    {text = '<LOC X05_T01_190_010>[{i Hex5}]: You will bow before the Seraphim.', bank = 'X05_VO', cue = 'X05_Hex5_T01_04433'},
    {text = '<LOC X04_T01_020_010>[{i OumEoshi}]: Only one species can attain perfection.', bank = 'X04_VO', cue = 'X04_Oum-Eoshi_T01_04384'},
    {text = '<LOC X04_T01_030_010>[{i OumEoshi}]: Do not fret. Dying by my hand is the supreme honor.', bank = 'X04_VO', cue = 'X04_Oum-Eoshi_T01_04385'},
    {text = '<LOC X04_T01_040_010>[{i OumEoshi}]: Soon there will be more of us than you can possibly ever hope to defeat.', bank = 'X04_VO', cue = 'X04_Oum-Eoshi_T01_04386'},
    {text = '<LOC X06_T01_210_010>[{i ThelUuthow}]: You Cybrans die as easily as any other human.', bank = 'X06_VO', cue = 'X06_Thel-Uuthow_T01_02973'},
    {text = '<LOC X06_T01_240_010>[{i ThelUuthow}]: Bow down before our might, and we may spare you.', bank = 'X06_VO', cue = 'X06_Thel-Uuthow_T01_02976'},
    {text = '<LOC X06_T01_260_010>[{i ThelUuthow}]: You will perish at my hand.', bank = 'X06_VO', cue = 'X06_Thel-Uuthow_T01_02978'},

--    {text = '<LOC MP_Taunt_0033>', bank = '', cue = ''},
}

local prevHandle

local function RecieveTaunt(sender, msg)
    if Prefs.GetOption('mp_taunt_head_enabled') == 'true' then
        local taunt = taunts[msg.data]
        if taunt then
            StopSound(prevHandle)
            prevHandle = PlayVoice(Sound({Cue = taunt.cue, Bank = taunt.bank}))
            import("/lua/ui/game/chat.lua").ReceiveChat(sender, {Chat = true, text = LOC(taunt.text), to = "all"})
        end
    end
end

function RecieveAITaunt(sender, msg)
    if Prefs.GetOption('mp_taunt_head_enabled') == 'true' then
        local taunt = taunts[msg.data]
        if taunt and msg.aisender then
            StopSound(prevHandle)
            prevHandle = PlayVoice(Sound({Cue = taunt.cue, Bank = taunt.bank}))
            import("/lua/ui/game/chat.lua").ReceiveChat(sender, {Chat = true, text = LOC(taunt.text), to = "all", aisender = msg.aisender})
        elseif taunt then
            StopSound(prevHandle)
            prevHandle = PlayVoice(Sound({Cue = taunt.cue, Bank = taunt.bank}))
            import("/lua/ui/game/chat.lua").ReceiveChat(sender, {Chat = true, text = LOC(taunt.text), to = "all"})
        end
    end
end

function Init()
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(RecieveTaunt, 'Taunt')
end
function SendTaunt(tauntIndex, sender)
    if sender then
        AIChatS.AISendChatMessage(nil, {Taunt = true, data = tauntIndex, aisender = sender})
    else
        SessionSendChatMessage({Taunt = true, data = tauntIndex})
    end
end

-- if this returns true, taunt found and handled, else return false so chat handling can continue
function CheckForAndHandleTaunt(text, sender)
    -- taunts start with /
    if (string.len(text) > 1) and (string.sub(text, 1, 1) == "/") then
        local tauntIndex = tonumber(string.sub(text, 2))
        if tauntIndex and taunts[tauntIndex] then
            SendTaunt(tauntIndex, sender)
            return true
        end
    end
    return false
end
