for d in */ ; do
    if [ -d "$d" ]; then

        echo "$d"
        cd "$d"

        pwd
        rm *.dds
        rm *.sca
        rm *.scm

        cd ..
    fi
done

read
