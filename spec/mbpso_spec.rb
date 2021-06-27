require_relative 'spec_helper'
require '../lib/MBPSO_Team_Formation/mbpso'
require 'csv'

RSpec.describe MBPSOTeamFormation::MBPSO do

  def test1
    CSV.parse(File.read('test1.csv'), headers: true)
  end

  def test2
    CSV.parse(File.read('test2.csv'), headers: true)
  end

  def inst_small_table
    row1 = CSV::Row.new(%w(id Gender Ethnicity Grade), [1, 0, -1, 1])
    row2 = CSV::Row.new(%w(id Gender Ethnicity Grade), [2, 1, 0, 2])
    row3 = CSV::Row.new(%w(id Gender Ethnicity Grade), [3, -1, 2, 3])
    row4 = CSV::Row.new(%w(id Gender Ethnicity Grade), [4, 0, 3, 4])
    row5 = CSV::Row.new(%w(id Gender Ethnicity Grade), [5, 1, 4, 5])
    row6 = CSV::Row.new(%w(id Gender Ethnicity Grade), [6, -1, -1, 6])
    row7 = CSV::Row.new(%w(id Gender Ethnicity Grade), [7, 0, 0, 7])
    row8 = CSV::Row.new(%w(id Gender Ethnicity Grade), [8, 1, 1, 1])
    row9 = CSV::Row.new(%w(id Gender Ethnicity Grade), [9, -1, 2, 3])
    row10 = CSV::Row.new(%w(id Gender Ethnicity Grade), [10, 0, 3, 5])
    CSV::Table.new([row1, row2, row3, row4, row5, row6, row7, row8, row9, row10], headers: %w(id Gender Ethnicity Grade))
  end

  def inst_small_table2
    row1 = CSV::Row.new(%w(id Gender Ethnicity Grade), [1, 0, -1, 1])
    row2 = CSV::Row.new(%w(id Gender Ethnicity Grade), [2, 1, 0, 2])
    row3 = CSV::Row.new(%w(id Gender Ethnicity Grade), [3, -1, 2, 3])
    row4 = CSV::Row.new(%w(id Gender Ethnicity Grade), [4, 0, 3, 4])
    row5 = CSV::Row.new(%w(id Gender Ethnicity Grade), [5, 1, 4, 5])
    row6 = CSV::Row.new(%w(id Gender Ethnicity Grade), [6, -1, -1, 6])
    row7 = CSV::Row.new(%w(id Gender Ethnicity Grade), [7, 0, 0, 7])
    row8 = CSV::Row.new(%w(id Gender Ethnicity Grade), [8, 1, 1, 1])
    row9 = CSV::Row.new(%w(id Gender Ethnicity Grade), [9, -1, 2, 3])
    CSV::Table.new([row1, row2, row3, row4, row5, row6, row7, row8, row9], headers: %w(id Gender Ethnicity Grade))
  end

  describe "Intialisation" do
    it "Initialised successfully with  a valid data set" do
      expect(MBPSOTeamFormation::MBPSO.new(test1)).to be_a(MBPSOTeamFormation::MBPSO)
      expect(MBPSOTeamFormation::MBPSO.new(test2)).to be_a(MBPSOTeamFormation::MBPSO)
    end

    it "Initialised successfully with different sets of optional paramteres" do

      expect(MBPSOTeamFormation::MBPSO.new(test2, num_particles: 20, gender_weight: 5, \
                                                  ethnicity_weight: 3, initial_inertia: 4.0)).to be_a(MBPSOTeamFormation::MBPSO)
      expect(MBPSOTeamFormation::MBPSO.new(test1, final_inertia: 0.1, control_param_personal: [0.99, 0.6, 0.1], \
                                                  control_param_local: [0.1, 0.1, 0.1], survival_number: 30)).to be_a(MBPSOTeamFormation::MBPSO)
      expect(MBPSOTeamFormation::MBPSO.new(test2, skill_table: {0..19 => 1, 20..49 => 20, 50..59 => 30, 60..76 => 40, 77..84 => 5, 85..100 => 4}, \
                                                  forbidden_pairs: [[1, 2], [3, 4]])).to be_a(MBPSOTeamFormation::MBPSO)
    end

    it "Instantiates with full set of optional parameters" do
      expect(MBPSOTeamFormation::MBPSO.new(test1, team_size: 4, max_iterations: 3000, num_particles: 20, \
                                                  gender_weight: 6, ethnicity_weight: 6, initial_inertia: 2.0, final_inertia: 0.1, \
                                                  control_param_personal: [0.3, 0.3, 0.3], control_param_local: [0.3, 0.3, 0.3], \
                                                  survival_number: 15, final_survival_number: 3, \
                                                  skill_table: {0..19 => 1, 20..49 => 20, 50..59 => 30, 60..76 => 40, 77..84 => 5, 85..100 => 4}, \
                                                  forbidden_pairs: [[1, 2], [3, 4]], tolerate_missing_values: false, init_num_particles: 2, \
                                                  output_stats: false, output_stats_name: 'data', neigh_change_interval: 100, inertia_change_interval: 20, \
                                                  sn_change_interval: 20, particles_to_move: 3, inertia_changes: 200, sn_changes: 200, convergence_iterations: 200)).to be_a(MBPSOTeamFormation::MBPSO)
    end

    it "Throws exceptions for invalid input" do
      expect {
        MBPSOTeamFormation::MBPSO.new(test1, final_inertia: 'x', control_param_personal: [0.99, 0.6, 0.1], \
                                             control_param_local: [0.1, 0.1, 0.1], survival_number: 30) }.to raise_error(ArgumentError)
      expect {
        MBPSOTeamFormation::MBPSO.new(test2, num_particles: -3, gender_weight: 5, \
                                             ethnicity_weight: 3, initial_inertia: 4.0) }.to raise_error(ArgumentError)
      expect {
        MBPSOTeamFormation::MBPSO.new(test2, skill_table: {0..12 => 1, 20..49 => 20, 50..59 => 30, 60..76 => 40, 77..84 => 5, 85..100 => 4}, \
                                             forbidden_pairs: [[1, 2], [3, 4]]) }.to raise_error(ArgumentError)

    end
  end
  describe "Running the algorithm" do
    it "Return the result in the format of Array of Arrays" do
      mbpso1 = MBPSOTeamFormation::MBPSO.new(test1, num_particles: 5, max_iterations: 10)
      mbpso2 = MBPSOTeamFormation::MBPSO.new(test2, num_particles: 4, max_iterations: 12)

      x = 5
      expect(x).to eq(5)
      mbpso1.run.each do |x|
        expect(x).to be_a(Array)
      end

      mbpso2.run.each do |x|
        expect(x).to be_a(Array)
      end
    end

    it "Exports statistics data into a .csv file with the expected amount of rows and columns" do
      mbpso1 = MBPSOTeamFormation::MBPSO.new(test1, num_particles: 15, max_iterations: 20, neigh_change_interval: 1, output_stats: true)
      mbpso2 = MBPSOTeamFormation::MBPSO.new(test2, num_particles: 10, max_iterations: 30, neigh_change_interval: 1, output_stats: true)
      mbpso1.run

      data = CSV.parse(File.read(File.join("\data", 'stats.csv')), headers: false)
      expect(data.length).to eq(17)
      expect(data[2].length).to eq(20)

      mbpso2.run

      data = CSV.parse(File.read(File.join("\data", 'stats.csv')), headers: false)
      expect(data.length).to eq(12)
      expect(data[2].length).to eq(30)
    end

    it "Exports data only if requested" do
      mbpso1 = MBPSOTeamFormation::MBPSO.new(test1, num_particles: 15, max_iterations: 20, neigh_change_interval: 1, output_stats_name: 'should_fail.csv')
      mbpso2 = MBPSOTeamFormation::MBPSO.new(test2, num_particles: 20, max_iterations: 2, neigh_change_interval: 1, output_stats: true, output_stats_name: 'should_succeed.csv')

      mbpso1.run
      expect { CSV.parse(File.read(File.join("\data", 'should_fail.csv')), headers: false) }.to raise_error(Errno::ENOENT)

      mbpso2.run
      expect(CSV.parse(File.read(File.join("\data", 'should_succeed.csv')), headers: false)).to be_a(Array)
    end
    it "Successfully allocates students if number of students is not a multiple of the teams size" do
      mbpso1 = MBPSOTeamFormation::MBPSO.new(inst_small_table, num_particles: 10, max_iterations: 5)
      i = 0
      mbpso1.run.each do |x|
        i += 1 if x.size == 5
      end
      expect(i).to eq(2)

      mbpso2 = MBPSOTeamFormation::MBPSO.new(inst_small_table2, num_particles: 12, max_iterations: 3)
      i = 0
      mbpso2.run.each do |x|
        i += 1 if x.size == 5
      end
      expect(i).to eq(1)
    end

    it "Succesfully allocated students to teams of various sizes" do
      mbpso1 = MBPSOTeamFormation::MBPSO.new(test1, team_size: 10, num_particles: 8, max_iterations: 10)
      mbpso1.run.each do |x|
        expect(x.size).to eq(10)
      end

      mbpso1 = MBPSOTeamFormation::MBPSO.new(test1, team_size: 20, num_particles: 8, max_iterations: 10)
      mbpso1.run.each do |x|
        expect(x.size).to eq(20)
      end

    end
  end
end


