require_relative 'spec_helper'
require '../lib/MBPSO_Team_Formation/mvh'
require 'csv'

RSpec.describe MBPSOTeamFormation::MVH do
  mvh = MBPSOTeamFormation::MVH.new
  describe "Detecting missing values " do
    it "Returning true if no values are missing" do
      row1 = CSV::Row.new(%w(id Gender Ethnicity Grade), [1, 1, 1, 0])
      row2 = CSV::Row.new(%w(id Gender Ethnicity Grade), [2, 0, 1, 100])
      row3 = CSV::Row.new(%w(id Gender Ethnicity Grade), [3, -1, 1, 80])
      row4 = CSV::Row.new(%w(id Gender Ethnicity Grade), [4, 0, 1, 90])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity Grade))
      expect(mvh.fill_missing_values(table, true)[4]).to eq(true)
    end

    it "Raise exception if missing values are found and the user doesn't want them handled" do
      row1 = CSV::Row.new(%w(id Gender Ethnicity Grade), [1, 1, 1, 0])
      row2 = CSV::Row.new(%w(id Gender Ethnicity Grade), [2, nil, 1, 100])
      row3 = CSV::Row.new(%w(id Gender Ethnicity Grade), [3, -1, 1, 80])
      row4 = CSV::Row.new(%w(id Gender Ethnicity Grade), [4, 0, 1, 90])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity Grade))
      expect { mvh.fill_missing_values(table, false) }.to raise_error(ArgumentError)
    end
  end

  def table
    row1 = CSV::Row.new(%w(id Gender Ethnicity Grade), [1, 1, 1, 10])
    row2 = CSV::Row.new(%w(id Gender Ethnicity Grade), [2, -1, nil, 25])
    row3 = CSV::Row.new(%w(id Gender Ethnicity Grade), [3, -1, 3, 38])
    row4 = CSV::Row.new(%w(id Gender Ethnicity Grade), [4, 1, 2, 50])
    row5 = CSV::Row.new(%w(id Gender Ethnicity Grade), [5, nil, 3, 82])
    row6 = CSV::Row.new(%w(id Gender Ethnicity Grade), [6, -1, 2, 90])
    row7 = CSV::Row.new(%w(id Gender Ethnicity Grade), [7, 1, 3, 37])
    row8 = CSV::Row.new(%w(id Gender Ethnicity Grade), [8, 0, 3, 45])
    row9 = CSV::Row.new(%w(id Gender Ethnicity Grade), [9, 1, 1, nil])
    row10 = CSV::Row.new(%w(id Gender Ethnicity Grade), [10, 1, 0, 68])
    CSV::Table.new([row1, row2, row3, row4, row5, row6, row7, row8, row9, row10], headers: %w(id Gender Ethnicity Grade))
  end
  def table2
    row1 = CSV::Row.new(%w(id Gender Ethnicity Grade), [1, 0, 1, 83])
    row2 = CSV::Row.new(%w(id Gender Ethnicity Grade), [2, nil, 2, 76])
    row3 = CSV::Row.new(%w(id Gender Ethnicity Grade), [3, -1, 2, 43])
    row4 = CSV::Row.new(%w(id Gender Ethnicity Grade), [4, 0, 2, nil])
    row5 = CSV::Row.new(%w(id Gender Ethnicity Grade), [5, -1, 3, 18])
    row6 = CSV::Row.new(%w(id Gender Ethnicity Grade), [6, -1, nil, 32])
    row7 = CSV::Row.new(%w(id Gender Ethnicity Grade), [7, 1, 3, 89])
    row8 = CSV::Row.new(%w(id Gender Ethnicity Grade), [8, 0, 4, 25])
    row9 = CSV::Row.new(%w(id Gender Ethnicity Grade), [9, 0, 1, 11])
    row10 = CSV::Row.new(%w(id Gender Ethnicity Grade), [10, 1, 2, 28])
    CSV::Table.new([row1, row2, row3, row4, row5, row6, row7, row8, row9, row10], headers: %w(id Gender Ethnicity Grade))
  end
  describe "Calculating needed statistics for the data set" do

    it "Calculates correctly the most frequent gender" do
      expect(mvh.fill_missing_values(table, true)[0]).to eq(1)
      expect(mvh.fill_missing_values(table2, true)[0]).to eq(0)
    end

    it "Calculates correctly the most frequent ethnicity" do
      expect(mvh.fill_missing_values(table, true)[1]).to eq(3)
      expect(mvh.fill_missing_values(table2, true)[1]).to eq(2)
    end

    it "Calculates correctly the mean of the grades" do
      res = mvh.fill_missing_values(table, true)[2]
      expect(res.round(2)).to eq(49.44)
      res = mvh.fill_missing_values(table2, true)[2]
      expect(res.round(2)).to eq(45)
    end
    
    it 'Calculated correctly standard deviation' do
      res = mvh.fill_missing_values(table, true)[3]
      expect(res.round(2)).to eq(24.74)
      res = mvh.fill_missing_values(table2, true)[3]
      expect(res.round(2)).to eq(28.06)
    end
  end
  describe "Replacing the missing values" do
    it "Replacing missing gender" do
      temp = table
      temp2 = table2
      result = mvh.fill_missing_values(temp, true)
      result2 = mvh.fill_missing_values(temp2, true)
      expect(temp[4]['Gender']).to eq(result[0])
      expect(temp2[1]['Gender']).to eq(result2[0])
    end

    it "Replacing missing ethnicity" do
      temp = table
      temp2 = table2
      result = mvh.fill_missing_values(temp, true)
      result2 = mvh.fill_missing_values(temp2, true)
      expect(temp[1]['Ethnicity']).to eq(result[1])
      expect(temp2[5]['Ethnicity']).to eq(result2[1])
    end

    it "Replacing missing grade" do
      temp = table
      temp2 = table2
      result = mvh.fill_missing_values(temp, true)
      mean1 = result[2]
      std1 = result[3]
      result2 = mvh.fill_missing_values(temp2, true)
      mean2 = result2[2]
      std2 = result2[3]
      possible_values1 = [[(mean1-3*std1).round, 0].max, [(mean1-2*std1).round,0].max , (mean1-std1).round, mean1.round, (mean1+std1).round, [(mean1+2*std1).round, 0].min, [(mean1+3*std1).round, 100].min]
      possible_values2 = [[(mean2-3*std2).round, 0].max, [(mean2-2*std2).round, 0].max, (mean2-std2).round, mean2.round, (mean2+std2).round, [(mean2+2*std2).round, 0].min, [(mean2+3*std2).round, 100].min]
      expect(possible_values1).to include(temp[8]['Grade'])
      expect(possible_values2).to include(temp2[3]['Grade'])
    end
  end
end