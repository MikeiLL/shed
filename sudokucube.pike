/* Sudoku cube solver... I hope.

Each square is correctly oriented for one possible position:
+---+---+---+
| 1 | 2 | 3 |
+---+---+---+
| 4 | M | 6 |
+---+---+---+
| 7 | 8 | 9 |
+---+---+---+

The middle position is the definitive beginning; everything else goes around that.
However, the middle position is also the only one that doesn't truly have any
orientation, so we have to assume it can be oriented any way.

Each digit is uniquely oriented, with the possible exception of the 8s. Thus any
given square can be in only one of the nine slots above, based on its orientation.
Squares are identified by two-digit numbers - the displayed digit and the position
- so a corner square might be a 21, 43, 77, or 19, and an edge could be 22, 24,
96, or 38.
*/

array corners = ("49,63,91 57,41,23 11,31,73 13,31,73 57,77,89 59,97,99 11,69,87 23,49,67"/" ")[*]/",";
array edges = ("36,98 72,96 36,74 32,68 24,42 82,92 16,24 56,84 64,86 38,44 28,88 28,52"/" ")[*]/",";
array middles = "1 1 4 5 6 7"/" ";

//Recursively attempt to add to a solution
//Returns 0 if nothing could be done.
array solve(array state,array corners,array edges)
{
	int nextpos = sizeof(state); if (nextpos>=5) ++nextpos;
	if (nextpos >= 10) return state;
	nextpos += '0'; //Use the character for convenience
	array search = (nextpos&1) ? corners : edges;
	foreach (search, array cube) foreach (cube, string square)
	{
		if (square[1] != nextpos) continue; //Exclusion: Wrong orientation
		if (has_value(state[0], square[..0])) continue; //Exclusion: Already got one.
		array st = state+({cube}); st[0]+=square[..0];
		array sol = solve(st, corners-({cube}), edges-({cube}));
		if (sol) return sol;
	}
}

int main()
{
	if (0)
	{
		//Sanity check(s)
		mapping counts=([]);
		foreach (corners+edges,array set) foreach (set,string square) counts[square[1..]]++;
		write("Position counts: %O\n",counts);
		counts=([]);
		foreach (corners+edges+({middles}),array set) foreach (set,string square) counts[square[..0]]++;
		write("Digit counts: %O\n",counts);
		write("Should be all sixes, Cox & Box style.\n");
		return 0;
	}
	write("%O\n",solve(({"5"}),corners,edges));
}
