
/*
Author: 	madur@psb.ugent.be
Updated:	2025-01-30
Description:
	A convenience tool to manually re-center a number of image stacks (3D + Time) to produce a time series of a single plane (2D + Time). 
	Asks the user for a starting point within the image as a first frame, from there the script will help the user grow the centered stack frame by frame.
*/


getDimensions(width, height, channels, slices, frames);

Stack.setFrame(1);
waitForUser("Focus on the first slice (first frame)"); 
Stack.getPosition(channel, slice, frame); // store position of the first frame
rename("work");

for(n = 1; n <= frames; n++) {
	if(n == 1) {
		Stack.setPosition(channel, slice, 1);
		run("Duplicate...", "duplicate slices=" + slice + " frames=1");
		rename("done"); // starting frame
	}
	else {
		run("Duplicate...", "duplicate slices=" + slice + " frames=1");
		rename("temp");
		run("Concatenate...", "open image1=done image2=temp");
		rename("done");
		Stack.setPosition(channel, 1, n); // last frame
		selectWindow("work");
		Stack.setPosition(channel, slice, 1); // show first frame, same level as previous
		run("Delete Slice", "delete=frame");
		run("Tile");
		Stack.setPosition(channel, slice, 1);
		waitForUser("Refocus slice");
		selectWindow("work");
		Stack.getPosition(channel, slice, frame);
	}
}

// final slice
run("Duplicate...", "duplicate slices=" + slice + " frames=1");
rename("temp");
run("Concatenate...", "open image1=done image2=temp");
rename("done");
close("\\Others");
