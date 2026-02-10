#!/usr/bin/awk -f
# Script: benchgab.awk
# Ver.: 2026.02.10.
# Type: AWK script
# Author: Gábor Dombay
# GitHub: https://github.com/yabmod/benchgab.awk
# Objective: Benchmarks and compares an arbitrary number of commands for runtime and peak group memory usage.
# Dependencies: cgmemtime
# Tracks: runtime (rt [s]) and peak group memory (pm [MB])
# Statistical Output: mean, standard deviation (SD), min, median, max, jitter[%]
# Normalized Benchmarks from medians: RT (normalized runtime), PM (normalized peak memory), d (Euclidean Distance), F (Resource Footpint, RTxPM)
# License: MIT — free to use, modify, and distribute
# Usage:
#	command["name"] = "command to be benchmarked"
#	warmup = number of warmup runs
#	runs = number of test runs
# This version contains the BEHILOS benchmarks.

BEGIN {
	command["grep"]  = "grep '^[behilos]*$' /usr/share/dict/web2"
	command["rg"]	 = "rg '^[behilos]*$' /usr/share/dict/web2"
	command["gawk"]  = "gawk '/^[behilos]*$/' /usr/share/dict/web2"
	command["mawk"]  = "mawk '/^[behilos]*$/' /usr/share/dict/web2"
	command["nawk"]  = "nawk '/^[behilos]*$/' /usr/share/dict/web2"
	command["ag"]	 = "ag -s '^[behilos]*$' /usr/share/dict/web2"
	command["pt"]	 = "pt -e '^[behilos]*$' /usr/share/dict/web2"
	command["ack"]	 = "ack '^[behilos]*$' /usr/share/dict/web2"
	command["ugrep"] = "ugrep '^[behilos]*$' /usr/share/dict/web2"
	command["sift"]  = "sift '^[behilos]*$' /usr/share/dict/web2"
	warmup = 1 
	runs = 100
	#############################################
	# Run benchmarks
	print "cmd\trun\trt[s]\tpm[MB]"
	for (cmd in command) {
		bench = "cgmemtime -t "command[cmd]" 2>&1"
		for (i = -warmup; i < runs; i++) {
			printf("%s\t%d", cmd, i)
			while ((bench | getline line) > 0) {
				splt = split(line, a, ";")
				if (splt == 5) {
					rt[cmd, i] = a[3]
					pm[cmd, i] = a[5] / 1024
					printf("\t%.4f\t%.4f\n", rt[cmd, i], pm[cmd, i])
				}
			}
			close(bench)
		}
	}	
	# Statistical Calculations
	if (runs == 1) {
		# No statistical calculations needed
		for (cmd in command) {
			med_rt[cmd] = rt[cmd, 0]
			med_pm[cmd] = pm[cmd, 0]
		} 
	} else {
		for (cmd in command) {
			# Calculate median
			# Sort results; required for median calculation
			for (i = 1; i < runs; i++) {
				# Sort rt
				tmp_rt = rt[cmd, i]
				j = i - 1
				while (j >= 0 && rt[cmd, j] > tmp_rt) {
					rt[cmd, j + 1] = rt[cmd, j]
					j--
				}
				rt[cmd, j + 1] = tmp_rt
				# Sort pm
				tmp_pm = pm[cmd, i]
				j = i - 1
				while (j >= 0 && pm[cmd, j] > tmp_pm) {
					pm[cmd, j + 1] = pm[cmd, j]
					j--
				}
				pm[cmd, j + 1] = tmp_pm
			}
			# Extract median
			med_rt[cmd] = (runs % 2 == 1) ? rt[cmd, int(runs/2)] : (rt[cmd, runs/2-1] + rt[cmd, runs/2]) / 2
			med_pm[cmd] = (runs % 2 == 1) ? pm[cmd, int(runs/2)] : (pm[cmd, runs/2-1] + pm[cmd, runs/2]) / 2
			# Calculate min, max
			min_rt[cmd] = rt[cmd, 0]
			min_pm[cmd] = pm[cmd, 0]
			max_rt[cmd] = rt[cmd, runs - 1]
			max_pm[cmd] = pm[cmd, runs - 1]
			for (i = 0; i < runs; i++) {
				sum_rt[cmd] += rt[cmd, i]
				sum_pm[cmd] += pm[cmd,i]
			}
			# Calculate mean
			mean_rt[cmd] = sum_rt[cmd] / runs
			mean_pm[cmd] = sum_pm[cmd] / runs
			# Calculate standard deviation (SD)
			for (i = 0; i < runs; i++) {
				ds_rt[cmd] = (rt[cmd, i] - mean_rt[cmd])^2
				sum_ds_rt[cmd] += ds_rt[cmd] 
				ds_pm[cmd] = (pm[cmd, i] - mean_pm[cmd])^2
				sum_ds_pm[cmd] += ds_pm[cmd] 
			}
			SD_rt[cmd] = sqrt(sum_ds_rt[cmd] / (runs - 1))
			SD_pm[cmd] = sqrt(sum_ds_pm[cmd] / (runs - 1))
			# Calculate Jitter[%]
			jtr = ((mean_rt[cmd] - med_rt[cmd]) / med_rt[cmd]) * 100
			jtr_rt[cmd] = (jtr < 0) ? -jtr : jtr
			jtr = ((mean_pm[cmd] - med_pm[cmd]) / med_pm[cmd]) * 100
			jtr_pm[cmd] = (jtr < 0) ? -jtr : jtr
		}
		print "\n--- Statistical Summary ---"		
		print "cmd\tRuntime [s]\t\t\t\t\tPeak Memory [MB]"
		print "\tmean ± sdev\tmin\tmedian\tmax\tJtr%\tmean ± sdev\tmin\tmedian\tmax\tJtr%"
		for (cmd in command) 
			printf("%s\t%.4f ± %.4f\t%.4f\t%.4f\t%.4f\t%.1f\t%.2f ± %.2f\t%.2f\t%.2f\t%.2f\t%.1f\n", \
				cmd, mean_rt[cmd], SD_rt[cmd], min_rt[cmd], med_rt[cmd], max_rt[cmd], jtr_rt[cmd], mean_pm[cmd], SD_pm[cmd], min_pm[cmd], med_pm[cmd], max_pm[cmd], jtr_pm[cmd])
	}	
	# Normalized Benchmarks based on median
	# Find baseline
	best_rt = ""
	best_pm = ""
	for (cmd in command) {
		best_rt = (best_rt == "" || med_rt[cmd] < best_rt) ? med_rt[cmd] : best_rt
		best_pm = (best_pm == "" || med_pm[cmd] < best_pm) ? med_pm[cmd] : best_pm
	}
	for (cmd in command) {
		# Calculate Normalized Runtime (nrt, displayed as RT) and Normalized Peak Memory (npm displayed as PM) 
		nrt[cmd] = med_rt[cmd] / best_rt	
		npm[cmd] = med_pm[cmd] / best_pm
		# Calculate Euclidean Distance
		d[cmd] = sqrt((nrt[cmd] - 1)^2 + (npm[cmd] - 1)^2) 
		# Calculate Resource Footprint
		F[cmd] = nrt[cmd] * npm[cmd] 
	}
	print "\n--- Normalized Benchmarks ---"
	# RT, PM, Euclidean Distance, Efficiency Score
	print "cmd\tRT\tPM\td\tF"
	for (cmd in command) 
		printf("%s\t%.2f\t%.2f\t%.2f\t%.2f\n", cmd, nrt[cmd], npm[cmd], d[cmd], F[cmd])
}

