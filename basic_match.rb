#!/usr/bin/env jruby -J-Dlog4j.configuration=log4j.xml

require 'java'
require 'lib/esper-4.4.0.jar'
require 'lib/commons-logging-1.1.1.jar'
require 'lib/antlr-runtime-3.2.jar'
require 'lib/cglib-nodep-2.2.jar'
require 'pp'

# Turn on debugging
cfg = com.espertech.esper.client.Configuration.new
logging_cfg = cfg.getEngineDefaults.getLogging
logging_cfg.setEnableExecutionDebug(true)
logging_cfg.setEnableTimerDebug(true)
logging_cfg.setEnableQueryPlan(true)

# Lets get the epService provider
epService = com.espertech.esper.client.EPServiceProviderManager.getDefaultProvider()

# And the configuration
configuration = epService.getEPAdministrator.getConfiguration

# Prepare the OrderEvent type
order_event_type = java.util.HashMap.new({"itemName" => "string",
  "price" => "double"})
configuration.addEventType("OrderEvent", order_event_type)

# Create EPL expression
#expression = "select * from OrderEvent where cast(price,double) > 150"
expression = "select avg(price) from OrderEvent"
statement = epService.getEPAdministrator.createEPL(expression)

# Create a listener object
class MyListener
  include com.espertech.esper.client.UpdateListener

  def update(newEvents, oldEvents)
    puts "matched: "
    newEvents.each do |event|
      puts "- " + event.getUnderlying.inspect
    end
  end
end

# Register listener to statement
listener = MyListener.new
statement.addListener(listener);

# Create an unmatched listener
class MyUnmatchedListener
  include com.espertech.esper.client.UnmatchedListener

  def update(event)
    puts "unmatched:\n- " + event.getProperties.inspect
  end
end

# Register unmatched listener
unmatched_listener = MyUnmatchedListener.new
epService.getEPRuntime.setUnmatchedListener(unmatched_listener)

# And finally process the event
eprRuntime = epService.getEPRuntime
eprRuntime.sendEvent({"itemName"=>"test","price"=>100}, "OrderEvent")
eprRuntime.sendEvent({"itemName"=>"test","price"=>200}, "OrderEvent")
eprRuntime.sendEvent({"itemName"=>"test","price"=>300}, "OrderEvent")
