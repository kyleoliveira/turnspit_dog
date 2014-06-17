#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/brewing_procedure'

# These are equipment parameters which will only be changed on the programming level
calcs = BrewingProcedure.new

puts '**************************************************************'
puts '* Turnspit Dog by Kyle Oliveira, kcoliveiraATucdavisDOTedu   *'
puts '* Based on BrewCalc.py by Joel Sleppy, jdsleppyATgmailDOTcom *'
puts '**************************************************************'
puts "Equipment values set to:"
puts "\tMash tun volume = #{calcs.max_mash_volume} gal"
puts "\tBoil kettle volume = #{calcs.max_boil_volume} gal"
puts "\tBoil-off rate is #{100*(1-calcs.boil_off)}%"
puts "\tDefault efficiency is #{calcs.efficiency}"
puts 'Equipment/default values can be edited: open BrewCalc.py with Notepad and have at it!'
puts '________________________________________________'

# Take recipe-dependent inputs from user

puts 'Give this brew a name (this will be the filename): '
name = gets.chomp
puts "Recipe name: #{name}"

puts 'Inputs for your batch'

puts 'Enter the final batch size [gallons]: '
calcs.batch_volume = gets.chomp.to_f
puts "Batch size: #{calcs.batch_volume.round(2)}"

puts 'Enter the grist weight [lbs.]: '
calcs.grist_weight = gets.chomp.to_f
puts "Grain weight: #{calcs.grist_weight.round(2)}"

# Let's figure out an acceptable original gravity value
calcs.pick_original_gravity!

# Input the water profile
calcs.pick_water_type!
puts 'Okay!'

calcs.pick_water_to_grain_ratio!

puts "Mash ratio: #{calcs.ratio}"

puts 'Enter the desired mash temp in Fahrenheit: '
calcs.mash_temperature = gets.chomp.to_f
puts "Mash temp: #{calcs.mash_temperature}"

puts 'Enter the grain temperature in Fahrenheit: '
calcs.grain_temperature = gets.chomp.to_f
puts "Grain temp: #{calcs.grain_temperature}"

# Hop and other additions
calcs.pick_additions!
  
# Output to .txt file
calcs.to_file(name)

puts 'We\'re done!'
