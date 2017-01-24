require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Mcfly" do
  before(:each) do
    Mcfly.whodunnit = {id: 10}

    @old = '2000-01-01'

    @dts = ['2001-01-01', '2001-01-05', '2001-01-10']

    @sis = [
      ["FN Fix-30 MBS",         "A"],
      ["FN Fix-30 Cash",        "A"],
      ["FN Fix-30 MBS Blend",   "A"],
      ["FN Fix-30 HB MBS",      "A"],
      ["FN Fix-15 MBS",         "B"],
      ["FN Fix-15 Cash",        "B"],
      ["FN Fix-15 HB MBS",      "B"],
      ["FN Fix-15 HB Cash",     "B"],
      ["FN ARM 3/1 LIBOR",      "D"],
      ["FN ARM 3/1 LIBOR Cash", "D"],
      ["FN ARM 5/1 LIBOR",      "D"],
      ["FN ARM 5/1 LIBOR Cash", "D"],
    ]

    @sis.each_with_index { |(name, sc), i|
      si = SecurityInstrument.new(name: name, settlement_class: sc)
      si.created_dt = @dts[i % @dts.length]
      si.save!
    }

    @sis.each_with_index { |(name, sc), i|
      ii = i+1
      si = SecurityInstrument.find_by_name(name)
      mp = MarketPrice.new(security_instrument_id: si.id,
                           coupon: ii * 1.1,
                           settlement_mm: ii,
                           settlement_yy: 2000+ii,
                           price: ii,
                           )
      mp.created_dt = si.created_dt
      mp.save!

      @vers = 5

      # create 5 additional verions for each mp
      (1..@vers).each {
        mp.price = mp.price + 1
        mp.created_dt = mp.created_dt + 1.day
        mp.save!
      }
    }

  end

  it "should update obsoleted_dt properly when created_dt is set" do
    si = SecurityInstrument.first
    mp = MarketPrice.new(security_instrument_id: si.id,
                         coupon: 2.0,
                         settlement_mm: 1,
                         settlement_yy: 2013,
                         price: 100.256,
                         )
    mp.created_dt = si.created_dt
    mp.save!

    mp.price = mp.price + 123
    mp.created_dt = si.created_dt + 1.day
    mp.save!

    l = MarketPrice.where("group_id = ?", mp.id).order("obsoleted_dt").all
    l.length.should == 2

    l[1].obsoleted_dt.should == Float::INFINITY
    l[0].obsoleted_dt.should == mp.created_dt

    # Make sure that setting an old created_dt fails.
    mp.price = mp.price + 123
    mp.created_dt = mp.created_dt - 1.day
    lambda {
      mp.save!
    }.should raise_error(ActiveRecord::StatementInvalid)
  end

  it "should make sure that append-only does not allow changes" do
    si = SecurityInstrument.lookup('infinity', "FN Fix-30 MBS")
    si.settlement_class.should == "A"

    si.name = "xyz"

    lambda {
      si.save!
    }.should raise_error(ActiveRecord::StatementInvalid)

  end

  it "should be able to delete append-only items" do
    osi = SecurityInstrument.find_by_name("FN Fix-30 MBS")
    osi.delete

    osi = SecurityInstrument.find_by_name("FN Fix-30 MBS")

    (osi.obsoleted_dt - DateTime.now).to_f.abs.should < 100

    lambda {
      osi.delete
    }.should raise_error(ActiveRecord::StatementInvalid)
  end

  it "should be able to delete append-only items and create a new clone" do
    osi = SecurityInstrument.find_by_name("FN Fix-30 MBS")
    osi.delete

    # now try to add a clone of si
    si = SecurityInstrument.new(name: osi.name,
                                settlement_class: osi.settlement_class)
    si.save!
  end

  it "should check basic versioning" do
    SecurityInstrument.lookup_all('infinity').count.should == @sis.count

    @dts.each_with_index { |pt, i|
      SecurityInstrument.lookup_all(pt + " 12:00 PST8PDT").count.should ==
      (i+1) * @sis.count/@dts.length
    }

    SecurityInstrument.lookup_all(@old).count.should == 0
    SecurityInstrument.lookup(@old, "FN Fix-30 MBS").should == nil

    # all versions
    MarketPrice.count == @sis.length * (@vers+1)

    MarketPrice.lookup_all('infinity').count.should == @sis.count

    si = SecurityInstrument.first

    mp = MarketPrice.lookup_si('infinity', si)

    odate = mp.created_dt - 0.5.day

    # previous version of mp
    omp = MarketPrice.lookup_si(odate, si)

    mp.price.should == omp.price + 1
  end

  it "should test mcfly uniqueness validations" do
    def new_mp(price)
      si = SecurityInstrument.first
      MarketPrice.new(security_instrument_id: si.id,
                      coupon: 2.0,
                      settlement_mm: 1,
                      settlement_yy: 2013,
                      price: price,
                      )
    end

    si = SecurityInstrument.first
    mp = new_mp(100.256)
    mp.created_dt = si.created_dt
    mp.save!

    # create another MarketPrice with the same si/coupon/mm/yy.  This
    # should fail.
    mp2 = new_mp(mp.price + 100)

    mp2.created_dt = si.created_dt + 1.day
    lambda {
      mp2.save!
    }.should raise_error(ActiveRecord::RecordInvalid)

    # now change mp's settlement_mm
    mp.settlement_mm += 1
    mp.save!

    # since we changed mp's settlement_mm, we should be able to create
    # a new one with the same info as mp's old instance.
    mp3 = new_mp(100.256)
    mp3.save!
  end

  it "should be able to delete objects" do
    si = SecurityInstrument.find_by_name("FN Fix-30 Cash")
    dt = '2010-01-01 08:00 PST8PDT'

    mp = MarketPrice.lookup_si(dt, si)
    mp.obsoleted_dt.should == Float::INFINITY

    sleep 1.seconds

    mp.delete

    MarketPrice.lookup_si('infinity', si).should == nil

    omp = MarketPrice.lookup_si(dt, si)
    omp.should_not == nil
    omp.obsoleted_dt.should_not == Float::INFINITY

    omp.price = 1010
    lambda {
      omp.save!
    }.should raise_error(ActiveRecord::StatementInvalid)
  end

  it "whodunnit should set user/o_user on CRUD" do
    Mcfly.whodunnit = {id: 20}

    si = SecurityInstrument.find_by_name("FN Fix-30 Cash")
    dt = '2010-01-01 08:00 PST8PDT'

    sleep 1.seconds

    mp = MarketPrice.lookup_si(dt, si)
    mp.user_id.should == 10

    mp.price = 123
    mp.save!

    # old version should still have original creator user
    mp = MarketPrice.lookup_si(dt, si)
    mp.user_id.should == 10
    mp.o_user_id.should == 20

    # new version should have new creator
    mp = MarketPrice.lookup_si('infinity', si)
    mp.user_id.should == 20
    mp.o_user_id.should == nil
  end

  it "should set o_user on delete" do
    si = SecurityInstrument.find_by_name("FN Fix-15 HB MBS")
    mp = MarketPrice.lookup_si('infinity', si)
    mp.obsoleted_dt.should == Float::INFINITY
    mp.o_user_id.should == nil

    rid = mp.id
    Mcfly.whodunnit = {id: 30}
    mp.delete
    mp = MarketPrice.find(rid)
    mp.o_user_id.should == 30
  end
end
