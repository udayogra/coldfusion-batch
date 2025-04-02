component extends="batching.writers.AbstractWriter" {

    property name="filePath";
    property name="delimiter";
    
    // Initialization function to set file path and delimiter
    public CSVWriter function init(required string filePath) {
        variables.filePath = arguments.filePath;
       // variables.delimiter = arguments.delimiter ?: ","; // Default to comma if no delimiter specified
        return this;
    }

    // Write function to output the data to CSV
    public void function write(array items) {
        if (arrayLen(items) == 0) {
            return;
        }

     
	CSVWrite(items,'csv',variables.filePath);

        // Close the file
       // fileClose(file);
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
