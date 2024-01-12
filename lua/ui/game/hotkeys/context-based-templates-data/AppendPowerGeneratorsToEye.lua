--******************************************************************************************************
--** Copyright (c) 2024  Il1I1
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
    TriggersOnBuilding = categories.STRUCTURE * categories.OPTICS * categories.TECH3 * categories.AEON,
    TemplateSortingOrder = 100,
    TemplateData = {
        10,
        10,
        {
            'dummy',
            2600,
            1,
            1
        },
        {
            'uab1101',
            2605,
            -1,
            5
        },
        {
            'uab1101',
            2621,
            1,
            5
        },
        {
            'uab1101',
            2636,
            3,
            5
        },
        {
            'uab1101',
            2651,
            5,
            3
        },
        {
            'uab1101',
            2666,
            5,
            1
        },
        {
            'uab1101',
            2680,
            5,
            -1
        },
        {
            'uab1101',
            2695,
            3,
            -3
        },
        {
            'uab1101',
            2710,
            1,
            -3
        },
        {
            'uab1101',
            2724,
            -1,
            -3
        },
        {
            'uab1101',
            2738,
            -3,
            -1
        },
        {
            'uab1101',
            2753,
            -3,
            1
        },
        {
            'uab1101',
            2767,
            -3,
            3
        }
    },
}
