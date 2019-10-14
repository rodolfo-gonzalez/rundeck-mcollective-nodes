#!/usr/bin/ruby

require 'rubygems'
require 'json'

mcoErrorCodes = [1, 3, 4]

if ENV['RD_CONFIG_MCO_COMMAND_LINE'] == nil
   $stderr.puts "no RD_CONFIG_MCO_COMMAND_LINE environment provided, check mco_command_line plugin configuration property"
   exit 1
end


cmdLine=ENV['RD_CONFIG_MCO_COMMAND_LINE']
json = IO.popen(cmdLine) do |io|
  io.read
end

cmdLineResult=$?

if mcoErrorCodes.include?(cmdLineResult)
   $stderr.puts "mco command line  #{cmdLine} failed (result code:  #{cmdLineResult})"
   exit 1
end


begin
   inv = JSON.parse(json)
   raise "JSON parse error" if inv.nil?
rescue
   $stderr.puts "Caught JSON parsing exception from command line: #{cmdLine}"
   exit 1
end

if inv.length == 0
   $stderr.puts "command line: ${cmdLine} produced no data"
   exit 1
end

print "<project>\n"

$i = 0;
while $i < inv.length do
   invEntry = inv[$i];
   sender = invEntry["sender"]
   
   if invEntry["data"]["facts"].kind_of?(Hash) && invEntry["data"]["facts"].has_key?("ipaddress_eth0")
      
      tags = (invEntry["data"]["classes"].kind_of?(Array) && invEntry["data"]["classes"].any? ? invEntry["data"]["classes"].join(",") : '')
      hostname = ( invEntry["data"]["facts"].has_key?("ipaddress_eth0")? invEntry["data"]["facts"]["ipaddress_eth0"] : '')
      architecture = ( invEntry["data"]["facts"].has_key?("architecture")? invEntry["data"]["facts"]["architecture"] : '')
      osfamily = ( invEntry["data"]["facts"].has_key?("osfamily")? invEntry["data"]["facts"]["osfamily"] : '')
      kernel = ( invEntry["data"]["facts"].has_key?("kernel")? invEntry["data"]["facts"]["kernel"] : '')
      kernelrelease = ( invEntry["data"]["facts"].has_key?("kernelrelease")? invEntry["data"]["facts"]["kernelrelease"] : '')
      username = ( invEntry["data"]["facts"].has_key?("id")? invEntry["data"]["facts"]["id"] : '')
      operatingsystemrelease = ( invEntry["data"]["facts"].has_key?("operatingsystemrelease")? invEntry["data"]["facts"]["operatingsystemrelease"] : '')

      if username == ""
         username="root"
      end
   
      print "   <node name=\"#{sender}\" description=\"#{osfamily} #{operatingsystemrelease}\" tags=\"#{tags}\" hostname=\"#{hostname}\"  osArch=\"#{architecture}\" osFamily=\"#{osfamily}\" osName=\"#{kernel}\" osVersion=\"#{kernelrelease}\" username=\"#{username}\"/>\n"
   end

   $i += 1;

end

print "</project>\n"
