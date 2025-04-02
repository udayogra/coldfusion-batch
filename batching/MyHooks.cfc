component {
    public void function beforeJob(string jobName) {
        writelog(text="Starting Job...");
    }

    public void function afterJob(string jobName) {
        writelog(text="Job Finished." & jobName );
    }

    public void function beforeChunk(required array chunk,string jobName) {
       // writelog(text="Before Chunk: " & serializeJSON(arguments.chunk));
    }

    public void function afterChunk(required array chunk,string jobName) {
      //  writelog(text="After Chunk: " & serializeJSON(arguments.chunk));
    }

    public void function onError(required array chunk,string jobName, required any e) {
      writelog(text="Error in Chunk: ");
        writelog(text="Error in Chunk: " & arguments.e.message);
    }
}
