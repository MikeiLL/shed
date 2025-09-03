inherit http_websocket;

constant markdown = #"# Dashboard
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

protected void create(string name) {
  ::create(name);
  G->G->http_endpoints[name] = lambda() {
    return redirect("/favicon/" + String.string2hex(random_string(4)));
  };
}
