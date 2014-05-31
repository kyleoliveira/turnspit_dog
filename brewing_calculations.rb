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

puts '\nGive this brew a name (this will be the filename): '
name = gets.chomp
puts "Recipe name: #{name}"

puts '\nInputs for your batch'

puts '\nEnter the final batch size [gallons]: '
batch_volume = gets.chomp
puts "Batch size: #{round(batch_volume,2)}"

puts '\nEnter the grist weight [lbs.]: '
grist_weight = gets.chomp
puts "Grain weight: #{round(grist_weight,2)}"

# Predict OG, or let user enter a prediction.  Used to calculate pre-boil SG

og_prediction = round(1 + (0.035 * calcs.efficiency * grist_weight / batch_volume), 3)

flag = 'Relax, don\'t worry, have a homebrew'

while flag != ''
  puts "\nI predict an OG of #{og_prediction}"
  puts "Hit ENTER to accept, 'g' to change grist weight, or 'n' to input a different estimate: "
  flag = gets.chomp

  case flag
    when 'n'
      puts '\nEnter predicted OG: '
      og_prediction = round(gets.chomp,3)
    when 'g'
      puts '\nEnter new grist weight in pounds: '
      grist_weight = gets.chomp
      og_prediction = round(1 + (0.035 * calcs.efficiency * grist_weight / batch_volume),3)
    when ''
      # Success!
    else
      puts '\nI think your finger slipped.  Try again, cowboy.'
  end

  # Input the water profile

  water_type_valid = false
  while water_type_valid
    puts '\nIs the recipe for a:\n' <<
         '\tsoft water beer (pils, helles) [1]\n' <<
         '\troasty beer (stout, porter) [2]\n' <<
         '\tBritish beer [3]\n' <<
         '\tor standard beer? [4]\n'
    water_type = gets.chomp
    water_type_valid = true if water_type > 0 && water_type < 5
  end
  puts 'Okay!'

  # Input and check mash volume, temperature
  mash_volume = 1e6   # start at very high value

  while mash_volume > calcs.max_mash_volume
    puts '\nEnter the mash water-to-grain ratio in quarts/pound '
    ratio = gets.chomp
    mash_volume = (ratio * grist_weight * 0.25) + (0.08 * grist_weight)
    # mash volume = water volume + grain volume; formula from www.rackers.org
    if mash_volume > calcs.max_mash_volume
      puts "Mash volume, #{round(mash_volume,2)}, is greater than tun capacity!"
    end
  end

  puts "Mash ratio: #{ratio}"

  puts '\nEnter the desired mash temp in Fahrenheit: '
  mash_temperature = gets.chomp
  puts "Mash temp: #{mash_temperature}"

  puts '\nEnter the grain temperature in Fahrenheit: '
  grain_temperature = gets.chomp
  puts "Grain temp: #{grain_temperature}"

  # Hop and other additions

  puts '\nHit ENTER to add reminders for hop/DME/other boil additions, or \'n\' to skip'
  flag = gets.chomp
  additions = []

  unless flag == 'n'
    flag = 'z'
    puts '\nEnter time (minutes), weight (oz.), and name, e.g.: 60 1.0 Centennial <ENTER>'
    puts 'When finished, enter \'f\''
    while flag != 'f'             # loops until input is 'f'
      puts '\n--> '
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
  strike_volume = round(ratio * grist_weight * 0.25, 2)   # in gallons

  # Find sparge water volume

  absorption = 0.1 * grist_weight   # grain absorbs about 0.1 gallon per pound
  sparge_volume = round((batch_volume / calcs.boil_off) - (strike_volume - absorption),2)

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
    txtFile.puts("\n\nReplace #{round(grist_weight*sauermalz_percent*0.16,1)} oz basemalt with acidulated malt")
    txtFile.puts("\n\nHeat #{strike_volume} gallons strike water to #{strike_temperature}F")
    txtFile.puts("\n\n\tAdd:\n\t\t#{round(cacl2 * strike_volume / 5,2)} tsp cacl2\n\t\t#{round(gypsum * strike_volume / 5, 2)} tsp gypsum")
    txtFile.puts("\n\n\tMash in to hit #{mash_temperature}F")
    txtFile.puts('\n\n\tMash for 60 minutes')
    txtFile.puts("\n\nHeat #{sparge_volume} gallons sparge water to 180F")
    txtFile.puts("\n\n\tAdd:\n\t\t#{round(cacl2 * sparge_volume / 5, 2)} tsp cacl2\n\t\t#{round(gypsum * sparge_volume / 5,2)} tsp gypsum")
    txtFile.puts('\n\nBoil water for yeast rehydration (if dry yeast)')
    txtFile.puts('\n\nVourlauf and drain mash\n\nBatch sparge')
    txtFile.puts("\n\nCollect #{round(batch_volume / calcs.boil_off, 2)} gallons with SG #{round( 1 + ((og_prediction-1)*calcs.boil_off),3)}")
    txtFile.puts('\n\nBoil!')

    # Write the boil additions
    same_flag = 0
    additions.each_with_index do |addition, i|
      if same_flag == 0
        txtFile.puts("\n\n\t#{addition[0]} min")
        txtFile.puts("\n\t\t#{addition[1]} oz #{addition[2]}")
      else
        txtFile.puts("\n\t\t#{addition[1]} oz #{addition[2]}")
      end

      if i < (additions.length - 1)
        same_flag = 1 if addition[0] == additions[i+1][0]
      end
    end

    txtFile.puts("\n\nPredicted post-boil OG: #{og_prediction}")

  end


  puts 'We\'re done!'
  flag = gets.chomp
end
