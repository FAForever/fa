--*******************************************************************************
-- MIT License
--
-- Copyright (c) 2024 (Jip) Willem Wijnia
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--
--*******************************************************************************

local function DefaultMoveToLayout()
    local keyActions = import("/lua/keymap/keyactions.lua").keyActions

    return {
        -- clear it out
        ['CTRL-SHIFT-BACKSPACE'] = keyActions.cinematics_move_to_clear,

        -- navigate between sequences
        ['Q'] = keyActions.cinematics_move_to_jump_backward,
        ['W'] = keyActions.cinematics_move_to_jump_current,
        ['E'] = keyActions.cinematics_move_to_jump_forward,

        -- add, insert, overwrite and remove camera orientations
        ['A'] = keyActions.cinematics_move_to_add,
        ['S'] = keyActions.cinematics_move_to_insert_at_index,
        ['D'] = keyActions.cinematics_move_to_overwrite_at_index,
        ['BACKSPACE'] = keyActions.cinematics_move_to_remove,
        ['DELETE'] = keyActions.cinematics_move_to_remove_at_index,

        -- animation
        ['Shift-Q'] = keyActions.cinematics_move_to_animate_forward,
        ['Shift-W'] = keyActions.cinematics_move_to_animate_backward,
        ['Shift-E'] = keyActions.cinematics_move_to_jump_and_animate_forward,
        ['Shift-R'] = keyActions.cinematics_move_to_jump_and_animate_backward,

        -- store/retrieve from preference file
        ['1'] = keyActions.cinematics_move_to_store_01,
        ['2'] = keyActions.cinematics_move_to_store_02,
        ['3'] = keyActions.cinematics_move_to_store_03,

        ['ALT-1'] = keyActions.cinematics_move_to_retrieve_01,
        ['ALT-2'] = keyActions.cinematics_move_to_retrieve_02,
        ['ALT-3'] = keyActions.cinematics_move_to_retrieve_03,
    }
end

function ApplyDefaultKeyLayout()
    local userKeys = import("/lua/keymap/keymapper.lua").GetKeyMappings()

    -- cinematics-related keys
    local moveToKeyMap = DefaultMoveToLayout()

    -- we overwrite existing user keys with our own key maps. This lasts for the entire session,
    -- only restarting the game can undo this. It does not affect your preference file.
    local combinedKeyMap = table.combine(userKeys, moveToKeyMap)

    -- apply the keys
    IN_ClearKeyMap()
    IN_AddKeyMapTable(combinedKeyMap)

    print("Applied hotkeys for cinematics")
end
