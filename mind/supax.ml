

open Commands



let () =
  let args = Array.to_list Sys.argv |> List.tl in
  let command = parse_command args in
  execute_command command
  