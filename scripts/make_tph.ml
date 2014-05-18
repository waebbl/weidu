let my_read size fd buff name =
  let sofar = ref 0 in
  while !sofar < size do
    let this_chunk = Unix.read fd buff !sofar (size - !sofar) in
    if this_chunk = 0 then begin
      failwith (Printf.sprintf "read %d of %d bytes from [%s]"
		  !sofar size name)
    end else
      sofar := !sofar + this_chunk
  done

let load_file name =
  let stats = Unix.stat name in
  let size = stats.Unix.st_size in
  let buff = String.make size '\000' in
  let fd = Unix.openfile name [Unix.O_RDONLY] 0 in
  my_read size fd buff name ;
  Unix.close fd ;
  Str.global_replace (Str.regexp "\\([\\\"\']\\)") "\\\\\\1" buff

let main () =
  let o = open_out "src/tph.ml" in
  output_string o "(* DO NOT EDIT, file generated automatically by scripts/make_tph.ml from src/tph/* *)\n";
  output_string o "let list_of_stuff = [";
  let file_define  = Sys.readdir "src/tph/define"  in
  let file_include = Sys.readdir "src/tph/include" in
  List.iter (fun (dir, files) ->
    Array.iter (fun file ->
      let file = String.lowercase file in
      let ext = Str.global_replace (Str.regexp ".*\\.") "" file in
      if ext = "tpa" || ext = "tpp" then begin
        let contents = load_file ("src/tph/" ^ dir ^ "/" ^ file) in
        Printf.fprintf o "(\"%s\",\"%s  \");\n" file contents;
      end) files) [("define",file_define); ("include",file_include)];
  output_string o "]\n";
  output_string o "let list_of_includes = [";
  Array.iter (fun file ->
    let file = String.lowercase file in
    let ext = Str.global_replace (Str.regexp ".*\\.") "" file in
    if ext = "tpa" || ext = "tpp" then Printf.fprintf o "\t\"%s\";\n" file) file_include;
  output_string o "]\n";
  close_out o;
;;

try
  main ()
with e -> print_endline (Printexc.to_string e)
