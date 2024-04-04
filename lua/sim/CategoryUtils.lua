--- A more computationally expensive, but richer, entity-category-expression-parser.
--
-- The native-code version does not handle all operators (such as -) correctly. This function solves
-- that, at the cost of being much slower. It parses an input category expression (which may support
-- all the operators supported by the categories datatype) and spits out the resulting category set.
-- This is particularly useful for defining unit restrictions.
-- This function only works sim-side, as it requires the `categories` table.
-- There's not really any error handling. In the presence of malformed category expressions the
-- behaviour is undefined, possibly resulting in native-code crashes due to invalid calls to the
-- native category classes.
---@param categoryExpression string
---@return EntityCategory | nil
function ParseEntityCategoryProperly(categoryExpression)
    local tokens = {}

    local OPERATORS = {
        ["("] = true,
        [")"] = true,
        ["-"] = true, -- Subtraction
        ["+"] = true, -- Union
        ["*"] = true, -- Intersection
    }

    -- Map operator tokens to their corresponding functions: used for building the category set.
    local OPERATOR_FUNCTIONS = {
        ---@param a EntityCategory
        ---@param b EntityCategory
        ["-"] = function(a, b)
            return a - b
        end,
        ---@param a EntityCategory
        ---@param b EntityCategory
        ["+"] = function(a, b)
            return a + b
        end,
        ---@param a EntityCategory
        ---@param b EntityCategory
        ["*"] = function(a, b)
            return a * b
        end,
    }

    -- Tokenise this thing...
    -- This routine isn't even _almost_ efficient.
    local currentIdentifier = ""
    categoryExpression:gsub(".", function(c)
    -- If we were collecting an identifier, we reached the end of it.
        if (OPERATORS[c] or c == " ") and currentIdentifier ~= "" then
            table.insert(tokens, currentIdentifier)
            currentIdentifier = ""
        end

        if OPERATORS[c] then
            table.insert(tokens, c)
        elseif c ~= " " then
            currentIdentifier = currentIdentifier .. c
        end
    end)
    
    -- gsub tokenizer stops before end of string character, without a chance to add the last currentidentifier as a token. So need to check once at the end if there is a remaining identifier.
    if currentIdentifier ~= "" then
        table.insert(tokens, currentIdentifier)
    end


    local numTokens = table.getn(tokens)

    local function explode(error)
        WARN("Category parsing failed for expression:")
        WARN(categoryExpression)
        WARN("Tokeniser interpretation:")
        WARN(repr(tokens))
        WARN("Error from parser:")
        WARN(debug.traceback(nil, error))
    end

    --- Given the token list and an offset, find the index of the matching bracket.
    local function findMatchingBracket(firstBracket)
        local bracketDepth = 1

        -- We're done when bracketDepth = 0, as it means we've just hit the closing bracket we want.
        local i = firstBracket + 1
        while (bracketDepth > 0 and i <= numTokens) do
            local token = tokens[i]

            if token == "(" then
                bracketDepth = bracketDepth + 1
            elseif token == ")" then
                bracketDepth = bracketDepth - 1
            end

            i = i + 1
        end

        if bracketDepth == 0 then
            return i - 1
        else
            explode("Mismatched bracket at token index " .. firstBracket)
        end
    end

    --- Given two categories and an operator token, return the result of applying the operator to
    -- the two categories (in the order given)
    ---@return EntityCategory | nil
    local function mergeCategories(currentCategory, newCategory, operator)
        -- Initialization case.
        if not operator and not currentCategory then
            return newCategory
        end

        if not OPERATOR_FUNCTIONS[operator] then
            explode("No such operator function: " .. operator .. ". This is either a parser bug or your expression is *really* fucked")
            return nil
        end

        return OPERATOR_FUNCTIONS[operator](currentCategory, newCategory)
    end

    -- Parsing time. Since Lua-operators on category objects work correctly, we simply have to
    -- translate the expression we have into those as we go along.
    ---@return EntityCategory | nil
    local function _parseSubexpression(start, finish)
        local currentCategory = nil

        -- The type of the next token we expect (want alternating identifier/operator)
        local expectingIdentifier = true

        -- The last operator encountered.
        local currentOperator = nil

        -- We need to be able to manipulate i while iterating, hence...
        local i = start
        while i <= finish do
            local token = tokens[i]
            --LOG('Parsing token: ' .. token)

            if expectingIdentifier then
                -- Bracket expressions are effectively identifiers
                if token == "(" then
                    -- Scan to the matching bracket, parse that subexpression, and current-operator
                    -- the result onto the working category.
                    local matchingBracket = findMatchingBracket(i)
                    local subcategory = _parseSubexpression(i + 1, matchingBracket - 1)
                    currentCategory = mergeCategories(currentCategory, subcategory, currentOperator)

                    -- We want i to end up beyond the bracket, and to end up *not* expecting ident,
                    -- as a bracket expression is effectively an ident.
                    i = matchingBracket
                elseif OPERATORS[token] then
                    explode("Expected category identifier, found OPERATOR " .. token)
                    return nil
                else
                    currentCategory = mergeCategories(currentCategory, ParseEntityCategory(token), currentOperator)
                end
            else
                if not OPERATORS[token] then
                    explode("Expected operator, found category identifier: " .. token)
                    return nil
                end

                currentOperator = token
            end

            expectingIdentifier = not expectingIdentifier

            i = i + 1
        end

        return currentCategory
    end
    return _parseSubexpression(1, numTokens)
end
-- converts specified category expression to a string
-- representing it in global categories or returns repr(categoryExpression)
---@param categoryExpression EntityCategory
---@return string
function ToString(categoryExpression)
    for key, value in categories or {} do
        if categoryExpression == value then
            return 'categories.' .. key
        end
    end
    -- TODO find a way to revers ParseEntityCategoryProperly and get a string
    -- representing categoryExpression, e.g. categories.TECH2 * categories.AIR
    return repr(categoryExpression)
end