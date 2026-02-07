#!/usr/bin/env bats
# Integration tests for keyenv-action against live API
# These tests require KEYENV_API_URL and KEYENV_TOKEN environment variables

setup() {
    # Skip if not in integration test environment
    if [[ -z "${KEYENV_API_URL:-}" ]] || [[ -z "${KEYENV_TOKEN:-}" ]]; then
        skip "KEYENV_API_URL and KEYENV_TOKEN required for integration tests"
    fi
    export KEYENV_PROJECT="${KEYENV_PROJECT:-sdk-test}"
}

# =============================================================================
# Authentication Tests
# =============================================================================

@test "fetch /users/me with valid token returns 200" {
    run curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${KEYENV_TOKEN}" \
        -H "Content-Type: application/json" \
        "${KEYENV_API_URL}/api/v1/users/me"
    [ "$status" -eq 0 ]
    [ "$output" = "200" ]
}

@test "invalid token returns 401" {
    run curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer invalid_token_12345" \
        -H "Content-Type: application/json" \
        "${KEYENV_API_URL}/api/v1/users/me"
    [ "$status" -eq 0 ]
    [ "$output" = "401" ]
}

# =============================================================================
# Secrets Export Tests
# =============================================================================

@test "export secrets returns secrets array" {
    # First get the project ID from /users/me
    local user_response
    user_response=$(curl -s \
        -H "Authorization: Bearer ${KEYENV_TOKEN}" \
        -H "Content-Type: application/json" \
        "${KEYENV_API_URL}/api/v1/users/me")

    local project_id
    project_id=$(echo "${user_response}" | jq -r '.project_ids[0] // empty')
    [ -n "$project_id" ]

    # Fetch secrets for development environment
    local http_code
    local body
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer ${KEYENV_TOKEN}" \
        -H "Content-Type: application/json" \
        "${KEYENV_API_URL}/api/v1/projects/${project_id}/environments/development/secrets/export")

    http_code=$(echo "${response}" | tail -n 1)
    body=$(echo "${response}" | sed '$d')

    [ "$http_code" = "200" ]
    echo "${body}" | jq -e '.secrets' > /dev/null
}

@test "non-existent project returns 404" {
    run curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${KEYENV_TOKEN}" \
        -H "Content-Type: application/json" \
        "${KEYENV_API_URL}/api/v1/projects/non-existent-project-id/environments/development/secrets/export"
    [ "$status" -eq 0 ]
    [ "$output" = "404" ]
}
