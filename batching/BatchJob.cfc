component {

    property name="name" type="string";
    property name="chunkSize" type="numeric" default="10";
    property name="maxRetries" type="numeric" default="3";
    property name="dependencies" type="array";
    property name="reader" type="any";
    property name="processor" type="any";
    property name="writer" type="any";
    property name="parallel" type="boolean" default="false";
    property name="transactional" type="boolean" default="true";
    property name="throttleMs" type="numeric" default="0";
    property name="backoffStrategy" type="struct" ;
    property name="callbacks" type="struct" ;
    property name="dependentJobs" type="array" default="[]";

    public BatchJob function init(required string name) {
        variables.dependencies = [];
        variables.hooks = {};
        variables.dependentJobs = [];
        variables.name = arguments.name;
	// Explicitly initialize backoffStrategy
    variables.backoffStrategy = {
        type: "fixed",
        base: 1000,
        factor: 2
    };
        return this;
    }

 

public any function setReader(required string readerClass, required struct params) {
    // Ensure the class name is a valid string
    if (!isSimpleValue(readerClass) || len(trim(readerClass)) == 0) {
        throw "Invalid reader class. It must be a non-empty string.";
    }

    // Dynamically create the reader object using `createObject`
    try{
    variables.reader = createObject("component", readerClass).init(argumentCollection=params);
    } catch (any e) {
             variables.reader = createObject("component", readerClass);
         }

    // If chunkSize is already set, apply it to the reader (if supported)
    if (structKeyExists(variables, "chunkSize") && structKeyExists(variables.reader, "setChunkSize")) {
        variables.reader.setChunkSize(variables.chunkSize);
    }

    return this;
}

public any function setWriter(required string writerClass, required struct params) {
    // Ensure the class name is a valid string
    if (!isSimpleValue(writerClass) || len(trim(writerClass)) == 0) {
        throw "Invalid writer class. It must be a non-empty string.";
    }

    // Dynamically create the reader object using `createObject`
    try{
    variables.writer = createObject("component", writerClass).init(argumentCollection=params);
 } catch (any e) {
           variables.writer = createObject("component", writerClass);
         }
   
    return this;
}


public BatchJob function setProcessor(required string processorClass, required struct params) { 
     // Ensure the class name is a valid string
    if (!isSimpleValue(processorClass) || len(trim(processorClass)) == 0) {
        throw "Invalid processor class. It must be a non-empty string.";
    }
    // Dynamically create the reader object using `createObject`
   try {
             variables.processor = createObject("component", processorClass).init(argumentCollection=params);
         } catch (any e) {
           variables.processor = createObject("component", processorClass);
         }

   
    return this;
}


public any function setChunkSize(required numeric size) {
     if (!isNumeric(size) || size <= 0) {
        throw "Invalid chunkSize. It must be a positive number.";
    }
    variables.chunkSize = arguments.size;

    if (structKeyExists(variables, "reader") && structKeyExists(variables.reader, "setChunkSize")) {
        variables.reader.setChunkSize(variables.chunkSize);
    }

    return this;
}

public BatchJob function setRetries(numeric retries) { 
    if (!isNumeric(retries) || retries < 0) {
        throw "Invalid retries. It must be a non-negative number.";
    }
    variables.maxRetries = retries; 
    return this; 
}

public BatchJob function setDependencies(array deps) { 
    if (!isArray(deps)) {
        throw "Invalid dependencies. It must be an array.";
    }
    variables.dependencies = deps; 
    return this; 
}

public BatchJob function setCallbacks(struct callbacks) { 
    if (!isStruct(callbacks)) {
        throw "Invalid callbacks. It must be a struct.";
    }
    
    // Validate callback references
    for (var key in callbacks) {
        if (!isSimpleValue(callbacks[key]) || !find(".", callbacks[key])) {
            throw "Invalid callback for '#key#'. It must be a valid component.method reference.";
        }
    }

    variables.callbacks = callbacks; 
    return this; 
}

public BatchJob function setParallel(boolean value) { 
    if (!isBoolean(value)) {
        throw "Invalid parallel value. It must be true or false.";
    }
    variables.parallel = value; 
    return this; 
}

public BatchJob function setTransactional(boolean value) { 
    if (!isBoolean(value)) {
        throw "Invalid transactional value. It must be true or false.";
    }
    variables.transactional = value; 
    return this; 
}

public BatchJob function setThrottleMs(numeric ms) { 
    if (!isNumeric(ms) || ms < 0) {
        throw "Invalid throttleMs value. It must be a non-negative number.";
    }
    variables.throttleMs = ms; 
    return this; 
}

public BatchJob function setBackoffStrategy(struct strategy) { 
    if (!isStruct(strategy)) {
        throw "Invalid backoffStrategy. It must be a struct.";
    }
    if (!structKeyExists(strategy, "type") || !structKeyExists(strategy, "base") || !structKeyExists(strategy, "factor")) {
        throw "Invalid backoffStrategy. It must contain 'type', 'base', and 'factor'.";
    }
    if (!isNumeric(strategy.base) || !isNumeric(strategy.factor) || strategy.base <= 0 || strategy.factor <= 0) {
        throw "Invalid backoffStrategy values. 'base' and 'factor' must be positive numbers.";
    }
    variables.backoffStrategy = strategy; 
    return this; 
}

public BatchJob function addDependentJob(BatchJob job) { 
    if (!isObject(job) || !job.instanceOf("batching.BatchJob")) {
        throw "Invalid dependent job. It must be an instance of BatchJob.";
    }
    arrayAppend(variables.dependentJobs, job); 
    return this; 
}


public any function getReader() { 
    return variables.reader; 
}

public any function getProcessor() { 
    return variables.processor; 
}

public any function getWriter() { 
    return variables.writer; 
}

public numeric function getChunkSize() { 
    return variables.chunkSize; 
}

public numeric function getRetries() { 
    return variables.maxRetries; 
}

public array function getDependencies() { 
    return variables.dependencies; 
}

public struct function getCallbacks() { 
    return variables.callbacks; 
}

public boolean function getParallel() { 
    return variables.parallel; 
}

public boolean function getTransactional() { 
    return variables.transactional; 
}

public numeric function getThrottleMs() { 
    return variables.throttleMs; 
}

public struct function getBackoffStrategy() { 
    return variables.backoffStrategy; 
}

public array function getDependentJobs() { 
    return variables.dependentJobs; 
}


public string function getName() {
    return variables.name;
}
    public void function run() {
    try{
        executeHook("beforeJob",[getName()]);
        var chunk = [];
        var keepRunning = true;
        while (keepRunning) {
            var item = variables.reader.readItem();
	   
            if (isNull(item)) {
                keepRunning = false;
            } else {
                arrayAppend(chunk, item);
                if (chunk.len() >= variables.chunkSize) {
                    executeChunk(chunk);
                    chunk = [];
                }
            }
        }

        if (chunk.len()) {
            executeChunk(chunk);
        }

      
        executeHook("afterJob",[getName()]);
       }
       finally {
        // Close the reader after processing
      if (structKeyExists(variables, "reader") && structKeyExists(variables.reader, "close")) {
            variables.reader.close();
        }
      }

        // Execute dependent jobs (Chaining Logic)
        for (var job in variables.dependentJobs) {
            job.run();
        }
    }

    private void function executeChunk(array chunk) {
     
	executeHook("beforeChunk",[chunk,getName()]);
        var retries = 0;
        var success = false;
	var delay = variables.backoffStrategy.base;

        if (variables.parallel) {
            thread name="batchThread#createUUID()#" chunk=chunk retries=retries delay=delay {
                 processChunk(chunk, retries, delay);
           }
        } else {
            processChunk(chunk, retries, delay);
        }

      
        executeHook("afterChunk",[chunk,getName()]);
       
        if (variables.throttleMs) {
            sleep(variables.throttleMs);
        }
    }

    private void function processChunk(array chunk, numeric retries, numeric delay) {
    var success = false;
    variables.retries = retries;
    while (variables.retries <= variables.maxRetries && !success) {
        try {
            if (variables.transactional) {
                transaction {
                    processAndWrite(chunk);
                }
            } else {
                processAndWrite(chunk);
            }
            success = true;
        } catch (any e) {
            writelog(text=e.message);
	     variables.retries++; //  Move outside the transaction

            if (variables.retries > variables.maxRetries) {
                executeHook("onError", [chunk, getName(), e]);
            } else {
                sleep(delay);
              if (variables.backoffStrategy.type == "fixed") {
                    delay = variables.backoffStrategy.base; // Fixed delay remains unchanged
                } else if (variables.backoffStrategy.type == "exponential" && structKeyExists(variables.backoffStrategy, "factor")) {
                    delay *= variables.backoffStrategy.factor; // Exponential increases delay
                }
            }
        }
    }
}


    private void function processAndWrite(array chunk) {
      // writedump(variables.processor,'console');
        var processed = [];
        for (var item in chunk) {
            arrayAppend(processed, variables.processor.process(item));
        }
        variables.writer.write(processed);
    }


    /**
 * Executes the hook if defined.
 * @param hookName The name of the hook (e.g., "beforeJob", "afterChunk")
 * @param args Optional arguments for the hook method
 */
private void function executeHook(required string hookName, any args=[]) {
    if (structKeyExists(variables.callbacks, arguments.hookName)) {
    
        var hookMethod = variables.callbacks[arguments.hookName];
        if (len(hookMethod)) {
            var hookInstance = createObject("component", listFirst(hookMethod, "."));
            var methodName = listLast(hookMethod, ".");
            
            // Check if the method exists before calling
            if (structKeyExists(hookInstance, methodName)) {
                invoke(hookInstance, methodName, arguments.args);
            }
        }
    }
}
}
