#! /usr/bin/env ruby

require 'rubygems'

class BrewingCalculations
  attr_accessor :max_mash_volume, :max_boil_volume, :boil_off, :efficiency

  def initialize
    @max_mash_volume = 5.0   # set by mash tun size, etc.
    @max_boil_volume = 9.0   # set by kettle size, burner, etc.
    @boil_off = 0.82
    @efficiency = 0.75
  end

end

# These are equipment parameters which will only be changed on the programming level

# max_mash_volume = 5.0   # set by mash tun size, etc.
# max_boil_volume = 9.0   # set by kettle size, burner, etc.
# boil_off = 0.82
# efficiency = 0.75
calcs = BrewingCalculations.new

puts '**************************************************************'
puts '* BrewCalc.py provided by Joel Sleppy, jdsleppyATgmailDOTcom *'
puts '**************************************************************'
puts "Equipment values set to:\n Mash tun volume = #{calcs.max_mash_volume} gal"
puts "Boil kettle volume = #{calcs.max_boil_volume} gal"
puts "Boil-off rate is #{100*(1-calcs.boil_off)}%"
puts "Default efficiency is #{calcs.efficiency}"
puts 'Equipment/default values can be edited: open BrewCalc.py with Notepad and have at it!'
puts '________________________________________________'

# Take recipe-dependent inputs from user

puts 'Give this brew a name (this will be the filename): '
name = gets.chomp
puts "Recipe name: #{name}"

puts 'Inputs for your batch'

puts 'Enter the final batch size [gallons]: '
batch_volume = gets.chomp.to_f
puts "Batch size: #{batch_volume.round(2)}"

puts 'Enter the grist weight [lbs.]: '
grist_weight = gets.chomp.to_f
puts "Grain weight: #{grist_weight.round(2)}"

# Predict OG, or let user enter a prediction.  Used to calculate pre-boil SG

og_prediction = (1 + (0.035 * calcs.efficiency * grist_weight / batch_volume)).round(3)

flag = 'Relax, don\'t worry, have a homebrew'

