#!/usr/bin/env bash
# $1: delimiter
# $2: text
split_by() {
        res=$(echo "$2" | tr "$1" "\n")
        echo $res
}

# $1: string as array
last() {
        arr=($1)
        res=${arr[${#arr[@]} - 1]}
        echo "$res"
}

# $1: file to search for
# $2: dir to search in
icon_in_dir () {
        if [ -d "$2" ]
        then
                search=$(find "$2" -name "$1.*")
                if [ -n "$search" ]
                then
                        echo $(last "$search")
                fi

                # Search for exacts too
                esearch=$(find "$2" -name "$1")
                if [ -n "$esearch" ]
                then
                        echo $(last "$esearch")
                fi
        fi
}

# $1: file to search for
icon_by_name () {
        # Check if the file exists
        file="$1"
        if [ -f "$file" ]
        then
                echo "$file"
                return 0
        fi

        # Check if it's contained in $HOME/.icons
        result=$(icon_in_dir "$file" "$HOME/.icons/hicolor")
        if [ -n "$result" ]
        then
                echo "$result"
                return 0
        fi

        # Check XDG_DATA_DIRS
        # Deviate from the official way at https://specifications.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html
        # Check hicolor and then every theme (at random) without respecting parent relations
        # Feel free to implement the official way - this has good enough balance of result/effort

        xdg_dirs_var=$XDG_DATA_DIRS
        if [ -z "$xdg_dirs_var" ]
        then
                xdg_dirs_var=/usr/local/share/:/usr/share/
        fi
        xdg_dirs=$(split_by ":" "$xdg_dirs_var") #replace the colon delimiter with new line to process it like an array
        for dir in $xdg_dirs
        do
                res=$(icon_in_dir "$file" "$dir/icons/hicolor")
                if [ -n "$res" ]
                then
                        echo "$res"
                        return 0
                fi
        done

        for dir in $xdg_dirs
        do
                res=$(icon_in_dir "$file" "$dir/icons/")
                if [ -n "$res" ]
                then
                        echo "$res"
                        return 0
                fi
        done

        # Check /usr/share/pixmaps
        result=$(icon_in_dir "$file" "/usr/share/pixmaps")
        if [ -n "$result" ]
        then
                echo "$result"
                return 0
        fi
}

# $1: prop name
# $2: desktop file contents
get_desktop_prop () {
	prop="$1"
	contents="$2"
	while IFS= read -r line # reads line by line ignoring backslash (IFS=)
	do
  		if [[ $line == $prop=* ]]
                then
			echo $line | cut -d'=' -f 2 # splits by -d and takes the -f-th string (not 0-based)
			return 0
                fi
	done < <(echo "$contents") # Pass contents to read
}

# Details for the Rofi script format can be found here: https://www.mankier.com/5/rofi-script

# Item picked
if [ -n "$2" ]
then
        target="$2"
fi

# First run
dir="$1"
if [ -z "$dir" ]
then
	exit 127;
fi

files=$(ls "$dir")

for file in $files
do
	if [[ ! $file == *.desktop ]]
	then
		continue
	fi

	if [ -z "$target" ]
	then
		# extract desktop info
		contents=$(cat "$dir/$file")

		nodisplay=$(get_desktop_prop NoDisplay "$contents")
		if [[ "$nodisplay" == 'true' ]]
		then
			continue
		fi

		name=$(get_desktop_prop Name "$contents")
		icon_d=$(get_desktop_prop Icon "$contents")
		icon=$(icon_by_name "$icon_d")

		echo -en "$name\0icon\x1f$icon\x1finfo\x1f$file\n"
	else
		# file selected
		if [[ $file == $ROFI_INFO ]]
		then
			contents=$(cat "$dir/$file")
			exe=$(get_desktop_prop Exec "$contents")
			coproc bash -c "i3-msg 'exec $exe'"
			exit
		fi
	fi
done
