# lwt-to-eio

**Practical migration tooling for moving from Lwt to Eio (OCaml 5).**

> 🚧 **Status:** MVP / Active Development  
> This project is experimental and focuses on *mechanical rewrites*, not semantic guarantees.

Migrating a real-world OCaml codebase from **Lwt** (monadic async) to **Eio** (direct style, structured concurrency) is repetitive, error-prone, and mentally exhausting.

**`lwt-to-eio`** is a CLI tool that performs **AST-level rewrites** to eliminate common Lwt patterns and produce **Eio-style direct code**, with `Lwt_eio` used as a compatibility bridge where full conversion is not yet possible.

This tool is designed to:
- remove boilerplate (`>>=`, `let*`, nested binds)
- flatten callback-heavy code
- make migration *incremental and reviewable*

It does **not** claim to produce perfect Eio code automatically.

## ✨ Before & After

### Input: Legacy Lwt (monadic, nested)
```ocaml
let fetch_user_data id =
  Lwt.bind (Db.get_user id) (fun user ->
    Db.get_posts user.id >>= fun posts ->
    Lwt_list.map_p process posts
  )
```

### Output: Direct Style (Eio-compatible)
```ocaml
let fetch_user_data id =
  let user =
    Lwt_eio.Promise.await_lwt (Db.get_user id)
  in
  let posts =
    Lwt_eio.Promise.await_lwt (Db.get_posts user.id)
  in
  Eio.Fiber.List.map process posts
```

### The resulting code:

- flat and readable

- removes monadic plumbing

- preserves execution order explicitly

- is suitable for manual refinement into native Eio

## 🚀 Usage

Currently, the tool prints transformed code to stdout.
```bash
# Run on a single file
dune exec lwt-to-eio -- src/my_file.ml > src/my_file_migrated.ml
```
The original file is never modified.

## 📦 Installation
```
git clone https://github.com/YOUR_USERNAME/lwt-to-eio.git
cd lwt-to-eio

# Install OCaml dependencies
opam install . --deps-only

# Build
dune build
```
OCaml ≥ 5.1 is recommended.

## ✅ Supported Transformations

The following patterns are currently handled via **recursive AST rewriting**:

| Pattern        | Lwt (Legacy)                  | Eio-Style Output                                   |
|----------------|-------------------------------|---------------------------------------------------|
| Bind           | `>>=` / `let*`                | `let x = Lwt_eio.Promise.await_lwt p in`           |
| Parallel map   | `Lwt_list.map_p`              | `Eio.Fiber.List.map`                              |
| Sleep          | `Lwt_unix.sleep t`             | `Eio.Time.sleep env#clock t`                      |
| Nested binds   | Deeply nested closures         | Flattened direct style                            |

⚠️ **Important:** semantic behavior (especially **cancellation**) may still require **manual review** after rewriting.

## 🧠 Design Philosophy

- Mechanical, not magical

- Readable diffs over clever rewrites

- Incremental migration over big-bang rewrites

- This tool is intentionally conservative. If a rewrite is ambiguous, it should not happen automatically.

## 🤝 Contributing (Help Wanted!)

- This project is intentionally contributor-friendly.

- We use ppxlib to match and rewrite OCaml AST nodes.