while flag != ''
  puts "\nI predict an OG of #{og_prediction}"
  puts "Hit ENTER to accept, 'g' to change grist weight, or 'n' to input a different estimate: "
  flag = gets.chomp

  case flag
    when 'n'
      puts 'Enter predicted OG: '
      og_prediction = gets.chomp.to_f.round(3)
    when 'g'
      puts 'Enter new grist weight in pounds: '
      grist_weight = gets.chomp.to_f
      og_prediction = (1 + (0.035 * calcs.efficiency * grist_weight / batch_volume)).round(3)
    when ''
      # Success!
    else
      puts 'I think your finger slipped.  Try again, cowboy.'
  end

  # Input the water profile

  water_type_valid = false
  while water_type_valid
    puts 'Is the recipe for a:\n' <<
         '\tsoft water beer (pils, helles) [1]\n' <<
         '\troasty beer (stout, porter) [2]\n' <<
         '\tBritish beer [3]\n' <<
         '\tor standard beer? [4]\n'
    water_type = gets.chomp.to_i
    water_type_valid = true if water_type > 0 && water_type < 5
  end
  puts 'Okay!'

  # Input and check mash volume, temperature
  mash_volume = 1e6   # start at very high value

  while mash_volume > calcs.max_mash_volume
    puts 'Enter the mash water-to-grain ratio in quarts/pound '
    ratio = gets.chomp.to_f
    mash_volume = (ratio * grist_weight * 0.25) + (0.08 * grist_weight)
    # mash volume = water volume + grain volume; formula from www.rackers.org
    if mash_volume > calcs.max_mash_volume
      puts "Mash volume, #{mash_volume.round(2)}, is greater than tun capacity!"
    end
  end

  puts "Mash ratio: #{ratio}"

  puts 'Enter the desired mash temp in Fahrenheit: '
  mash_temperature = gets.chomp.to_f
  puts "Mash temp: #{mash_temperature}"

  puts 'Enter the grain temperature in Fahrenheit: '
  grain_temperature = gets.chomp.to_f
  puts "Grain temp: #{grain_temperature}"

  # Hop and other additions

  puts 'Hit ENTER to add reminders for hop/DME/other boil additions, or \'n\' to skip'
  flag = gets.chomp
  additions = []

  unless flag == 'n'
    flag = 'z'
    puts 'Enter time (minutes), weight (oz.), and name, e.g.: 60 1.0 Centennial <ENTER>'
    puts 'When finished, enter \'f\''
    while flag != 'f'             # loops until input is 'f'
      puts '--> '
      flag = gets.chomp
      flag = flag.split unless flag == 'f'

      if (flag.length == 3) && (flag.match(/^[0-9]/m)) && (flag[2].match(/^..[A-Za-z]/m))  # Checks to see that the input is valid
        flag[0] = flag[0].to_i
        flag[1] = flag[1].to_f
        additions.push flag    # adds the 3 item list to 'additions'
      else
        break
      end
    end
  end

  additions.sort!{ |x, y| y <=> x } # Sort additions by time

  # Process infusion temperature.  Formula from "How to Brew"

  strike_temperature = ((0.23/ratio)*(mash_temperature - grain_temperature) + mash_temperature).to_i
  strike_volume = (ratio * grist_weight * 0.25).round(2)   # in gallons

  # Find sparge water volume

  absorption = 0.1 * grist_weight   # grain absorbs about 0.1 gallon per pound
  sparge_volume = ((batch_volume / calcs.boil_off) - (strike_volume - absorption)).round(2)

  # Process water_type data

  sauermalz_percent = 0 # percent of grist to replace with sauermalz
  cacl2 = 0             # tsp of calcium chloride to add per 5 gallons mash or sparge water used
  gypsum = 0            # tsp of gypsum to add per 5 gallons mash or sparge water used

  case water_type
    when 1
      sauermalz_percent = 3.0
      cacl2 = 0.5
    when 2
      cacl2 = 1.0
      sauermalz_percent = 0.0
    when 3
      sauermalz_percent = 2.0
      cacl2 = 1.0
      gypsum = 1.0
    else
      sauermalz_percent = 2.0
      cacl2 = 1.0
  end

  # Output to .txt file

  File.open("#{name}.txt", 'w') do |txtFile|
    txtFile.puts("Procedure for #{name}")
    txtFile.puts("Replace #{(grist_weight*sauermalz_percent*0.16).round(1)} oz basemalt with acidulated malt")
    txtFile.puts("Heat #{strike_volume} gallons strike water to #{strike_temperature}F")
    txtFile.puts("\tAdd:\n\t\t#{(cacl2 * strike_volume / 5).round(2)} tsp cacl2\n\t\t#{(gypsum * strike_volume / 5).round(2)} tsp gypsum")
    txtFile.puts("\tMash in to hit #{mash_temperature}F")
    txtFile.puts("\tMash for 60 minutes")
    txtFile.puts("Heat #{sparge_volume} gallons sparge water to 180F")
    txtFile.puts("\tAdd:\n\t\t#{(cacl2 * sparge_volume / 5).round(2)} tsp CaCl2\n\t\t#{(gypsum * sparge_volume / 5).round(2)} tsp gypsum")
    txtFile.puts('Boil water for yeast rehydration (if dry yeast)')
    txtFile.puts("Vourlauf and drain mash\n\nBatch sparge")
    txtFile.puts("Collect #{(batch_volume / calcs.boil_off).round(2)} gallons with SG #{(1 + ((og_prediction-1)*calcs.boil_off)).round(3)}")
    txtFile.puts('Boil!')

    # Write the boil additions
    same_flag = 0
    additions.each_with_index do |addition, i|
      if same_flag == 0
        txtFile.puts("\t#{addition[0]} min")
        txtFile.puts("\n\t\t#{addition[1]} oz #{addition[2]}")
      else
        txtFile.puts("\n\t\t#{addition[1]} oz #{addition[2]}")
      end

      if i < (additions.length - 1)
        same_flag = 1 if addition[0] == additions[i+1][0]
      end
    end

    txtFile.puts("Predicted post-boil OG: #{og_prediction}")

  end


  puts 'We\'re done!'
  flag = gets.chomp
end
