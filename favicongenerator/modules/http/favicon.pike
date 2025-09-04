inherit http_websocket;

mapping default_settings = ([
  "singleletter": "G",
  "primarycolor": "#770055",
  "secondarycolor": "#00dddd",
  "textcolor": "#6677cc",
  "shape": "circle",
]);

@retain: mapping favicon_configs = ([]);

constant markdown = #"# Dashboard
<form id=controls>
  <label>Single Letter Text<input type=text name=singleletter size=1></label>
  <label>Primary Color<input type=color name=primarycolor></label>
  <label>Secondary Color<input type=color name=secondarycolor></label>
  <label>Text Color<input type=color name=textcolor></label>
</form>
<div id=indexbox>
</div>
";

constant http_path_pattern = "/favicon/%[^/]";

mapping(string:mixed)|Concurrent.Future http_request(Protocols.HTTP.Server.Request req, string tag) {
  if (!tag || tag == "") return redirect("/");
  if (sizeof(tag) > 64) return redirect("/");
  return render(req, markdown, (["vars": (["ws_group": tag /* type and code may be specified here */])]));
}

mapping(string:mixed) generate_image(Protocols.HTTP.Server.Request req) {
  if (!req->variables->singleletter) return redirect("/favicon/" + String.string2hex(random_string(4)));
  // first intersect (right side) then merge (pipe)
  mapping cfg = default_settings | (default_settings & req->variables);
}

mapping get_state(string|int group, string|void id, string|void type) {
  werror("Getting state for %O %O %O\n", group, id, type);
  return default_settings | (favicon_configs[group] || ([]));
}

void websocket_cmd_configure(mapping(string:mixed) conn, mapping(string:mixed) msg) {
  werror("Configure: %O\n", msg);
  if (!favicon_configs[conn->group]) favicon_configs[conn->group] = ([]);
  favicon_configs[conn->group] |= default_settings & msg;
  send_updates_all(conn->group);
}

protected void create(string name) {
  ::create(name);
  G->G->http_endpoints[name] = lambda() {
    return redirect("/favicon/" + String.string2hex(random_string(4)));
  };
  G->G->http_endpoints[name] = generate_image;
}
