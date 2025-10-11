#!/bin/sh
set -e

# Pre-commit hook to automatically update README.md with directory structure
# This ensures the documentation stays up-to-date with the repository structure

# Check if tree command is available
if ! command -v tree >/dev/null 2>&1; then
  echo "⚠️  Warning: 'tree' command not found. Skipping directory structure update."
  echo "   Install tree to enable automatic README updates."
  exit 0
fi

# Define markers for the directory structure section
START_MARKER="<!-- DIRECTORY_STRUCTURE_START -->"
END_MARKER="<!-- DIRECTORY_STRUCTURE_END -->"

# Generate the directory structure
# Exclude: .git, result*, .cache, tmp, node_modules, and other build artifacts
TREE_OUTPUT=$(tree -a -I '.git|result*|.cache|tmp|node_modules|dist|build|__pycache__|*.pyc' --charset ascii)

# Create temporary file for the new README content
TEMP_FILE=$(mktemp)

# Check if markers exist in README.md
if grep -q "$START_MARKER" README.md && grep -q "$END_MARKER" README.md; then
  # Markers exist, update the section
  awk -v start="$START_MARKER" -v end="$END_MARKER" -v tree="$TREE_OUTPUT" '
    BEGIN { in_section=0 }
    $0 ~ start { 
      print $0
      print ""
      print "```"
      print tree
      print "```"
      print ""
      in_section=1
      next
    }
    $0 ~ end { in_section=0 }
    !in_section { print }
  ' README.md > "$TEMP_FILE"
else
  # Markers don't exist, append the section before the last line if it's empty, or at the end
  {
    cat README.md
    echo ""
    echo "$START_MARKER"
    echo ""
    echo '```'
    echo "$TREE_OUTPUT"
    echo '```'
    echo ""
    echo "$END_MARKER"
  } > "$TEMP_FILE"
fi

# Replace README.md with updated content
mv "$TEMP_FILE" README.md

# Stage the updated README.md
git add README.md

echo "✅ README.md updated with current directory structure"

exit 0
