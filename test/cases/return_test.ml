(* test/cases/return_test.ml *)
let simple_value = Lwt.return 5

let complex_calculation = 
  Lwt.return (10 + 20)

let nested_structure =
  (* This tests if your recursion works! *)
  Lwt.return (Lwt_list.map_p (fun x -> x) [])
