# benchgab.awk
**AWK script to benchmark commands for runtime and peak memory usage**

## Author
Gábor Dombay  
[GitHub](https://github.com/yabmod/benchgab.awk)

## Objective
Benchmarks and compares an arbitrary number of commands for runtime and peak group memory, with configurable numbers of warmup and test runs.

## Dependencies
- [`cgmemtime`](https://github.com/gsauthof/cgmemtime) (for measuring runtime and peak group memory)

## Output
Tracks **runtime** (rt [s]) and **peak group memory usage** (pm [MB]) For each command, calulates:
- mean, standard deviation (SD), min, and max values.

For performance comparison, provides:
- Normalized Performance Matrix  

## Usage
1. At the beginning of the script, define the **commands to benchmark**, the **number of warmup runs**, and the **number of test runs**.  
By default, it tests it tests `gawk`, `nawk`, and `mawk` by displaying the number of duplicate lines on a provisional sales.csv file. 
```awk
	command["gawk"] = "gawk -F, 'x[$0]++ { i++ } END { print i }' sales.csv"
	command["mawk"] = "mawk -F, 'x[$0]++ { i++ } END { print i }' sales.csv"
	command["nawk"] = "nawk -F, 'x[$0]++ { i++ } END { print i }' sales.csv"
	warmup = 1 
	runs = 10
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
During execution, the script displays the tested command name, the actual run number (negative values indicate warmup runs; warmup runs are excluded from calculations), wall-time, and peak group memory usage.
```
cmd  run  rt[s]   pm[MB]
gawk  -1  1.3776  550.7344
gawk  0   1.3979  550.9883
gawk  1   1.3437  550.9883
gawk  2   1.4178  550.9844
...
```
The results are displayed as follows:
```
Benchmarking Results
cmd	  Runtime [s]			        Peak Memory [MB]
      mean ± sdev    min    max     mean ± sdev     min     max
gawk  1.385 ± 0.026  1.344	1.418	550.94 ± 0.23	550.49	551.27
mawk  1.245 ± 0.036  1.206	1.302	290.59 ± 0.27	290.23	290.99
nawk  1.264 ± 0.007  1.251	1.276	278.82 ± 0.20	278.52	279.03

Normalized Performance Matrix
cmd   RT    PM
gawk  1.11	1.98
mawk  1.00	1.04
nawk  1.02	1.00
```
The **Normalized Performance Matrix** displays each command’s relative efficiency by independently setting the best-in-class runtime (RT) and peak memory (PM) to a 1.0 baseline. All other values represent the exact **proportional overhead** compared to the most efficient result in each category.

## License
MIT — free to use, modify, and distributeSee [LICENSE](LICENSE) for full text.
