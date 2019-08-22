# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'Mcfly' do
  self.use_transactional_tests = false

  after(:each) do
    ActiveRecord::Base.connection.execute('TRUNCATE security_instruments;')
  end

  before(:each) do
    Mcfly.whodunnit = { id: 10 }

    @dts = %w[2001-01-01 2001-01-05 2001-01-10]

    @sis = [
      ['FN Fix-30 MBS', 'A'],
      ['FN Fix-30 Cash',          'A'],
      ['FN Fix-30 MBS Blend',     'A'],
      ['FN Fix-30 HB MBS',        'A']
    ]

    @sis.each_with_index do |(name, sc), i|
      si = SecurityInstrument.new(name: name, settlement_class: sc)
      si.created_dt = @dts[i % @dts.length]
      si.save!
    end
  end

  it 'deleted append-only records should have reasonable obsoleted_dt' do
    @sis[0..3].each do |name, _st|
      osi = SecurityInstrument.find_by(name: name)
      osi.destroy
      # p ActiveRecord::Base.connection.execute("select now();").first
      sleep(2)
    end
    t = Time.zone.now

    deltas = @sis[0..3].map do |name, _st|
      (t - SecurityInstrument.find_by(name: name).obsoleted_dt).round
    end

    expect(deltas).to eq([8, 6, 4, 2])
  end
end
