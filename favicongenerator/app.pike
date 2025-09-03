/* Http server

*/

array(string) bootstrap_files = ({"globals.pike", "console.pike", "connection.pike", "modules", "modules/http"});
array(string) restricted_update;
mapping G = ([]);

mapping constant_sources = ([]);
string currently_compiling_module;

class CompilerHandler {
	int(1bit) reported;
	void compile_error(string filename, int line, string msg) {
		reported = 1;
		werror("\e[1;31m%s:%d\e[0m: %s\n", filename, line, msg); // ansi color codes
	}
	mixed resolv(string identifier, string filename, object|void handler, object|void compat_handler) {
		mixed ret = master()->resolv(identifier, filename, handler, compat_handler);
		if (!ret && filename == "utils.pike") {
			if (string fn = constant_sources[identifier]) {
				werror("Resolving %s from %s\n", identifier, fn);
				ret = bootstrap(fn)[identifier];
				currently_compiling_module = filename;
			}
		}
		return ret;
	}
}

object bootstrap(string c) // c is the code file to compile
{
	currently_compiling_module = c;
	sscanf(explode_path(c)[-1], "%s.pike", string name);
	program|object compiled;

	object handler = CompilerHandler();
	//mixed ex = catch {compiled = compile_file(c, handler);};
	//if (ex) {if (!handler->reported) werror("Exception in compile!\n%s\n", ex->describe()); return 0;}
	mixed ex = catch {compiled = compile_file(c, handler);}; // try is implicit.
	if (ex) {
		if (!handler->reported) {
			werror("Exception in compile!\n");
			werror(ex->describe()+"\n");
		}
		return 0;
	}
	if (!compiled) werror("Compilation failed for "+c+"\n");
	if (mixed ex = catch {
			compiled = compiled(name);
		}) {
		G->warnings++;
		werror(describe_backtrace(ex)+"\n");
	}
	werror("Bootstrapped "+c+"\n");
	return compiled;
}

int bootstrap_all()
{
	if (restricted_update) bootstrap_files = restricted_update;
	else {
		constant_sources = ([]);
		object main = bootstrap(__FILE__);
		if (!main || !main->bootstrap_files) {werror("UNABLE TO RESET ALL\n"); return 1;}
		bootstrap_files = main->bootstrap_files;
	}
	int err = 0;
	foreach (bootstrap_files, string fn)
		if (file_stat(fn)->isdir)
		{
			foreach (sort(get_dir(fn)), string f)
				if (has_suffix(f, ".pike")) err += !bootstrap(fn + "/" + f);
		}
		else err += !bootstrap(fn);
	if (!err && !restricted_update) {
		Stdio.write_file("constant_sources.json", Standards.JSON.encode(constant_sources, 7));
	}
	return err;
}

int | Concurrent.Future main(int argc,array(string) argv)
{
	add_constant("add_constant") {
		add_constant(@__ARGS__);
		if (__ARGS__[1]) constant_sources[__ARGS__[0]] = currently_compiling_module;
	};

	add_constant("G", this);
	G->args = Arg.parse(argv);
	foreach ("tables usercreate userdelete userupdate help" / " ", string cmd) if (G->args[cmd]) G->args->exec = cmd;
	if (string fn = G->args->exec) {
		// pike app.pike --exec=test
		restricted_update = ({"globals.pike", "console.pike", "database.pike", "utils.pike"});
		constant_sources = Standards.JSON.decode(Stdio.read_file("constant_sources.json") || "{}");
		bootstrap_all();
		if (fn == 1)
			if (sizeof(G->args[Arg.REST])) [fn, G->args[Arg.REST]] = Array.shift(G->args[Arg.REST]);
			else fn = "help";
		return (G->utils[replace(fn, "-", "_")] || G->utils->help)();
	}
	bootstrap_all();
	// kill -l will show mapping of signals to numbers.
	// 1 is SIGHUP, 2 is SIGINT, 3 is SIGQUIT, 9 is SIGKILL, 15 is SIGTERM
	// SIGHUP means "hang up", which is what systemd sends us when we use systemctl
	// to ask systemd to reload this process by pressing some keys on the keyboard
	// in the sequence "sudo systemctl reload oren".
	signal(1, bootstrap_all);
	return -1;
}
