/*
	Author: 		madur@psb.ugent.be
	Updated: 		2023-10-27
	Description:
		Takes a series of CZI files (one file per timepoint) generated by TipTracker (Wangenheim et al. 2017) and returns a series of TIF files (one per position). 
		Internally, the macro uses the duplicate method to concatenate images (typically a stack) of a single position. This preserves the initial CZI metadata (scaling, objectives, ...)!
		The macro works across different takes (a 'take' is a single series/folder within a multi-day experiment ) collected in a top folder. 
		It is important that the sub folders are at least prefixed with 'take'. Other folders will not be scanned.
		Images are saved in a user-selected output folder. The number of input sub folders ('takes') will equal the number of output sub folders that are created.
		Each sub folder contains the full image for that take (one per position) and a maximum intensity projection of that image.
		
		NOTE: White spaces in file paths and file names are NOT accepted.
*/


function process_dir (top_dir, sub_dir, output_dir) {
	// list all files in take
	input_dir = top_dir + sub_dir;
	list = getFileList(input_dir);
		
	// determine the number of files to process (n)
	n=0;
	for (ii=0; ii<list.length; ii++) {
	  if (endsWith(list[ii], ".czi")) { // currently only files with .czi extension
	  	n++;
	  }
	}
	
	// collect the file names in an array
	files = newArray(n);
	l = 0; 
	for (ii=0; ii<list.length; ii++) {
	  if (endsWith(list[ii], ".czi")) {
	  	files[l] = list[ii];
	  	l++;
	  }
	}
	files = Array.sort(files); // order images
	
	// open the first two files
		// take parameters from the first file
		print("Processing file: " + files[0] +" (1/" + toString(files.length) + ")");
		run("Bio-Formats Importer", "open="+ input_dir + files[0] +" autoscale color_mode=Grayscale concatenate_series open_all_series view=Hyperstack stack_order=XYCZT");
		rename("A");
		getDimensions(bwidth, bheight, bchannels, bslices, bframes);
		getPixelSize(unit, pw, ph, pd);
		bd = bitDepth();
	
		// take the next file
		print("Processing file: " + files[1] +" (2/" + toString(files.length) + ")");
		run("Bio-Formats Importer", "open="+ input_dir + files[1] +" autoscale color_mode=Grayscale concatenate_series open_all_series view=Hyperstack stack_order=XYCZT");
		rename("B");
	
	// create several images (one per position)
	for(jj=1; jj <= bframes; jj++) {
		// positions from first image
		selectWindow("A");
		run("Duplicate...", "title=A" + toString(jj) + " duplicate frames=" + jj);
		// positions from second image
		selectWindow("B");
		run("Duplicate...", "title=B" + toString(jj) + " duplicate frames=" + jj);
		
		// concatenate first and second image of each position (will mistakingly concatenate z planes instead of creating a hyperstack)
		run("Concatenate...", "title=A" + toString(jj) +  " open image1=A" + toString(jj) +" image2=B" + toString(jj));
		// re-order the dimensions to ensure that the starting point is a hyperstack, then the concatenate method behaves as desired
		run("Stack to Hyperstack...", "order=xyczt(default) channels=" + bchannels + " slices=" + bslices + " frames=" + 2 + " display=Grayscale"); // now there should be two frames (t)
	}
	close("A");
	close("B");
	
	// expand each image by step-wise concatenation of new files
	for(ii = 2; ii < files.length; ii++) {
		print("Processing file: " + files[ii] + " (" + toString(ii + 1) + "/" + toString(files.length) + ")"); // add 3rd image and so on
		run("Bio-Formats Importer", "open="+ input_dir + files[ii] +" autoscale color_mode=Grayscale concatenate_series open_all_series view=Hyperstack stack_order=XYCZT");
		rename("B");
		for(jj=1; jj <= bframes; jj++) {
			selectWindow("B");
			run("Duplicate...", "title=B" + toString(jj) + " duplicate frames=" + jj);
			run("Concatenate...", "open image1=A" + toString(jj) +" image2=B" + toString(jj));
			close("A" + toString(jj));
			rename("A" + toString(jj));
		}
		close("B"); // close image and move on to the next
	}
	
	// create directory with results (resuse name of original sub directory)
	output_sub_dir = output_dir + sub_dir;
	File.makeDirectory(output_sub_dir);
	
	for(ii=1; ii <= bframes; ii++) { 
		// save concatenated image
		print("Writing data of position " + toString(ii) + " to " + output_sub_dir);
		selectWindow("A" + toString(ii));	
		saveAs("Tiff", output_sub_dir + "B" + toString(ii) + ".tif"); // saved as 'B<x>', this is just a naming convention
		
		// save projection
		run("Z Project...", "projection=[Max Intensity] all");
		saveAs("Tiff", output_sub_dir + "MAX_B" + toString(ii) + ".tif");
		close();
	}

}

setBatchMode("hide");

top_dir = getDirectory("Choose a Directory (Input)");
sub_dir = getFileList(top_dir);
output_dir = getDirectory("Choose a Directory (Output)");

start_time_ms = getTime();

// do for each sub directory
for(ii = 0; ii < sub_dir.length; ii++) {
	if(startsWith(sub_dir[ii], "take") && endsWith(sub_dir[ii], "/")) {
		print("Processing " + sub_dir[ii]);
		process_dir(top_dir, sub_dir[ii], output_dir);
	}
}

close("*");
setBatchMode("show");

end_time_min = (getTime() - start_time_ms) / 60000; 
print("Completed");
print("Execution time: " + end_time_min + "mins")

showMessage("Processing complete");
