

module HumanTimer = struct
  let human_typing_speed = 0.02 (* delay in seconds *)

  let delay seconds =
    let start = Sys.time () in
    while Sys.time () -. start < seconds do
      ()
    done

  let type_text text =
    let rec type_char i =
      if i < String.length text then
        let () = print_char text.[i] in
        let () = flush stdout in
        let () = delay human_typing_speed in
        type_char (i + 1)
    in
    type_char 0
end
