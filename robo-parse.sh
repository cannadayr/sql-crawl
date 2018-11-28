#!/bin/bash

domain="$1"

robots_url="${domain}/robots.txt"

robots_txt=$(wget -qO- ${robots_url})

#echo "${robots_txt}"

# strip all the comments
# strip all the empty lines
# convert input to lowercase
# get the rules for the following user-agent sections:
#   Lynx*, *,
# get the disallowed paths & convert to regex pattern
# insert the rules into the db
printf "%s" "${robots_txt}" \
    | sed 's/#.*$//g' \
    | sed '/^\s*$/d' \
    | tr '[:upper:]' '[:lower:]' \
    | tr -d '\015' \
    | awk 'BEGIN{RS="user-agent: "} /^lynx/{print} /^\*/{print}' \
    | awk -v domain="${domain}" '\
        BEGIN{FS=": "} \
        /^disallow/ { \
            print \
                "insert into \"rule\" (" \
                    "whitelist_id," \
                    "pattern," \
                    "is_allowed" \
                ") values (" \
                    "(select id from whitelist where domain = \x27" domain "\x27)," \
                    "\x27" $2 "\x27, 0" \
                ");" \
        } \
        /^allow/ { \
            print \
                "insert into \"rule\" (" \
                    "whitelist_id," \
                    "pattern," \
                    "is_allowed" \
                ") values (" \
                    "(select id from whitelist where domain = \x27" domain "\x27)," \
                    "\x27" $2 "\x27, 1);"}'


