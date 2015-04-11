# EECS280-Project5-Tester
This is an easy way to compile and test everything for Project 5 and run and process Valgrind outputs.

All you need to do is open this project with Xcode 6.3 on Mac OS X, change the directory variable on the top to the location of where all your .cpp and .h files are stored and hit the run button. All the essential output will be printed to the console.

This utility will tell you of all memory leaks for all your regression and unit tests, any unit tests that you fail and any regression tests you fail.

For unit tests all files of the form: `List_testXX.cpp`, `Stack_testXX.cpp` and `Rational_testXX.cpp` where XX is a sequential number starting at 00.

For regression tests we will run calc with the all the input files of the form: `Calc_testXX.in` and compare the output to `Calc_testXX.out.correct`. Ensure that the correct out file is included if the in file is present while running regression tests. (You can use valgrind with regression tests with just the in files)

To switch off one of the process scroll all the way to the bottom in the `main.swift` file and comment out the function calls.

Finally, ensure that all of these files are in the same directory and that you did not forget to change the directory variable at the top.
