--******************************************************************************************************
--** Copyright (c) 2024  Il1i1
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

---@type ContextBasedTemplate
Template = {
    Name = 'Power generators',
    TriggersOnBuilding = categories.STRUCTURE * categories.ARTILLERY * categories.SIZE20,
    TemplateSortingOrder = 100,
    TemplateData = {
        26,
        26,
        {
            'dummy',
            0,
            3,
            3
        },
        {
            'uab1301',
            101,
            12,
            2
        },
        {
            'uab1101',
            102,
            9,
            7
        },
        {
            'uab1301',
            111,
            4,
            12
        },
        {
            'uab1101',
            112,
            -1,
            9
        },

        {
            'uab1301',
            121,
            -6,
            4
        },
        {
            'uab1101',
            122,
            -3,
            -1
        },

        {
            'uab1301',
            131,
            2,
            -6
        },
        {
            'uab1101',
            132,
            7,
            -3
        },

    },
}
