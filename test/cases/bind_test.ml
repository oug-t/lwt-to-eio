(* test/cases/bind_test.ml *)
open Lwt.Syntax

let fetch_user_data id =
  (* Pattern 1: Standard Lwt.bind *)
  Lwt.bind (Db.get_user id) (fun user ->
    
    (* Pattern 2: Infix operator >>= *)
    Db.get_posts user.id >>= (fun posts ->
      
      (* Nested logic that we want to flatten *)
      Lwt.return (user, posts)
    )
  )
