import {
	choc,
	set_content,
	fix_dialogs,
	on,
	DOM,
} from "https://rosuav.github.io/choc/factory.js";
const { A, BR, BUTTON, DIALOG, DIV, FOOTER, H3, HEADER, P, SECTION, SPAN } = choc; //autoimport
on("click", ".logout", e => {
	fetch("/logout", { credentials: "same-origin" })
		.then(r => location.reload());
});


document.querySelectorAll("[data-icon]").forEach(el => el.prepend(icons[el.dataset.icon]({width: 24, height: 32})));

fix_dialogs({
	close_selector: ".dialog_cancel,.dialog_close",
	click_outside: "formless",
	methods: 1, // apply all choc fixes
});

function ensure_simpleconfirm_dlg() {
	//Setting the z-index is necessary only on older Firefoxes that don't support true showModal()
	if (!DOM("#simpleconfirmdlg")) document.body.appendChild(
		DIALOG({ id: "simpleconfirmdlg", style: "z-index: 999" },
			SECTION([
				HEADER([H3("Are you sure?"),
				DIV(
					BUTTON({ type: "button", class: "dialog_cancel" }, "x"))]),
				DIV([
					P({ id: "simpleconfirmdesc" }, "Really do the thing?"),
					FOOTER([BUTTON({ id: "simpleconfirmyes" }, "Confirm"), BUTTON({ class: "dialog_close" }, "Cancel")]),
				]),
			])));
}

let simpleconfirm_callback = null, simpleconfirm_arg = null, simpleconfirm_match;

//Simple confirmation dialog. If you need more than just a text string in the
//confirmdesc, provide a function; it can return any Choc Factory content.
//One argument will be carried through. For convenience with Choc Factory event
//objects, its match attribute will be carried through independently.
export function simpleconfirm(confirmdesc, callback) {
	ensure_simpleconfirm_dlg();
	return e => {
		simpleconfirm_callback = callback; simpleconfirm_arg = e;
		if (e && e.match) simpleconfirm_match = e.match;
		set_content("#simpleconfirmdesc", typeof confirmdesc === "string" ? confirmdesc : confirmdesc(e));
		DOM("#simpleconfirmdlg").showModal();
	};
}
on("click", "#simpleconfirmyes", e => {
	const cb = simpleconfirm_callback, arg = simpleconfirm_arg;
	if (simpleconfirm_match) arg.match = simpleconfirm_match;
	simpleconfirm_match = simpleconfirm_arg = simpleconfirm_callback = undefined;
	if (cb) cb(arg);
	DOM("#simpleconfirmdlg").close();
})

on("click", ".opendlg", e => { e.preventDefault(); DOM("#" + e.match.dataset.dlg).showModal(); });
