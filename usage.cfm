<cfscript>

// usage.cfm (CFScript version)
manager = new batching.BatchJobManager();

hooks = {
    beforeJob: "MyHooks.beforeJob",
    afterJob: "MyHooks.afterJob",
    beforeChunk: "MyHooks.beforeChunk",
    afterChunk: "MyHooks.afterChunk",
    onError: "MyHooks.onError"
};

job = new batching.BatchJob("SampleJob")
    .setReader("batching.readers.SpreadSheetFileReader", {
        filePath: "C:\Users\Administrator\Downloads\1mb.xlsx",
        skipLines: 0,
	maxLines :16
    })
    .setProcessor( "batching.processors.CustomProcessor",{})
   .setWriter("batching.writers.TextFileWriter", {
        filePath: "c:/abc.txt",
	delimiter : '|'
    })
    .setChunkSize(10)
    .setRetries(2)
    .setParallel(true)
    .setThrottleMs(100)
    .setBackoffStrategy({
        type: "fixed",
        base: 1000,
        factor: 2
    })
    .setCallbacks(hooks);
 startTime = now();
manager.addJob(job);
manager.executeJob("SampleJob");
//manager.removeJob("SampleJob");
//manager.scheduleJob(job,30);
 endTime = now();
executionTime = dateDiff("s", startTime, endTime);
        writeDump("Execution Time (seconds): " & executionTime);
</cfscript>