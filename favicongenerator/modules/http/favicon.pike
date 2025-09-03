inherit http_websocket;

constant markdown = #"# Dashboard
<div id=controls>
  <label>Single Letter Text<input type=text name=text size=1></label>
</div>
<div id=indexbox>
</div>
";

constant http_path_pattern = "/favicon/%[^/]";

mapping(string:mixed)|Concurrent.Future http_request(Protocols.HTTP.Server.Request req, string tag) {
  if (!tag || tag == "") return redirect("/");
  if (sizeof(tag) > 64) return redirect("/");
  return render(req, markdown, (["vars": (["ws_group": tag /* type and code may be specified here */])]));
}

__async__ mapping get_state(string|int group, string|void id, string|void type) {
  werror("Getting state for %O %O %O\n", group, id, type);
  return (["hello": "world."]);
}

void websocket_cmd_configure(mapping(string:mixed) conn, mapping(string:mixed) msg) {
  werror("Configure: %O\n", msg);
}

protected void create(string name) {
  ::create(name);
  G->G->http_endpoints[name] = lambda() {
    return redirect("/favicon/" + String.string2hex(random_string(4)));
  };
}
