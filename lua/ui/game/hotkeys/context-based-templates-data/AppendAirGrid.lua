--******************************************************************************************************
--** Copyright (c) 2023  Willem 'Jip' Wijnia
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
    Name = 'Air grid',
    TriggersOnBuilding = (categories.AIR * categories.SUPPORTFACTORY * categories.TECH3),
    TemplateSortingOrder = 100,
    TemplateData = {
        0,
        0,
        {
            'dummy',
            0,
            2,
            2
        },
        {
            'uab1301',
            1,
            10,
            2
        },
        {
            'zab9602',
            1,
            10,
            10
        },
        {
            'uab1301',
            2,
            -6,
            2
        },
        {
            'zab9602',
            1,
            -6,
            10
        },
        {
            'uab1301',
            3,
            2,
            -6
        },
        {
            'zab9602',
            1,
            10,
            -6
        },
        {
            'uab1301',
            4,
            2,
            10
        },
        {
            'zab9602',
            1,
            -6,
            -6
        },
    }
}
