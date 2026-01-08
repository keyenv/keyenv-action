#!/usr/bin/env bats
# Tests for KeyEnv GitHub Action bash functions

# Load the library
setup() {
  load '../lib/keyenv.sh'
}

# =============================================================================
# Input Validation Tests
# =============================================================================

@test "validate_inputs fails without token" {
  run validate_inputs "" "production"
  [ "$status" -eq 1 ]
  [[ "$output" == *"token"*"required"* ]]
}

@test "validate_inputs fails without environment" {
  run validate_inputs "test-token" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"environment"*"required"* ]]
}

@test "validate_inputs succeeds with valid inputs" {
  run validate_inputs "test-token" "production"
  [ "$status" -eq 0 ]
}

# =============================================================================
# API Response Parsing Tests
# =============================================================================

@test "parse_user_response extracts project_id" {
  local response='{"id":"user-1","email":"test@example.com","project_id":"proj-123"}'
  run parse_user_response "$response"
  [ "$status" -eq 0 ]
  [ "$output" = "proj-123" ]
}

@test "parse_user_response returns empty for missing project_id" {
  local response='{"id":"user-1","email":"test@example.com"}'
  run parse_user_response "$response"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "parse_secrets_response extracts secrets array" {
  local response='{"secrets":[{"key":"FOO","value":"bar"},{"key":"BAZ","value":"qux"}]}'
  run parse_secrets_response "$response"
  [ "$status" -eq 0 ]
  [[ "$output" == *"FOO"* ]]
  [[ "$output" == *"BAZ"* ]]
}

@test "parse_secrets_response fails on invalid JSON" {
  local response='{"invalid":"response"}'
  run parse_secrets_response "$response"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid response"* ]]
}

@test "get_secret_count returns correct count" {
  local response='{"secrets":[{"key":"A","value":"1"},{"key":"B","value":"2"},{"key":"C","value":"3"}]}'
  run get_secret_count "$response"
  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}

@test "get_secret_count returns zero for empty secrets" {
  local response='{"secrets":[]}'
  run get_secret_count "$response"
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

# =============================================================================
# .env File Generation Tests
# =============================================================================

@test "format_env_line handles simple values" {
  run format_env_line "DATABASE_URL" "postgres://localhost"
  [ "$status" -eq 0 ]
  [ "$output" = "DATABASE_URL=postgres://localhost" ]
}

@test "format_env_line quotes values with spaces" {
  run format_env_line "GREETING" "hello world"
  [ "$status" -eq 0 ]
  [ "$output" = 'GREETING="hello world"' ]
}

@test "format_env_line escapes double quotes" {
  run format_env_line "MESSAGE" 'say "hello"'
  [ "$status" -eq 0 ]
  [ "$output" = 'MESSAGE="say \"hello\""' ]
}

@test "format_env_line handles multiline values" {
  local multiline=$'line1\nline2\nline3'
  run format_env_line "MULTILINE" "$multiline"
  [ "$status" -eq 0 ]
  [[ "$output" == 'MULTILINE="'* ]]
}

@test "is_multiline detects newlines" {
  local multiline=$'line1\nline2'
  run is_multiline "$multiline"
  [ "$status" -eq 0 ]
}

@test "is_multiline returns false for single line" {
  run is_multiline "single line value"
  [ "$status" -eq 1 ]
}

# =============================================================================
# HTTP Error Handling Tests
# =============================================================================

@test "http_error_message returns empty for 200" {
  run http_error_message 200
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "http_error_message handles 401 unauthorized" {
  run http_error_message 401
  [ "$status" -eq 0 ]
  [[ "$output" == *"Authentication failed"* ]]
}

@test "http_error_message handles 403 forbidden" {
  run http_error_message 403
  [ "$status" -eq 0 ]
  [[ "$output" == *"Access denied"* ]]
}

@test "http_error_message handles 404 not found" {
  run http_error_message 404
  [ "$status" -eq 0 ]
  [[ "$output" == *"not found"* ]]
}

@test "http_error_message handles generic 500 error" {
  run http_error_message 500
  [ "$status" -eq 0 ]
  [[ "$output" == *"HTTP 500"* ]]
}

# =============================================================================
# Header Generation Tests
# =============================================================================

@test "generate_env_header includes environment name" {
  run generate_env_header "production"
  [ "$status" -eq 0 ]
  [[ "$output" == *"KeyEnv GitHub Action"* ]]
  [[ "$output" == *"production"* ]]
}
