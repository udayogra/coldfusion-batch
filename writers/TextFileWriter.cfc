component extends="batching.writers.AbstractWriter" {

    property name="filePath";
    property name="delimiter";

    // Initialization function to set file path and delimiter
    public TextFileWriter function init(required string filePath, string delimiter = "|") {
        variables.filePath = arguments.filePath;
        variables.delimiter = arguments.delimiter ?: "|"; // Default delimiter is "|"
        return this;
    }

    // Write function to append structured data to a text file
    public void function write(array items) {
        if (arrayLen(items) == 0) {
            return;
        }

        var content = "";

        // Determine if items contain structs or arrays
        var isStructs = isStruct(items[1]); // Check first element type

        // Process array of structs
        if (isStructs) {
            for (var item in items) {
                var line = "";
                var keys = structKeyList(item);
                
                for (var key in listToArray(keys)) {
                    line &= item[key] & variables.delimiter; // Use delimiter dynamically
                }

                content &= left(line, len(line) - len(variables.delimiter)) & chr(10); // Remove last delimiter & add new line
            }
        } 
        // Process array of arrays
        else {
            for (var row in items) {
                var line = arrayToList(row, variables.delimiter); // Convert array to delimiter-separated string
                content &= line & chr(10);
            }
        }

       
	cflock(name="TextFileWriterLock", type="exclusive", timeout="10") {
          fileAppend(variables.filePath, content);
        }
    }

    // Return the name of this writer
    public any function getName() {
        return "batching.writers.TextFileWriter";
    }

    // Return parameters for this writer
    public any function getParams() {
        return {
            filePath: variables.filePath,
            delimiter: variables.delimiter
        };
    }
}
