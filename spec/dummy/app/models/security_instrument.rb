class SecurityInstrument < ActiveRecord::Base
  has_mcfly append_only: true
  validates_presence_of :name, :settlement_class
  mcfly_validates_uniqueness_of :name

  mcfly_lookup :lookup, sig: 2 do
    |pt, name|
    find_by_name(name)
  end

  mcfly_lookup :lookup_all, sig: 1 do
    |pt| all
  end
end
