/* Throughput and analysis measurement for the Her Yeri Parlak Cans system

Timing: All packets get usec time incorporated. On receipt, calculate offset:
your_time() - packet time
This value is the sum of two unknown quantities: the transmission latency
and the clock difference between the two computers. We assume that the clock
difference is an approximately stable quantity, and we can be confident that
the latency is a nonnegative value. Therefore we take the lowest total ever
seen and take that to be the clock offset. (Closest to negative infinity,
not closest to zero; the clock offset could be either direction.)

Having established a "best ever seen" offset, we assume that the current
packet's offset exceeds that best by a value representing only the latency.
As such, we can now discard any packets with latency in excess of some
predetermined value (eg 1500ms). In the face of clock errors or other time
discrepancies, this will either cope smoothly (if the clock offset is
lowered permanently and stably), or cause the audio to be muted (if the
offset increases permanently) or intermittent (if it fluctuates). Anyone who
hears silence can bounce the receiver to reset all time offsets and force a
recalculation; the fluctuating time issue is fundamentally unresolvable, and
the only solution is to have a latency window that exceeds the fluctuation.

The upshot of this is that the clock used does not actually need to have any
correlation to wall time. It doesn't even have to be consistent across nodes
in the group! Implementations are encouraged to use a monotonic clock if one
is available.
*/
constant ADDR = "224.0.0.1"; //Multicast address: All hosts on current network.
constant PORT = 5170;
Stdio.UDP|array(Stdio.UDP) udp = Stdio.UDP()->bind(PORT); //NOTE: *Not* enabling IPv6; this app is v4-only.
array(string) ips;
string sendchannel = "global";
array(string) recvchannels = ({"global"});

mapping(string:int) senders = ([]);
mapping(string:float) active = ([]);
int basetime = time();

void send()
{
	call_out(send, 0.01);
	udp->send(ADDR, PORT, sprintf("T%d C%s\nHello, world", gethrtime(), sendchannel), 2);
	string line = "";
	float cutoff = time(basetime) - 0.5;
	foreach (sort(indices(active)), string ip)
		if (active[ip] > cutoff) line += " " + ip;
	write(line + "\e[K\r");
}

void recv(mapping(string:int|string) info)
{
	if (info->port != PORT) return; //Not from one of us.
	if (has_value(ips, info->ip)) return; //Normally ignore our loopback (remove this for testing)
	//NOTE: Currently the packet format is strict, but it's designed to be able to be
	//more intelligently parsed in the future, with space-delimited tokens and marker
	//letters, ending with a newline before the payload. (The payload is binary data,
	//which normally will be an audio blob; the header is ASCII text. Maybe UTF-8.)
	sscanf(info->data, "T%d C%s\n%s", int packettime, string chan, string(0..255) data);
	if (!data) return; //Packet not in correct format.
	if (!has_value(recvchannels, chan)) return; //Was sent to a channel we don't follow.
	int offset = gethrtime() - packettime;
	int lastofs = senders[info->ip];
	if (undefinedp(lastofs) || offset < lastofs) senders[info->ip] = lastofs = offset;
	int lag = offset - lastofs;
	if (lag > 500000) werror("%s: lag %d usec\n", info->ip, lag); //Half a second old? Drop it.
	active[info->ip] = time(basetime);
}

int main(int argc, array(string) argv)
{
	udp->set_read_callback(recv);
	ips = sort(values(Stdio.gethostip())->ips * ({ }));
	if (argc > 1 && has_value(ips, argv[1])) ips = ({argv[1]});
	write("My IP: %s\n", ips * " + ");
	//We pick the first one (after sorting textually) to be our identity.
	//Since we listen on every available IP, this won't majorly hurt,
	//and the sort ensures that it's stable, if a little arbitrary.
	//Most computers will have just one IP anyway, so none of this matters.
	udp->enable_multicast(ips[0]);
	udp->add_membership(ADDR);
	if (has_value(argv, "--send-all"))
	{
		//To avoid craziness in a multi-network situation, send via
		//every available IP address, not just the default. Note that
		//this can cause split-brain situations if there are actually
		//multiple networks using the cans, but otherwise, it means
		//you don't have to explicitly pick an IP or interface.
		udp = ({udp});
		foreach (ips[1..], string ip)
		{
			udp += ({Stdio.UDP()->bind(PORT)});
			udp[-1]->enable_multicast(ip);
		}
	}
	call_out(send, 0.01);
	return -1;
}
