#!/bin/bash
# expects no trailing backslash
to_regex()
{
    # transform pattern to valid regex
    # /  -> \/
    # .* -> *
    # ?  -> \?
    # +  -> \+
    # *  -> .*
    # '  -> ''
    sed 's/\//\\\//g' \
        | sed 's/\.\*/*/g' \
        | sed 's/\?/\\?/g' \
        | sed 's/\+/\\+/g' \
        | sed 's/\*/.*/g' \
        | sed 's/\x27/\x27\x27/g'
}

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
    | awk 'BEGIN{RS="user-agent: "} /^Lynx/{print} /^\*/{print}' \
    | awk -v domain="${domain}" '
        BEGIN{FS=": "}
        /^disallow/ { \
            print \
                "insert into rule (" \
                    "whitelist_id," \
                    "rule," \
                    "is_allowed" \
                ") values (" \
                    "(select id from whitelist where domain = \x27" domain "\x27)," \
                    "\x27" $2 "\x27, 0" \
                ");" \
        } \
        /^allow/ { \
            print \
                "insert into rule (" \
                    "whitelist_id," \
                    "rule," \
                    "is_allowed" \
                ") values (" \
                    "(select id from whitelist where domain = \x27" domain "\x27)," \
                    "\x27" $2 "\x27, 1);"}'


