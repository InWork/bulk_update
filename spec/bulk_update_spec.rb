require 'spec_helper.rb'

require 'pry'

describe BulkUpdate do
  before :each do
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
