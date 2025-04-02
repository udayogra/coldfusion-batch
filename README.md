
# ColdFusion Batching Framework

This is a powerful and extensible **batch processing framework for ColdFusion**, inspired by Spring Batch. It allows users to process large data efficiently in chunks, with built-in support for retries, throttling, parallel execution, scheduling, and persistence.

## Features
- **Reader/Processor/Writer model**
- **Chunk-based processing** for handling large datasets efficiently
- **Retries with exponential backoff**
- **Parallel execution**
- **Throttling to control job execution speed**
- **Persistence**, so jobs resume from where they left off in case of failure
- **Hooks/callbacks for event handling**
- **Scheduling support (interval and cron-based)**

---

## **1. Installation**
Clone or download the repository and place it in your ColdFusion application.

```sh
# Clone the repository
git clone https://github.com/your-repo/cf-batching.git
```

---

## **2. Usage Example**
### **Creating and Running a Job**
```cfscript
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
        filePath: "C:\\Users\\Administrator\\Downloads\\1mb.xlsx",
        skipLines: 0,
        maxLines: 16
    })
    .setProcessor("batching.processors.CustomProcessor", {})
    .setWriter("batching.writers.TextFileWriter", {
        filePath: "c:/abc.txt",
        delimiter: '|'
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
endTime = now();
executionTime = dateDiff("s", startTime, endTime);
writeDump("Execution Time (seconds): " & executionTime);
```

---

## **3. Understanding the Parameters**
### **Chunk Size** (`setChunkSize(n)`)  
- Defines the number of records processed at a time.
- Example: `setChunkSize(10)` will process 10 records in one go before writing.

### **Retries** (`setRetries(n)`)  
- Number of times a failed chunk should be retried.
- Example: `setRetries(2)` will attempt processing twice before failing.

### **Throttling** (`setThrottleMs(ms)`)  
- Controls the time delay (in milliseconds) between processing chunks.
- Example: `setThrottleMs(100)` introduces a 100ms delay.

### **Backoff Strategy** (`setBackoffStrategy({...})`)  
- Configures delay strategy between retries.
- Example:
  ```cfscript
  .setBackoffStrategy({
      type: "fixed",
      base: 1000,
      factor: 2
  })
  ```
  This means that retry delays will start at 1000ms.

---

## **4. Custom Readers and Writers**
### **Creating a Custom Reader**
A reader must extend `batching.readers.AbstractReader` and implement `readChunk()`.

```cfscript
component extends="batching.readers.AbstractReader" {
    public array function readChunk() {
        var data = []; // Fetch data logic here
        return data;
    }
}
```

### **Creating a Custom Writer**
A writer must extend `batching.writers.AbstractWriter` and implement `write()`.

```cfscript
component extends="batching.writers.AbstractWriter" {
    public void function write(array items) {
        for (var item in items) {
            // Logic to write data
        }
    }
}
```

---

## **5. Inbuilt Readers & Writers**
### **SpreadSheetFileReader (Built-in Reader)**
Reads from an Excel file.
```cfscript
setReader("batching.readers.SpreadSheetFileReader", {
    filePath: "C:/data.xlsx",
    skipLines: 1,
    maxLines: 100
})
```

### **TextFileWriter (Built-in Writer)**
Writes data to a text file.
```cfscript
setWriter("batching.writers.TextFileWriter", {
    filePath: "C:/output.txt",
    delimiter: ','
})
```

---

## **6. Callbacks (Hooks)**
Hooks allow custom logic to be executed at different job stages.

### **Example Hook Implementation**
```cfscript
component {
    public void function beforeJob() {
        writeDump("Job is starting...");
    }
    public void function afterJob() {
        writeDump("Job has completed!");
    }
    public void function beforeChunk() {
        writeDump("Processing a new chunk...");
    }
    public void function afterChunk() {
        writeDump("Chunk processing completed.");
    }
    public void function onError() {
        writeDump("An error occurred.");
    }
}
```

---

## **7. Scheduling Jobs**
### **Interval-based Scheduling**
```cfscript
manager.scheduleJob(job, 30); // Runs every 30 seconds
```

### **Cron-based Scheduling**
```cfscript
manager.scheduleJob(job, 0, "0 0 * * *"); // Runs every day at midnight
```

---

## **8. Persistence and Recovery**
If a server crashes or stops mid-job, execution resumes from the last processed row.
- The framework **persists the last read/written row** to ensure continuity.

---

## **9. Full Example Code**
```cfscript
manager = new batching.BatchJobManager();

job = new batching.BatchJob("SampleJob")
    .setReader("batching.readers.SpreadSheetFileReader", { filePath: "C:/data.xlsx" })
    .setProcessor("batching.processors.CustomProcessor", {})
    .setWriter("batching.writers.TextFileWriter", { filePath: "C:/output.txt" })
    .setChunkSize(10)
    .setRetries(3)
    .setParallel(true)
    .setThrottleMs(200);

manager.addJob(job);
manager.executeJob("SampleJob");
```

---

## **10. Contributing**
Contributions are welcome! Fork the repo, make changes, and submit a pull request.

---

## **11. License**
MIT License.
