#!/usr/bin/env bash
# Configuration validation tests
#
# This script validates various configuration files in the repository.
# It works both standalone and inside the Bazel sandbox (sh_test).

set -euo pipefail

# Resolve REPO_ROOT: prefer Bazel runfiles, fall back to dirname for manual runs
if [[ -n "${TEST_SRCDIR:-}" && -n "${TEST_WORKSPACE:-}" ]]; then
  # Running inside Bazel sandbox - data files are in runfiles
  REPO_ROOT="${TEST_SRCDIR}/${TEST_WORKSPACE}"
  IN_BAZEL=1
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  IN_BAZEL=0
fi

echo "Configuration Validation"
echo "========================"

FAILED=0

# Validate flake.nix syntax
echo ""
echo "Checking: flake.nix"
if [ -f "$REPO_ROOT/flake.nix" ]; then
  if [[ $IN_BAZEL -eq 1 ]]; then
    # In Bazel sandbox, nix flake check won't work (no .git, no network).
    # Just verify the file is non-empty and looks like a flake.
    if head -5 "$REPO_ROOT/flake.nix" | grep -q 'description\|inputs\|outputs'; then
      echo "  PASS: flake.nix has expected structure"
    else
      echo "  FAIL: flake.nix does not look like a valid flake"
      FAILED=1
    fi
  else
    if command -v nix &>/dev/null; then
      if nix flake check --no-build "$REPO_ROOT" 2>/dev/null; then
        echo "  PASS: Nix flake is valid"
      else
        echo "  FAIL: Nix flake check failed"
        FAILED=1
      fi
    else
      echo "  SKIP: Nix not available"
    fi
  fi
else
  echo "  FAIL: flake.nix not found"
  FAILED=1
fi

# Validate flake.lock exists
echo ""
echo "Checking: flake.lock"
if [ -f "$REPO_ROOT/flake.lock" ]; then
  echo "  PASS: flake.lock exists"
else
  echo "  FAIL: flake.lock not found (run 'nix flake update')"
  FAILED=1
fi

# Validate .gitlab-ci.yml syntax
echo ""
echo "Checking: .gitlab-ci.yml"
if [ -f "$REPO_ROOT/.gitlab-ci.yml" ]; then
  # Verify the file is non-empty and has expected top-level keys.
  # We avoid python3 yaml.safe_load because:
  #   - The Bazel sandbox may not have PyYAML installed
  #   - GitLab CI files can use custom tags (!reference) that safe_load rejects
  # The GitLab API and nix fmt already validate full YAML correctness in CI.
  if grep -q '^stages:' "$REPO_ROOT/.gitlab-ci.yml" &&
    grep -q '^variables:' "$REPO_ROOT/.gitlab-ci.yml"; then
    echo "  PASS: .gitlab-ci.yml has expected structure"
  else
    echo "  FAIL: .gitlab-ci.yml missing expected top-level keys (stages, variables)"
    FAILED=1
  fi
else
  echo "  FAIL: .gitlab-ci.yml not found"
  FAILED=1
fi

# Check for sensitive files that should not exist
echo ""
echo "Checking: No sensitive files committed"

if [[ $IN_BAZEL -eq 1 ]]; then
  # In Bazel sandbox, only declared data files exist - skip find-based scan
  echo "  SKIP: Sensitive file scan not applicable in Bazel sandbox"
else
  SENSITIVE_PATTERNS=(
    "terraform.tfvars.bak"
    "*.pem"
    "*.key"
    ".env"
    ".env.*"
  )

  SENSITIVE_FOUND=0
  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    found=$(find "$REPO_ROOT" -name "$pattern" -not -path "*/.git/*" -not -path "*/result/*" 2>/dev/null | head -5)
    if [ -n "$found" ]; then
      echo "  WARN: Found sensitive file pattern '$pattern':"
      echo "$found" | sed 's/^/    /'
      SENSITIVE_FOUND=1
    fi
  done

  if [ $SENSITIVE_FOUND -eq 0 ]; then
    echo "  PASS: No sensitive files found"
  fi
fi

# Check .gitignore includes common patterns
echo ""
echo "Checking: .gitignore coverage"
if [ -f "$REPO_ROOT/.gitignore" ]; then
  REQUIRED_PATTERNS=("*.tfstate" "*.tfvars" ".terraform/" ".env")
  MISSING=0
  for pattern in "${REQUIRED_PATTERNS[@]}"; do
    if ! grep -q "$pattern" "$REPO_ROOT/.gitignore"; then
      echo "  WARN: Missing pattern '$pattern' in .gitignore"
      MISSING=1
    fi
  done
  if [ $MISSING -eq 0 ]; then
    echo "  PASS: Essential patterns present"
  fi
else
  echo "  FAIL: .gitignore not found"
  FAILED=1
fi

echo ""
echo "========================"
if [ $FAILED -eq 0 ]; then
  echo "All configuration checks passed"
else
  echo "Some configuration checks failed"
  exit 1
fi
