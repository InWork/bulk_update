require 'spec_helper.rb'

require 'pry'

describe BulkUpdate do
  describe 'Normal values' do
    before :each do
      Time.zone = 'Pacific Time (US & Canada)'
      @columns = [:name, :value]
      @values  = [['test1', 'value1'], ['test2', 'value2'], ['test3', 'value3'], ['test4', 'value4']]
      MyHash.bulk_insert @columns, @values
    end


    it 'inserts multiple records in one SQL' do
      MyHash.count.should be 4
    end


    it 'updates and deletes records' do
      @values  = [['test1', 'value1.1'], ['test2', 'value2'], ['test4', 'value4.4'], ['test5', 'value5.5']]
      MyHash.bulk_update @columns, @values, key: 'name'
      MyHash.count.should be 4
      MyHash.where(name: 'test1').first.value.should eq 'value1.1'
      MyHash.where(name: 'test2').first.value.should eq 'value2'
      MyHash.where(name: 'test3').first.should be nil
      MyHash.where(name: 'test4').first.value.should eq 'value4.4'
      MyHash.where(name: 'test5').first.value.should eq 'value5.5'
    end
  end

  describe 'Datetime values' do
    before :each do
      Time.zone = 'Bern'
      @columns = [:name, :value, :time_value]
      @values  = [['test1', 'value1', Time.parse('2014-03-11 11:11:11 +0100')],
                  ['test2', 'value2', '2014-03-12 12:12:12 +0100'],
                  ['test3', 'value3', '2014-03-13 13:13:13'],
                  ['test4', 'value4', Time.parse('2014-03-14 14:14:14 +0100')]]
      MyDateTimeHash.bulk_insert @columns, @values
    end


    it 'inserts multiple records in one SQL' do
      MyDateTimeHash.count.should be 4
      MyDateTimeHash.where(name: 'test1').first.time_value.to_s(:db).should eq "2014-03-11 10:11:11"
      MyDateTimeHash.where(name: 'test2').first.time_value.to_s(:db).should eq "2014-03-12 11:12:12"
      MyDateTimeHash.where(name: 'test3').first.time_value.to_s(:db).should eq "2014-03-13 12:13:13"
      MyDateTimeHash.where(name: 'test4').first.time_value.to_s(:db).should eq "2014-03-14 13:14:14"
    end


    it 'updates and deletes records' do
      @values  = [['test1', 'value1.1', Time.parse('2014-03-11 11:11:40 +0100')],
                  ['test2', 'value2', '2014-03-12 12:12:40 +0100'],
                  ['test4', 'value4.4', '2014-03-13 13:13:40'],
                  ['test5', 'value5.5', Time.parse('2014-03-14 14:14:14 +0100')]]

      MyDateTimeHash.bulk_update @columns, @values, key: 'name'

      MyDateTimeHash.count.should be 4
      MyDateTimeHash.where(name: 'test1').first.value.should eq 'value1.1'
      MyDateTimeHash.where(name: 'test2').first.value.should eq 'value2'
      MyDateTimeHash.where(name: 'test3').first.should be nil
      MyDateTimeHash.where(name: 'test4').first.value.should eq 'value4.4'
      MyDateTimeHash.where(name: 'test5').first.value.should eq 'value5.5'
      MyDateTimeHash.where(name: 'test1').first.time_value.to_s(:db).should eq "2014-03-11 10:11:40"
      MyDateTimeHash.where(name: 'test2').first.time_value.to_s(:db).should eq "2014-03-12 11:12:40"
      MyDateTimeHash.where(name: 'test4').first.time_value.to_s(:db).should eq "2014-03-13 12:13:40"
      MyDateTimeHash.where(name: 'test5').first.time_value.to_s(:db).should eq "2014-03-14 13:14:14"
    end
  end

end
