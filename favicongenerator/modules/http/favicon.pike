inherit http_websocket;
inherit annotated;

mapping default_settings = ([
  "text": "G",
  "primarycolor": "#770055",
  "secondarycolor": "#00dddd",
  "textcolor": "#6677cc",
  "shape": "circle",
]);

@retain: mapping favicon_configs = ([]);

constant markdown = #"# Dashboard
<form id=controls>
  <label>Single Letter Text<input type=text name=text size=1></label>
  <label>Primary Color<input type=color name=primarycolor></label>
  <label>Secondary Color<input type=color name=secondarycolor></label>
  <label>Text Color<input type=color name=textcolor></label>
</form>
<div id=indexbox>
<img id=preview>
</div>
";

constant http_path_pattern = "/favicon/%[^/]";

mapping(string:mixed)|Concurrent.Future http_request(Protocols.HTTP.Server.Request req, string tag) {
  if (!tag || tag == "") return redirect("/");
  if (sizeof(tag) > 64) return redirect("/");
  return render(req, markdown, (["vars": (["ws_group": tag /* type and code may be specified here */])]));
}

mapping(string:mixed) generate_image(Protocols.HTTP.Server.Request req) {
  if (!req->variables->text) return redirect("/favicon/" + String.string2hex(random_string(4)));
  // first intersect (right side) then merge (pipe)
  mapping cfg = default_settings | (default_settings & req->variables);
  Image.Image icon = generate_favicon(cfg);
  array attrs = values(cfg); sort(indices(cfg), attrs);
  string etag = "W/\"" + String.string2hex(Crypto.SHA1.hash(attrs * ",")) + "\""; // weak etag
  return ([
		"type": "image/png", "data": Image.PNG.encode(icon),
		"extra_heads": (["ETag": etag, "Cache-Control": "max-age=604800"]), // 604800 seconds in a week
	]);
}

mapping get_state(string|int group, string|void id, string|void type) {
  mapping cfg = default_settings | (favicon_configs[group] || ([]));
  array keys = indices(cfg), values = values(cfg); sort(keys, values);
  array params = ({});
  //NOTE: Not using Protocols.HTTP.http_encode_query as we want to guarantee that the keys are in a consistent order
  foreach (keys; int i; string k) params += ({k + "=" + Protocols.HTTP.uri_encode(values[i])});
  cfg->url = "/favicon?" + params * "&";
  return cfg;
}

void websocket_cmd_configure(mapping(string:mixed) conn, mapping(string:mixed) msg) {
  werror("Configure: %O\n", msg);
  if (!favicon_configs[conn->group]) favicon_configs[conn->group] = ([]);
  favicon_configs[conn->group] |= default_settings & msg;
  send_updates_all(conn->group);
}

protected void create(string name) {
  ::create(name);
  G->G->http_endpoints[name] = generate_image;
}
