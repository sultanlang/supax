open Progress
open Sys

module Installer = struct
  let get_core_module coreName =
    match coreName with
    | "sultan" -> "Sultanc"
    (* | "std" -> "Std"
    | "server" -> "Server"
    | "web" -> "Web" *)
    | _ -> failwith "Invalid package name"

  let package_file_path = Sys.getenv "HOME" ^ "/castle/file.txt"

  let install_directory name =
    if name = "sultan" then Sys.getenv "HOME" ^ "/castle/"
    (* else if name = "std" then Sys.getenv "HOME" ^ "/castle/libs/"
    else if name = "server" then Sys.getenv "HOME" ^ "/castle/libs/"
    else if name = "web" then Sys.getenv "HOME" ^ "/castle/libs/" *)
    else failwith "Invalid package name"

  let read_file filename =
    let ic = open_in filename in
    let rec read_lines acc =
      try
        let line = input_line ic in
        read_lines (line :: acc)
      with End_of_file ->
        close_in ic;
        List.rev acc
    in
    read_lines []

  let check_package name =
    let lines = read_file package_file_path in
    let rec find_url lines =
      match lines with
      | [] -> None
      | line :: rest ->
        if String.starts_with ~prefix:(name ^ ": ") line then
          Some (String.sub line (String.length name + 2) (String.length line - String.length name - 2))
        else
          find_url rest
    in
    find_url lines

  let use_url name =
    match check_package name with
    | Some url -> url
    | None -> failwith "Package not found"

  let install name =
    let url = use_url name in
    let dir = install_directory name in
    let subdir = Filename.concat dir name in
    let total_steps = 3 in
    let (update, print_message) = Progress.create total_steps in

    update 1 "Creating directory";
    if not (file_exists subdir) then (
      let mkdir_command = Printf.sprintf "mkdir -p %s" subdir in
      let status = Sys.command mkdir_command in
      if status <> 0 then (
        print_message (Printf.sprintf "Failed to create directory %s" subdir);
        exit 1
      )
    );

    update 1 "Cloning repository";
    let command = Printf.sprintf "git clone --recurse-submodules %s %s > /dev/null 2>&1" url subdir in
    let status = Sys.command command in
    if status <> 0 then (
      print_message (Printf.sprintf "Failed to clone repository for package %s" name);
      exit 1
    );

    update 1 "Installation complete";
    print_message (Printf.sprintf "Successfully installed package %s" name)
end