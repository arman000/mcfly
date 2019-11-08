# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'Mcfly' do
  before(:each) do
    Mcfly.whodunnit = { id: 10 }

    @old = '2000-01-01'

    @dts = %w[2001-01-01 2001-01-05 2001-01-10]

    @sis = [
      ['FN Fix-30 MBS',         'A'],
      ['FN Fix-30 Cash',        'A'],
      ['FN Fix-30 MBS Blend',   'A'],
      ['FN Fix-30 HB MBS',      'A'],
      ['FN Fix-15 MBS',         'B'],
      ['FN Fix-15 Cash',        'B'],
      ['FN Fix-15 HB MBS',      'B'],
      ['FN Fix-15 HB Cash',     'B'],
      ['FN ARM 3/1 LIBOR',      'D'],
      ['FN ARM 3/1 LIBOR Cash', 'D'],
      ['FN ARM 5/1 LIBOR',      'D'],
      ['FN ARM 5/1 LIBOR Cash', 'D']
    ]

    @sis.each_with_index do |(name, sc), i|
      si = SecurityInstrument.new(name: name, settlement_class: sc)
      si.created_dt = @dts[i % @dts.length]
      si.save!
    end

    @sis.each_with_index do |(name, _sc), i|
      ii = i + 1
      si = SecurityInstrument.find_by(name: name)
      mp = MarketPrice.new(security_instrument_id: si.id,
                           coupon: ii * 1.1,
                           settlement_mm: ii,
                           settlement_yy: 2000 + ii,
                           price: ii)
      mp.created_dt = si.created_dt
      mp.save!

      @vers = 5

      # create 5 additional verions for each mp
      (1..@vers).each do
        mp.price = mp.price + 1
        mp.created_dt = mp.created_dt + 1.day
        mp.save!
      end
    end
  end

  it 'should update obsoleted_dt properly when created_dt is set' do
    si = SecurityInstrument.first
    mp = MarketPrice.new(security_instrument_id: si.id,
                         coupon: 2.0,
                         settlement_mm: 1,
                         settlement_yy: 2013,
                         price: 100.256)
    mp.created_dt = si.created_dt
    mp.save!

    mp.price = mp.price + 123
    mp.created_dt = si.created_dt + 1.day
    mp.save!

    l = MarketPrice.where('group_id = ?', mp.id).order('obsoleted_dt').all
    expect(l.length).to eq(2)

    expect(l[1].obsoleted_dt).to eq(Float::INFINITY)
    expect(l[0].obsoleted_dt).to eq(mp.created_dt)

    # Make sure that setting an old created_dt fails.
    mp.price = mp.price + 123
    mp.created_dt = mp.created_dt - 1.day
    expect do
      mp.save!
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'should make sure that append-only does not allow changes' do
    si = SecurityInstrument.lookup('infinity', 'FN Fix-30 MBS')
    expect(si.settlement_class).to eq('A')

    si.name = 'xyz'

    expect do
      si.save!
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'should be able to delete append-only items' do
    osi = SecurityInstrument.find_by(name: 'FN Fix-30 MBS')
    osi.delete

    osi = SecurityInstrument.find_by(name: 'FN Fix-30 MBS')

    expect((osi.obsoleted_dt - DateTime.now).to_f.abs).to be < 100

    expect do
      osi.delete
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'should be able to delete append-only items and create a new clone' do
    osi = SecurityInstrument.find_by(name: 'FN Fix-30 MBS')
    osi.delete

    # now try to add a clone of si
    si = SecurityInstrument.new(name: osi.name,
                                settlement_class: osi.settlement_class)
    si.save!
  end

  it 'should check basic versioning' do
    expect(SecurityInstrument.lookup_all('infinity').count).to eq(@sis.count)

    @dts.each_with_index do |pt, i|
      expect(SecurityInstrument.lookup_all(pt + ' 12:00 PST8PDT').count).to eq(
        (i + 1) * @sis.count / @dts.length
      )
    end

    expect(SecurityInstrument.lookup_all(@old).count).to eq(0)
    expect(SecurityInstrument.lookup(@old, 'FN Fix-30 MBS')).to eq(nil)

    # all versions
    MarketPrice.count == @sis.length * (@vers + 1)

    expect(MarketPrice.lookup_all('infinity').count).to eq(@sis.count)

    si = SecurityInstrument.first

    mp = MarketPrice.lookup_si('infinity', si)

    odate = mp.created_dt - 0.5.days

    # previous version of mp
    omp = MarketPrice.lookup_si(odate, si)

    expect(mp.price).to eq(omp.price + 1)
  end

  it 'should test mcfly uniqueness validations' do
    def new_mp(price)
      si = SecurityInstrument.first
      MarketPrice.new(security_instrument_id: si.id,
                      coupon: 2.0,
                      settlement_mm: 1,
                      settlement_yy: 2013,
                      price: price)
    end

    si = SecurityInstrument.first
    mp = new_mp(100.256)
    mp.created_dt = si.created_dt
    mp.save!

    # create another MarketPrice with the same si/coupon/mm/yy.  This
    # should fail.
    mp2 = new_mp(mp.price + 100)

    mp2.created_dt = si.created_dt + 1.day
    expect do
      mp2.save!
    end.to raise_error(ActiveRecord::RecordInvalid)

    # now change mp's settlement_mm
    mp.settlement_mm += 1
    mp.save!

    # since we changed mp's settlement_mm, we should be able to create
    # a new one with the same info as mp's old instance.
    mp3 = new_mp(100.256)
    mp3.save!
  end

  it 'should be able to delete objects' do
    si = SecurityInstrument.find_by(name: 'FN Fix-30 Cash')
    dt = '2010-01-01 08:00 PST8PDT'

    mp = MarketPrice.lookup_si(dt, si)
    expect(mp.obsoleted_dt).to eq(Float::INFINITY)

    sleep 1.second

    mp.delete

    expect(MarketPrice.lookup_si('infinity', si)).to eq(nil)

    omp = MarketPrice.lookup_si(dt, si)
    expect(omp).not_to eq(nil)
    expect(omp.obsoleted_dt).not_to eq(Float::INFINITY)

    omp.price = 1010
    expect do
      omp.save!
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'whodunnit should set user/o_user on CRUD' do
    Mcfly.whodunnit = { id: 20 }

    si = SecurityInstrument.find_by(name: 'FN Fix-30 Cash')
    dt = '2010-01-01 08:00 PST8PDT'

    sleep 1.second

    mp = MarketPrice.lookup_si(dt, si)
    expect(mp.user_id).to eq(10)

    mp.price = 123
    mp.save!

    # old version should still have original creator user
    mp = MarketPrice.lookup_si(dt, si)
    expect(mp.user_id).to eq(10)
    expect(mp.o_user_id).to eq(20)

    # new version should have new creator
    mp = MarketPrice.lookup_si('infinity', si)
    expect(mp.user_id).to eq(20)
    expect(mp.o_user_id).to eq(nil)
  end

  it 'should set o_user on delete' do
    si = SecurityInstrument.find_by(name: 'FN Fix-15 HB MBS')
    mp = MarketPrice.lookup_si('infinity', si)
    expect(mp.obsoleted_dt).to eq(Float::INFINITY)
    expect(mp.o_user_id).to eq(nil)

    rid = mp.id
    Mcfly.whodunnit = { id: 30 }
    mp.delete
    mp = MarketPrice.find(rid)
    expect(mp.o_user_id).to eq(30)
  end

  describe '#mcfly_belongs_to' do
    it 'should raise an error if association is obsoleted' do
      si = SecurityInstrument.find_by(name: 'FN Fix-15 HB MBS').dup
      si.update!(name: 'test')
      si.destroy!
      si.reload

      mp = MarketPrice.where(obsoleted_dt: 'infinity').last
      mp.update(security_instrument: si)
      expect(mp.errors[:security_instrument].first).to match(
        /Obsoleted association value of security_instrument for #<MarketPrice/
      )
    end

    it 'should not allow to deleted record of append_only association' do
      mp = MarketPrice.where(obsoleted_dt: 'infinity').first
      si = mp.security_instrument

      expect(si.destroy).to be false
      expect(si.errors.messages[:base]).to eq(
        [
          "SecurityInstrument can't be deleted because MarketPrice records exist"
        ]
      )
    end
  end

  describe '#mcfly_has_many' do
    it "shouldn't include obsoleted records" do
      si = SecurityInstrument.find_by(name: 'FN Fix-15 HB MBS')

      prices = MarketPrice.where(security_instrument_id: si.id)
      obsoleted_prices = prices.where.not(obsoleted_dt: 'infinity')
      non_obsoleted_prices = prices.where(obsoleted_dt: 'infinity')

      expect(obsoleted_prices.any?).to be true
      expect(si.market_prices).to eq non_obsoleted_prices
    end
  end
end
