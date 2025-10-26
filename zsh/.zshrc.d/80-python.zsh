# Description: Python aliases and virtual environment helpers
# Dependencies: python3.13

# ============================================================================
# Python Aliases & Functions
# ============================================================================
# Ensure python and python3 always point to Python 3.13
alias python='python3.13'
alias python3='python3.13'
alias py='python3.13'
alias pip='pip3.13'
alias pip3='pip3.13'

# Quick virtual environment activation
venv() {
    [ -d .venv ] || python3.13 -m venv .venv
    source .venv/bin/activate
}
