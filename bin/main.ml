open Cmdliner

let process_file target filename =
  try
    let ic = open_in filename in
    let lexbuf = Lexing.from_channel ic in

    Lexing.set_filename lexbuf filename;
    let ast = Ppxlib.Parse.implementation lexbuf in
    close_in ic;

    (* Pass the 'target' mode to the library *)
    let new_ast = Lwt_to_eio_lib.Migrate.run_migration target ast in

    Ppxlib.Pprintast.structure Format.std_formatter new_ast
  with
  | Sys_error msg -> Printf.eprintf "Error: %s\n" msg
  | exn -> Printf.eprintf "Unexpected error: %s\n" (Printexc.to_string exn)

(* Argument: --target eio | --target direct *)
let target_arg =
  let open Lwt_to_eio_lib.Migrate in
  let doc = "The target concurrency model: $(b,eio) (default) or $(b,direct) (for Lwt 6.0+)." in
  let mode_enum = Arg.enum [("eio", Eio); ("direct", Lwt_direct)] in
  Arg.(value & opt mode_enum Eio & info ["t"; "target"] ~docv:"TARGET" ~doc)

let filename_arg =
  let doc = "The OCaml file to migrate." in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"FILE" ~doc)

let cmd =
  let doc = "Automatically migrate Lwt code to Eio or Lwt_direct." in
  let info = Cmd.info "lwt-to-eio" ~doc in
  Cmd.v info Term.(const process_file $ target_arg $ filename_arg)

let () = exit (Cmd.eval cmd)
