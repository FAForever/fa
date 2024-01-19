# sanity checks on the unit blueprint files

directory="./units"
output_file="./tests/blueprints/generated-unit-blueprint-list.lua"

# Check if the directory exists
if [ ! -d "$directory" ]; then
    echo "Error: Directory $directory not found."
    exit 1
fi

# Create an associative array to store file paths
declare -A lua_files

# Iterate over Lua files in the directory
for file in "$directory"/*/*.bp; do
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
echo -e "$lua_table" >"$output_file"

echo "Lua table written to $output_file"

# Run the tests

had_error=0
tests_complete=0

run_test() {
    file="$1"

    output="$(lua "$file" 2>&1 |
        sed "s:/dev/fd/[0-9]\+:$file:g")"

    if [[ $output != "" ]]; then
        echo "$output" >/dev/fd/2
        if [[ "$output" == *"FAIL"* || "$output" == *"stack traceback"* ]]; then
            had_error=1
        fi
    fi
}

run_test "./tests/unit.spec.lua"

if [[ $had_error != 0 ]]; then
    echo "Tests returned errors."
    exit $had_error
else
    echo "Tests OK."
fi

  echo "${lua --help}"