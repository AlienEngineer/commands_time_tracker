# ==============================================================================
# Zsh Command Tracking Script
# Logs execution duration and success/failure status of development commands
# to a specified file.
# ==============================================================================

zmodload zsh/datetime # Required for high-precision time tracking

LOG_FILE="$HOME/track_build_metrics.txt"
DATE_FORMAT="%Y-%m-%d %H:%M:%S"

# Converts raw float duration (seconds) into human-readable HHh MMm SSs
format_time() {
    local -i total=$(( $1 + 0.5 )) 
    local h=$(( total / 3600 ))
    local m=$(( (total % 3600) / 60 ))
    local s=$(( total % 60 ))
    
    if (( h > 0 )); then printf "%dh %dm %ds" $h $m $s
    elif (( m > 0 )); then printf "%dm %ds" $m $s
    else printf "%ds" $s; fi
}

# Hook: Triggers BEFORE a command executes
preexec_track_metrics() {
    local cmd="$1"

    # Validation: Check if the current directory ($PWD) contains the required 
    # folder defined in the $TRACK_FOLDER environment variable.
    # If $TRACK_FOLDER is not set, tracking applies globally.
    local is_in_tracked_path=true
    if [[ -n "$TRACK_FOLDER" ]]; then
        [[ "$PWD" != *"$TRACK_FOLDER"* ]] && is_in_tracked_path=false
    fi

    # Filter: Track command ONLY if it matches specific keywords AND we are in 
    # the correct folder (or folder validation is disabled/not required).
    if [[ "$cmd" =~ (flutter|dart|make|pod|gradle|cache) ]] && [[ "$is_in_tracked_path" = true ]]; then
        _TRACK_CMD="$cmd"
        _STEP_START=$EPOCHREALTIME # Capture start time with nanosecond precision
    else
        unset _TRACK_CMD
        unset _STEP_START
    fi
}

# Hook: Triggers AFTER a command finishes
precmd_track_metrics() {
    # Check if we have active tracking state from the preexec hook
    if [[ -n "$_TRACK_CMD" && -n "$_STEP_START" ]]; then
        local end_step=$EPOCHREALTIME
        local duration_raw=$(( end_step - _STEP_START ))
        local duration_pretty=$(format_time $duration_raw)
        
        # Determine command success based on Zsh exit status ($?)
        local cmd_status="SUCCESS"
        [[ $? -ne 0 ]] && cmd_status="FAILED"

        # Ensure log file exists with header
        local header="TIMESTAMP           | COMMAND                        | STATUS  | DURATION"
        if [[ ! -f "$LOG_FILE" ]]; then
            echo "$header" > "$LOG_FILE"
            echo "--------------------------------------------------------------------------" >> "$LOG_FILE"
        fi
        
        # Append metrics to log
        printf "%-19s | %-30s | %-7s | %s\n" \
            "$(date +"$DATE_FORMAT")" \
            "${_TRACK_CMD:0:30}" \
            "$cmd_status" \
            "$duration_pretty" >> "$LOG_FILE"
    
        # Clean up variables to prevent stale tracking
        unset _TRACK_CMD
        unset _STEP_START
    fi
}

# 
# Registration: Attach functions to Zsh execution hooks
autoload -Uz add-zsh-hook
add-zsh-hook preexec preexec_track_metrics
add-zsh-hook precmd precmd_track_metrics