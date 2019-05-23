let oc = open_out_gen [Open_append; Open_creat] 0o666 "ls.log"
let log_to_file lbl txt =
    Printf.fprintf oc "[%s] %s\n" lbl txt;
    flush oc

let send label out =
  let cl = "Content-Length: " ^ string_of_int (String.length out) ^ "\r\n\r\n" in
  print_string cl;
  print_string out;
  flush stdout;
  log_to_file (label ^ "_length") cl;
  log_to_file label out

let send_response = send "response"
let send_notification = send "notification"

let show_message msg =
  let params = `WindowShowMessage (Lsp_t.
      { window_show_message_params_type_ = 3
      ; window_show_message_params_message = msg
      }) in
  let notification = Lsp.notification params in
  send_notification (Lsp_j.string_of_notification_message notification)

let position_of_pos pos = Lsp_t.
  (* The LSP spec requires zero-based positions *)
  { position_line = if pos.Source.line > 0 then pos.Source.line - 1 else 0
  ; position_character = pos.Source.column
  }

let range_of_region at = Lsp_t.
  { range_start = position_of_pos at.Source.left
  ; range_end_ = position_of_pos at.Source.right
  }

let diagnostics_of_message msg = Lsp_t.
  { diagnostic_range = range_of_region msg.Diag.at
  ; diagnostic_severity = Some (match msg.Diag.sev with Diag.Error -> 1 | Diag.Warning -> 2)
  ; diagnostic_code = None
  ; diagnostic_source = Some "actorscript"
  ; diagnostic_message = msg.Diag.text
  ; diagnostic_relatedInformation = None
  }

let publish_diagnostics uri diags =
  let params = `PublishDiagnostics (Lsp_t.
    { publish_diagnostics_params_uri = uri
    ; publish_diagnostics_params_diagnostics = diags
    }) in
  let notification = Lsp.notification params in
  send_notification (Lsp_j.string_of_notification_message notification)

let start () =
  let client_capabilities = ref None in

  let rec loop () =
    let clength = read_line () in
    log_to_file "content-length" clength;
    let cl = "Content-Length: " in
    let cll = String.length cl in
    let num =
      (int_of_string
        (String.trim
           (String.sub
              clength
              cll
              (String.length(clength) - cll - 1)))) + 2 in
    let buffer = Buffer.create num in
    Buffer.add_channel buffer stdin num;
    let raw = String.trim (Buffer.contents buffer) in
    log_to_file "raw" raw;

    let message = Lsp_j.incoming_message_of_string raw in
    let message_id = message.Lsp_t.incoming_message_id in

    (match (message_id, message.Lsp_t.incoming_message_params) with

    (* Request messages *)

    | (Some id, `Initialize params) ->
        client_capabilities := Some params.Lsp_t.initialize_params_capabilities;
        let result = `Initialize (Lsp_t.
          { initialize_result_capabilities =
              { server_capabilities_textDocumentSync = 1
              ; server_capabilities_hoverProvider = Some true
              }
          }) in
        let response = Lsp.response_result_message id result in
        send_response (Lsp_j.string_of_response_message response);

    | (Some id, `TextDocumentHover params) ->
        let position = params.Lsp_t.text_document_position_params_position in
        let textDocument = params.Lsp_t.text_document_position_params_textDocument in
        let result = `TextDocumentHoverResponse (Lsp_t. {
          hover_result_contents = "hovered over: " ^ textDocument.text_document_identifier_uri
            ^ " " ^ string_of_int position.position_line
            ^ ", " ^ string_of_int position.position_character
        }) in
        let response = Lsp.response_result_message id result in
        send_response (Lsp_j.string_of_response_message response);

    | (_, `TextDocumentDidSave params) ->
       let textDocumentIdent = params.Lsp_t.text_document_did_save_params_textDocument in
       let uri = textDocumentIdent.Lsp_t.text_document_identifier_uri in
       (match Base.String.chop_prefix ~prefix:"file://" uri with
        | Some file_name -> begin
           let result = Pipeline.compile_files
             Pipeline.DfinityMode
             false
             [file_name] in
           show_message ("Compiling file: " ^ file_name);
           (* TODO: let msgs = match result with | Error msgs -> msgs | Ok (_, msgs) -> in *)
           (match result with
            | Ok _ -> show_message "Compilation successful"
            | Error msgs ->
               (match !client_capabilities with
               | Some capabilities ->
                   (* TODO: determine if the client accepts diagnostics with related info *)
                   (* let textDocument = capabilities.client_capabilities_textDocument in
                    * let send_related_information = textDocument.publish_diagnostics.relatedInformation in *)
                   let diags = List.map diagnostics_of_message msgs in
                   publish_diagnostics uri diags;
               | None -> ());

               (* TODO: remove *)
               show_message
                 ("Compilation failed with " ^
                    String.concat
                      " "
                      (List.map Diag.string_of_message msgs)))
          end
        | None ->
           log_to_file
             "error"
             ("Failed to strip filename from: " ^ uri));

    (* Notification messages *)

    | (None, `Initialized _) ->
       show_message "Language server initialized"

    (* Unhandled messages *)

    | _ ->
      log_to_file "unhandled message" raw;
    );

    loop ()
  in loop ()
