#!/usr/bin/env bash

set -euo pipefail

# Check if the script was called with no arguments and show help in that case
if [ $# -eq 0 ]; then
    cat <<EOF
Usage: $0 --project-name PROJECT_NAME --input-file INPUT_FILE --vim-version VIM_VERSION --toc TOC --description DESCRIPTION --dedup-subheadings DEDUP_SUBHEADINGS --treesitter TREESITTER

Arguments:
  --project-name: the name of the project
  --input-file: the input markdown file
  --vim-version: the version of Vim that the project is compatible with
  --toc: 'true' if the output should include a table of contents, 'false' otherwise
  --description: a description of the project
  --dedup-subheadings: 'true' if duplicate subheadings should be removed, 'false' otherwise
  --demojify: 'false' if emojis should not be removed, 'true' otherwise
  --treesitter: 'true' if the project uses Tree-sitter syntax highlighting, 'false' otherwise
  --ignore-rawblocks: 'true' if the project should ignore HTML raw blocks, 'false' otherwise
  --doc-mapping: 'false' if h4 headings should double as mapping docs, 'true' otherwise
  --doc-mapping-project-name: 'true' if tags generated for mapping docs contain project name, 'false' otherwise
  --shift-heading-level-by: 0 if you don't want to shift heading levels , n otherwise
  --increment-heading-level-by: 0 if don't want to increment the starting heading number, n otherwise
EOF
    exit 0
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    --project-name)
        PROJECT_NAME="$2"
        shift # past argument
        shift # past value
        ;;
    --input-file)
        INPUT_FILE="$2"
        shift # past argument
        shift # past value
        ;;
    --vim-version)
        VIM_VERSION="$2"
        shift # past argument
        shift # past value
        ;;
    --toc)
        TOC="$2"
        shift # past argument
        shift # past value
        ;;
    --description)
        DESCRIPTION="$2"
        shift # past argument
        shift # past value
        ;;
    --dedup-subheadings)
        DEDUP_SUBHEADINGS="$2"
        shift # past argument
        shift # past value
        ;;
    --ignore-rawblocks)
        IGNORE_RAWBLOCKS="$2"
        shift # past argument
        shift # past value
        ;;
    --doc-mapping)
        DOC_MAPPING="$2"
        shift # past argument
        shift # past value
        ;;
    --doc-mapping-project-name)
        DOC_MAPPING_PROJECT_NAME="$2"
        shift # past argument
        shift # past value
        ;;
    --demojify)
        DEMOJIFY="$2"
        shift # past argument
        shift # past value
        ;;
    --treesitter)
        TREESITTER="$2"
        shift # past argument
        shift # past value
        ;;
    --shift-heading-level-by)
        SHIFT_HEADING_LEVEL_BY="$2"
        shift # past argument
        shift # past value
        ;;
    --increment-heading-level-by)
        INCREMENT_HEADING_LEVEL_BY="$2"
        shift # past argument
        shift # past value
        ;;
    *) # unknown option
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Check if /scripts directory exists
if [ -d "/scripts" ]; then
    SCRIPTS_DIR="/scripts"
else
    SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")/scripts"
fi

# If the scripts folder doesn't exist, throw an error
if [ ! -d "$SCRIPTS_DIR" ]; then
    printf "%s\n" "Error: $SCRIPTS_DIR directory not found."
    exit 1
fi

# Define arguments in an array
ARGS=(
    "--shift-heading-level-by=${SHIFT_HEADING_LEVEL_BY:-0}"
    "--metadata=project:$PROJECT_NAME"
    "--metadata=vimversion:${VIM_VERSION:-""}"
    "--metadata=toc:${TOC:-true}"
    "--metadata=description:${DESCRIPTION:-""}"
    "--metadata=dedupsubheadings:${DEDUP_SUBHEADINGS:-true}"
    "--metadata=ignorerawblocks:${IGNORE_RAWBLOCKS:-true}"
    "--metadata=docmapping:${DOC_MAPPING:-false}"
    "--metadata=docmappingproject:${DOC_MAPPING_PROJECT_NAME:-true}"
    "--metadata=treesitter:${TREESITTER:-true}"
    "--metadata=incrementheadinglevelby:${INCREMENT_HEADING_LEVEL_BY:-0}"
    "--lua-filter=$SCRIPTS_DIR/skip-blocks.lua"
    "--lua-filter=$SCRIPTS_DIR/include-files.lua"
)

# Add an additional lua filter if demojify is true
if [[ ${DEMOJIFY:-false} == "true" ]]; then
    ARGS+=(
        "--lua-filter=$SCRIPTS_DIR/remove-emojis.lua"
    )
fi

ARGS+=("-t" "$SCRIPTS_DIR/panvimdoc.lua")

# Print and execute the command
printf "%s\n" "pandoc --citeproc ${ARGS[*]} $INPUT_FILE -o doc/$PROJECT_NAME.txt"
pandoc "${ARGS[@]}" "$INPUT_FILE" -o "doc/$PROJECT_NAME.txt"
