# frozen_string_literal: true

class SecurityInstrument < ApplicationRecord
  mcfly append_only: true
  validates_presence_of :name, :settlement_class
  mcfly_validates_uniqueness_of :name

  mcfly_has_many :market_prices

  mcfly_lookup :lookup, sig: 2 do |_pt, name|
    find_by(name: name)
  end

  mcfly_lookup :lookup_all, sig: 1 do |_pt|
    all
  end
end
