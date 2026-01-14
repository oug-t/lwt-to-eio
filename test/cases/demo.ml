(* test/cases/demo.ml *)
let process_data items =
  (* This is the pattern we want to fix! *)
  Lwt_list.map_p (fun x -> Lwt_unix.sleep 1.0) items
