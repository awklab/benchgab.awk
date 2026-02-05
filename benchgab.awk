#!/usr/bin/awk -f
# Script: benchgab.awk
# Version: 2026.01.
# Type: AWK script
# Author: Gábor Dombay
# GitHub: https://github.com/yabmod/benchgab.awk
# Objective: Benchmarks and compares an arbitrary number of commands for runtime and peak group memory usage.
# Dependencies: cgmemtime
# Tracks: runtime (rt [s]) and peak group memory (pm [MB])
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
	print "cmd\trun\trt[s]\tpm[MB]"
	for (cmd in command) {
		bench = "cgmemtime -t "command[cmd]" 2>&1"
		for (i = -warmup; i < runs; i++) {
			printf("%s\t%d", cmd, i)
			while ((bench | getline line) > 0) {
				line_num++			
				if (line_num % 2 == 0) {
					split(line, a, ";")
					rt[cmd, i] = a[3]
					pm[cmd, i] = a[5] / 1024
					printf("\t%.4f\t%.4f\n", rt[cmd, i], pm[cmd, i])
				}
			}
			close(bench)
		}
	}	
	# Calculating mean, min max, standard deviation (SD)
	for (cmd in command) {
		min_rt[cmd] = rt[cmd, 0]
		min_pm[cmd] = pm[cmd, 0]
		for (i = 0; i < runs; i++) {
			sum_rt[cmd] += rt[cmd, i]
			sum_pm[cmd] += pm[cmd,i]
			if (rt[cmd, i] > max_rt[cmd])
				max_rt[cmd] = rt[cmd, i]
			if (pm[cmd, i] > max_pm[cmd])
				max_pm[cmd] = pm[cmd, i]
			if (rt[cmd, i] < min_rt[cmd])
				min_rt[cmd] = rt[cmd, i]
			if (pm[cmd, i] < min_pm[cmd])
				min_pm[cmd] = pm[cmd, i]
		}
		mean_rt[cmd] = sum_rt[cmd] / runs
		mean_pm[cmd] = sum_pm[cmd] / runs
		# Calculating standard deviation
		for (i = 0; i < runs; i++) {
			diff_rt[cmd] = rt[cmd, i] - mean_rt[cmd]
			ds_rt[cmd] = diff_rt[cmd] * diff_rt[cmd]
			sum_ds_rt[cmd] += ds_rt[cmd] 
			diff_pm[cmd] = pm[cmd, i] - mean_pm[cmd]
			ds_pm[cmd] = diff_pm[cmd] * diff_pm[cmd]
			sum_ds_pm[cmd] += ds_pm[cmd] 
		}
		SD_rt[cmd] = sqrt(sum_ds_rt[cmd] / (runs - 1))
		SD_pm[cmd] = sqrt(sum_ds_pm[cmd] / (runs - 1))
	}
	# Calculating Normalized Performanc Matrix
	best_rt = ""
	best_pm = ""
	for (cmd in command) {
	    if (best_rt == "" || mean_rt[cmd] < best_rt) {
		    best_rt = mean_rt[cmd]
		}
	    if (best_pm == "" || mean_pm[cmd] < best_pm) {
		    best_pm = mean_pm[cmd]
		}
	}
	for (cmd in command) {
		NPM[cmd, "rt"] = mean_rt[cmd] / best_rt	
		NPM[cmd, "pm"] = mean_pm[cmd] / best_pm
	}
	# Printing results	
	print "\nBenchmarking Results"		
	print "cmd\tRuntime [s]\t\t\tPeak Memory [MB]"
	print "\tmean ± sdev\tmin\tmax\tmean ± sdev\tmin\tmax"
	for (cmd in command) 
		printf("%s\t%.3f ± %.3f\t%.3f\t%.3f\t%.2f ± %.2f\t%.2f\t%.2f\n", cmd, mean_rt[cmd], SD_rt[cmd], min_rt[cmd], max_rt[cmd], mean_pm[cmd], SD_pm[cmd], min_pm[cmd], max_pm[cmd])
	print "\nNormalized Performance Matrix"
	print "cmd\tRT\tPM"
	for (cmd in command) 
		printf("%s\t%.2f\t%.2f\n", cmd, NPM[cmd, "rt"], NPM[cmd, "pm"])
}

