#!/usr/bin/env jq
# This is a collection of filters for `jq`, intended to manipulate JSON objects
# into JSON representing a website index, for further processing in a template.

# Convert "truthy" value to actual boolean.
def bool:
    (. == {} or . == [] or . == false or . == null or . == 0) | not
;


# Group the values of properties of an array of objects. For example, [{"a":1,
# "b":2}, {"a":3}] turns into {"a":[1, 3], "b":[3]}. This can be used to
# partition an array; example: [1,2,3] | map({(.%2|tostring):.}) | group
def group:
    reduce ([.[] | to_entries[]] | group_by(.key))[] as $group
    ( {} 
    ; .[ $group[0].key ] |= (. // []) + [ $group[].value ] 
    )
;


# Insert a child element at a particular path.
# Like `setpath/2`, but instead of making objects like `{"a":{"b":{…}}}`, this
# makes objects like `{"contents":[{"name":"a", "contents":[{"name":"b",…}]}]}`
def insert($path; $child):
    if ($path | length) > 0 then
        if ([.contents[]? | select(.name == $path[0])] | length) > 0 then
            (.contents[] | select(.name == $path[0])) |= (. | insert($path[1:]; $child))
        else
            (.contents |= (. // []) + [ {} | .name = $path[0] | insert($path[1:]; $child)])
        end
    else
        . * $child
    end
;


# Merge together `filetree.json` and `*.meta.json` files, with behaviour
# depending on the filename of the object. Use with the `--null-input` switch.
def process_files:
    reduce inputs as $input
        (   {}
        ;   ($input | input_filename) as $f |
            if ($f | endswith(".meta.json")) then 
                insert
                ( $f | ltrimstr($prefix) | rtrimstr(".meta.json") | split("/")
                ; {"meta": $input} )
            else 
                reduce $input[] as $entry
                ( .
                ;   insert
                    ( $entry.path | split("/")
                    ; $entry )
                )
            end
        )
;


# Any page gets a link to its HTML.
def add_links:
    if (has("path") and (.path | endswith(".md"))) then
        .link = (.path | rtrimstr(".md") | . + ".html")
    else
        .contents[]? |= add_links
    end
;


# Front matter is the page to be associated with the enclosing directory rather
# than itself.
def add_frontmatter:
    if has("contents") then
        ( .contents | map({(.name=="index.md" or .meta.frontmatter|tostring):.}) | group) as {$true, $false}
        | .frontmatter = $true[0]
        | .contents = ($false + $true[1:])
        | (.contents[]? |= add_frontmatter)
    else
        .
    end
;


# If marked as such, drafts can be excluded from being uploaded and included
# in the table of contents.
def add_drafts:
    if has("contents") then
        ( .contents | map({(.meta.draft|bool|tostring):.}) | group) as {$true, $false}
        | .contents = ($false // [])
        | .drafts = ($true // [])
        | (.contents[]? |= add_drafts)
    else
        .
    end
;


# A resource is anything that is neither a directory nor a page with metadata.
def add_resources:
    if has("contents") then
        ( .contents | map({(has("meta") or has("contents")|tostring):.}) | group) as {$true, $false}
        | .contents = ($true // [])
        | .resources = ($false // [])
        | (.contents[]? |= add_resources)
    else
        .
    end;


# Combines the given stream of JSON objects by merging them, and performs the
# given operations to turn it into a proper index.
def index:
    process_files
    | add_links
    | add_frontmatter
    | add_drafts
    | add_resources
;
