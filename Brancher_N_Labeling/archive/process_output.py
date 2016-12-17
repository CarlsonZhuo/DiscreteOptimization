file_name1 = "q2_mzn_med_result"
file_name2 = "q2_mzn_min_result"

med_runtime = []
med_solvetime = []
med_solutions = []
med_variables = []
med_propagators = []
med_propagations = []
med_nodes = []
med_failures = []
med_restarts = []
med_peak_depth = []

min_runtime = []
min_solvetime = []
min_solutions = []
min_variables = []
min_propagators = []
min_propagations = []
min_nodes = []
min_failures = []
min_restarts = []
min_peak_depth = []

with open(file_name1, 'r') as content:
    for i in range(240):
        line = content.readline()
        if (i-3) % 12 is 0:
            line = line.split()
            solve_time = line[3].split('(')
            solve_time = solve_time[1]
            med_solvetime.append(solve_time)

print med_solvetime

