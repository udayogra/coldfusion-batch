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