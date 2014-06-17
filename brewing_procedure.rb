#! /usr/bin/env ruby

#require 'rubygems'
require File.dirname(__FILE__) + '/brewing_calculations'

class BrewingProcedure

  include BrewingCalculations
  extend BrewingCalculations

  attr_accessor :sauermalz_percent, :cacl2,
                :gypsum, :original_gravity,
                :additions

  def initialize
    super
    @sauermalz_percent = 0 # percent of grist to replace with sauermalz
    @cacl2 = 0             # tsp of calcium chloride to add per 5 gallons mash or sparge water used
    @gypsum = 0            # tsp of gypsum to add per 5 gallons mash or sparge water used
    @additions = []
  end

  def pick_water_to_grain_ratio!
    while mash_volume > @max_mash_volume
      puts 'Enter the mash water-to-grain ratio in quarts/pound '
      @ratio = gets.chomp.to_f
      # mash volume = water volume + grain volume; formula from www.rackers.org
      if mash_volume > @max_mash_volume
        puts "Mash volume, #{mash_volume.round(2)}, is greater than tun capacity!"
      end
    end
  end

  def pick_additions!
    puts 'Hit ENTER to add reminders for hop/DME/other boil additions, or \'n\' to skip'
    flag = gets.chomp
    unless flag == 'n'
      flag = 'z'
      puts 'Enter time (minutes), weight (oz.), and name, e.g.: 60 1.0 Centennial <ENTER>'
      puts 'When finished, enter \'f\''
      until flag == 'f'
        puts '--> '
        flag = gets.chomp
        break if flag == 'f'

        flag = flag.split
        if flag.length > 2
          (3..flag.length-1).to_a.each do |i|
            flag[2] = "#{flag[2]} #{flag[i]}"
          end
          flag = flag[0..2]
        end
        if (flag.length == 3) &&
           (flag[0].match(/^[0-9]/m)) &&
           (flag[2].match(/^..[A-Za-z]/m))
          flag[0] = flag[0].to_i
          flag[1] = flag[1].to_f
          @additions.push flag # adds the 3 item list to 'additions'
        else
          puts 'There was a problem with your input! Please try again, or ' <<
               "enter 'f' to finish adding reminders and additions. " <<
               "(Got: #{flag.inspect})"
        end
      end
    end

    @additions.sort!{ |x, y| y[0] <=> x[0] } # Sort additions by time
  end
  
  def pick_original_gravity!
    while @original_gravity.nil?
      puts "\nI predict an OG of #{og_prediction}"
      puts "Hit ENTER to accept, 'g' to change grist weight, or 'n' to input a different estimate: "
      flag = gets.chomp

      case flag
        when ''
          # Accepted as-is
          @original_gravity = @og_prediction
        when 'n'
          # Not accepted, simply take the user's calculation
          puts 'Enter predicted OG: '
          @original_gravity = gets.chomp.to_f.round(3)
        when 'g'
          # Fix the grist weight and try again
          puts 'Enter new grist weight in pounds: '
          @grist_weight = gets.chomp.to_f
        else
          # Huh?
          puts 'I think your finger slipped.  Try again, cowboy.'
      end
    end
  end

  def pick_water_type!
    water_type = nil
    while water_type.nil? || !(water_type > 0 && water_type < 5)
      puts "Is the recipe for a:\n" <<
           "\tsoft water beer (pils, helles) [1]\n" <<
           "\troasty beer (stout, porter) [2]\n" <<
           "\tBritish beer [3]\n" <<
           "\tor standard beer? [4]\n"
      water_type = gets.chomp.to_i
    end
    
    case water_type
      when 1
        @sauermalz_percent = 3.0
        @cacl2 = 0.5
      when 2
        @cacl2 = 1.0
        @sauermalz_percent = 0.0
      when 3
        @sauermalz_percent = 2.0
        @cacl2 = 1.0
        @gypsum = 1.0
      else
        @sauermalz_percent = 2.0
        @cacl2 = 1.0
    end
  end

  def to_file(filename)
    File.open("#{filename}.txt", 'w') do |txtFile|
      txtFile.puts("Procedure for #{filename}")
      txtFile.puts("Replace #{(@grist_weight * @sauermalz_percent*0.16).round(1)} oz basemalt with acidulated malt")
      txtFile.puts("Heat #{strike_volume} gallons strike water to #{strike_temperature}F")
      txtFile.puts("\tAdd:\n\t\t#{(@cacl2 * strike_volume / 5).round(2)} tsp cacl2\n\t\t#{(@gypsum * strike_volume / 5).round(2)} tsp gypsum")
      txtFile.puts("\tMash in to hit #{@mash_temperature}F")
      txtFile.puts("\tMash for 60 minutes")
      txtFile.puts("Heat #{sparge_volume} gallons sparge water to 180F")
      txtFile.puts("\tAdd:\n\t\t#{(@cacl2 * sparge_volume / 5).round(2)} tsp CaCl2\n\t\t#{(@gypsum * sparge_volume / 5).round(2)} tsp gypsum")
      txtFile.puts('Boil water for yeast rehydration (if dry yeast)')
      txtFile.puts("Vourlauf and drain mash\n\nBatch sparge")
      txtFile.puts("Collect #{(@batch_volume / @boil_off).round(2)} gallons with SG #{(1 + ((@original_gravity - 1)*@boil_off)).round(3)}")
      txtFile.puts('Boil!')

      # Write the boil additions
      same_flag = 0
      @additions.each_with_index do |addition, i|
        if same_flag == 0
          txtFile.puts("\t#{addition[0]} min")
          txtFile.puts("\n\t\t#{addition[1]} oz #{addition[2]}")
        else
          txtFile.puts("\n\t\t#{addition[1]} oz #{addition[2]}")
        end

        if i < (@additions.length - 1)
          same_flag = 1 if addition[0] == @additions[i+1][0]
        end
      end

      txtFile.puts("Predicted post-boil OG: #{@original_gravity}")
    end
  end

end
