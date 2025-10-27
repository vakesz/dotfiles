# Description: Python aliases and virtual environment helpers
# Dependencies: python3 (system or Homebrew)

# ============================================================================
# Python Aliases & Functions
# ============================================================================
# Ensure python and python3 always point to Python 3
# Use python3.13 specifically if it exists, otherwise fall back to python3
if command -v python3.13 >/dev/null 2>&1; then
    alias python='python3.13'
    alias python3='python3.13'
    alias py='python3.13'
    alias pip='pip3.13'
    alias pip3='pip3.13'
    _PYTHON_CMD='python3.13'
else
    alias python='python3'
    alias py='python3'
    alias pip='pip3'
    _PYTHON_CMD='python3'
fi

# Quick virtual environment activation
venv() {
    # If .venv exists but activation script is missing, remove it (corrupted)
    if [ -d .venv ] && [ ! -f .venv/bin/activate ]; then
        echo "Removing corrupted .venv directory..."
        rm -rf .venv
    fi
    
    # Create .venv if it doesn't exist
    [ -d .venv ] || $_PYTHON_CMD -m venv .venv
    source .venv/bin/activate
}
