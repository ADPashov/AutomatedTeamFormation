require_relative 'spec_helper'
require '../lib/MBPSO_Team_Formation/particle'
require 'csv'

RSpec.describe MBPSOTeamFormation::Particle do

  table1 = CSV.parse(File.read('test1.csv'), headers: true)
  table2 = CSV.parse(File.read('test1.csv'), headers: true)

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
    row11 = CSV::Row.new(%w(id Gender Ethnicity Grade), [10, 1, 4, 7])
    row12 = CSV::Row.new(%w(id Gender Ethnicity Grade), [10, -1, 2, 4])
    CSV::Table.new([row1, row2, row3, row4, row5, row6, row7, row8, row9, row10, row11, row12], headers: %w(id Gender Ethnicity Grade))
  end

  def inst_mid_table
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
    row11 = CSV::Row.new(%w(id Gender Ethnicity Grade), [10, 1, 4, 7])
    row12 = CSV::Row.new(%w(id Gender Ethnicity Grade), [10, -1, 2, 4])
    CSV::Table.new([row1, row2, row3, row4, row5, row6, row7, row8, row9, row10, row11, row12, row1, row2, row3, row4, row5, row6, row7, row8, row9, row10, row11, row12], headers: %w(id Gender Ethnicity Grade))
  end

  def inst(table)
   MBPSOTeamFormation::Particle.new(table.length, table.length/4, [0.8, 0.6, 0.8], [0.8, 0.6, 0.8], 0.8, table, 2, 2, 4, {0 => [-5]})
 end

  def inst2(table)
    MBPSOTeamFormation::Particle.new(table.length, table.length/4, [0.8, 0.6, 0.8], [0.8, 0.6, 0.8], 0.8, table, 2, 2, 4, {0 => [-5]})
  end

  describe 'Initialising Particle' do
    it 'Initial Position generated' do
      p = inst(table1)
      expect(p.position.class).to eq(Array)
    end

    it 'Every student is assigned to excatly one team after initial position generation' do
      p1 = inst(table1).position
      p2 = inst(table2).position
      flag = false
      p1.each do |x|
        flag = true if x.sum != 1
      end
      p2.each do |x|
        flag = true if x.sum != 1
      end
      expect(flag).to eq(false)
    end

    it 'Every team is composed of exactly 4 students after initial position generation' do
      p1 = inst(table1).position
      p2 = inst(table2).position
      flag = false
      (0..p1[0].length - 1).each do |y|
        sum1 = 0
        sum2 = 0
        (0..p1.length - 1).each do |x|
          sum1 += p1[x][y]
          sum2 += p2[x][y]
        end
        flag = true if sum1 != 4 || sum2 != 4
      end
      expect(flag).to eq(false)
    end
  end

  describe "Calculating particle parameters" do
    it "Accurately calculating position" do
      p1 = inst(inst_small_table)
      s1 = [1, 0, 0]
      s2 = [1, 0, 0]
      s3 = [1, 0, 0]
      s4 = [1, 0, 0]
      s5 = [0, 1, 0]
      s6 = [0, 1, 0]
      s7 = [0, 1, 0]
      s8 = [0, 1, 0]
      s9 = [0, 0, 1]
      s10 = [0, 0, 1]
      s11 = [0, 0, 1]
      s12 = [0, 0, 1]
      p1.position = [s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12]
      p1.calculate_fitness
      expect(p1.fitness.round(2)).to eq(55.91)

      p2 = inst(inst_mid_table)
      s1 = [1, 0, 0, 0, 0, 0]
      s2 = [0, 1, 0, 0, 0, 0]
      s3 = [0, 0, 1, 0, 0, 0]
      s4 = [0, 0, 0, 1, 0, 0]
      s5 = [0, 0, 0, 0, 1, 0]
      s6 = [0, 0, 0, 0, 0, 1]
      p2.position = [s1, s2, s3, s4, s5, s6, s1, s2, s3, s4, s5, s6,s1, s2, s3, s4, s5, s6, s1, s2, s3, s4, s5, s6]
      p2.calculate_fitness
      expect(p2.fitness.round(2)).to eq(-776.62)
    end

    it " Accurately updating personal best fitness and position" do
      p1 = inst(inst_small_table)
      zero_position = Array.new(12){Array.new(4,0)}
      p1.position = zero_position
      p1.calculate_fitness
      s1 = [1, 0, 0]
      s2 = [1, 0, 0]
      s3 = [1, 0, 0]
      s4 = [1, 0, 0]
      s5 = [0, 1, 0]
      s6 = [0, 1, 0]
      s7 = [0, 1, 0]
      s8 = [0, 1, 0]
      s9 = [0, 0, 1]
      s10 = [0, 0, 1]
      s11 = [0, 0, 1]
      s12 = [0, 0, 1]
      p1.position = [s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12]
      p1.calculate_fitness
      expect(p1.p_best_position).to eq(p1.position)
      expect(p1.fitness.round(2)).to eq(55.91)

      zero_position = Array.new(120){Array.new(30,0)}
      p2 = inst(table1)
      p2.position = zero_position
      p2.calculate_fitness
      expect(p2.p_best_fitness).to eq(p2.fitness)
      expect(p2.p_best_position).to eq(p2.position)
    end

    it "Maintaining valid position for a number of iterations" do
      def generate_random_position(length)
        pos = Array.new(length){Array.new(length/4, 0)}
        array = 0.upto(length - 1).to_a
        array = array.shuffle
        (0..length - 1).each do |x|
          student = array[x]
          pos[student][x % length/4] = 1
        end
        pos
      end
      p1 = inst(table1)
      p2 = inst(table2)
      length = table1.length
      (0..50).each do |x|
        p1.calculate_fitness
        p2.calculate_fitness
        p1.update_velocity(generate_random_position(length))
        p2.update_velocity(generate_random_position(length))
        p1.update_position
        p2.update_position

        (0..length/4 - 1).each do |y|
          sum1 = 0
          sum2 = 0
          (0..length - 1).each do |x|
            expect(p1.position[x].sum).to eq(1)
            expect(p2.position[x].sum).to eq(1)

            sum1 += p1.position[x][y]
            sum2 += p2.position[x][y]
          end
          expect(sum1).to eq(4)
          expect(sum2).to eq(4)
        end
      end
    end
  end
end
