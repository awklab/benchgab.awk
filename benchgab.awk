#!/usr/bin/awk -f
# Script: benchgab.awk
# Type: AWK script
# Author: Gábor Dombay
# GitHub: https://github.com/yabmod/benchgab.awk
# Objective: Benchmarks and compares an arbitrary number of commands for runtime and peak group memory usage.
# Dependencies: cgmemtime
# Tracks: wall-time (wt [s]) and group_mem_high (gmh [MB])
# Output: mean, standard deviation (SD), min, max, Normalized Performance Matrix
# License: MIT — free to use, modify, and distribute
# Usage:
#	command["name"] = "command to be benchmarked"
#	warmup = number of warmup runs
#	runs = number of test runs

BEGIN {
	command["gawk"] = "gawk -F, 'x[$0]++ { i++ } END { print i }' sales.csv"
	command["mawk"] = "mawk -F, 'x[$0]++ { i++ } END { print i }' sales.csv"
	command["nawk"] = "nawk -F, 'x[$0]++ { i++ } END { print i }' sales.csv"
	warmup = 1 
	runs = 10
	#############################################
	print "cmd\trun\twt[s]\tgmh[MB]"
	for (cmd in command) {
		bench = "cgmemtime -t "command[cmd]" 2>&1"
		for (i = -warmup; i < runs; i++) {
			printf("%s\t%d", cmd, i)
			while ((bench | getline line) > 0) {
				line_num++			
				if (line_num % 2 == 0) {
					split(line, a, ";")
					wt[cmd, i] = a[3]
					gmh[cmd, i] = a[5] / 1024
					printf("\t%.4f\t%.4f\n", wt[cmd, i], gmh[cmd, i])
				}
			}
			close(bench)
		}
	}	
	# Calculating mean, min max, standard deviation (SD)
	for (cmd in command) {
		min_wt[cmd] = wt[cmd, 0]
		min_gmh[cmd] = gmh[cmd, 0]
		for (i = 0; i < runs; i++) {
			sum_wt[cmd] += wt[cmd, i]
			sum_gmh[cmd] += gmh[cmd,i]
			if (wt[cmd, i] > max_wt[cmd])
				max_wt[cmd] = wt[cmd, i]
			if (gmh[cmd, i] > max_gmh[cmd])
				max_gmh[cmd] = gmh[cmd, i]
			if (wt[cmd, i] < min_wt[cmd])
				min_wt[cmd] = wt[cmd, i]
			if (gmh[cmd, i] < min_gmh[cmd])
				min_gmh[cmd] = gmh[cmd, i]
		}
		mean_wt[cmd] = sum_wt[cmd] / runs
		mean_gmh[cmd] = sum_gmh[cmd] / runs
		# Calculating standard deviation
		for (i = 0; i < runs; i++) {
			diff_wt[cmd] = wt[cmd, i] - mean_wt[cmd]
			ds_wt[cmd] = diff_wt[cmd] * diff_wt[cmd]
			sum_ds_wt[cmd] += ds_wt[cmd] 
			diff_gmh[cmd] = gmh[cmd, i] - mean_gmh[cmd]
			ds_gmh[cmd] = diff_gmh[cmd] * diff_gmh[cmd]
			sum_ds_gmh[cmd] += ds_gmh[cmd] 
		}
		SD_wt[cmd] = sqrt(sum_ds_wt[cmd] / (runs - 1))
		SD_gmh[cmd] = sqrt(sum_ds_gmh[cmd] / (runs - 1))
	}
	# Calculating Normalized Performanc Matrix
	best_wt = ""
	best_gmh = ""
	for (cmd in command) {
	    if (best_wt == "" || mean_wt[cmd] < best_wt) {
		    best_wt = mean_wt[cmd]
		}
	    if (best_gmh == "" || mean_gmh[cmd] < best_gmh) {
		    best_gmh = mean_gmh[cmd]
		}
	}
	for (cmd in command) {
		NPM[cmd, "wt"] = mean_wt[cmd] / best_wt	
		NPM[cmd, "gmh"] = mean_gmh[cmd] / best_gmh
	}
	# Printing results	
	print "\nBenchmarking Results"		
	print "cmd\twall-time [s]\t\t\tgroup mem high [MB]"
	print "\tmean ± sdev\tmin\tmax\tmean ± sdev\tmin\tmax"
	for (cmd in command) 
		printf("%s\t%.3f ± %.3f\t%.3f\t%.3f\t%.2f ± %.2f\t%.2f\t%.2f\n", cmd, mean_wt[cmd], SD_wt[cmd], min_wt[cmd], max_wt[cmd], mean_gmh[cmd], SD_gmh[cmd], min_gmh[cmd], max_gmh[cmd])
	print "\nNormalized Performance Matrix"
	print "cmd\twt\tgmh"
	for (cmd in command) 
		printf("%s\t%.2f\t%.2f\n", cmd, NPM[cmd, "wt"], NPM[cmd, "gmh"])
}

