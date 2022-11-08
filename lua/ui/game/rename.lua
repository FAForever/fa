local UIUtil = import("/lua/ui/uiutil.lua")

local dialog = false

function ShowRenameDialog(currentName)
    -- Dialog already showing? Don't show another one
    if dialog then
        WARN("NOPE")
        return
    end

    dialog = UIUtil.CreateInputDialog(GetFrame(0), LOC("<LOC RENAME_0000>Enter New Name"),
        function(self, newName)
            GetSelectedUnits()[1]:SetCustomName(newName)
        end
)
    dialog.inputBox:SetText(currentName)

    dialog.OnClosed = function()
        dialog = nil
    end
end
