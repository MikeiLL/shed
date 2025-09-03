import { choc, on, DOM } from "https://rosuav.github.io/choc/factory.js";
const {H1} = choc; //autoimport
import * as utils from "./utils.js";

export function render(state) {
  set_content("#indexbox", [

  ]);
}

on("change", "input", (e) => ws_sync.send({
  cmd: "configure",
  [e.match.name]: e.match.value,
}))
