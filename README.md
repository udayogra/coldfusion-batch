
# ColdFusion Batching Framework

This is a powerful and extensible **batch processing framework for ColdFusion**, inspired by Spring Batch. It allows users to process large data efficiently in chunks, with built-in support for retries, throttling, parallel execution, scheduling, and persistence.

## Features

- **Chunk-based Processing**: Processes data in manageable chunks to optimize performance.
- **Customizable Readers, Writers, and Processors**: Easily extendable components to suit various data sources and destinations.
- **Retry Mechanism**: Configurable retry attempts for failed chunks with support for backoff strategies.
- **Throttling**: Control the execution speed of batch jobs to prevent system overload.
- **Parallel Execution**: Option to process chunks in parallel for improved performance.
- **Job Scheduling**: Schedule jobs at fixed intervals or using cron expressions.
- **Job Persistence**: Ensures jobs resume from the last processed chunk in case of interruptions.
- **Callback Hooks**: Customize execution flow with lifecycle callbacks.

---

## **1. Installation**
Clone or download the repository and place it in your ColdFusion application.

```sh
# Clone the repository
git clone https://github.com/udayogra/coldfusion-batch.git
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

  ```cfscript
  .setBackoffStrategy({
    type: "exponential",
    base: 1000,
    factor: 2
   })
  ```
  In this example, the first retry occurs after 1000ms, the second after 2000ms, the third after 4000ms, and so on.

---

## **4. Custom Readers and Writers**
### **Creating a Custom Reader**
A reader must extend `batching.readers.AbstractReader` and implement `readItem()` which should return a single entity.

```cfscript
component extends="batching.readers.AbstractReader" {
    property numeric counter = 1;
    function readItem() {
        if (counter > 5) 
	   return NULL;
        return counter++;
    }

      public any function getName() {
        return "batching.readers.CustomReader";
    }

     public any function getParams() {
       return {};
    }
}
```

### **Creating a Custom Processor**
A processor must extend `batching.processors.AbstractProcessor` and implement `process()`.

```cfscript
// CustomProcessor.cfc
component extends="batching.processors.AbstractProcessor" {
    function process(item) {
       // writelog(text="Processing items: #serializeJSON(item)#");
        return item ;
    }

      public any function getName() {
        return "batching.processors.CustomProcessor";
    }

     public any function getParams() {
       return {};
    }

}
```

### **Creating a Custom Writer**
A writer must extend `batching.writers.AbstractWriter` and implement `write()`.

```cfscript
// CustomWriter.cfc
component extends="batching.writers.AbstractWriter" {
    function write(array items) {
        writelog(text="Writing items: #serializeJSON(items)#");
    }

      public any function getName() {
        return "batching.writers.CustomWriter";
    }

     public any function getParams() {
       return {};
    }
}
```

---



## **5. Inbuilt Readers & Writers**
## Built-in Reader: SpreadsheetFileReader

The `SpreadsheetFileReader` allows reading structured data from an Excel spreadsheet (`.xlsx` format). It processes the file row by row and passes the data in chunks to be handled by the processor and writer.

### Parameters:
| Parameter  | Type   | Description |
|------------|--------|-------------|
| `filePath` | `string` | Absolute path to the spreadsheet file. |
| `skipLines` (optional) | `numeric` | Number of initial rows to skip before reading (default: `0`). |
| `maxLines` (optional) | `numeric` | Maximum number of rows to read (default: reads all). |

### Example Usage:
```cfscript
job.setReader("batching.readers.SpreadSheetFileReader", {
    filePath: "C:/Users/Administrator/Downloads/data.xlsx",
    skipLines: 1,
    maxLines: 100
});
```
## Built-in Writer: TextFileWriter

The `TextFileWriter` is a built-in writer that writes structured data to a plain text file. Each record is written as a new line, with fields separated by a configurable delimiter.

### Parameters:
| Parameter  | Type   | Description |
|------------|--------|-------------|
| `filePath` | `string` | Absolute path to the output text file. |
| `delimiter` (optional) | `string` | Character used to separate fields in each line (default: `|`). |

### Example Usage:
```cfscript
job.setWriter("batching.writers.TextFileWriter", {
    filePath: "C:/output.txt",
    delimiter: ","
});
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
