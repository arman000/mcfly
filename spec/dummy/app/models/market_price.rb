require 'mcfly'

class MarketPrice < ApplicationRecord
  has_mcfly

  validates_presence_of :security_instrument_id, :coupon,
  :settlement_mm, :settlement_yy

  mcfly_validates_uniqueness_of :security_instrument_id,
  scope: [:coupon,
          :settlement_mm,
          :settlement_yy,
         ]

  mcfly_belongs_to :security_instrument

  mcfly_lookup :lookup_si, sig: 2 do
    |pt, si| find_by_security_instrument_id(si.id)
  end

  mcfly_lookup :lookup_all, sig: 1 do
    |pt| all
  end
end
