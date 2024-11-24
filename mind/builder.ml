open Progress


let change_directory path =
  try
    Sys.chdir path
  with
  | Sys_error msg -> Printf.printf "Failed to enter %s: %s\n" path msg; exit 1

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

let compile_sultanc () =
  change_directory  (Sys.getenv "HOME" ^ "/castle/sultan/compiler/core/");
  Printf.printf "Building...\n";

  let core_files = [
 
    "errorlog.ml";
    "error.mli";
    "error.ml";
    "logging.ml";
    "almostashar.ml";
    "id.ml";
    "Symboltable.ml";
    "ast.ml";
    "binding.ml";
    "import_detection.mli";
    "import_detection.ml"
  ] in

  let parser_files = [
    "sparser.mli";
    "sparser.ml"
  ] in

  let additional_files = [
    "driver.ml";
    "main.ml"
  ] in

  let total_steps = List.length core_files + List.length parser_files + List.length additional_files + 3 in
  let (update_progress, print_message) = Progress.create total_steps in
  let step = ref 0 in

  let compile_core file =
    compile_file "ocamlfind ocamlc -package uutf,dynlink,compiler-libs.common -linkpkg -I core -c" file update_progress;
    incr step
  in
  let compile_parser file =
    compile_file "ocamlfind ocamlc -package uutf,dynlink,compiler-libs.common -linkpkg -I core -c" file update_progress;
    incr step
  in
  let compile_additional file =
    compile_file "ocamlfind ocamlc -package uutf,dynlink,compiler-libs.common -linkpkg -I core -c" file update_progress;
    incr step
  in

  List.iter compile_core core_files;

  let menhir_command = "menhir --ocamlc \"ocamlc -I core -I +compiler-libs\" --infer --explain --trace sparser.mly > /dev/null 2>&1" in
  let status = Sys.command menhir_command in
  if status <> 0 then (
    Printf.printf "Failed to compile sparser.mly\n";
    exit 1
  );
  incr step;
  update_progress 1 "sparser.mly";

  List.iter compile_parser parser_files;

  let ocamllex_command = "ocamllex slexer.mll > /dev/null 2>&1" in
  let status = Sys.command ocamllex_command in
  if status <> 0 then (
    Printf.printf "Failed to compile slexer.mll\n";
    exit 1
  );
  incr step;
  update_progress 1 "slexer.mll";

  compile_file "ocamlfind ocamlc -package uutf,dynlink,compiler-libs.common -linkpkg -I core -c" "slexer.ml" update_progress;
  incr step;

  List.iter compile_additional additional_files;

  Printf.printf "\n=> Linking all modules to create sultanc\n";
  let link_command = "ocamlfind ocamlc -o sultanc -package uutf,dynlink,compiler-libs.common -linkpkg errorlog.cmo error.cmo logging.cmo almostashar.cmo id.cmo Symboltable.cmo ast.cmo binding.cmo import_detection.cmo sparser.cmo slexer.cmo driver.cmo main.cmo > /dev/null 2>&1" in
  let status = Sys.command link_command in
  if status <> 0 then (
    Printf.printf "Linking failed\n";
    exit 1
  );
  incr step;
  update_progress 1 "linking";

  let move_command = "mv sultanc ../../ > /dev/null 2>&1" in
  let status = Sys.command move_command in
  if status <> 0 then (
    Printf.printf "Failed to move sultanc\n";
    exit 1
  );
  incr step;
  update_progress 1 "moving sultanc";

  print_message "Build completed successfully"

let run clean =
  compile_sultanc ();
  if clean then clean_files ()



    open Progress

let change_directory path =
  try
    Sys.chdir path
  with
  | Sys_error msg -> Printf.printf "Failed to enter %s: %s\n" path msg; exit 1

let run_make target =
  let make_command = Printf.sprintf "make -f install.mk %s" target in
  let status = Sys.command make_command in
  if status <> 0 then (
    Printf.printf "Failed to run %s\n" make_command;
    exit 1
  )

let compile_sultanc () =
  change_directory (Sys.getenv "HOME" ^ "/castle/cmake/");
  Printf.printf "Building...\n";
  run_make "all";
  Printf.printf "Build completed successfully\n"

let clean_sultanc () =
  change_directory (Sys.getenv "HOME" ^ "/cmake/");
  Printf.printf "Cleaning...\n";
  run_make "clean";
  Printf.printf "Clean completed successfully\n"

let run clean =
  compile_sultanc ();
  if clean then clean_sultanc ()