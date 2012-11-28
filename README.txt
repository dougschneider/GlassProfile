GlassProfile is a Java profiler built on AspectJ. It takes advantage of the way AOP addresses cross-cutting
concerns to profile all of the method calls during execution.

GlassProfile can easily be added to any project that has aspects available. Any non-AspectJ project
in eclipse can easily be transformed into an AspectJ project with the following.

1. Install the AspectJ plug-in.
2. Right-click on the target project in the package explorer. Configure->Convert to AspectJ Project...

Once your project is set up for using AspectJ, you can set up GlassProfile with the following steps.

1. Download GlassProfile (if not already done).
2. Import GlassProfile into your Eclipse workspace.
3. Right-click on the target project, Properties
4. Select the AspectJ Build tab on the left.
5. Select the Aspect Path tab on the top of the screen.
6. Click Add Project... on the right. Select GlassProfile, and click OK.
7. Run your program, profiling information should be printed to the console and written to 
   file upon termination of the program.