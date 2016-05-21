/* All windows on the second monitor should exist on all desktops.

Effectively, with this active, workspace switching applies only to the primary
monitor, and not to the second. In order to do this, it needs to know the size
of the primary monitor; this is presumed to be the width of any instance of an
xfce4-panel, calculated on startup.
*/

int monitor_width;

void poll()
{
	call_out(poll, 60);
	sscanf(Process.run(({"wmctrl", "-lG"}))->stdout,"%{0x%8x %d %d %d %d %d%*[ ]%*[^ ] %s\n%}", array info);
	if (!monitor_width)
	{
		//First, zip through and find xfce4-panel, and grab the greatest width.
		//This assumes that the user is running a panel that takes up the entire
		//first monitor; currently, I don't know of any better way to get this.
		foreach (info, array row) if (row[-1] == "xfce4-panel")
			monitor_width = max(monitor_width, row[2]+row[4]);
		write("Monitor width: %d\n", monitor_width);
	}
	foreach (info, [int id, int desktop, int x, int y, int w, int h, string title])
	{
		if (x > monitor_width)
			//This window is past the edge
			Process.create_process(({"wmctrl", "-ir", (string)id, "-b", "add,sticky"}))->wait();
		else if (we stickied this window)
			Process.create_process(({"wmctrl", "-ir", (string)id, "-b", "remove,sticky"}))->wait();
	}
}

int main()
{
	poll();
}
