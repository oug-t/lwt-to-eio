open Ppxlib

(* REMOVED: (_ : Ast_traverse.map) *)
class lwt_mapper = object
  inherit Ast_traverse.map as super

  method! expression expr =
    (* We need 'loc' for the [%expr] macro to work *)
    let loc = expr.pexp_loc in

    match expr with
    (* RULE: Lwt_list.map_p -> Eio.Fiber.List.map *)
    | [%expr Lwt_list.map_p [%e? fn] [%e? lst]] ->
      Printf.printf "  [+] Rewriting Lwt_list.map_p\n";
      [%expr Eio.Fiber.List.map [%e fn] [%e lst]]

    (* RULE: Lwt_unix.sleep -> Eio.Time.sleep *)
    | [%expr Lwt_unix.sleep [%e? time]] ->
      Printf.printf "  [+] Rewriting Lwt_unix.sleep\n";
      (* We assume 'env' is available in the user's scope *)
      [%expr Eio.Time.sleep env#clock [%e time]]

    (* Fallback: Keep everything else the same *)
    | _ -> super#expression expr
end

let run_migration structure =
  let mapper = new lwt_mapper in
  mapper#structure structure
