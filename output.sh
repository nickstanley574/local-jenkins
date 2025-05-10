# Handle different types of logging and output formatting.
# - info: Outputs standard informational messages, prefixed with the script name.
# - debug: Outputs debug messages if the DEBUG environment variable is set.
# - verbose: Outputs verbose messages if the VERBOSE environment variable is set.
# - warn: Outputs warning messages, highlighted in yellow.
# - error: Outputs error messages, highlighted in bold red.
# Color codes are defined for red, yellow, and no color (NC) to format the outputs.

script_name=$(basename "$0")
script_name="${script_name%.*}"

REDB='\033[1;31m'   # Bold Red
YELLOW='\033[0;33m' # Yellow
CYAN='\033[0;36m'
NC='\033[0m'        # No Color

# Function to check if verbose mode is enabled
is_verbose() { [[ "$VERBOSE" -eq 1 ]] }

is_quiet() { [[ "$QUIET" -eq 1 ]] }


console_log() {
  prefix="[$script_name] "
  echo -e "$2$prefix$1$NC"
}

info() {
  if ! is_quiet; then
    console_log "$1" "$NC"
  fi
}

quiet() {
  console_log "$1" "$NC"
}

debug() {
  if [ $DEBUG -ge 1 ]; then
    console_log "$1" "$NC"
  fi
}

verbose() {
  if is_verbose; then
    console_log "$1" "$NC"
  fi
}

notice() {
  if ! is_quiet; then
    console_log "$1" "$CYAN"
  fi
}

warn() {
  console_log "$1" "$YELLOW"
}

error() {
  console_log "$1" "$REDB"
}