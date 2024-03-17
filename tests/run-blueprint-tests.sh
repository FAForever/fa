#******************************************************************************************************
#** Copyright (c) 2024 FAForever
#**
#** Permission is hereby granted, free of charge, to any person obtaining a copy
#** of this software and associated documentation files (the "Software"), to deal
#** in the Software without restriction, including without limitation the rights
#** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#** copies of the Software, and to permit persons to whom the Software is
#** furnished to do so, subject to the following conditions:
#**
#** The above copyright notice and this permission notice shall be included in all
#** copies or substantial portions of the Software.
#**
#** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#** SOFTWARE.
#******************************************************************************************************

# Sanity checks on the unit blueprint files. We need to do a few hacks here
# because we can't easily iterate over all the blueprint files in Lua. 

# Because of that we first generate a file that acts as a list to all the
# blueprint files. This file is essentially one large table. The Lua
# files can then read this table and load in the blueprints that we wish
# to run tests on.

directoryWithUnitBlueprints="./units"
generateListOfUnitBlueprints="./tests/generated/unit-blueprint-list.lua"

if [ ! -d "$directoryWithUnitBlueprints" ]; then
    echo "Error: Directory $directoryWithUnitBlueprints not found."
    exit 1
fi

# Create the directory that will store the generated files
mkdir "./tests/generated"

# -----------------------------------------------------------------------------
# Create the file that will store a reference to all unit blueprints

declare -A lua_files

# Iterate over Lua files in the directory
for file in "$directoryWithUnitBlueprints"/*/*.bp; do
    if [ -f "$file" ]; then

        # Add the file to the Lua table
        filename=$(basename "$file")
        lua_files["$filename"]=$file
    fi
done

# Generate Lua table
lua_table="Files = {\n"
for key in "${!lua_files[@]}"; do
    lua_table="$lua_table \"${lua_files[$key]}\",\n"
done

lua_table="$lua_table}\n"

# Write Lua table to disk
echo -e "$lua_table" >"$generateListOfUnitBlueprints"

echo "Lua table written to $generateListOfUnitBlueprints"

# -----------------------------------------------------------------------------
# Run the tests

had_error=0
tests_complete=0

run_test() {
    file="$1"

    output="$(lua "$file" 2>&1 |
        sed "s:/dev/fd/[0-9]\+:$file:g")"

    if [[ $output != "" ]]; then
        echo "$output" >/dev/fd/2
        if [[ "$output" == *"FAIL"* || "$output" == *"lua:"* ]]; then
            had_error=1
        fi
    fi
}

run_test "./tests/blueprint/unit.spec.lua"

if [[ $had_error != 0 ]]; then
    echo "Tests returned errors."
    exit $had_error
else
    echo "Tests OK."
fi

echo "${lua--help}"
