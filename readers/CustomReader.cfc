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