import os
import pymzn as pymzn

# pymzn.config.set('minizinc', 'C:/Program Files/MiniZinc/')


solver = pymzn.Chuffed(solver_id='chuffed')
"""
s2 = pymzn.ORTools(solver_id='or-tools')
s3 = pymzn.Gurobi(solver_id='gurobi')
s4 = pymzn.CBC(solver_id='osicbc')
s5 = pymzn.OscarCBLS(solver_id='oscar-cbls')
"""


def save_file(path, file_name, file):
    completeName = os.path.join(path, file_name)
    file_perf = open(completeName, "w")
    file_perf.write(file)


output_performances = ""

for i in range(1, 41):

    solns = pymzn.minizinc('cp.mzn', 'dzn-instances\ins-{}-dzn.dzn'.format(i), output_base="\my-out",
                           output_mode="raw", timeout=180, solver=solver)

    time = 0
    out = ""
    performances = ""
    for line in solns.splitlines():
        if line[0] != "%":
            out += line + "\n"
        elif "time" in line:
            time = float(line.split("=")[1])

    #print(out)

    if solns.find("% Time limit exceeded!") != -1 or out == "":
        if solns.find("=====UNKNOWN=====") != -1 or out == "":
            print("{} - UKNOWN".format(i))
            performances += "UKNOWN".format(i)
        else:
            print("{} - TIMED OUT".format(i))
            performances += "TIMED OUT".format(i)

    else:
        print("{} - {:.3f} s".format(i, time))
        performances += "{:.3f}".format(time)

    save_file("my-out/occurrence-luby_restart",
              "ins-{}-solved.txt".format(i),
              out)

    output_performances += performances + "\n"



save_file("my-out/occurrence-luby_restart","occurrence-luby_restart.txt",output_performances)
