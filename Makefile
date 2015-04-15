# Makefile for EECS 280 Project 5

CXX := g++
CXXFLAGS := -Wall -Werror -pedantic -O1

list_test_srcs = $(wildcard List_test[0-9][0-9].cpp)
list_test_exes = $(list_test_srcs:.cpp=)

stack_test_srcs = $(wildcard Stack_test[0-9][0-9].cpp)
stack_test_exes = $(stack_test_srcs:.cpp=)

rational_test_srcs = $(wildcard Rational_test[0-9][0-9].cpp)
rational_test_exes = $(rational_test_srcs:.cpp=)

# Default target
all: calc compile_check my-tests

# Compile calc executable
calc: calc.cpp Rational.cpp List.h Stack.h
	$(CXX) $(CXXFLAGS) calc.cpp Rational.cpp -o $@

# Compile Rational unit test
Rational_test%: Rational_test%.cpp Rational.cpp
	$(CXX) $(CXXFLAGS) Rational_test$*.cpp Rational.cpp -o $@
# Compile List unit test
List_test%: List_test%.cpp List.h
	$(CXX) $(CXXFLAGS) List_test$*.cpp -o $@

# Compile Stack unit test
Stack_test%: Stack_test%.cpp Stack.h List.h
	$(CXX) $(CXXFLAGS) Stack_test$*.cpp -o $@

# Compile the compilation check.
compile_check: List.h List_compile_check.cpp
	$(CXX) $(CXXFLAGS) List_compile_check.cpp -o $@
	@echo 'Compilation succeeded'
	rm -f $@

my-tests: $(list_test_exes)
	@python run_my_tests.py

# disable built-in rules
.SUFFIXES:

# these targets do not create any files
.PHONY: test clean compile_check

clean:
	rm -vf *.o calc \
    List_test[0-9][0-9] \
    Rational_test[0-9][0-9] \
    Stack_test[0-9][0-9]

tar: List.h Stack.h Rational.cpp calc.cpp $(list_test_srcs) group.txt
	tar -czvf submit.tar.gz $^

manav: calc.cpp Rational.cpp List.h Stack.h List.h List_compile_check.cpp $(list_test_exes) $(stack_test_exes) $(rational_test_exes)
	@$(CXX) $(CXXFLAGS) calc.cpp Rational.cpp -o calc
	@$(CXX) $(CXXFLAGS) List_compile_check.cpp -o List_compile_check
	@rm -f List_compile_check
	@echo -e 'Compilation\t\tSuccess'
	@python run_my_tests_valgrind.py
	@echo 'Finished running all unit tests.'
	@echo -e '\nRegression tests complete.' 
	@rm -rf *.o calc \
	List_test[0-9][0-9] \
	Rational_test[0-9][0-9] \
	Stack_test[0-9][0-9]
