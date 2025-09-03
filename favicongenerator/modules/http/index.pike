inherit http_websocket;

constant markdown = #"# Dashboard
<div id=dashboardtiles class=flexwrap>
	<section id=pricesheets><span class=loading>Loading</span></section>
	<section id=customers><span class=loading>Loading</span></section>
</div>
";

mapping(string:mixed)|Concurrent.Future http_request(Protocols.HTTP.Server.Request req) {
	if (!req->misc->session->user) return redirect("/login");
	// for now group is arbitrarily set to customers.
	// atm supporting two sockets, customers and quotes
	return render(req, markdown, (["vars": (["ws_group": "", "ws_type": "customers", "ws_code": "dashboard"])]));
}

protected void create(string name) {
	::create(name);
	G->G->http_endpoints[""] = http_request;
}
