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
#   expects no trailing backslash
#   transform pattern to valid regex
#   /  -> \/
#   .* -> *
#   ?  -> \?
#   +  -> \+
#   *  -> .*
#   '  -> ''
# insert the rules into the db
printf "%s" "${robots_txt}" \
    | sed 's/#.*$//g' \
    | sed '/^\s*$/d' \
    | tr '[:upper:]' '[:lower:]' \
    | awk 'BEGIN{RS="user-agent: "} /^lynx/{print} /^\*/{print}' \
    | awk -v domain="${domain}" \
          -v to_regex="sed 's#\x5c/#\x5c\x5c\x5c/#g' \
                        | sed 's#\x5c.\x5c*#*#g' \
                        | sed 's#\x5c?#\x5c\x5c?#g' \
                        | sed 's#\x5c+#\x5c\x5c+#g' \
                        | sed 's#\x5c*#.*#g' \
                        | sed 's#\x27\x5c\x27\x27#\x27\x5c\x27\x27\x27\x5c\x27\x27#g'" '\
        BEGIN{FS=": "} \
        /^disallow/ { \
            cmd = "printf \"%s\" \"" $2 "\" |" to_regex; \
            cmd | getline rule_pattern; \
            close(cmd); \
            print \
                "insert into \"rule\" (" \
                    "whitelist_id," \
                    "pattern," \
                    "is_allowed" \
                ") values (" \
                    "(select id from whitelist where domain = \x27" domain "\x27)," \
                    "\x27" rule_pattern "\x27, 0" \
                ");" \
        } \
        /^allow/ { \
            cmd = "printf \"%s\" \"" $2 "\" |" to_regex; \
            cmd | getline rule_pattern; \
            close(cmd); \
            print \
                "insert into \"rule\" (" \
                    "whitelist_id," \
                    "pattern," \
                    "is_allowed" \
                ") values (" \
                    "(select id from whitelist where domain = \x27" domain "\x27)," \
                    "\x27" rule_pattern "\x27, 1);"}'


