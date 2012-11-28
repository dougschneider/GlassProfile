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
import org.aspectj.lang.Signature;

public class MethodProfile implements Comparable<MethodProfile>{
	
	private Signature methodSignature;
	private long numCalls;
	
	/*
	 * in milliseconds
	 */
	private long totalTimeInMethod;
	
	public MethodProfile(Signature signature)
	{
		this.methodSignature = signature;
		this.numCalls = 0;
		this.totalTimeInMethod = 0;
	}
	
	public Signature getSignature()
	{
		return this.methodSignature;
	}
	
	public long getNumCalls()
	{
		return this.numCalls;
	}
	
	/**
	 * in milliseconds
	 */
	public long getTotalTimeInMethod()
	{
		return this.totalTimeInMethod;
	}
	
	/**
	 * in milliseconds
	 */
	public double getAvgTimePerCall()
	{
		return (totalTimeInMethod/numCalls);
	}
	
	/**
	 * Increment the number of times this method has been called. And increment
	 * the total time spent in this method by the given time.
	 * 
	 * @param timeInCall The time spent in the call to this method.
	 */
	public void addCall(long timeInCall)
	{
		this.numCalls++;
		this.totalTimeInMethod += timeInCall;
	}

	/**
	 * Used to sort method profiles based on the total time spent in the method.
	 * This sorts in reverse order for efficiency reasons (longest time first).
	 */
	@Override
	public int compareTo(MethodProfile o) {
		long value = this.totalTimeInMethod - o.getTotalTimeInMethod(); 
		if(value > 0)
			return -1;
		else if(value < 0)
			return 1;
		else
			return 0;
	}

}
