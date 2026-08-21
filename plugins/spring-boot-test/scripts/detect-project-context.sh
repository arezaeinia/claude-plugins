#!/usr/bin/env bash
# Detects the primary language and test framework of a Spring Boot project.
# Usage: ./detect-project-context.sh [project-root]
# Language: default java; overridden to kotlin if any .kt file found under src/.
# Output: two lines — LANGUAGE=<kotlin|java|mixed> and FRAMEWORK=<kotest-mockk|junit5-mockito|unknown>

set -e

ROOT="${1:-}"

# Walk up from cwd to find project root if not provided
if [[ -z "$ROOT" ]]; then
  ROOT="$PWD"
  while [[ "$ROOT" != "/" ]]; do
    if [[ -f "$ROOT/pom.xml" || -f "$ROOT/build.gradle" || -f "$ROOT/build.gradle.kts" ]]; then
      break
    fi
    ROOT="$(dirname "$ROOT")"
  done
fi

if [[ "$ROOT" == "/" ]]; then
  echo "LANGUAGE=unknown"
  echo "FRAMEWORK=unknown"
  exit 0
fi

# --- Language detection ---
# Any .kt file anywhere under the project root means Kotlin is present.
# Any .java file means Java is present. Both present = mixed.

LANGUAGE="java"

kt_files=$(find "$ROOT/src" -name "*.kt" 2>/dev/null || true)
[[ -n "$kt_files" ]] && LANGUAGE="kotlin"

# --- Framework detection ---

has_kotest=false
has_mockk=false
has_junit5=false
has_mockito=false

check_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  grep -q "io\.kotest\|kotest-runner\|kotest-assertions" "$file" 2>/dev/null && has_kotest=true
  grep -qE "mockk|MockK" "$file" 2>/dev/null && has_mockk=true
  grep -qE "junit-jupiter|junit\.jupiter|org\.junit\.jupiter" "$file" 2>/dev/null && has_junit5=true
  grep -qE "mockito|org\.mockito" "$file" 2>/dev/null && has_mockito=true
}

check_file "$ROOT/pom.xml"
check_file "$ROOT/build.gradle"
check_file "$ROOT/build.gradle.kts"

if $has_kotest && $has_mockk; then
  FRAMEWORK="kotest-mockk"
elif $has_junit5 && $has_mockito; then
  FRAMEWORK="junit5-mockito"
elif $has_junit5 && $has_mockk; then
  # Fallback: JUnit5+MockK treated as JUnit5+Mockito routing (use Mockito templates as closest match)
  FRAMEWORK="junit5-mockito"
else
  # Apply defaults based on language
  case "$LANGUAGE" in
    kotlin|mixed) FRAMEWORK="kotest-mockk" ;;
    java)         FRAMEWORK="junit5-mockito" ;;
    *)            FRAMEWORK="unknown" ;;
  esac
fi

echo "LANGUAGE=$LANGUAGE"
echo "FRAMEWORK=$FRAMEWORK"
