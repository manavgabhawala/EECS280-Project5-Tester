//
//  main.swift
//  Project5 Tester
//
//  Created by Manav Gabhawala on 4/11/15.
//  Copyright (c) 2015 Manav Gabhawala. All rights reserved.
//

import Foundation

//TODO: - Fix the directory
let directory = "CHANGE DIRECTORY"


extension String
{
	var shellSafeString : String
		{
		get
		{
			return self.stringByReplacingOccurrencesOfString(" ", withString: "\\ ")
		}
	}
}

//MARK: - Globals
let fileManager = NSFileManager()
let userFriendly = false

//MARK: - Generic Helpers
/**
This function compiles an executable file by compiling the files passed into it.

:param: files The list of files, add any dependency cpp files in the array too. The last file's name will be used to create the executable.
*/
func compileFiles(files: [String])
{
	assert(files.count > 0)
	let task = NSTask()
	
	task.currentDirectoryPath = directory
	task.launchPath = "/usr/bin/g++"
	var arguments = files.map { "\(directory)/\($0)" }
	arguments.append("-Wall")
	arguments.append("-Werror")
	arguments.append("-pedantic")
	arguments.append(userFriendly ? "-g" : "-O1")
	arguments.append("-o")
	arguments.append("\(directory)/\(files.last!.stringByDeletingPathExtension)")
	task.arguments = arguments
	fileManager.removeItemAtPath("\(directory)/\(files.last!.stringByDeletingPathExtension)", error: nil)
	task.launch()
	task.waitUntilExit()
}
/**
Run an executable file.

:param: file       The executable file to run.
:param: arguments  The arguments to pass in to the executable.
:param: inputFile  Redirect the input to this process from an input file stored at some path
:param: outputFile Redirect the output from this process to this output file stored at some path.

:returns: The termination code of the executable.
*/
func runExecutableFile(file : String, arguments: [String] = [], inputFile: String? = nil, outputFile: String? = nil) -> Int
{
	let task = NSTask()
	let pipe = NSPipe()
	if outputFile == nil
	{
		task.standardOutput = pipe
	}
	else
	{
		fileManager.createFileAtPath("\(directory)/\(outputFile!)", contents: nil, attributes: nil)
		task.standardOutput = NSFileHandle(forWritingAtPath: "\(directory)/\(outputFile!)")!
	}
	if inputFile != nil
	{
		task.standardInput = NSFileHandle(forReadingAtPath: "\(directory)/\(inputFile!)")!
	}
	task.currentDirectoryPath = directory
	task.launchPath = "\(directory)/\(file)"
	task.arguments = arguments
	task.launch()
	task.waitUntilExit()
	if outputFile == nil
	{
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		let output: String = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
		print(output)
	}
	return Int(task.terminationStatus)
}

/**
Run valgrind for an executable file.

:param: file      The executable file to run with valgrind.
:param: inputFile Redirect the input to this process from an input file stored at some path

:returns: The valgrind memory leak and error summary as a tuple
*/
func runValgrindForExecutableFile(file: String, inputFile: String? = nil) -> (memoryLeak: Int, error: Int)
{
	let task = NSTask()
	let pipe = NSPipe()
	
	task.standardOutput = pipe
	task.standardError = pipe
	if (inputFile != nil)
	{
		task.standardInput = NSFileHandle(forReadingAtPath: "\(directory)/\(inputFile!)")!
	}
	task.currentDirectoryPath = directory
	task.launchPath = "/usr/local/Cellar/valgrind/HEAD/bin/valgrind"
	task.arguments = ["./\(file)"]
	task.launch()
	task.waitUntilExit()
	
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	let output: String = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
	var leakage = 0
	
	var index = output.rangeOfString("definitely lost: ")!.endIndex
	var leakSummary = output.substringFromIndex(index)
	leakage += leakSummary.componentsSeparatedByString(" ").first!.toInt()!
	
	index = output.rangeOfString("indirectly lost: ")!.endIndex
	leakSummary = output.substringFromIndex(index)
	leakage += leakSummary.componentsSeparatedByString(" ").first!.toInt()!
	
	index = output.rangeOfString("possibly lost: ")!.endIndex
	leakSummary = output.substringFromIndex(index)
	leakage += leakSummary.componentsSeparatedByString(" ").first!.toInt()!
	
	index = output.rangeOfString("ERROR SUMMARY: ")!.endIndex
	leakSummary = output.substringFromIndex(index)
	var errors = leakSummary.componentsSeparatedByString(" ").first!.toInt()!
	
	return (leakage, errors)
}

