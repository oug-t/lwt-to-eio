open Cmdliner

let process_file filename =
  try
    (* 1. Read the source file and parse it into an AST *)
    let ic = open_in filename in
    let lexbuf = Lexing.from_channel ic in
    (* Initialize location to avoid parsing errors *)
    Lexing.set_filename lexbuf filename;
    let ast = Ppxlib.Parse.implementation lexbuf in
    close_in ic;

    (* 2. Run your migration logic ("The Brain") *)
    let new_ast = Lwt_to_eio_lib.Migrate.run_migration ast in

    (* 3. Print the new code to Standard Output *)
    Ppxlib.Pprintast.structure Format.std_formatter new_ast
  with
  | Sys_error msg -> Printf.eprintf "Error: %s\n" msg
  | exn -> Printf.eprintf "Unexpected error: %s\n" (Printexc.to_string exn)

(* CLI Configuration (Boilerplate) *)
let filename_arg =
  let doc = "The OCaml file to migrate." in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"FILE" ~doc)

let cmd =
  let doc = "Automatically migrate Lwt code to Eio." in
  let info = Cmd.info "lwt-to-eio" ~doc in
  Cmd.v info Term.(const process_file $ filename_arg)

let () = exit (Cmd.eval cmd)
