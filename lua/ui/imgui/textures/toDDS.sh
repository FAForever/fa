
# Program description: Converts all images and / or images of directories to 
# the dds format. Any number of arguments are accepted - you can drag and 
# drop folders and files and they are converted accordingly. Sub folders are
# ignored.

# Program arguments: 
#  - $@: directories or files to convert to dds

# Function description: prints out a basic progress bar to the console.

# Function arguments: 
#  - $1: maximum number of elements
#  - $2: current element index

progressBar()
{
    n="$1"
    c="$2"

    echo -n "[ "
    for ((i = 0 ; i <= c; i++)); do echo -n "#"; done
    for ((j = c ; j < n - 1 ; j++)); do echo -n " "; done
    echo -n " ] " 
    echo -n " $c/$n" $'\r'
}

for path in "$@"
do

    # convert an entire directory
    if [[ -d "$path" ]]; then 
        # determine target directory
        directory=`basename "$path"`
        parent="${path%\\*}"
        destination="$parent\\$directory-dds"

        echo "Converting folder: '$directory' to '$directory-dds'"

        # create output folder if it doesn't exist
        if [ ! -d "$destination" ]; then 
            mkdir "$destination"
        fi

        # progress bar data
        n=`ls "$path" | wc -l`
        c=0

        # for each file in the directory
        for entry in "$path/"*;
        do
            # update progress bar
            c=$(($c+1)) 
            progressBar "$n" "$c"

            # determine name of output file
            extension="${entry#*.}"
            base=`basename "$entry" ".$extension"`
            target="$destination/$base.dds"

            # check if our output is more recent
            if [[ "$entry" -nt "$target" ]] || [ ! -f "$target" ]; then
                # convert the image
                magick "$entry" -define dds:compression=dxt5 "$target"
            fi
        done

        # skip the progress bar line
        echo ""
    fi

    # convert a single file
    if [[ -f "$path" ]]; then 

        # get extension, file name and directory
        extension="${path#*.}"
        base=`basename "$path" ".$extension"`
        directory="${path%\\*}"
        target="$directory/$base.dds"

        # convert it
        if [[ "$path" -nt "$target" ]] || [ ! -f "$target" ]; then
            # convert the image
            echo "Converting file: '$base' to '$base.dds'"
            magick "$path" -define dds:compression=dxt5 "$target"
        else
            echo "Skipping file: '$base' (not updated)"
        fi
    fi
done

# Script made by (Jip) Willem Wijnia
# Licensed with (CC BY-NC-SA 4.0)
# For more information: https://creativecommons.org/licenses/by-nc-sa/4.0/
