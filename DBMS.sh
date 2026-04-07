#!/bin/bash

create_db() {
    read -p "Enter Database Name: " db
    if [ -d "$db" ]; then
        echo "Database already exists"
    else
        mkdir "$db" && echo "Database created successfully"
    fi
}

list_db() {
    ls -F | grep / | tr -d '/'
}

drop_db() {
    read -p "Enter Database Name: " db
    if [ -d "$db" ]; then
        rm -r "$db" && echo "Database deleted"
    else
        echo "Database not found"
    fi
}

connect_db() {
    read -p "Enter Database Name: " db
    if [ -d "$db" ]; then
        cd "$db"
        table_menu
        cd ..
    else
        echo "Database not found"
    fi
}

get_meta() {
    if [ ! -f "$1" ]; then
        return 1
    fi
    header=$(head -1 "$1")
    cols=$(echo "$header" | sed 's/#columns: \(.*\) | pk:.*$/\1/' | xargs)
    pk_name=$(echo "$header" | sed 's/.*| pk:\(.*\)$/\1/' | xargs)
    pk_idx=$(echo "$cols" | awk -v col="$pk_name" '{for(i=1;i<=NF;i++) if($i==col) print i}')
    types=$(echo "$header" | sed 's/.*| types: \(.*\) | pk:.*$/\1/' | xargs)
    return 0
}
validate_type() {
    value=$1
    type=$2

    if [ "$type" == "int" ]; then
        [[ $value =~ ^[0-9]+$ ]] || return 1
    elif [ "$type" == "string" ]; then
        [[ $value =~ ^[a-zA-Z]+$ ]] || return 1
    fi

    return 0
}

main_menu() {
    while true; do
        echo "======== Main Menu ========"
        echo "1) Create Database"
        echo "2) List Databases"
        echo "3) Connect Database"
        echo "4) Drop Database"
        echo "5) Exit"
        read -p "Choose: " choice
        case $choice in
            1) create_db ;;
            2) list_db ;;
            3) connect_db ;;
            4) drop_db ;;
            5) exit ;;
            *) echo "Invalid Choice" ;;
        esac
    done
}

table_menu() {
    while true; do
        echo "======== Table Menu ========"
        echo "1) Create Table"
        echo "2) List Tables"
        echo "3) Drop Table"
        echo "4) Insert"
        echo "5) Select"
        echo "6) Delete"
        echo "7) Update"
        echo "8) Back"
        read -p "Choose: " choice
        case $choice in
            1) create_table ;;
            2) ls ;;
            3) drop_table ;;
            4) insert_data ;;
            5) select_data ;;
            6) delete_data ;;
            7) update_data ;;
            8) break ;;
            *) echo "Invalid Choice" ;;
        esac
    done
}

create_table() {
    read -p "Enter table name: " table
    if [ -f "$table" ]; then
        echo "Table already exists"
        return
    fi

    read -p "Enter number of columns: " num_col
    cols=""; pk=""; types=""
    for ((i=1; i<=num_col; i++)); do
        read -p "Column $i name: " col_name
        read -p "Column $i type (int/string): " type
        if [ -z "$pk" ]; then
            read -p "Is $col_name the primary key (y/n)? " is_pk
            [ "$is_pk" == "y" ] && pk="$col_name"
        fi
        cols+="$col_name "
        types+="$type "
    done
    
    cols=$(echo "$cols" | xargs)
    [ -z "$pk" ] && pk=$(echo "$cols" | cut -d' ' -f1)
    
    echo "#columns: $cols | types: $types | pk: $pk" > "$table"
    echo "Table '$table' created successfully."
}

drop_table() {
    read -p "Enter table name to drop: " table
    if [ -f "$table" ]; then
        rm "$table" && echo "Table deleted"
    else
        echo "Table not found"
    fi
}

insert_data() {
    read -p "Enter table name: " table
    if ! get_meta "$table"; then
        echo "Table not found"
        return
    fi

    row=""
    i=1
    for c in $cols; do
        type=$(echo "$types" | awk -v idx="$i" '{print $idx}')
        read -p "Enter value for $c: " val
        if ! validate_type "$val" "$type"; then
            echo "Invalid type for $c Expected $type"
            return
        fi
        if [ "$c" == "$pk_name" ]; then
            idx=$(echo "$cols" | awk -v col="$c" '{for(i=1;i<=NF;i++) if($i==col) print i}')
            if tail -n +2 "$table" | cut -d':' -f"$idx" | grep -q "^$val$"; then
                echo "Error: Primary key '$val' already exists"
                return
            fi
        fi
        row+="$val:"
        ((i++))
    done
    echo "${row%:}" >> "$table"
    echo "Data inserted."
}

select_data() {
    read -p "Enter table name: " table
    if ! get_meta "$table"; then
        echo "Table not found"
        return
    fi
    echo "------------------------------------------------"
    echo " $cols "
    echo "------------------------------------------------"
    tail -n +2 "$table" | column -t -s ":"
}

update_data() {
    read -p "Enter table name: " table
    if ! get_meta "$table"; then
        echo "Table not found"
        return
    fi

    read -p "Enter $pk_name value to identify row: " pk_val
    read -p "Enter column name to update: " col
    read -p "Enter new value: " val
    
    idx=$(echo "$cols" | awk -v col="$col" '{for(i=1;i<=NF;i++) if($i==col) print i}')
    if [ -z "$idx" ]; then
        echo "Column not found"
        return
    fi
    
    tmp=$(mktemp)
    head -1 "$table" > "$tmp"
    tail -n +2 "$table" | awk -F':' -v pi="$pk_idx" -v pv="$pk_val" -v ci="$idx" -v nv="$val" 'BEGIN{OFS=":"} {if($pi==pv) $ci=nv; print $0}' >> "$tmp"
    mv "$tmp" "$table"
    echo "Record updated."
}

delete_data() {
    read -p "Enter table name: " table
    if ! get_meta "$table"; then
        echo "Table not found"
        return
    fi

    read -p "Enter $pk_name value to delete: " val
    tmp=$(mktemp)
    head -1 "$table" > "$tmp"
    tail -n +2 "$table" | awk -F':' -v idx="$pk_idx" -v val="$val" '$idx != val' >> "$tmp"
    mv "$tmp" "$table"
    echo "Record deleted."
}
main_menu