# AI Assistant Common Rules

This file defines the common rules and guidelines for any AI coding assistant (Gemini, Cursor, Copilot, Windsurf, etc.) working on this Godot project.
**AI ASSISTANT: You MUST read and follow these rules before making any code modifications.**

## 1. Code Formatting & Linting (MANDATORY)
This project enforces strict code formatting and linting using `gdtoolkit` (`gdformat` and `gdlint`).

### Your Responsibilities as an AI:
Whenever you modify, create, or refactor any GDScript (`.gd`) file, you MUST do the following before declaring your task complete:
1. **Format the code**: Run `gdformat .` (or `gdformat <file>`) to automatically format the code.
2. **Lint the code**: Run `gdlint .` (or `gdlint <file>`) to check for structural errors.
3. **Fix any errors**: If `gdlint` returns any errors (e.g., `class-definitions-order`, `function-preload-variable-name`, `max-line-length`), you MUST manually fix them and re-run `gdlint` until it reports `Success: no problems found`.

### Environment Setup
If your terminal environment does not have `gdtoolkit` installed, install it via:
```bash
pip3 install gdtoolkit
```

## 2. Godot Best Practices
- **Do NOT remove UID tags** from `.tscn` files unless they are explicitly throwing invalid UID errors. Godot manages these automatically.
- **Node References**: Prefer `@onready var` for node references instead of calling `get_node()` inside `_process` or `_physics_process`.
- **Preloads**: `preload()` must be declared at the top level of the script (global scope) as a `var` or `const`, not inside a function scope.
- **Class Definitions Order**: Adhere to the strict Godot class definition order:
  1. `class_name` / `extends`
  2. `signal`
  3. `enum`
  4. `const`
  5. `@export` variables
  6. public variables (`var`)
  7. private variables (`var _name`)
  8. `@onready var`
  9. `_init()`, `_ready()`, `_process()`, `_physics_process()`
  10. public/private functions

## 3. GitHub Actions & Exporting
- The `.github/workflows` directory contains critical CI/CD pipelines for Web Export and Linting. Do not modify these unless explicitly requested.
- `export_presets.cfg` is required for headless Web exports. Do not delete it.
