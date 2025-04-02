<Cfscript>

this.name = 'batch-app';

public void function onApplicationEnd(struct applicationScope) {
        if (structKeyExists(applicationScope, "batchJobs")) {
            // Ensure batch jobs are saved before shutdown
            new batching.BatchJobManager().saveJobs();
        }
    }

</cfscript>