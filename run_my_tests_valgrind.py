#!/usr/bin/env python

from os import listdir
from os import getcwd
from fnmatch import fnmatch
from subprocess import call
import subprocess

list_test_exe_pattern = 'List_test[0-9][0-9]'

list_test_exes = [filename for filename in listdir('.')
				  if fnmatch(filename, list_test_exe_pattern)]

stack_test_exe_pattern = 'Stack_test[0-9][0-9]'

stack_test_exes = [filename for filename in listdir('.')
				   if fnmatch(filename, stack_test_exe_pattern)]

rational_test_exe_pattern = 'Rational_test[0-9][0-9]'

rational_test_exes = [filename for filename in listdir('.')
					  if fnmatch(filename, rational_test_exe_pattern)]
calc_inputs_pattern = 'calc_test[0-9][0-9].in'
calc_inputs = [filename for filename in listdir('.')
			   if fnmatch(filename, calc_inputs_pattern)]

def find_between( s, first, last ):
	start = s.index( first ) + len( first )
	end = s.index( last, start )
	return s[start:end]

num_tests_run = 0
num_tests_passed = 0
num_possible_leaks = 0
num_errors = 0
all_exes = []
for exe  in list_test_exes:
	all_exes.append(exe)
for exe  in stack_test_exes:
	all_exes.append(exe)
for exe  in rational_test_exes:
	all_exes.append(exe)

for test in all_exes:
	return_code = call(['./' + test])
	out = subprocess.Popen(['valgrind', './' + test], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	error, output = out.communicate()
	leaks = 0
	if not "All heap blocks were freed" in output:
		leaks += int(find_between(output, "definitely lost: ", " bytes in"))
		leaks += int(find_between(output, "indirectly lost: ", " bytes in"))
		leaks += int(find_between(output, "possibly lost: ", " bytes in"))
	num_possible_leaks += leaks
	index = output.find("ERROR SUMMARY: ") + 15
	end_index = output.find(" errors from")
	errors = int(output[index:end_index])
	num_errors += errors

	num_tests_run += 1
	if return_code == 0:
		num_tests_passed += 1
	else:
		print "Failed " + test
	if errors > 0 or leaks > 0:
		print test + " had " + str(leaks) + " bytes of memory leaks and " + str(errors) + " errors."

print '''\n\n########## Unit Tests Summary ############\n
	Ran {0} unit tests.
	Expected passes: {0}
	Expected failures: 0
	Expected leaks: 0
	Expected errors:0\n
	\t{1} tests passed.
	\t{2} tests failed.
	\t{3} bytes of possible leaks found
	\t{4} valgrind errors found\n\n
	Unit Tests Percentage: {5}%
	'''.format(num_tests_run, num_tests_passed, num_tests_run - num_tests_passed, num_possible_leaks, num_errors, (float(num_tests_passed) / float(num_tests_run)) * 100.0)

regression_tests_run = 0
regression_tests_passed = 0
regression_leaks = 0
regression_errors = 0

for calc_input in calc_inputs:
	print calc_input
	regression_tests_run += 1
	outfile = calc_input[:-2]
	outfile += 'out'
	correct_file = outfile + '.correct'
	output_fd = open(outfile, "w")
	input_fd = open(calc_input, "r")
	subprocess.Popen(['./calc'], stdin=input_fd, stdout=output_fd)
	out = subprocess.Popen(['valgrind', './calc'], stdin=input_fd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	error, output = out.communicate()
	leaks = 0
	if not "All heap blocks were freed" in output:
		leaks += int(find_between(output, "definitely lost: ", " bytes in"))
		leaks += int(find_between(output, "indirectly lost: ", " bytes in"))
		leaks += int(find_between(output, "possibly lost: ", " bytes in"))
	regression_leaks += leaks
	index = output.find("ERROR SUMMARY: ") + 15
	end_index = output.find(" errors from")
	errors = int(output[index:end_index])
	regression_errors += errors
	input_fd.close()
	output_fd.close()
	output_fd = open(getcwd() + '/' + outfile, "r")
	correct_file_fd = open(getcwd() + '/' + correct_file, "r")
	if output_fd.read() == correct_file_fd.read():
		regression_tests_passed += 1
	else:
		print outfile + " differs from " +  correct_file
	if leaks > 0 or errors > 0:
		print "Regression test for " + calc_input[:-3] + " leaked " + leaks + " bytes of memory and had " + errors + " errors."
	correct_file_fd.close()
	output_fd.close()

print '''\n\n########## Regression Tests Summary ############\n
	Ran {0} regression tests.
	Expected passes: {0}
	Expected failures: 0
	Expected leaks: 0
	Expected errors:0\n
	\t{1} tests passed.
	\t{2} tests failed.
	\t{3} bytes of possible leaks found
	\t{4} valgrind errors found\n\n
	Regression Tests Percentage: {5}%
	'''.format(regression_tests_run, regression_tests_passed, regression_tests_run - regression_tests_passed, regression_leaks, regression_errors, (float(regression_tests_passed) / float(regression_tests_run)) * 100.0)