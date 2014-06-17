#! /usr/bin/env ruby

#require 'rubygems'

module BrewingCalculations
  attr_accessor :max_mash_volume, :max_boil_volume,
                :boil_off, :efficiency,
                :ratio, :grist_weight,
                :batch_volume,
                :mash_temperature, :grain_temperature

  def initialize
    @max_mash_volume = 5.0 # in Gallons. Set by mash tun size, etc.
    @max_boil_volume = 9.0 # in Gallons. Set by kettle size, burner, etc.
    @boil_off = 0.82
    @efficiency = 0.75
    @ratio = nil
  end
  
  def strike_temperature
    ((0.23/@ratio)*(@mash_temperature - @grain_temperature) + @mash_temperature).to_i
  end

  def strike_volume
    (@ratio * @grist_weight * 0.25).round(2)
  end

  # Predict OG, or let user enter a prediction.  Used to calculate pre-boil SG
  def og_prediction
    (1 + (0.035 * @efficiency * @grist_weight / @batch_volume)).round(3)
  end

  def mash_volume
    @ratio.nil? ? 1e6 : ((@ratio * @grist_weight * 0.25) + (0.08 * @grist_weight))
  end

  def absorption
    0.1 * @grist_weight # grain absorbs about 0.1 gallon per pound
  end

  def sparge_volume
    ((@batch_volume / @boil_off) - (strike_volume - absorption)).round(2)
  end

end