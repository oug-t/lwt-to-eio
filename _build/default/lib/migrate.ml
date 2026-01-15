open Ppxlib

class lwt_mapper = object (self) (* <-- enable 'self' to recurse *)
  inherit Ast_traverse.map as super

  method! expression expr =
    let loc = expr.pexp_loc in
    match expr with
    | [%expr Lwt_list.map_p [%e? fn] [%e? lst]] ->
      Printf.printf "  [+] Rewriting Lwt_list.map_p\n";
      [%expr Eio.Fiber.List.map [%e self#expression fn] [%e self#expression lst]]

    | [%expr Lwt_unix.sleep [%e? time]] ->
      Printf.printf "  [+] Rewriting Lwt_unix.sleep\n";
      [%expr Eio.Time.sleep env#clock [%e self#expression time]]

    (* RULE 3: Recursive Rewrite for Lwt.bind *)
    | [%expr Lwt.bind [%e? promise] (fun [%p? arg] -> [%e? body])] ->
      Printf.printf "  [+] Rewriting Lwt.bind\n";
      [%expr 
        let [%p arg] = Lwt_eio.Promise.await_lwt [%e self#expression promise] in 
        [%e self#expression body] (* <--- CRITICAL FIX: Recurse here! *)
      ]

    (* RULE 4: Recursive Rewrite for >>= *)
    | [%expr [%e? promise] >>= (fun [%p? arg] -> [%e? body])] ->
      Printf.printf "  [+] Rewriting >>=\n";
      [%expr 
        let [%p arg] = Lwt_eio.Promise.await_lwt [%e self#expression promise] in 
        [%e self#expression body] (* <--- CRITICAL FIX: Recurse here! *)
      ]

    | _ -> super#expression expr
end

let run_migration structure =
  let mapper = new lwt_mapper in
  mapper#structure structure
