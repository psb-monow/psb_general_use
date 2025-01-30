/*
Author: 	madur@psb.ugent.be
Updated:	2025-01-30
Description:
	Draws time labels on an image stack. The result is an overlayed image, to produce the final image the image needs to be flattened. Can be easily adjusted to fit your needs.
*/

// --- Presets ---
// interval
start_time_hours = 60;
interval_minutes = 15; // time between acquisitions

// borders
offset_text_x = 25;
offset_text_y = 50;

// text size and color (rgb)
font_size = 21;
setForegroundColor(255, 255, 255); 


// --- Draw ---

getDimensions(width, height, channels, slices, frames);

for (j = 1; j <= nSlices ; j++) {
	setSlice(j);
	
	min = (j-1) * interval_minutes; // total minutes, start from 0
	hr = floor(min / 60); // number of hours elapsed during imaging
	
	totalHours = toString(start_time_hours + hr); // total hours elapsed
	// if(lengthOf(totalHours) == 1) totalHours += "0"; // adjust string length of single digits
	
	remainingMinutes = toString(min - (hr * 60)); // number of minutes to add
	if(lengthOf(remainingMinutes) == 1) remainingMinutes += "0"; // adjust string length of single digits
	
	// create label
	label =  totalHours + " h " + remainingMinutes + " min";
	setFont("arial", font_size, "antialiased");
	setJustification("right");
	
	// draw label
	drawString(label , width - offset_text_x, offset_text_y); // positioning x, y
}
