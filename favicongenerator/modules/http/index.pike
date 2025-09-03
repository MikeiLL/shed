inherit http_websocket;

constant markdown = #"# Dashboard
<div id=indexbox>
  Hello, el Mundo!
</div>
";

mapping(string:mixed)|Concurrent.Future http_request(Protocols.HTTP.Server.Request req) {
	// for now group is arbitrarily set to customers.
	// atm supporting two sockets, customers and quotes
	return render(req, markdown, (["vars": (["ws_group": "" /* type and code may be specified here */])]));
}

protected void create(string name) {
	::create(name);
	G->G->http_endpoints[""] = http_request;
}
