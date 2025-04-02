component {

    property name="jobs" type="struct";

    public BatchJobManager function init() {
    if (!structKeyExists(application, "batchJobs")) {
        application.batchJobs = {}; // Store jobs persistently
    }
    variables.jobs = application.batchJobs;
    restoreJobs(); // Load jobs from storage on restart
    return this;
}


    public void function addJob( required any job) {
        //writedump(job.getName());
        application.batchJobs[arguments.job.getName()] = arguments.job;
	
	
    }

    public void function removeJob(required string jobName) {
    structDelete(application.batchJobs, jobName);
    saveJobs(); // Persist after removing
}

    public BatchJob function getJob(required string jobName) {
     restoreJobs();
        if (!structKeyExists(application.batchJobs, jobName)) {
            throw "Job '#jobName#' not found!";
        }
        return application.batchJobs[jobName];
    }

    public void function executeAll() {
        for (var jobName in  application.batchJobs) {
            executeJob(jobName);
        }
    }

   remote void function executeJob(required string jobName, array executionStack = []) {
    if (arrayFind(executionStack, jobName)) {
        throw "Circular dependency detected in job execution!";
    }
    arrayAppend(executionStack, jobName);

    var job = getJob(arguments.jobName);
    if (structKeyExists(job, "dependencies") && arrayLen(job.dependencies)) {
        for (var dep in job.dependencies) {
            executeJob(dep, executionStack);
        }
    }

    job.run();
}


    public void function scheduleJob(required any job, numeric interval = 0, string cronExpression = "") {
      addJob(job);
      var serverUrl = "http://" & cgi.server_name & ":" & cgi.server_port;
      var jobUrl = serverUrl & "/batching/BatchJobManager.cfc?method=executeJob&jobName=" & arguments.job.getName();

      if (len(cronExpression)) {
           cfschedule(action="update", task=arguments.job.getName(), 
            url=jobUrl, startDate=now(), crontime=cronExpression);
      } else if (arguments.interval > 0) {
        cfschedule(action="update", task=arguments.job.getName(), 
            url=jobUrl, startDate=now(), interval=interval);
      } else {
        throw "Either interval or cronExpression must be provided.";
      }
      saveJobs(); // Persist job after adding
}


public void function saveJobs() {
    var jobData = [];
    
    for (var jobName in application.batchJobs) {
        var job = application.batchJobs[jobName];

        arrayAppend(jobData, {
            name: job.getName(),
            chunkSize: job.getChunkSize(),
            maxRetries: job.getRetries(),
            dependencies: job.getDependencies(),
            parallel: job.getParallel(),
            transactional: job.getTransactional(),
            throttleMs: job.getThrottleMs(),
            backoffStrategy: job.getBackoffStrategy(),
            callbacks: job.getCallbacks(),
	    reader: job.getReader().getName(),
	    readerParams :job.getReader().getParams(),
            writer: job.getWriter().getName(),
	    writerParams :job.getWriter().getParams(),
	    processor: job.getProcessor().getName(),
	    processorParams :job.getProcessor().getParams()
        });
    }

    fileWrite(expandPath("/batching/jobStore.json"), serializeJSON(jobData));
}


public void function restoreJobs() {
    // Ensure batchJobs exists
    if (!structKeyExists(application, "batchJobs")) {
        application.batchJobs = {}; // Initialize if missing
        restoreJobs(); // Restore from storage
    }else{
      
    var jobFilePath = expandPath("/batching/jobStore.json");
    
    if (fileExists(jobFilePath)) {
        var jobData = deserializeJSON(fileRead(jobFilePath));
	
        for (var job in jobData) {
            var restoredJob = new batching.BatchJob(job.name)
                .setChunkSize(job.chunkSize)
                .setRetries(job.maxRetries)
                .setParallel(job.parallel)
                .setTransactional(job.transactional)
                .setThrottleMs(job.throttleMs)
                .setBackoffStrategy(job.backoffStrategy)
		.setCallbacks(job.callbacks);

	     // Restore reader, processor, and writer dynamically
            if (structKeyExists(job, "reader")) {
	        restoredJob.setReader(job.reader, job.readerParams);
            }
            if (structKeyExists(job, "writer")) {
	        restoredJob.setWriter(job.writer, job.writerParams);
            }
	      if (structKeyExists(job, "processor")) {
	        restoredJob.setProcessor(job.processor, job.processorParams);
            }

            application.batchJobs[job.name] = restoredJob;
        }
      }
    }

   
}





private any function restoreComponent(required string className, required struct params) {
    // Dynamically create instance using arguments
    var instance = createObject("component", className);

    // Ensure init method exists and call it with params
   if (structKeyExists(instance, "init")) {
        return instance.init(argumentCollection=params);
    }
    
    return instance;
}



}