//MARK: - Compilation
/**
Compiles the files specific to project 5.
*/
func compileProject5Files()
{
	println("##########################\nCompilation\n##########################\n")
	for file in fileManager.contentsOfDirectoryAtPath(directory, error: nil) as! [String]
	{
		if file.pathExtension == "cpp"
		{
			if (file.rangeOfString("List") != nil || file.rangeOfString("Stack") != nil)
			{
				println("Compiling \(file)")
				compileFiles([file])
			}
			if file.rangeOfString("Rational_test") != nil || file.rangeOfString("calc") != nil
			{
				println("Compiling \(file) and Rational.cpp")
				compileFiles(["Rational.cpp", file])
			}
		}
		
	}
}

// MARK: - Unit Testing
/**
Runs all your unit tests.
*/
func runUnitTests()
{
	println("\n##########################\nUnit Tests\n##########################")
	var numberOfTestsRun = 0
	var numberOfSuccesses = 0
	for file in fileManager.contentsOfDirectoryAtPath(directory, error: nil) as! [String]
	{
		if file.pathExtension == "cpp"
		{
			if file.rangeOfString("calc") == nil && file.rangeOfString("compile") == nil
			{
				if fileManager.fileExistsAtPath("\(directory)/\(file.stringByDeletingPathExtension)")
				{
					let returnValue = runExecutableFile(file.stringByDeletingPathExtension)
					++numberOfTestsRun
					if returnValue == 0
					{
						++numberOfSuccesses
					}
					else
					{
						println("Failed unit test: \(file.stringByDeletingLastPathComponent)")
					}
				}
			}
		}
	}
	println("\n########## Unit Tests Summary ############\nRan \(numberOfTestsRun) unit tests.")
	println("Expected passes: \(numberOfTestsRun) tests.")
	println("Expected failures: 0 tests.")
	println("\t\(numberOfSuccesses) tests passed.")
	println("\t\(numberOfTestsRun - numberOfSuccesses) tests failed.")
	println("Unit Tests Score: \(Double(numberOfSuccesses) / Double(numberOfTestsRun) * 100.0)%")
}

// MARK: - Unit Testing Valgrind
/**
Runs all your unit tests with valgrind and processes this information.
*/
func runUnitTestsWithValgrind()
{
	println("\n##########################\nUnit Tests Valgrind\n##########################\n")
	var totalLeaks = 0
	var totalErrors = 0
	for file in fileManager.contentsOfDirectoryAtPath(directory, error: nil) as! [String]
	{
		if file.pathExtension == "cpp"
		{
			if file.rangeOfString("calc") == nil && file.rangeOfString("compile") == nil
				
			{
				if fileManager.fileExistsAtPath("\(directory)/\(file.stringByDeletingPathExtension)")
				{
					let (leaks, errors) = runValgrindForExecutableFile(file.stringByDeletingPathExtension)
					totalLeaks += leaks
					totalErrors += errors
					if leaks != 0 || errors != 0
					{
						println("\(file.stringByDeletingPathExtension) leaked \(leaks) bytes of memory and has \(errors) unsupressed errors")
					}
				}
			}
		}
	}
	println("\n########## Unit Tests Valgrind Summary ############")
	println("Memory leaked:\t\(totalLeaks)")
	println("Total errors:\t\(totalErrors)")
}


