# Contributing to lwt-to-eio

First off, thanks for taking the time to contribute! ❤️

## Quick Start

1.  **Install Dependencies:**

    ```bash
    opam install . --deps-only
    ```

2.  **Run the Project:**

    ```bash
    dune exec lwt-to-eio -- test/cases/demo.ml
    ```

3.  **Run Tests:**
    We currently verify changes by running the CLI against files in `test/cases/`.
    - Add a new `.ml` file in `test/cases/` with the Lwt pattern you want to fix.
    - Run the tool and verify the output is valid Eio code.

## Project Structure

- `bin/main.ml`: The CLI entry point.
- `lib/migrate.ml`: **The Brain.** This is where the AST rewriting logic lives.
- `test/cases/`: Example files used for manual verification.

## How to add a new Migration Rule

1.  Open `lib/migrate.ml`.
2.  Find the `class lwt_mapper`.
3.  Add a new pattern match to the `expression` method.
    - Use `[%expr ...]` to match the Lwt code.
    - Return the Eio equivalent using `[%expr ...]`.
    - **Important:** Remember to use `self#expression` if your node might contain nested Lwt code!

## Style Guide

- Use `dune fmt` to format your code before pushing.
- Keep commit messages clear (e.g., `feat: add support for Lwt.catch`).
