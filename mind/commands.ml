open Installer
open Builder

type commands =
  | Install of string list 
  | Uninstall of string
  | Update of string
  | Help
  | Version
  | Build of string
  | Clean
  | Unknown of string
  | CoreBuilder of bool

let parse_command args =
  let rec parse args clean =
    match args with
    | [] -> Help
    | "-cn" :: rest -> parse rest true
    | "install" :: packages -> Install packages
    | "uninstall" :: package :: _ -> Uninstall package
    | "update" :: package :: _ -> Update package
    | "help" :: _ -> Help
    | "version" :: _ -> Version
    | "build" :: target :: _ -> Build target
    | "clean" :: _ -> Clean
    | "corebuild" :: _ -> CoreBuilder clean
    | cmd :: _ -> Unknown cmd
  in
  parse args false

let execute_command command =
  match command with
  | Install packages ->
      List.iter (fun package ->
        try
          Installer.install package
        with Failure msg ->
          Printf.printf "Failed to install package %s: %s\n" package msg
      ) packages
  | Uninstall package ->
      (* Uninstall logic here *)
      Printf.printf "Uninstalling package: %s\n" package
  | Update package ->
      Printf.printf "Updating package: %s\n" package
  | Help ->
      Printf.printf "Help: Available commands are install, uninstall, update, help, version, build, clean, corebuild\n"
  | Version ->
      Printf.printf "Version: 1.0.0\n"
  | Build target ->
      Printf.printf "Building target: %s\n" target
  | Clean ->
      Printf.printf "Cleaning project\n"
  | CoreBuilder clean ->
      Builder.run clean
  | Unknown cmd ->
      Printf.printf "Unknown command: %s\n" cmd