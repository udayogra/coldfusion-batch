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

    function inti(){

    }
}