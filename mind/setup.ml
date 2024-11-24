open Progress

type system_info = {
  os_type: string;
  arch: string;
  mkdir_command: string;
  copy_command: string;
}

let detect_system_type () =
  let os_type = Sys.os_type in
  let arch = Sys.getenv_opt "HOSTTYPE" |> Option.value ~default:"unknown" in
  match os_type, arch with
  | "Unix", "x86_64" -> { os_type = "Unix"; arch = "x86_64"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", "arm" -> { os_type = "Unix"; arch = "ARM"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", "aarch64" -> { os_type = "Unix"; arch = "ARM64"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", "i386" -> { os_type = "Unix"; arch = "i386"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", "i686" -> { os_type = "Unix"; arch = "i686"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", "ppc" -> { os_type = "Unix"; arch = "PowerPC"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", "ppc64" -> { os_type = "Unix"; arch = "PowerPC64"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", "sparc" -> { os_type = "Unix"; arch = "SPARC"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", "mips" -> { os_type = "Unix"; arch = "MIPS"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", "riscv" -> { os_type = "Unix"; arch = "RISCV"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", "s390x" -> { os_type = "Unix"; arch = "S390x"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Unix", _ -> { os_type = "Unix"; arch = "unknown"; mkdir_command = "mkdir"; copy_command = "cp" }
  | "Win32", _ -> { os_type = "Windows"; arch = "unknown"; mkdir_command = "mkdir"; copy_command = "copy" }
  | "Cygwin", _ -> { os_type = "Cygwin"; arch = "unknown"; mkdir_command = "mkdir"; copy_command = "cp" }
  | _ -> { os_type = "Unknown"; arch = "unknown"; mkdir_command = "mkdir"; copy_command = "cp" }

let compile_file command file update_progress =
  let full_command = Printf.sprintf "%s %s > /dev/null 2>&1" command file in
  let status = Sys.command full_command in
  if status <> 0 then (
    Printf.printf "Failed to compile %s\n" file;
    exit 1
  );
  update_progress 1 file

let clean_files () =
  let clean_command = "rm -f *.cmo *.cmi > /dev/null 2>&1" in
  let status = Sys.command clean_command in
  if status <> 0 then (
    Printf.printf "Clean failed\n";
    exit 1
  )

let isCurrentBuild print_out = 
  print_endline (print_out)

let setup =
  let system_info = detect_system_type () in
  Printf.printf "Detected system type: %s (%s)\n" system_info.os_type system_info.arch;

  isCurrentBuild "Building...";
  let supaxFiles = [
    "progress.ml";
    "timer.ml";
    "builder.ml";
    "installer.ml";
    "commands.ml";
    "supax.ml"
  ] in
  let total_steps = List.length supaxFiles + 3 in
  let (update_progress, print_message) = Progress.create total_steps in
  let step = ref 0 in
  let compile_file file = 
    compile_file "ocamlfind ocamlc -c" file update_progress in
  List.iter (fun file -> compile_file file; step := !step + 1) supaxFiles;

  (* Compile the supax executable *)
  let compile_supax_command = "ocamlfind ocamlc -o supax " ^ (String.concat " " supaxFiles) in
  let status = Sys.command compile_supax_command in
  if status <> 0 then (
    Printf.printf "Failed to compile supax\n";
    exit 1
  );
  update_progress 1 "supax";

  (* Create ~/castle directory if it does not exist *)
  let home_dir = Sys.getenv "HOME" in
  let castle_dir = Filename.concat home_dir "castle" in
  if not (Sys.file_exists castle_dir) then (
    let status = Sys.command (system_info.mkdir_command ^ " " ^ castle_dir) in
    if status <> 0 then (
      Printf.printf "Failed to create directory %s\n" castle_dir;
      exit 1
    )
  );

  (* Move the supax executable to ~/castle *)
  let install_command = Printf.sprintf "mv supax %s" castle_dir in
  let status = Sys.command install_command in
  if status <> 0 then (
    Printf.printf "Failed to move supax to %s\n" castle_dir;
    exit 1
  );
  update_progress 1 "install supax";

  (* Print a newline before asking for the password *)
  print_endline "";

  (* Create a system-wide symbolic link for supax *)
  let system_link_command = Printf.sprintf "sudo ln -sf %s/supax /usr/local/bin/supax" castle_dir in
  let status = Sys.command system_link_command in
  if status <> 0 then (
    Printf.printf "Failed to create system-wide symbolic link for supax\n";
    exit 1
  );
  update_progress 1 "system link supax";

  (* Copy mind.txt to ~/castle *)
  let copy_command = Printf.sprintf "%s mind.txt %s" system_info.copy_command castle_dir in
  let status = Sys.command copy_command in
  if status <> 0 then (
    Printf.printf "Failed to copy mind.txt to %s\n" castle_dir;
    exit 1
  );

  isCurrentBuild "Build successful\n";