// MARK: - Regression Testing
/**
Runs all your regression tests.
*/
func runRegressionTests()
{
	println("\n\n##########################\nRegression Tests\n##########################")
	var numberOfCalculatorRuns = 0
	var numberOfCalculatorSuccesses = 0
	while true
	{
		if fileManager.fileExistsAtPath("\(directory)/calc")
		{
			let testNum = String(format: "%02d", numberOfCalculatorRuns)
			if fileManager.fileExistsAtPath("\(directory)/calc_test\(testNum).in")
			{
				++numberOfCalculatorRuns
				runExecutableFile("calc", outputFile: "calc_test\(testNum).out", inputFile: "calc_test\(testNum).in")
				let myFile = "\(directory)/calc_test\(testNum).out"
				let correctFile = "\(directory)/calc_test\(testNum).out.correct"
				let myFileOutput = String(contentsOfFile: "\(directory)\(myFile)", encoding: NSUTF8StringEncoding, error: nil)
				let correctFileOutput = String(contentsOfFile: "\(directory)/\(correctFile)", encoding: NSUTF8StringEncoding, error: nil)
				system("diff -q \(correctFile.shellSafeString) \(myFile.shellSafeString)")
				if myFileOutput == correctFileOutput
				{
					++numberOfCalculatorSuccesses
					println("Passed Calculator Test \(testNum).")
				}
				
			}
			else
			{
				break
			}
		}
		else
		{
			break
		}
	}
	println("\n########## Regression Tests Summary ############\nRan:\t\(numberOfCalculatorRuns) tests.")
	println("Passed:\t\(numberOfCalculatorSuccesses) tests.")
	println("Failed:\t\(numberOfCalculatorRuns - numberOfCalculatorSuccesses) tests.")
	println("Regression Tests Score: \(Double(numberOfCalculatorSuccesses) / Double(numberOfCalculatorRuns) * 100.0)%")
}

// MARK: - Regression Testing Valgrind
/**
Runs all your regression tests with valgrind and processes this information.
*/
func runRegressionTestsWithValgrind()
{
	println("\n##########################\nRegression Tests Valgrind\n##########################\n")
	var numberOfCalculatorRuns = 0
	var totalRegressionLeaks = 0
	var totalRegressionErrors = 0
	while true
	{
		if fileManager.fileExistsAtPath("\(directory)/calc")
		{
			let testNum = String(format: "%02d", numberOfCalculatorRuns)
			++numberOfCalculatorRuns
			if fileManager.fileExistsAtPath("\(directory)/calc_test\(testNum).in")
			{
				let (leaks, errors) = runValgrindForExecutableFile("calc",  inputFile: "calc_test\(testNum).in")
				totalRegressionLeaks += leaks
				totalRegressionErrors += errors
				if leaks != 0 || errors != 0
				{
					println("Calculator running test \(testNum) leaked \(leaks) bytes of memory and has \(errors) unsupressed errors")
				}
			}
			else
			{
				break
			}
		}
		else
		{
			break
		}
	}
	println("########## Regression Tests Valgrind Summary ############")
	println("Memory leaked:\t\(totalRegressionLeaks)")
	println("Total errors:\t\(totalRegressionErrors)\n\n")
}

// MARK: - Cleanup
/**
Deletes all the files we created
*/
func runCleanup()
{
	for file in fileManager.contentsOfDirectoryAtPath(directory, error: nil) as! [String]
	{
		var error : NSError?
		if file.pathExtension == "dSYM"
		{
			if !fileManager.removeItemAtPath("\(directory)/\(file.stringByDeletingPathExtension).dSYM", error: &error)
			{
				println("Failed to delete \(file.stringByDeletingPathExtension).dSYM")
			}
		}
		if file.pathExtension == "cpp"
		{
			if !fileManager.fileExistsAtPath("\(directory)/\(file.stringByDeletingPathExtension)") && fileManager.removeItemAtPath("\(directory)/\(file.stringByDeletingPathExtension)", error: &error)
			{
				println("Failed to delete executable \(file.stringByDeletingPathExtension)")
			}
		}
		if file.pathExtension == "out"
		{
			if !fileManager.removeItemAtPath("\(directory)/\(file.stringByDeletingPathExtension).dSYM", error: &error)
			{
				println("Failed to delete \(file.stringByDeletingPathExtension).dSYM")
			}
		}
	}
}


//MARK: - Main
// Comment out any function to turn off that process. Change the order of these function calls to change what gets run in what order.
compileProject5Files()
runUnitTests()
runRegressionTests()
runUnitTestsWithValgrind()
runRegressionTestsWithValgrind()
