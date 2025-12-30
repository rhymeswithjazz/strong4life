#!/bin/sh
# Setup git hooks for the project

echo "Setting up git hooks..."

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# Pre-commit hook that runs mix format on staged Elixir files

# Get list of staged .ex and .exs files
STAGED_EX_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.exs\?$')

if [ -n "$STAGED_EX_FILES" ]; then
  echo "Running mix format on staged files..."
  mix format $STAGED_EX_FILES

  # Re-add formatted files to staging
  echo "$STAGED_EX_FILES" | xargs git add

  echo "✓ Code formatted successfully"
fi

exit 0
EOF

# Make it executable
chmod +x .git/hooks/pre-commit

echo "✓ Git hooks installed successfully"
echo ""
echo "The pre-commit hook will automatically format Elixir files before each commit."
