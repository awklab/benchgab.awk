# benchgab.awk
**AWK script to benchmark commands for runtime and peak memory usage**

## Author
Gábor Dombay  
[GitHub](https://github.com/awklab/benchgab.awk)

## Objective
Benchmarks and statistically compares an arbitrary number of commands for runtime and peak group memory, with configurable numbers of warmup and test runs.

## Dependencies
- [`cgmemtime`](https://github.com/gsauthof/cgmemtime) (for measuring runtime and peak group memory)

## Output
Tracks **runtime** (rt [s]) and **peak group memory usage** (pm [MB]) For each command, calulates:
- mean, standard deviation (SD), median, min and max values, jitter (JTR%).

For performance comparison, provides:
- Normalized Benchmarks  

## Usage
1. At the beginning of the script, define the **commands to benchmark**, the **number of warmup**, and the **number of test runs**.  
By default, it tests it tests the [BEHILOS Benchmark](https://awklab.com/behilos-benchmark). 
```awk
	command["grep"]  = "grep '^[behilos]*$' /usr/share/dict/web2"
	command["rg"]	 = "rg '^[behilos]*$' /usr/share/dict/web2"
	command["gawk"]  = "gawk '/^[behilos]*$/' /usr/share/dict/web2"
	...
	warmup = 1 
	runs = 100
```
2. Make the script executable:

```bash
chmod +x benchgab.awk
```  
3. Run the script directly:
```bash
./benchgab.awk
```

## Sample Output
During execution, the script displays the tested command name, the actual run number (negative values indicate warmups; warmups are excluded from calculations), runtime, and peak group memory.
```
cmd	run	rt[s]	pm[MB]
gawk	-1	0.0211	0.4883
gawk	0	0.0218	1.0000
gawk	1	0.0214	0.7500
gawk	2	0.0219	0.7383
...
```
The results are displayed as follows:
```
--- Statistical Summary ---
cmd     Runtime [s]                      Peak Memory [MB]
        mean ± sdev      min     median  max     Jtr%    mean ± sdev      min     median  max     Jtr%
grep    0.0048 ± 0.0003  0.0041  0.0048  0.0068  0.3     0.71 ± 0.11      0.60    0.64    1.12    10.9
rg      0.0056 ± 0.0003  0.0048  0.0056  0.0064  1.1     1.13 ± 0.17      0.98    1.01    1.75    11.4
gawk    0.0220 ± 0.0008  0.0204  0.0219  0.0251  0.5     0.75 ± 0.16      0.48    0.74    1.00    1.0
...

--- Normalized Benchmarks ---
cmd     RT      PM      d       F
grep    1.00    1.18    0.18    1.18
rg      1.17    1.88    0.89    2.19
gawk    4.52    1.37    3.54    6.20
...

```
The normalized benchmarks show each command’s relative efficiency, setting the best-in-class runtime (RT) and peak memory (PM) to a baseline of 1.0. The benchmark also calculates the Euclidean distance (d) and the total resource footprint (F).

## License
MIT — free to use, modify, and distributeSee [LICENSE](LICENSE) for full text.
