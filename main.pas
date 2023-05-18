program main;

{$ifdef fpc}
{$packrecords c}
{$endif}

{$linklib c}
{$linklib "./libtwirc.a"}

uses ctypes;

type
   Ptwirc_state_t = ^twirc_state_t;
   twirc_state_t = record
		   end;
   Ptwirc_tag_t = ^twirc_tag_t;
   twirc_tag_t = record
		    key : pchar;
		    value : pchar;
		 end;
   Ptwirc_event_t = ^twirc_event_t;
   twirc_event_t = record
		      raw : pchar;
		      prefix : pchar;
		      command : pchar;
		      params : ^pchar;
		      num_params : csize_t;
		      trailing : cint;
		      tags : ^Ptwirc_tag_t;
		      num_tags : csize_t;
		      origin : pchar;
		      channel : pchar;
		      target : pchar;
		      message : pchar;
		      ctcp : pchar;
		   end;
   twirc_callback = procedure (s:Ptwirc_state_t; e:Ptwirc_event_t);cdecl;
   Ptwirc_callbacks_t = ^twirc_callbacks_t;
   twirc_callbacks_t = record
			  connect : twirc_callback;
			  welcome : twirc_callback;
			  globaluserstate : twirc_callback;
			  capack : twirc_callback;
			  ping : twirc_callback;
			  join : twirc_callback;
			  part : twirc_callback;
			  mode : twirc_callback;
			  names : twirc_callback;
			  privmsg : twirc_callback;
			  whisper : twirc_callback;
			  action : twirc_callback;
			  notice : twirc_callback;
			  roomstate : twirc_callback;
			  usernotice : twirc_callback;
			  userstate : twirc_callback;
			  clearchat : twirc_callback;
			  clearmsg : twirc_callback;
			  hosttarget : twirc_callback;
			  reconnect : twirc_callback;
			  disconnect : twirc_callback;
			  invalidcmd : twirc_callback;
			  other : twirc_callback;
			  outbound : twirc_callback;
		       end;

function twirc_init:Ptwirc_state_t;cdecl;external;
function twirc_get_callbacks(s:Ptwirc_state_t):Ptwirc_callbacks_t;cdecl;external;
function twirc_connect_anon(s:Ptwirc_state_t; host:pchar; port:pchar):cint;cdecl;external;
function twirc_loop(s:Ptwirc_state_t):cint;cdecl;external;
function twirc_cmd_join(s : Ptwirc_state_t; chan: pchar):cint;cdecl;external;
procedure twirc_kill(s:Ptwirc_state_t);cdecl;external;

procedure handle_welcome(state : Ptwirc_state_t; event:Ptwirc_event_t);cdecl;
var
   arg	: shortstring;
   arr	: array of char;
   i	: integer;
   stri	: integer = 1;
begin
   arg := paramStr(1);
   setlength(arr,byte(arg[0]) + 2);
   for i := 1 to byte(arg[0]) do
   begin
      arr[i] := arg[stri];
      stri := stri + 1;
   end;
   arr[0] := '#';
   arr[byte(arg[0]) + 1] := #0;
   twirc_cmd_join(state, pchar(arr));
end;

procedure handle_messages(state : Ptwirc_state_t; event:Ptwirc_event_t);cdecl;
begin
   write(#27'[1;31m');
   write((event^).origin, ': ');
   write(#27'[1;32m');
   writeln((event^).message);
   write(#27'[0;37m');
end;

var
   state     : Ptwirc_state_t;
   callbacks : Ptwirc_callbacks_t;
begin
   if paramCount < 1 then
      begin
	 writeln(stderr, 'Error: you have to provide channel name');
	 exit;
      end;
   state := twirc_init;
   callbacks := twirc_get_callbacks(state);
   (callbacks^).welcome := @handle_welcome;
   (callbacks^).privmsg := @handle_messages;
   twirc_connect_anon(state, 'irc.chat.twitch.tv', '6667');
   twirc_loop(state);
   twirc_kill(state);   
end.
