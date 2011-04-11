
let (>>) arg fn = fn arg;;

let status () =
    let update_status () =
        let t = Unix.time () >>  Unix.localtime in
        let st_text = Printf.sprintf "%d-%02d-%02d %d:%02d" (1900+t.Unix.tm_year) (1+t.Unix.tm_mon) t.Unix.tm_mday t.Unix.tm_hour t.Unix.tm_min in
        match Unix.system (Printf.sprintf "wmiir xwrite /rbar/status '%s'" st_text) with
          Unix.WEXITED(rc) -> rc=0 
        | _ -> false in
    while update_status () do
        Unix.sleep 1;
    done;;

let _ = status ();;
