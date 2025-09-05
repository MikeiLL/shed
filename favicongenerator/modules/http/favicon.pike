inherit http_websocket;
inherit annotated;

mapping default_settings = ([
  "text": "G",
  "primarycolor": "#770055",
  "secondarycolor": "#00dddd",
  "textcolor": "#6677cc",
  "shape": "circle",
  "font": "Lato",
]);

@retain: mapping favicon_configs = ([]);

array select_fonts = ({
    "Adobe Jenson Pro",
    "AdobeJensonSmallCaps",
    "Aloja Extended",
    "AmerType Md BT",
    "Amiri",
    "Amiri Quran",
    "Amiri Quran Colored",
    "Anagram NF",
    "Arabic Transparent",
    "Arber Vintage Extended",
    "Archive",
    "Arkhip",
    "Armin Grotesk",
    "Asap",
    "Asap Black",
    "Asap Condensed",
    "Asap Extra",
    "Asap ExtraLight",
    "Asap Light",
    "Asap Medium",
    "Asap Semi",
    "Austra",
    "Banaue",
    "Besom extended",
    "Blippo Black LT Regular",
    "Blippo Stencil LT Regular",
    "Building",
    "Calamity Teen BTN",
    "CaslonCPswash",
    "Chapbook",
    "Choplin",
    "Cornera",
    "Cornpile",
    "Crop Circle Dingbats",
    "DejaVu Sans",
    "Dekar",
    "Dekar Light",
    "Disclaimer",
    "Doulos SIL",
    "Droid Serif",
    "ENTRA",
    "ElKarnito",
    "ElKarnito Catchwords",
    "Emily In White",
    "Emily In White Swashes",
    "Espa",
    "Espa Extended",
    "Eurostile Next Pro",
    "FS Renaissance",
    "FetteEgyptienne",
    "Fjord-free",
    "FontAwesome",
    "Franchise",
    "GOGOIA",
    "Gandhari Unicode",
    "Geomanist",
    "Gilway Paradox",
    "Governor",
    "Gravity",
    "Hover",
    "Hover Classic",
    "Iconic",
    "Iconic Pictograms",
    "Iconic Stencil",
    "Iconic Stencil Layer",
    "Inconsolata",
    "Intro Goodies",
    "Intro Head B",
    "Intro Head B UC",
    "Intro Head H",
    "Intro Head H UC",
    "Intro Head L",
    "Intro Head L UC",
    "Intro Head R",
    "Intro Head R UC",
    "Intro Rust",
    "Intro Rust Book",
    "Intro Rust G",
    "Intro Rust H1",
    "Intro Rust H2",
    "Intro Rust L",
    "Intro Script B",
    "Intro Script L",
    "Intro Script R",
    "Isidora",
    "KiloGram",
    "Kompakt LT Std",
    "LH Line1 Sans",
    "Lane - Narrow",
    "Langdon",
    "Lato",
    "Le Havre Hand",
    "Leira",
    "Lexend",
    "Lighthouse Personal Use",
    "Lino Stamp",
    "Lokka",
    "Luna Bar",
    "Mangal",
    "Material Icons",
    "MetDemo",
    "Minnadrop",
    "MinstrelPosterWHG",
    "Mom?sTypewriter",
    "Muli",
    "Muli ExtraBold",
    "Muller",
    "Museo",
    "MuseoModerno",
    "MusiSync",
    "Myriad Pro",
    "Nakula",
    "Noah",
    "Noah Grotesque",
    "Noah Head",
    "Noah Text",
    "NoteHedz",
    "Noto Emoji",
    "Open Sans",
    "OpenDyslexic NF",
    "OpenDyslexic Nerd Font",
    "OpenDyslexic Nerd Font Mono",
    "OpenDyslexicAlta NF",
    "OpenDyslexicAlta Nerd Font",
    "OpenDyslexicAlta Nerd Font Mono",
    "OpenDyslexicMono NF",
    "OpenDyslexicMono Nerd Font",
    "OpenDyslexicMono Nerd Font Mono",
    "PL Benguiat Caslon",
    "PT Sans Narrow",
    "Palatino Small Caps & Old Style",
    "Peomy-Extended",
    "Perspective Sans Black",
    "PiS VinoZupa",
    "Please write me a song",
    "Raleway",
    "Raleway Black",
    "Raleway ExtraBold",
    "Raleway ExtraLight",
    "Raleway Light",
    "Raleway Medium",
    "Raleway SemiBold",
    "Raleway Thin",
    "Roboto Flex",
    "Saab",
    "Sabler Titling",
    "Sahadeva",
    "Scansky",
    "Si Kancil",
    "SimSun",
    "Spline Sans Mono",
    "Stab",
    "Summer Font",
    "Tchaikovsky",
    "Tibetan Machine Uni",
    "ToneDeaf BB",
    "Trajan Pro",
    "TypeMyMusic",
    "Undeka",
    "Vanio Trial",
    "Weem",
    "file-icons",
    "lilyjazz-text"
});

constant markdown = #"# Dashboard
<form id=controls>
  <label>Single Letter Text<input type=text name=text size=1></label>
  <label>Primary Color<input type=color name=primarycolor></label>
  <label>Secondary Color<input type=color name=secondarycolor></label>
  <label>Text Color<input type=color name=textcolor></label>
  <label>Shape/Pattern<select name=shape>
    <option value=none>None</option>
    <option value=circle>Circle</option>
    <option value=diamond>Diamond</option>
    <option value=6star>Six Pointed Star</option>
    <option value=hsplit>Horizontal Split</option>
    <option value=vsplit>Vertical Split</option>
    <option value=dsplitl>Diagonal Split Left</option>
    <option value=dsplitr>Diagonal Split Right</option>
    <option value=hstripe>Horizontal Stripes</option>
    <option value=vstripe>Vertical Stripes</option>
    <option value=dtriangle>Down Triangle</option>
    <option value=utriangle>Up Triangle</option>
    </select>
  </label>
  <label>Font<select name=font>$$fonts$$</select></label>
</form>
<div id=indexbox>
<img id=preview>
</div>
";

constant http_path_pattern = "/favicon/%[^/]";

mapping(string:mixed)|Concurrent.Future http_request(Protocols.HTTP.Server.Request req, string tag) {
  if (!tag || tag == "") return redirect("/");
  if (sizeof(tag) > 64) return redirect("/");
  array fonts = sort(indices(Image.Fonts.list_fonts()));
  return render(req, ([
    "vars": (["ws_group": tag /* type and code may be specified here */]),
    "fonts": map(fonts & select_fonts, lambda(string name){return sprintf("<option value=\"%s\">%<s</option>\n", (string) name);}) * "",
  ]));
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
  if (!favicon_configs[conn->group]) favicon_configs[conn->group] = ([]);
  favicon_configs[conn->group] |= default_settings & msg;
  send_updates_all(conn->group);
}

protected void create(string name) {
  ::create(name);

  Image.Fonts.set_font_dirs(({"/Users/mikekilmer/Library/Fonts"}));
  G->G->http_endpoints[name] = generate_image;
}
