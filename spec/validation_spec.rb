# frozen_string_literal: true
require_relative 'spec_helper'
require '../lib/MBPSO_Team_Formation/validation'
require 'csv'

RSpec.describe MBPSOTeamFormation::Validation do
  val = MBPSOTeamFormation::Validation.new
  describe "Validate Numbers" do
    it "Integer validator accepts only valid positive integers" do
      expect(val.validate_number(3, 'test', 'pos_int')).to eq(3)
      expect { val.validate_number(-2, 'test', 'pos_int') }.to raise_error(ArgumentError)
      expect { val.validate_number(0, 'test', 'pos_int') }.to raise_error(ArgumentError)
      expect { val.validate_number(3.1, 'test', 'pos_int') }.to raise_error(ArgumentError)
      expect { val.validate_number(-2.1, 'test', 'pos_int') }.to raise_error(ArgumentError)
      expect { val.validate_number([3, 5], 'test', 'pos_int') }.to raise_error(ArgumentError)
      expect { val.validate_number('should fail', 'test', 'pos_int') }.to raise_error(ArgumentError)
    end

    it "Non-negative number accepts only valid integers and floats" do
      expect(val.validate_number(5, 'test', 'nn_num')).to eq(5)
      expect(val.validate_number(5.0, 'test', 'nn_num')).to eq(5.0)
      expect(val.validate_number(0, 'test', 'nn_num')).to eq(0)
      expect(val.validate_number(0.0, 'test', 'nn_num')).to eq(0.0)
      expect { val.validate_number(-1.0, 'test', 'nn_num') }.to raise_error(ArgumentError)
      expect { val.validate_number(-1, 'test', 'nn_num') }.to raise_error(ArgumentError)
      expect { val.validate_number(['a', 5], 'test', 'nn_num') }.to raise_error(ArgumentError)
      expect { val.validate_number('should_fa', 'test', 'nn_num') }.to raise_error(ArgumentError)
    end

    it "Works only with 'pos_int' and 'nn_num' arguments" do
      expect(val.validate_number(5, 'test', 'pos_int')).to eq(5)
      expect(val.validate_number(5.0, 'test', 'nn_num')).to eq(5.0)
      expect { val.validate_number(-1.0, 'test', 'random') }.to raise_error(ArgumentError)
      expect { val.validate_number(-1, 'test', 'positive integer') }.to raise_error(ArgumentError)
      expect { val.validate_number(['a', 5], 'test', 'negative float') }.to raise_error(ArgumentError)
      expect { val.validate_number('should_fa', 'test', 'test') }.to raise_error(ArgumentError)
    end
  end

  describe "Validate Survaival Number" do
    it "Accepts only integers between 2 and the  number of students" do
      expect(val.validate_survival_number(3, 5)).to eq(3)
      expect(val.validate_survival_number(3, 520)).to eq(3)
      expect(val.validate_survival_number(100, 500)).to eq(100)
      expect {val.validate_survival_number(100, 50)}.to raise_error(ArgumentError)
      expect {val.validate_survival_number(100.0, 50)}.to raise_error(ArgumentError)
      expect {val.validate_survival_number(100.0, 5000)}.to raise_error(ArgumentError)
      expect {val.validate_survival_number(1, 50)}.to raise_error(ArgumentError)
      expect {val.validate_survival_number(-3, 50)}.to raise_error(ArgumentError)
      expect {val.validate_survival_number('asdd', 50)}.to raise_error(ArgumentError)
      expect {val.validate_survival_number([4, {}], 50)}.to raise_error(ArgumentError)
    end
  end

  describe "Validate Control Parameters" do
    it "Accepts only valid 3-valued arrays with floats in [0:1]" do
      expect(val.validate_control_parameters([0.1, 0.1, 0.1], 'local')).to eq([0.1, 0.1, 0.1])
      expect(val.validate_control_parameters([0, 0.1, 1], 'local')).to eq([0, 0.1, 1])
      expect(val.validate_control_parameters([0, 0.1, 1], 'personal')).to eq([0, 0.1, 1])
      expect(val.validate_control_parameters([0.1, 0.1, 0.1], 'personal')).to eq([0.1, 0.1, 0.1])
      expect {val.validate_control_parameters([2, 2, 2], 'local')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0.2, 0.2, 0.2, 0.2], 'local')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0.1, 0.1, 2], 'local')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0.5, -32, 0.5], 'local')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0, 0, 32], 'local')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters(['test', 0.1, 0.1], 'local')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters(['test', 8], 'local')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters(4, 'local')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters('test', 'local')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([2, 2, 2], 'personal')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0.2, 0.2, 0.2, 0.2], 'personal')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0.1, 0.1, 2], 'personal')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0.5, -32, 0.5], 'personal')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0, 0, 32], 'personal')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters(['test', 0.1], 'personal')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters(['test', 0.1, 8], 'personal')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters(4, 'personal')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters('test', 'personal')}.to raise_error(ArgumentError)
    end

    it "Works only with 'local' and 'personal' arguments" do
      expect(val.validate_control_parameters([0, 0.1, 1], 'local')).to eq([0, 0.1, 1])
      expect(val.validate_control_parameters([0, 0.1, 1], 'personal')).to eq([0, 0.1, 1])
      expect {val.validate_control_parameters([0.5, 0.5, 0.5], 'test')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0.5, 0.5, 0.5], 'parameter')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0.5, 0.5, 0.5], '')}.to raise_error(ArgumentError)
      expect {val.validate_control_parameters([0.5, 0.5, 0.5], 5)}.to raise_error(ArgumentError)
    end
  end

  describe "Validate Skill Table" do
    it "Accepts only hashes that cover the whole [0:100] Integer range and are not ambiguous" do
      expect(val.validate_skill_table({(0..50) => 5, (51..100) => 2})).to eq({(0..50) => 5, (51..100) => 2})
      expect {val.validate_skill_table({(0.0..50.0) => 5, (50..100) => 2})}.to raise_error(ArgumentError)
      expect {val.validate_skill_table({(0.0..50.0) => 5, (60..100) => 2})}.to raise_error(ArgumentError)
      expect {val.validate_skill_table({('a'..'d') => 5, (50..100) => 2})}.to raise_error(ArgumentError)
      expect {val.validate_skill_table({(0..48) => 5, (50..100) => 2})}.to raise_error(ArgumentError)
      expect {val.validate_skill_table([[5, 10], [20, 30]])}.to raise_error(ArgumentError)
    end

    it "Accepts only integer keys" do
      expect{val.validate_skill_table({(0..50) => 5.0, (51..100) => 2})}.to raise_error(ArgumentError)
      expect{val.validate_skill_table({(0..50) => [5], (51..100) => 2})}.to raise_error(ArgumentError)
      expect{val.validate_skill_table({(0..50) => '5', (51..100) => 2})}.to raise_error(ArgumentError)
    end
  end

  describe "Validate Boolean" do
    it "Accepts only logical/bolean values" do
      expect(val.validate_bool(true, 'test')).to eq(true)
      expect(val.validate_bool(false, 'test')).to eq(false)
      expect{ val.validate_bool(5, 'test')}.to raise_error(ArgumentError)
      expect{ val.validate_bool('true', 'test')}.to raise_error(ArgumentError)
      expect{ val.validate_bool({}, 'test')}.to raise_error(ArgumentError)
    end
  end

  describe "Validate Data Set" do
    it "Accepts only CSV::Table formats" do
      row = CSV::Row.new(%w(id Gender Ethnicity Grade), [1, 1, 1, 1])
      table = CSV::Table.new([row], headers: %w(id Gender Ethnicity Grade))
      expect(val.validate_dataset(table)).to eq(table)
      expect {val.validate_dataset(5)}.to raise_error(ArgumentError)
      expect {val.validate_dataset([[5], [5]])}.to raise_error(ArgumentError)
      expect {val.validate_dataset('test')}.to raise_error(ArgumentError)
      expect {val.validate_dataset(nil)}.to raise_error(ArgumentError)
    end
    it "Accepts data sets only with valid headers and valid number of columns" do
      row = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      table = CSV::Table.new([row], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)
      row = CSV::Row.new(%w(id Gender Ethnicity Grade nationality ), [1, 1, 1, 1])
      table = CSV::Table.new([row], headers: %w(id Gender Ethnicity Grade nationality))
      expect {val.validate_dataset(table)}.to raise_error(ArgumentError)
    end

    it 'Declines data sets with duplicating IDs' do
      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 1, 1, 1])
      table = CSV::Table.new([row1, row2, row3], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)
    end

    it "Declines data sets with gender values different from '-1', '0' and '1'" do
      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 0, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [3, -1, 1, 1])
      row4 = CSV::Row.new(%w(id Gender Ethnicity marks), [4, -5, 0, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)

      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 0, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [3, -1, 1, 1])
      row4 = CSV::Row.new(%w(id Gender Ethnicity marks), [4, 8, 1, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)

      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 0, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [3, -1, 1, 1])
      row4 = CSV::Row.new(%w(id Gender Ethnicity marks), [4, 'male', 0, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)

      row1 = CSV::Row.new(%w(id Gender Ethnicity Grade), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity Grade), [2, 0, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity Grade), [3, -1, 1, 1])
      row4 = CSV::Row.new(%w(id Gender Ethnicity Grade), [4, 0, 1, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity Grade))
      expect(val.validate_dataset(table)).to eq(table)
    end

    it "Declines data sets with ethnicity values different from the Integers in the [-1:4] range" do
      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 0, 5, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [3, -1, 1, 1])
      row4 = CSV::Row.new(%w(id Gender Ethnicity marks), [4, 0, 0, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)

      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 0, -3, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [3, -1, 1, 1])
      row4 = CSV::Row.new(%w(id Gender Ethnicity marks), [4, 0, 1, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)

      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 0, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [3, -1, 'white', 1])
      row4 = CSV::Row.new(%w(id Gender Ethnicity marks), [4, -1, 0, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)

      row1 = CSV::Row.new(%w(id Gender Ethnicity Grade), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity Grade), [2, 0, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity Grade), [3, -1, 1, 1])
      row4 = CSV::Row.new(%w(id Gender Ethnicity Grade), [4, 0, 1, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity Grade))
      expect(val.validate_dataset(table)).to eq(table)
    end

    it "Declines data sets with gender values different from '-1', '0' and 1" do
      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 0, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [3, -1, 1, 101])
      row4 = CSV::Row.new(%w(id Gender Ethnicity marks), [4, 0, 0, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)

      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 0, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [3, -1, 1, 1])
      row4 = CSV::Row.new(%w(id Gender Ethnicity marks), [4, 0, 1, -5])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)

      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 0, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [3, -1, 1, '100%'])
      row4 = CSV::Row.new(%w(id Gender Ethnicity marks), [4, 0, 0, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)

      row1 = CSV::Row.new(%w(id Gender Ethnicity marks), [1, 1, 1, 1])
      row2 = CSV::Row.new(%w(id Gender Ethnicity marks), [2, 0, 1, 1])
      row3 = CSV::Row.new(%w(id Gender Ethnicity marks), [3, -1, 1, 50.0])
      row4 = CSV::Row.new(%w(id Gender Ethnicity marks), [4, 0, 0, 1])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity marks))
      expect { val.validate_dataset(table)}.to raise_error(ArgumentError)

      row1 = CSV::Row.new(%w(id Gender Ethnicity Grade), [1, 1, 1, 0])
      row2 = CSV::Row.new(%w(id Gender Ethnicity Grade), [2, 0, 1, 100])
      row3 = CSV::Row.new(%w(id Gender Ethnicity Grade), [3, -1, 1, 80])
      row4 = CSV::Row.new(%w(id Gender Ethnicity Grade), [4, 0, 1, 90])
      table = CSV::Table.new([row1, row2, row3, row4], headers: %w(id Gender Ethnicity Grade))
      expect(val.validate_dataset(table)).to eq(table)
    end
  end

  describe "Validate Forbidden Pair" do
    it "Accepts instances of Array or CSV::Table with two values per row" do

      row1 = CSV::Row.new([1, 3], [1, 1])
      row2 = CSV::Row.new([1, 3], [2, 0])
      table = CSV::Table.new([row1, row2], headers: [1, 3])
      expect(val.validate_forbidden_pairs(table)). to eq(table)
      
      array = [[1, 2], [2, 3]]
      expect(val.validate_forbidden_pairs(array)). to eq(array)

      row2 = CSV::Row.new([1, 3, 4], [2, 0, 5])
      row1 = CSV::Row.new([1, 3, 4], [1, 1, 5])
      table = CSV::Table.new([row1, row2], headers: [1, 3, 4])
      expect {val.validate_forbidden_pairs(table)}.to raise_error(ArgumentError)

      array = [[1, 2, 3], [2, 3]]
      expect {val.validate_forbidden_pairs(array)}.to raise_error(ArgumentError)

      expect {val.validate_forbidden_pairs('should fail')}.to raise_error(ArgumentError)
    end

  end
end