component extends="batching.readers.AbstractReader" accessors="true" {
    property name="filePath" type="string";
    property name="spreadsheetObj" type="any";
    property name="currentRow" type="numeric" default="2";
    property name="chunkSize" type="numeric";
    property name="skipLines" type="numeric";
    property name="checkpointFile" type="string";
    property name="buffer" type="array"; // Stores current chunk of rows
    property name="bufferIndex" type="numeric"; // Tracks position in buffer
    property name="maxLines" type="numeric";

    public void function setChunkSize(required numeric size) {
        variables.chunkSize = arguments.size;
    }
    
    public SpreadSheetFileReader function init(required string filePath,  numeric skipLines=0,numeric maxLines=0) {
        variables.filePath = arguments.filePath;
       variables.skipLines = arguments.skipLines;
        variables.checkpointFile = replace(variables.filePath, ".", "_") & ".checkpoint"; // Auto-managed checkpoint file
        variables.buffer = [];
        variables.bufferIndex = 1;
	variables.maxLines = arguments.maxLines;

        if (!fileExists(variables.filePath)) {
            throw "File not found ";
        }
        variables.spreadsheetObj = spreadsheetRead(variables.filePath);

        restart(); // Resume from last checkpoint
        return this;
    }

    public string function getName() {
    return "batching.readers.SpreadSheetFileReader";
}

public struct function getParams() {
    return {
        filePath: variables.filePath,
        skipLines: variables.skipLines
    };
}

    // **Reads and returns one row at a time from the buffer**
    public any function readItem() {
      if(variables.maxLines > 0  && variables.currentRow > variables.maxLines && variables.bufferIndex > arrayLen(variables.buffer) )
          return JavaCast("null", ""); // No more data

        if (arrayIsEmpty(variables.buffer) || variables.bufferIndex > arrayLen(variables.buffer)) {
            readChunk(); // Load new chunk
            if (arrayIsEmpty(variables.buffer)) {
                return JavaCast("null", ""); // No more data
            }
        }

        var rowData = variables.buffer[variables.bufferIndex];
        variables.bufferIndex++;

        saveCheckpoint();
        return rowData;//transformRow(rowData);
    }

    // **Reads a chunk of data and stores it in buffer**
    private void function readChunk() {
        var totalRows = SpreadsheetGetLastRowNumber(variables.spreadsheetObj);
	  if (variables.currentRow == 2) {
            variables.currentRow += variables.skipLines;
        }

    readStruct={format="query",headerRow=1, excludeHeaderRow="true", rows="#variables.currentRow#-#variables.currentRow +  (variables.chunkSize -1 )#"}  
    value=streamingspreadsheetread(#variables.filePath#,readStruct)  
         variables.buffer = [];

      
	for (row in value) { 
            //  if (!isRowEmpty(row)) {
                arrayAppend(variables.buffer, row);
            //}
	    variables.currentRow++;
        }
    

        variables.bufferIndex = 1;
    }

    private boolean function isRowEmpty(required array rowData) {
        return arrayLen(rowData) == 0 || arrayEvery(rowData, function(value) { return trim(value) == ""; });
    }

    private array function transformRow(required array rowData) {
        return arrayMap(rowData, function(value) {
            return isDate(value) ? parseDateTime(value) : value;
        });
    }

    private void function saveCheckpoint() {
        fileWrite(variables.checkpointFile, variables.currentRow);
    }

    public void function restart() {
        if (fileExists(variables.checkpointFile)) {
            variables.currentRow = val(fileRead(variables.checkpointFile));
        }
    }

  public void function close() {
  
    //  Delete checkpoint file after reading is complete
    if (!isNull(checkpointFile) && fileExists(checkpointFile)) {
        try {
            fileDelete(checkpointFile);
        } catch (any e) {
            logError("Failed to delete checkpoint file: #checkpointFile#", e);
        }
    }
}

}
