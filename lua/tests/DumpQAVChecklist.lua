-- /mods/CampaignBranch/ExtractMPBlueprints.lua
--
-- Run this script with ExtractMPBlueprints.bat

local datadir = '../../'
local outfile = 'QAVChecklist.txt'
local current_id

local all_blueprints = {}


dofile(datadir..'lua/system/repr.lua')
dofile(datadir..'lua/system/utils.lua')

function LOC(s)
    return (string.gsub(s, '^<[^>]*>', ''))
end

--===================================================================
-- Define constructors that get called from the Blueprint files
---------------------------------------------------------------------
function Sound(t)
    return t
end

function RPCSound(t)
    return t
end

function UnitBlueprint(bp)
    bp.BlueprintId = current_id
    all_blueprints[current_id] = bp
end


--===================================================================
-- Generate the partial blueprint file
---------------------------------------------------------------------
function LoadAllBlueprints()
    for i,d in io.dir(datadir .. 'units/*.*') do
        current_id = string.lower(d)

        local filename = string.format('%sunits/%s/%s_unit.bp', datadir, d, d)
        local ok,msg = pcall(dofile, filename)
        if not ok and not string.find(msg,'cannot read.*: No such file or directory') then
            error(msg)
        end
    end
end


function dump(bp, file)
    file:write(string.format('%s - %s (%s)\n', bp.BlueprintId, LOC(bp.Description) or '', bp.General.FactionName or 'no faction'))
    file:write('  Tech level: ', string.gsub(bp.General.TechLevel or 'None', 'RULEUTL_', ''),'                              Unit technology level.                                                   Selected unit will display its technology level.\n')
    file:write('  Strategic: ', bp.StrategicIconName or 'none            ', '                    In-game icon.                                                         Selected unit will display this icon when fully zoomed out and on the Unit View UI.\n')

    if bp.Audio then
---------file:write('  Sounds:\n')
        for name, t in sortedpairs(bp.Audio) do
            file:write('    ',name,'                                          Sound is present.                                             Selected unit will play sound when used.  \n')
        end
    end

     if bp.General.CommandCaps then
----------file:write('  Command capabilities:\n')
         for name,flag in sortedpairs(bp.General.CommandCaps) do
             if flag then
                 local cap = string.gsub(name,'RULEUCC_','')
                 local air = string.gsub(bp.Physics.MotionType or 'None', 'RULEUMT_', '')
                     if cap=='CallTransport' and air~='Air' then
                         file:write('    ',cap,'                                         Cursor functionality.                                    Selected unit\'s cursor automatically changes to a transport cursor when hovering over transport or transport beacon.\n')
                     else
                        if cap=='RetaliateToggle' then
                           cap = "Hold Fire"
                        end
                        if cap=='Guard' then
                           cap = "Assist"
                        end
                        if cap~='CallTransport' then
                           file:write('    ',cap,'                                           Orders displayed in the Orders Cluster.                        Selected unit can be given an order and appropriate sounds, effects, and behavior are accomplished.\n')
                        end
                     end
             end
         end
     end

    if bp.Defense and bp.Defense.Shield then
---------file:write("  Defense:\n")
        file:write("    shield                                       Unit has a shield.                                        Selected unit has a shield that plays appropriate sounds, effects, and protects against enemy attacks.\n");
    end

    if bp.Display then
---------file:write("  Display:\n")
        for k,v in sortedpairs(bp.Display) do
            if string.find(k, "^Animation") then
                file:write("    ",k,'                                        Animations are present.                                             Selected unit plays appropriate animations in game when engaged to do so.        \n')
            end
        end
        if bp.Display then
            for k,v in sortedpairs(bp.Display) do
              if string.find(k, "^Movement") then
                 file:write("    ",k,'                                        Movement Effects are present.                                             Selected unit has appropriate effects in game when engaged to do so.        \n')
              end
            end  
        end
        if bp.Display.Tarmacs then
            file:write("    Tarmac                                       Graphics under fixed units.                                        Selected unit will have a tarmac under it when it has completed building.\n")
        end
    end

    if bp.Economy.NaturalProducer then
        file:write("    Natural Producer                                       Unit produces energy/mass.                                        Selected unit will have a tarmac under it when it has completed building.\n")
    end
 
    if bp.Enhancements then
---------file:write("  Enhancments:\n")
        for k,v in sortedpairs(bp.Enhancements) do
            file:write("    ",k,'                                         Enhancement behavior.                                             Selected unit can enable/disable/use enhancment in game.        \n')
        end  
    end
    if bp.Physics then
---------file:write("  Physics\n")
        file:write("    Motion type: ", string.gsub(bp.Physics.MotionType or 'None', 'RULEUMT_', ''), '                             Movement type.                                                        Selected unit will use this form of movement. \n')
    end

    if bp.Wreckage and bp.Wreckage.WreckageLayers then
        file:write("  Wreakage when unit destroyed                    Wreckage behavior.                                                   Selected unit will have sound, effects and leave a wreckage when it is destroyed.\n")
--        for k,v in sortedpairs(bp.Wreckage.WreckageLayers) do
--            if v then
--                file:write("    ",k,"                                          Wreckage behavior.                                                   Selected unit will have sound, effects and leave a wreckage when it is destroyed.\n")
--            end
--        end
    end
    
    if bp.Adjacency then
---------file:write("  Adjacency:\n")
        for name, t in sortedpairs(bp.Adjacency) do
             file:write('    ',name,'                                Adjancency behavior.                                        Selected unit will give bonus when built next to other units.\n')
        end
    end
    
    
    if bp.Weapon then
---------file:write('  Weapon Type, Category and Sounds:\n')
        for i,weapon in bp.Weapon do
            file:write('    ',weapon.Label,'   ',weapon.WeaponCategory,'                            ',weapon.DisplayName,' is present.                                             Selected unit will fire this weapon.\n')
            if weapon.Audio then
                for k,v in sortedpairs(weapon.Audio) do
                    if v then
                        file:write('    ',k,'                                          Weapon sound is present for ',weapon.DisplayName,'                                    Selected unit will play sound when weapon is used.\n')
                    end     
                end
            end
        end
    end


-----file:write('\n')
end


function WriteAllBlueprints()
    local n = 0
    local file = io.open(outfile, "w")
    file:write("-- Generated by ExtractMPBlueprints.lua (", os.date(), " ", os.getenv "USERNAME", ")\n")

    for id,bp in sortedpairs(all_blueprints) do

        dump(bp, file)
        n = n+1
    end
    file:close()

    print('Wrote '..n..' blueprints to '..outfile)
end


LoadAllBlueprints()
WriteAllBlueprints()
