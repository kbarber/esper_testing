#!/usr/bin/env ruby

require 'java'
require 'lib/esper-4.4.0.jar'
require 'lib/commons-logging-1.1.1.jar'
require 'lib/antlr-runtime-3.2.jar'
require 'lib/cglib-nodep-2.2.jar'
require 'pp'

# Turn on debugging
cfg = com.espertech.esper.client.Configuration.new
cfg.getEngineDefaults.getLogging.setEnableExecutionDebug(true)
cfg.getEngineDefaults.getLogging.setEnableTimerDebug(true)

# Lets get the epService provider
epService = com.espertech.esper.client.EPServiceProviderManager.getDefaultProvider()

# And the configuration
configuration = epService.getEPAdministrator.getConfiguration

# Prepare the OrderEvent type
order_event_type = java.util.HashMap.new({"itemName" => "string",
  "price" => "int"})
configuration.addEventType("OrderEvent", order_event_type)

# Create EPL expression
expression = "select avg(price) from OrderEvent.win:time(30 sec)";
#expression = "select * from OrderEvent.win:time(30 sec)";
statement = epService.getEPAdministrator.createEPL(expression)

# Create a listener object
class MyListener
    include com.espertech.esper.client.UpdateListener

    java_signature 'public void update(EventBean[] newEvents, EventBean[] oldEvents)'
    def update(newEvents, oldEvents)
        event = newEvents[0]
        puts event.inspect
        puts("avg=" + event.get("avg(price)"))
    end
end

# Register listener to statement
listener = MyListener.new
statement.addListener(listener);

# Create an event
order_event = {
  "itemName" => "test",
  "price" => 300,
}
order_event_java = java.util.HashMap.new(order_event)

# And finally process the event
epService.getEPRuntime.sendEvent(order_event_java)
