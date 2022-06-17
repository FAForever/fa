--****************************************************************************
--**
--**  File     :  /lua/upgradetemplates.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  This is a list of all units that upgrade, and what
--**              they upgrade to.
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

UnitUpgradeTemplates =
{
    -- earth unit upgrades
    {
        -- engineer
        { 'uel0105', 'uel0208'},
        { 'uel0208', 'uel0309'},
    },

    -- alien unit upgrades
    {
        -- engineer
        { 'ual0105', 'ual0208'},
        { 'ual0208', 'ual0309'},
    },

    -- recycler unit upgrades
    {
        -- engineer
        { 'url0105', 'url0208'},
        { 'url0208', 'url0309'},

        -- scout
        { 'url0101', 'urb3103'},
    },

    -- seraphim unit upgrades
    {
        -- engineer
        { 'xsl0105', 'xsl0208'},
        { 'xsl0208', 'xsl0309'},
    },
}

StructureUpgradeTemplates =
{
    -- earth structure upgrades
    {
        -- land factory
        { 'ueb0101', 'ueb0201'},
        { 'ueb0201', 'ueb0301'},

        -- air factory
        { 'ueb0102', 'ueb0202'},
        { 'ueb0202', 'ueb0302'},

        -- naval factory
        { 'ueb0103', 'ueb0203'},
        { 'ueb0203', 'ueb0303'},

        -- mass extractors
        { 'ueb1103', 'ueb1202'},
        { 'ueb1202', 'ueb1302'},

        -- radar
        { 'ueb3101', 'ueb3201'},
        { 'ueb3201', 'ueb3104'},

        -- sonar
        { 'ueb3102', 'ueb3202'},
        { 'ueb3202', 'ues0305'},

        --Shield
        { 'ueb4202', 'ueb4301'},

        --Engineering Station
        { 'xeb0104', 'xeb0204'},

    },

    -- alien structure upgrades
    {
        -- land factory
        { 'uab0101', 'uab0201'},
        { 'uab0201', 'uab0301'},

        -- air factory
        { 'uab0102', 'uab0202'},
        { 'uab0202', 'uab0302'},

        -- naval factory
        { 'uab0103', 'uab0203'},
        { 'uab0203', 'uab0303'},

        -- mass extractors
        { 'uab1103', 'uab1202'},
        { 'uab1202', 'uab1302'},

        -- radar
        { 'uab3101', 'uab3201'},
        { 'uab3201', 'uab3104'},

        -- sonar
        { 'uab3102', 'uab3202'},
        { 'uab3202', 'uas0305'},


    },

    -- recycler structure upgrades
    {
        -- land factory
        { 'urb0101', 'urb0201'},
        { 'urb0201', 'urb0301'},

        -- air factory
        { 'urb0102', 'urb0202'},
        { 'urb0202', 'urb0302'},

        -- naval factory
        { 'urb0103', 'urb0203'},
        { 'urb0203', 'urb0303'},

        -- mass extractors
        { 'urb1103', 'urb1202'},
        { 'urb1202', 'urb1302'},

        -- radar
        { 'urb3101', 'urb3201'},
        { 'urb3201', 'urb3104'},

        -- sonar
        { 'urb3102', 'urb3202'},
        { 'urb3202', 'urs0305'},

        -- shields
        { 'urb4202', 'urb4204'},
        { 'urb4204', 'urb4205'},
        { 'urb4205', 'urb4206'},
        { 'urb4206', 'urb4207'},

        --Engineering Station
        { 'xrb0104', 'xrb0204'},
        { 'xrb0204', 'xrb0304'},
    },

    -- seraphim structure upgrades
    {
        -- land factory
        { 'xsb0101', 'xsb0201'},
        { 'xsb0201', 'xsb0301'},

        -- air factory
        { 'xsb0102', 'xsb0202'},
        { 'xsb0202', 'xsb0302'},

        -- naval factory
        { 'xsb0103', 'xsb0203'},
        { 'xsb0203', 'xsb0303'},

        -- mass extractors
        { 'xsb1103', 'xsb1202'},
        { 'xsb1202', 'xsb1302'},

        -- radar
        { 'xsb3101', 'xsb3201'},
        { 'xsb3201', 'xsb3104'},

        -- sonar
        { 'xsb3102', 'xsb3202'},
--        { 'xsb3202', 'xsb0305'}, -- unit xsb3202 can't upgrade to xsb0305 (building does not exist).

        --Shield
        { 'xsb4202', 'xsb4301'},

    },
}
