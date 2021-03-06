import math
import random
import statistics
import matplotlib.pyplot as plt
import numpy as np
import scipy.stats as stats

def parse_roll_test(test):
	# Parse the result of 'roll test' from Minstrel Hall
	dist = {}
	total = 0
	for line in test.split("\n"):
		if ":" in line:
			val, prob = line.split(":")
			dist[val] = int(prob)
			total += int(prob)
	# Parsing complete. We now have a mapping of result to number of instances,
	# and a total result count. So dist[X]/total == probability of X occurring,
	# for any X.
	return dist, total

def chisq(dist, total):
	expected = total / len(dist)
	error = 0
	for result, count in dist.items():
		error += (count - expected) ** 2 / expected
	print("χ² =", error)


if 0: chisq(*parse_roll_test("""
1: 10135
2: 9971
3: 9774
4: 9849
5: 10059
6: 9936
7: 9990
8: 10027
9: 9917
10: 10054
11: 10202
12: 10008
13: 10136
14: 10060
15: 10012
16: 9941
17: 10007
18: 9956
19: 10096
20: 9870
"""))

def roll_dice(n):
	# Roll an N-sided dice. Mess with this to create unfair distributions.
	roll = random.randrange(n) + 1
	if roll in {1, n} and not random.randrange(40):
		roll = random.randrange(n) + 1
	return roll

def test_dice_roller(n, tries):
	dist = {}
	# Initialize to all zeroes to ensure that we have entries for everything
	for i in range(n):
		dist[i + 1] = 0
	# Roll a bunch of dice and see what comes up
	for _ in range(tries):
		dist[roll_dice(n)] += 1
	chisq(dist, tries)

# for _ in range(15): test_dice_roller(20, 200000)


#(x ** 500_000_000) * ((1-x) ** 500_000_000)

#fac(1_000_000_000) / (fac(500_000_000) * fac(500_000_000))

def choose(n, k):
	# Actually calculate n choose k
	# n! / (k!(n-k)!)
	num = denom = 1
	for i in range(1, k + 1):
		num *= i + n - k
		denom *= i
	return num // denom
def approxchoose(n, k):
	# Approximate n choose k for large n and k
	# Returns values a smidge too high, and has to be special-cased for N choose 0 and N choose N
	if k == 0 or k == n: return 1
	return (n / (2 * math.pi * k * (n-k))) ** 0.5 * (n ** n) / (k ** k * (n - k) ** (n - k))
def choosehalf(n):
	# Approximate 2n choose n
	return 2 ** (2*n) / (math.pi * n)**0.5
print(choose(20, 10))
print(approxchoose(20, 10))
print(choosehalf(10))
# print(approxchoose(1_000_000, 500_000))
# print(choosehalf(500_000))

# Binomial distribution for N coin tosses
# What is the standard deviation of [0]*N + [1]*N ?
N = 1_000_000_000
half = 5_000_000_000
def stdev(N):
	ss = 0
	for n in range(N):
		ss += approxchoose(N, n) * (n - N/2) ** 2
	return (ss / (2**N-1)) ** 0.5

def pascal(n):
	if n == 0: return [1]
	p = [0] + pascal(n - 1) + [0]
	return [p[i] + p[i + 1] for i in range(len(p) - 1)]

if 0:
	# Calculate the error in the approxchoose function by comparing against
	# the corresponding row in Pascal's Triangle
	N = 20
	for n, count in enumerate(pascal(N)):
		print(f"%{len(str(N))}d %.5f" % (n, approxchoose(N, n) / count), count)
	import sys; sys.exit(0)

# statistics.NormalDist(0.5, stdev(N))
# for N in (4, 10, 20, 100, 1_000_000, 1_000_000_000, 1_000_000_000_000):
for N in (5, 10, 15, 20, 50, 75, 100):
	sigmaN = stdev(N) / N
	print(N, sigmaN)
	x = np.linspace(0, 1.0, N + 2)
	if N < 50:
		p = [p * n / 2**N * 2 for n, p in enumerate(pascal(N) + [0])]
		plt.plot(x, p, label=f"Actual [{N}]")
	if 0: # Slow calculation of the same figure stdev gives
		samples = []
		for n, count in enumerate(pascal(N)): samples.extend(count * [n])
		# mu / N, sigma / N
		muN, sigmaN = 0.5, statistics.stdev(samples)/N
		print(N, sigmaN)
	plt.plot(x, stats.norm.pdf(x, 0.5, sigmaN), label=str(N))
# What is the first derivative of the PDF of (1e9 choose 5e8) at 0.5?
# f''(x) = 1/sqrt(2*pi)*e**(-1/2x^2) * (x^2-1)
# 499_000_000 <= x <= 501_000_000 ?? What probability?
# CDF: What is the probability that x < 499e6 ?
# CDF: What is the probability that x < 501e6 ?
# What is the spread around the mean such that CDF(x+spread) - CDF(x-spread) == 0.99?

plt.legend()
plt.show()
