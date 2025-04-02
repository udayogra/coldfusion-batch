component extends="batching.writers.AbstractWriter" {

    property name="filePath";
    property name="delimiter";

    // Initialization function to set file path and delimiter
    public CSVWriter function init(required string filePath, string delimiter = ",") {
        variables.filePath = arguments.filePath;
        variables.delimiter = arguments.delimiter ?: ","; // Default to comma if no delimiter specified
	 return this;
    }

  public void function write(array items) {
    if (arrayLen(items) == 0) {
        return;
    }

    // Convert array of structs to array of arrays (remove the structure)
    var rows = [];
  
    // Iterate through each struct in the items array
    for (var item in items) {
        var row = [];
         
        // Get keys from the struct (structure) and append values to the row
        var keys = structKeyList(item); // Get keys of the structure
        
        // Loop over the keys to create a row of values
        for (var key in listToArray(keys)) { // Convert key list into an array
            arrayAppend(row, item[key]);
        }
        
        // Append the row to the rows array
        arrayAppend(rows, row);
    }
    
    // Read existing CSV data if the file exists
    var citems = [];
    if (fileExists(variables.filePath)) {
        citems = csvRead(variables.filePath, 'arrayofcfarray');
    }

    // Append new rows one by one to avoid nesting issues
    for (var row in rows) {
        arrayAppend(citems, row, true); // true ensures proper 2D array structure
	 writeDump(row);
    }

    // Debugging
   

    // Write back to CSV
    CSVWrite(citems, 'arrayofcfarray', variables.filePath, { 'delimiter' : ',' });
}


    // Return the name of this writer
    public any function getName() {
        return "batching.writers.CSVWriter";
    }

    // Return parameters for this writer
    public any function getParams() {
        return {
            filePath: variables.filePath,
            delimiter: variables.delimiter
        };
    }
}
