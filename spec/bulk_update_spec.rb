require 'spec_helper.rb'

require 'pry'

describe BulkUpdate do
  before :each do
    @columns = [:name, :value]
    @values  = [['test1', 'value1'], ['test2', 'value2'], ['test3', 'value3'], ['test4', 'value4']]
    MyHash.bulk_insert @columns, @values
    @ts = MyHash.first.created_at
  end


  it 'inserts multiple records in one SQL' do
    MyHash.count.should be 4
  end


  it 'updates and deletes records' do
    @values  = [['test1', 'value1.1'], ['test2', 'value2'], ['test4', 'value4.4'], ['test5', 'value5.5']]
    MyHash.bulk_update @columns, @values, key: 'name'
    MyHash.count.should be 4
    MyHash.where(name: 'test1').first.value.should eq 'value1.1'
    MyHash.where(name: 'test1').first.created_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test1').first.updated_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test2').first.value.should eq 'value2'
    MyHash.where(name: 'test2').first.created_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test2').first.updated_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test3').first.should be nil
    MyHash.where(name: 'test4').first.value.should eq 'value4.4'
    MyHash.where(name: 'test4').first.created_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test4').first.updated_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test5').first.value.should eq 'value5.5'
    MyHash.where(name: 'test5').first.created_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test5').first.updated_at.to_i.should eq @ts.to_i
  end


  it 'should update the created_at and updated_at timestamps if specified' do
    columns = [:name, :value, :updated_at, :created_at]
    ts_1    = 1.hour.ago
    ts_2    = 2.hour.ago
    ts_1_s  = ts_1.to_s(:db)
    ts_2_s  = ts_2.to_s(:db)
    values  = [['test1', 'value1.1', ts_1_s, ts_2_s], ['test2', 'value2', ts_1_s, ts_2_s], ['test4', 'value4.4', ts_1_s, ts_2_s], ['test5', 'value5.5', ts_1_s, ts_2_s]]
    MyHash.bulk_update columns, values, key: 'name'
    MyHash.count.should be 4
    MyHash.where(name: 'test1').first.value.should eq 'value1.1'
    MyHash.where(name: 'test1').first.created_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test1').first.updated_at.to_i.should eq ts_1.to_i
    MyHash.where(name: 'test2').first.value.should eq 'value2'
    MyHash.where(name: 'test2').first.created_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test2').first.updated_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test3').first.should be nil
    MyHash.where(name: 'test4').first.value.should eq 'value4.4'
    MyHash.where(name: 'test4').first.created_at.to_i.should eq @ts.to_i
    MyHash.where(name: 'test4').first.updated_at.to_i.should eq ts_1.to_i
    MyHash.where(name: 'test5').first.value.should eq 'value5.5'
    MyHash.where(name: 'test5').first.created_at.to_i.should eq ts_2.to_i
    MyHash.where(name: 'test5').first.updated_at.to_i.should eq ts_1.to_i
  end

end
