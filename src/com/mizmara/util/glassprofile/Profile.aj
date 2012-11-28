/*
 *  Copyright 2012 Douglas Schneider
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
package com.mizmara.util.glassprofile;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.LinkedList;

import org.aspectj.lang.Signature;

import com.mizmara.util.table.Table;

public aspect Profile {
	
	private static HashMap<Signature, MethodProfile> profileInfo;
	private static LinkedList<Date> methodEntryTimeStack;
	private static boolean profilingStarted = false;
	private static boolean profilingStopped = false;
	
	/*
	 * All method calls *except* the ones made in this Aspect.
	 */
	pointcut profileCall(): 
							call(* *(..)) && 
							!within(Profile);

	/**
	 * Before every method starts we note the time so we can measure how long the method execution takes.
	 */
	before(): profileCall()
	{
		if(profilingStopped)
			return;
		if(!profilingStarted)
			Profile.setUpProfiling();
		Date now = new Date();
		methodEntryTimeStack.push(now);
	}
	
	/**
	 * Set the profiler up. The first part is creating a shutdown hook to dump the profiling information. 
	 * The second part is to perform initialisation for the advice in this aspect.
	 */
	private static void setUpProfiling()
	{
		Profile.profilingStarted = true;
		ProfileDump dump = new Profile.ProfileDump();
		Runtime.getRuntime().addShutdownHook(dump);
		
		Profile.methodEntryTimeStack = new LinkedList<Date>();
		Profile.profileInfo = new HashMap<Signature, MethodProfile>();
	}
	
	/**
	 * After a method call completes we note down it's completion time. 
	 * We then add an entry to the profiling information for the method call and how long it took.
	 */
	after(): profileCall()
	{
		if(profilingStopped)
			return;
		Date now = new Date();
		Date before = methodEntryTimeStack.pop();
		Signature signature = thisJoinPoint.getSignature();
		Profile.updateMethodProfile(signature, now, before);
	}
	
	/**
	 * Update a method profile with how long the method took.
	 * 
	 * @param signature The method signature.
	 * @param now The time when the method call ended.
	 * @param before The time when the method call began.
	 */
	private static void updateMethodProfile(Signature signature, Date now, Date before)
	{
		if(!Profile.profileInfo.containsKey(signature))
			Profile.profileInfo.put(signature, new MethodProfile(signature));
		
		long timeInCall = now.getTime() - before.getTime();
		Profile.profileInfo.get(signature).addCall(timeInCall);
	}
	
	/**
	 * This class acts as a shutdown hook for the profiler.
	 * 
	 * It handles dumping the profile statistics gathered during the programs execution.
	 */
	private static class ProfileDump extends Thread
	{
		@Override
		public void run()
		{
			Profile.profilingStopped = true;
			ArrayList<MethodProfile> methodProfiles = this.getSortedMethodProfiles();
			this.logMethodProfiles(methodProfiles);
		}
		
		private ArrayList<MethodProfile> getSortedMethodProfiles()
		{
			ArrayList<MethodProfile> methodProfiles = new ArrayList<MethodProfile>(Profile.profileInfo.values());
			Collections.sort(methodProfiles);
			return methodProfiles;
		}
		
		/**
		 * Print a pretty table of the profiling statistics to the screen. 
		 * The same table is also written to a timestamped .pfl file. 
		 * In addition the statics are written to a .csv file, with the same timestamp.
		 * 
		 * @param methodProfiles The method profiling information.
		 */
		private void logMethodProfiles(ArrayList<MethodProfile> methodProfiles)
		{
			System.out.println("Dumping profiling stats...");
			Object[][] data = this.generateProfileData(methodProfiles);
			String[] headers = {"Method Signature", "Total Time in Method(s)", "Number of Method Calls", "Average Time Per Method Call(s)"};
			this.makeProfilingDirectory();
			String logPrefix = "profiling/profile-" + (new Date().getTime());
			logRawData(headers, data, logPrefix);
			logTable(headers, data, logPrefix);
			System.out.println("...done dumping profiling stats!");
		}
		
		/**
		 * Create the profiling director if it does not exist.
		 */
		private void makeProfilingDirectory()
		{
			File dir = new File("profiling");
			if(!dir.exists())
				dir.mkdir();
		}
		
		/**
		 * Generate a table of the profiling data from the gathered profiling statistics.
		 * 
		 * @param methodProfiles A list of the methods profiling statistics.
		 * @return A two-dimensional array of the data collected from the statistics. 
		 * 		   The data consists of rows of columns. Each row represents a method call. 
		 * 		   Each column of a row represents a statistic or an attribute of the method.
		 */
		private Object[][] generateProfileData(ArrayList<MethodProfile> methodProfiles)
		{
			Object[][] data = new Object[methodProfiles.size()][4];			
			int count = 0;
			for(MethodProfile profile : methodProfiles)
			{
				data[count][0] = profile.getSignature();
				data[count][1] = profile.getTotalTimeInMethod()/1000.0;
				data[count][2] = profile.getNumCalls();
				data[count][3] = profile.getAvgTimePerCall()/1000.0;
				count += 1;
			}
			return data;
		}
		
		/**
		 * Print the raw data to a csv file.
		 * 
		 * @param headers The headers for the data.
		 * @param data The data to log. A list of rows, of columns.
		 * @param logPrefix The prefix to the log.
		 */
		private void logRawData(String[] headers, Object[][]data, String logPrefix)
		{
			PrintStream out = null;
			try {
				out = new PrintStream(new File(logPrefix + ".csv"));
				this.logCsvRow(headers, out);
				for(int row = 0; row < data.length; row++)
				{
					this.logCsvRow(data[row], out);
				}
			} catch (FileNotFoundException e) {
				System.err.println("Unable to log the csv data to file.");
				e.printStackTrace();
			}
			finally
			{
				out.close();
			}
		}
		
		/**
		 * Write a single row of a csv file to the given print stream.
		 * 
		 * @param row The data to write. 
		 * @param out The stream to write the data to.
		 */
		private void logCsvRow(Object[] row, PrintStream out)
		{
			for(int col = 0; col < row.length; col++)
			{
				out.print(row[col]);
				if(col+1 < row.length)
					out.print(", ");
				else
					out.println();
			}
		}
		
		/**
		 * Print the pretty table formatted data to a .pfl file.
		 * 
		 * @param headers The headers for the table.
		 * @param data The data to log. A list of rows, of columns.
		 * @param logPrefix The prefix to the log.
		 */
		private void logTable(String[] headers, Object[][] data, String logPrefix)
		{
			Table table = new Table(headers, data);				
			table.print();
			try {
				table.print(new PrintStream(new File(logPrefix + ".pfl")));
			} catch (FileNotFoundException e) {
				System.err.println("Unable to log the profile table to file.");
				e.printStackTrace();
			}
		}
	}
}
