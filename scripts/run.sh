#!/bin/bash
#
# Starts the app, making sure it can bind its port.
#
# Usage: scripts/run.sh [port] [pinned]
#
# If a previous instance of this app holds the port, it is stopped. If any
# other program holds it, that program is left alone and the next free port is
# used instead, unless the port is pinned, in which case this script fails.

set -euo pipefail

readonly app_name="App"
readonly project_dir="$(pwd)"
readonly preferred_port="${1:-8080}"
readonly pinned="${2:-}"
readonly max_port_attempts=100

listener_pid() {
    lsof -n -P -t -iTCP:"$1" -sTCP:LISTEN | head -n 1 || true
}

process_directory() {
    lsof -a -p "$1" -d cwd -Fn | sed -n 's/^n//p'
}

process_name() {
    basename "$(ps -p "$1" -o comm=)"
}

describe_process() {
    echo "$(process_name "$1") (PID $1, started in $(process_directory "$1"))"
}

is_previous_instance() {
    [ "$(process_name "$1")" = "$app_name" ] && [ "$(process_directory "$1")" = "$project_dir" ]
}

wait_until_free() {
    for _ in $(seq 1 50); do
        [ -z "$(listener_pid "$1")" ] && return 0
        sleep 0.1
    done

    return 1
}

stop_previous_instance() {
    local pid
    pid="$(listener_pid "$1")"

    if [ -n "$pid" ] && is_previous_instance "$pid"; then
        echo "Stopping previous instance on port $1: PID $pid" >&2
        kill "$pid"
        wait_until_free "$1" || true
    fi
}

find_free_port() {
    local port="$preferred_port"

    for _ in $(seq 1 "$max_port_attempts"); do
        stop_previous_instance "$port"

        if [ -z "$(listener_pid "$port")" ]; then
            echo "$port"
            return 0
        fi

        if [ -n "$pinned" ]; then
            break
        fi

        echo "Port $port is held by $(describe_process "$(listener_pid "$port")"), leaving it alone." >&2
        port=$((port + 1))
    done

    return 1
}

if ! port="$(find_free_port)"; then
    echo "Port $preferred_port is held by $(describe_process "$(listener_pid "$preferred_port")")." >&2
    echo "Free it or choose another port: make run PORT=<port>" >&2
    exit 1
fi

echo "Starting on http://127.0.0.1:$port"

exec swift run "$app_name" --port "$port"
