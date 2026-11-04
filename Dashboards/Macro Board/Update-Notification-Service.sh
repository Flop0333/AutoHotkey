#!/usr/bin/env bash
set -uo pipefail

notify() {
    UPDATE_MESSAGE="$1" powershell.exe -NoProfile -File "$(cygpath -w "$(dirname "$0")/Show-UpdateNotification.ps1")"
}

fail() {
    printf '\nUPDATE MISLUKT: %s\n' "$1" >&2
    notify "Update Notification Service mislukt: $1"
    read -r -p 'Git Bash blijft open. Druk op Enter om dit venster te sluiten. ' _
    exit 1
}

run_checked() {
    local output_file output status
    output_file=$(mktemp) || fail 'Kan geen tijdelijk uitvoerbestand maken.'
    "$@" 2>&1 | tee "$output_file"
    status=${PIPESTATUS[0]}
    output=$(cat "$output_file")
    rm -f "$output_file"
    if (( status != 0 )); then
        fail "${*} (exit $status). Laatste uitvoer: $(printf '%s\n' "$output" | tail -n 25)"
    fi
    REPLY="$output"
}

cd /c/Notification-Service || fail 'Map /c/Notification-Service is niet bereikbaar.'
run_checked git status --short
[[ -z "$REPLY" ]] || printf 'Lokale wijzigingen blijven behouden.\n'
run_checked git branch --show-current
[[ "$REPLY" == main ]] || fail "Huidige branch is '$REPLY'; schakel eerst naar main."

run_checked docker ps --all --quiet --filter label=com.docker.compose.project=notification-service --filter label=com.docker.compose.service=api
container=${REPLY%%$'\n'*}
[[ -n "$container" ]] || fail 'Geen bestaande Notification Service-productiecontainer gevonden.'
run_checked docker inspect --format '{{ index .Config.Labels "com.docker.compose.project.environment_file" }}' "$container"
[[ -n "$REPLY" && "$REPLY" != '<no value>' ]] || fail 'Het productie-env-bestand ontbreekt in de Docker Compose-labels.'
env_file=$(cygpath -u "$REPLY") || fail 'Het pad naar het productie-env-bestand is ongeldig.'
[[ -r "$env_file" ]] || fail "Productie-env-bestand is niet leesbaar: $env_file"
export COMPOSE_FILE=compose.production.yml COMPOSE_PROJECT_NAME=notification-service
compose=(docker compose --env-file "$env_file" -f compose.production.yml)
run_checked scripts/backup-postgres.sh "$env_file"
run_checked git pull --ff-only origin main

run_checked scripts/migrate-production.sh "$env_file"
run_checked "${compose[@]}" up -d --build --force-recreate --wait --wait-timeout 300
run_checked "${compose[@]}" ps
ps_output=$REPLY
run_checked "${compose[@]}" config --services
expected=$REPLY
run_checked "${compose[@]}" ps --status running --services
running=$REPLY
[[ -n "$expected" ]] || fail 'Docker Compose heeft geen services gevonden.'
while IFS= read -r service; do
    [[ -z "$service" ]] || grep -Fxq -- "$service" <<< "$running" || fail "Compose-service '$service' draait niet. docker compose ps: $ps_output"
done <<< "$expected"

notify 'Notification Service is bijgewerkt en opnieuw gestart'
