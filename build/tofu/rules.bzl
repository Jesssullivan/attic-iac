"""OpenTofu Bazel Rules

Custom Starlark rules for validating and formatting OpenTofu modules.
These rules integrate OpenTofu validation into the Bazel build graph,
enabling incremental validation and remote caching of results.

Usage:
    load("//build/tofu:rules.bzl", "tofu_module", "tofu_validate", "tofu_fmt_test")

    tofu_module(
        name = "my_module",
        srcs = glob(["*.tf"]),
        providers = ["kubernetes", "helm"],
    )
"""

# =============================================================================
# Provider for sharing module information
# =============================================================================

TofuModuleInfo = provider(
    "Information about an OpenTofu module",
    fields = {
        "name": "Module name",
        "srcs": "Source files (.tf)",
        "path": "Path to module directory",
        "providers": "Required providers (for documentation)",
    },
)

# =============================================================================
# tofu_module - Defines an OpenTofu module
# =============================================================================

def _tofu_module_impl(ctx):
    """Implementation of tofu_module rule."""
    return [
        DefaultInfo(
            files = depset(ctx.files.srcs),
        ),
        TofuModuleInfo(
            name = ctx.label.name,
            srcs = ctx.files.srcs,
            path = ctx.label.package,
            providers = ctx.attr.providers,
        ),
    ]

tofu_module = rule(
    implementation = _tofu_module_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".tf", ".tf.json"],
            mandatory = True,
            doc = "OpenTofu source files",
        ),
        "providers": attr.string_list(
            default = [],
            doc = "Required providers (kubernetes, helm, aws, etc.)",
        ),
        "deps": attr.label_list(
            providers = [TofuModuleInfo],
            doc = "Other tofu_module dependencies",
        ),
    },
    doc = "Defines an OpenTofu module for validation and bundling",
)

# =============================================================================
# tofu_validate - Validates an OpenTofu module
# =============================================================================

def _tofu_validate_impl(ctx):
    """Implementation of tofu_validate rule."""
    module = ctx.attr.module[TofuModuleInfo]

    # Create validation script
    script_content = """#!/usr/bin/env bash
set -euo pipefail

MODULE_PATH="{module_path}"
MODULE_NAME="{module_name}"

echo "Validating OpenTofu module: $MODULE_NAME"

# Check if tofu is available
if ! command -v tofu &>/dev/null; then
    echo "ERROR: OpenTofu (tofu) not found in PATH"
    exit 1
fi

cd "$BUILD_WORKSPACE_DIRECTORY/$MODULE_PATH"

# Initialize without backend
if ! tofu init -backend=false -input=false -no-color 2>&1; then
    echo "FAIL: tofu init failed for $MODULE_NAME"
    exit 1
fi

# Validate the module
if ! tofu validate -no-color 2>&1; then
    echo "FAIL: tofu validate failed for $MODULE_NAME"
    exit 1
fi

echo "PASS: $MODULE_NAME validated successfully"

# Write success marker
touch "$1"
""".format(
        module_path = module.path,
        module_name = module.name,
    )

    # Create the validation script
    script = ctx.actions.declare_file(ctx.label.name + "_validate.sh")
    ctx.actions.write(
        output = script,
        content = script_content,
        is_executable = True,
    )

    # Create success marker file
    marker = ctx.actions.declare_file(ctx.label.name + ".validated")

    # Run validation (this is a test, so it runs at test time)
    ctx.actions.run(
        inputs = module.srcs,
        outputs = [marker],
        executable = script,
        arguments = [marker.path],
        use_default_shell_env = True,
        mnemonic = "TofuValidate",
        progress_message = "Validating OpenTofu module %s" % module.name,
    )

    return [
        DefaultInfo(
            files = depset([marker]),
            runfiles = ctx.runfiles(files = module.srcs + [script]),
        ),
    ]

tofu_validate = rule(
    implementation = _tofu_validate_impl,
    attrs = {
        "module": attr.label(
            providers = [TofuModuleInfo],
            mandatory = True,
            doc = "The tofu_module to validate",
        ),
    },
    doc = "Validates an OpenTofu module using `tofu validate`",
)

# =============================================================================
# tofu_fmt_test - Tests that OpenTofu files are formatted
# =============================================================================

def _tofu_fmt_test_impl(ctx):
    """Implementation of tofu_fmt_test rule."""
    module = ctx.attr.module[TofuModuleInfo]

    # Create format check script
    script_content = """#!/usr/bin/env bash
set -euo pipefail

MODULE_PATH="{module_path}"
MODULE_NAME="{module_name}"

echo "Checking OpenTofu formatting: $MODULE_NAME"

# Check if tofu is available
if ! command -v tofu &>/dev/null; then
    echo "ERROR: OpenTofu (tofu) not found in PATH"
    exit 1
fi

cd "$BUILD_WORKSPACE_DIRECTORY/$MODULE_PATH"

# Check formatting (returns non-zero if files need formatting)
UNFORMATTED=$(tofu fmt -check -recursive -diff 2>&1) || true

if [ -n "$UNFORMATTED" ]; then
    echo "FAIL: The following files need formatting:"
    echo "$UNFORMATTED"
    echo ""
    echo "Run 'tofu fmt -recursive $MODULE_PATH' to fix"
    exit 1
fi

echo "PASS: $MODULE_NAME is properly formatted"
""".format(
        module_path = module.path,
        module_name = module.name,
    )

    # Create the test script
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = script,
        content = script_content,
        is_executable = True,
    )

    return [
        DefaultInfo(
            executable = script,
            runfiles = ctx.runfiles(files = module.srcs),
        ),
    ]

tofu_fmt_test = rule(
    implementation = _tofu_fmt_test_impl,
    attrs = {
        "module": attr.label(
            providers = [TofuModuleInfo],
            mandatory = True,
            doc = "The tofu_module to check formatting",
        ),
    },
    test = True,
    doc = "Tests that an OpenTofu module is properly formatted",
)

# =============================================================================
# Convenience macros
# =============================================================================

def tofu_module_test(name, srcs, providers = [], **kwargs):
    """Convenience macro that creates a module and its validation test.

    Args:
        name: Module name
        srcs: Source files
        providers: Required providers
        **kwargs: Additional arguments passed to the rules
    """

    # Create the module
    tofu_module(
        name = name,
        srcs = srcs,
        providers = providers,
    )

    # Create validation test
    tofu_validate(
        name = name + "_validate",
        module = ":" + name,
        tags = ["tofu", "validation"],
        **kwargs
    )

    # Create format test
    tofu_fmt_test(
        name = name + "_fmt_test",
        module = ":" + name,
        tags = ["tofu", "formatting"],
        **kwargs
    )
