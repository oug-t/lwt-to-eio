open Ppxlib

(* Define the translation targets *)
type mode = Eio | Lwt_direct

class lwt_mapper (mode : mode) = object (self)
  inherit Ast_traverse.map as super

  method! expression expr =
    let loc = expr.pexp_loc in
    match expr with
    
    (* RULE: Lwt_list.map_p *)
    | [%expr Lwt_list.map_p [%e? fn] [%e? lst]] ->
      Printf.printf "  [+] Rewriting Lwt_list.map_p\n";
      begin match mode with
      | Eio -> 
          (* Eio uses Fiber.List.map *)
          [%expr Eio.Fiber.List.map [%e self#expression fn] [%e self#expression lst]]
      | Lwt_direct -> 
          [%expr Lwt_list.map_p [%e self#expression fn] [%e self#expression lst]]
      end

    (* RULE: Lwt_unix.sleep *)
    | [%expr Lwt_unix.sleep [%e? time]] ->
      begin match mode with
      | Eio -> [%expr Eio.Time.sleep env#clock [%e self#expression time]]
      | Lwt_direct -> [%expr Lwt_direct.await (Lwt_unix.sleep [%e self#expression time])]
      end

    (* RULE: Lwt.bind *)
    | [%expr Lwt.bind [%e? promise] (fun [%p? arg] -> [%e? body])] ->
      let awaiting_expr = 
        match mode with
        | Eio -> [%expr Lwt_eio.Promise.await_lwt [%e self#expression promise]]
        | Lwt_direct -> [%expr Lwt_direct.await [%e self#expression promise]]
      in
      [%expr 
        let [%p arg] = [%e awaiting_expr] in 
        [%e self#expression body]
      ]

    (* RULE: >>= *)
    | [%expr [%e? promise] >>= (fun [%p? arg] -> [%e? body])] ->
       let awaiting_expr = 
        match mode with
        | Eio -> [%expr Lwt_eio.Promise.await_lwt [%e self#expression promise]]
        | Lwt_direct -> [%expr Lwt_direct.await [%e self#expression promise]]
      in
      [%expr 
        let [%p arg] = [%e awaiting_expr] in 
        [%e self#expression body]
      ]
    
    (* RULE: Lwt.return *)
    | [%expr Lwt.return [%e? v]] ->
       self#expression v

    | _ -> super#expression expr
end

let run_migration mode structure =
  let mapper = new lwt_mapper mode in
  mapper#structure structure
