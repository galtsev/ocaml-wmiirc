
let keys = ref [];;
let wmii_normcolors = "#888888 #222222 #333333";;
let wmii_focuscolors = "#ffffff #285577 #4c7899";;

let (>>) arg fn = fn arg;;

let communicate cmd args data =
    let pin, pout = Unix.pipe () in
    let rin, rout = Unix.pipe () in
    let out_chan = Unix.out_channel_of_descr pout in
    let in_chan = Unix.in_channel_of_descr rin in
    Unix.set_close_on_exec rin;
    Unix.set_close_on_exec pout;
    let pid = Unix.create_process cmd args pin rout Unix.stderr in
    Unix.close pin;
    Unix.close rout;
    output_string out_chan data;
    close_out out_chan;
    let res = try input_line in_chan with End_of_file -> "" in
    Unix.waitpid [] pid >> ignore;
    res;;

let lstrip ?(ch=' ') s =
    let len = String.length s in
    let rec _lstrip s ch pos =
        if pos>=len then "" else if s.[pos] = ch then _lstrip s ch (pos+1) else String.sub s pos (len - pos) in
    _lstrip s ch 0;;

let split1 ?(ch=' ') s =
    let ln = String.length s in
    let rec _split s ch pos =
        if pos = ln then (s,"")
        else if s.[pos] = ch then (String.sub s 0 pos), (String.sub s (pos+1) (ln - pos - 1))
        else _split s ch (pos+1) in
    _split s ch 0;;

let rec make_handler proc =
    let cmd, args = split1 (lstrip proc) in
    match cmd with
      "cmd" -> (function () -> Unix.system ("wmiir xwrite " ^ args) >> ignore)
    | "exec" -> (function () -> Unix.system args >> ignore)
    | "actions" -> handle_actions
    | _ -> (function () -> ())
and reload_keys () =
    let chan = (open_in "/home/dan/.wmii/keys") in
    let read_ln () = try Some(input_line chan) with End_of_file -> None in
    let skip_empty ln = (ln = "" || ln.[0] = '#') in 
    let rec _read_conf keys =
        match (read_ln ()) with
          None -> keys
        | Some ln -> if skip_empty ln then _read_conf keys else 
            let key, proc = split1 ~ch:':' ln in
            _read_conf ((key, (make_handler proc))::keys) in
    keys:=_read_conf [];
    let kk = Unix.open_process_out "wmiir write /keys" in
    let rec write_keys kl =
        match kl with
          [] -> ()
        | (k,_)::tail -> output_string kk (k ^ "\n"); write_keys tail in
    write_keys !keys; 
    Unix.close_process_out kk >> ignore 
and handle_actions () =
    let ac = communicate "dmenu" [| "dmenu" |] "quit\nreload_keys\nwww\n" in
    match ac with
      "quit" -> Unix.system "wmiir xwrite /ctl quit" >> ignore
    | "reload_keys" -> reload_keys ()
    | "www" -> Unix.system "firefox &" >> ignore
    | _ -> ();;

let handle_event ln =
    let evt, args = split1 ln in
    let tag = lstrip args in
    match evt with
      "Key" -> List.assoc tag !keys ()
    | "CreateTag" -> 
        let oo = Unix.open_process_out ("wmiir create /lbar/" ^ tag) in 
        output_string oo tag ; Unix.close_process_out oo >> ignore
    | "DestroyTag" -> 
        Unix.system ("wmiir remove /lbar/" ^ tag) >> ignore
    | "FocusTag" ->
        Unix.system (Printf.sprintf "wmiir xwrite /lbar/%s '%s' %s" tag wmii_focuscolors tag) >> ignore
    | "UnfocusTag" ->
        Unix.system (Printf.sprintf "wmiir xwrite /lbar/%s '%s' %s" tag wmii_normcolors tag) >> ignore
    | "LeftBarClick" ->
        let _,ntag = split1 tag in 
        Unix.system ("wmiir xwrite /ctl view " ^ ntag) >> ignore
    | _ -> ()

let process () =
    reload_keys () ;
    let event_chan = Unix.open_process_in "wmiir read /event" in
    try
    while true do
        handle_event (input_line event_chan)
    done
    with End_of_file -> ();
    Unix.close_process_in event_chan >> ignore;;

let _ = process ();;
