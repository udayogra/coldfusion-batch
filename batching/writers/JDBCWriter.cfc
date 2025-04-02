component extends="batching.writers.AbstractWriter" {
    property name="dataSource";
    property name="insertQuery";
    property name="params";

    public JDBCWriter function init(required string dataSource, required string insertQuery, required array params) {
        variables.dataSource = arguments.dataSource;
        variables.insertQuery = arguments.insertQuery;
        variables.params = arguments.params; // Dynamic parameter keys
        return this;
    }

   public void function write(array items) {
    if (arrayLen(items) == 0) {
        return;
    }

    var paramArray = [];

    for (var item in items) {
        var paramStruct = {};
        for (var param in variables.params) {
            if (structKeyExists(item, param)) {
                paramStruct[param] = item[param];
            } else {
                paramStruct[param] = ""; // Default if missing
            }
        }
        arrayAppend(paramArray, paramStruct);
    }

    // Dynamically generate correct placeholders based on `params`
    var placeholders = [];
    for (var param in variables.params) {
        arrayAppend(placeholders, ":" & param); // Ensures correct parameter names
    }
    var queryWithPlaceholders = variables.insertQuery & " VALUES (" & arrayToList(placeholders, ", ") & ")";

    // Ensure correct parameter struct keys
    //writeDump(paramArray); 

    // Execute batch insert
    queryExecute(queryWithPlaceholders, paramArray, { datasource: variables.dataSource });
}


    public any function getName() {
        return "batching.writers.JDBCWriter";
    }

    public any function getParams() {
        return {
            dataSource: variables.dataSource,
            insertQuery: variables.insertQuery,
            params: variables.params
        };
    }
}
