require_relative 'spec_helper'
require '../lib/MBPSO_Team_Formation/neighbourhood'
require '../lib/MBPSO_Team_Formation/particle'
require 'csv'

RSpec.describe MBPSOTeamFormation::Neighbourhood do
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

  def instantiate_neighbourhood(table, num)
    MBPSOTeamFormation::Neighbourhood.new(12, 3, [0.8, 0.6, 0.8], [0.8, 0.6, 0.8], 0.8, table, 2, 2,num, {0 => [-5]}, 4)
  end

  def instantiate_particle(table)
    MBPSOTeamFormation::Particle.new(table.length, table.length/4, [0.8, 0.6, 0.8], [0.8, 0.6, 0.8], 0.8, table, 2, 2, 4, {0 => [-5]})
  end

  describe "Initialisation" do
    it "Succesfully initialising and generating particles list of the correct size" do
      n1 = instantiate_neighbourhood(inst_small_table, 3)
      n2 = instantiate_neighbourhood(inst_small_table,4)
      n3 = instantiate_neighbourhood(inst_small_table,5)
      expect(n1.particles_list.size).to eq(3)
      expect(n2.particles_list.size).to eq(4)
      expect(n3.particles_list.size).to eq(5)
    end

    it "All particles in the list are successfully created" do
      n1 = instantiate_neighbourhood(inst_small_table, 3)
      n2 = instantiate_neighbourhood(inst_small_table,4)
      n3 = instantiate_neighbourhood(inst_small_table,5)

      n1.particles_list.each do |x|
        expect(x.position[0].sum).to eq(1)
      end

      n2.particles_list.each do |x|
        expect(x.position[0].sum).to eq(1)
      end

      n3.particles_list.each do |x|
        expect(x.position[0].sum).to eq(1)
      end
    end

    describe "Particles list manipulation" do
      it "Successfully adding particles to the neighbourhood" do
        n2 = instantiate_neighbourhood(inst_small_table,4)
        n2.add_particle(instantiate_particle(inst_small_table))
        expect(n2.particles_list.size).to eq(5)
        n2.add_particle(instantiate_particle(inst_small_table))
        expect(n2.particles_list.size).to eq(6)
        n2.add_particle(instantiate_particle(inst_small_table))
        expect(n2.particles_list.size).to eq(7)
      end

      it "Successfully maintaining particles list size when removing particles" do
        n2 = instantiate_neighbourhood(inst_small_table,6)
        n2.remove_particle
        expect(n2.particles_list.size).to eq(5)

        n2.remove_particle
        expect(n2.particles_list.size).to eq(4)

        n2.remove_particle
        expect(n2.particles_list.size).to eq(3)
      end

      it "Returning particle only if thera are present particles in the list before removing" do
        n2 = instantiate_neighbourhood(inst_small_table,2)
        expect(n2.remove_particle.class).to eq(MBPSOTeamFormation::Particle)
        expect(n2.remove_particle.class).to eq(MBPSOTeamFormation::Particle)
        expect(n2.remove_particle.class).to eq(NilClass)
      end

      it "Returning nil only if trying to remove particle from empty list" do
        n2 = instantiate_neighbourhood(inst_small_table,2)
        expect(n2.remove_particle.class).to eq(MBPSOTeamFormation::Particle)
        expect(n2.remove_particle.class).to eq(MBPSOTeamFormation::Particle)
        expect(n2.remove_particle.class).to eq(NilClass)
      end
    end

    describe "Value update" do
      it "Accurately updating inertia" do
        n2 = instantiate_neighbourhood(inst_small_table,5)
        n2.update_inertia(0.6)
        n2.particles_list.each do |x|
          expect(x.inertia).to eq(0.6)
        end

        n2.update_inertia(0.2)
        n2.particles_list.each do |x|
          expect(x.inertia).to eq(0.2)
        end
      end

      it "Successfully iterate particles and accurately update local best fitness" do
        n2 = instantiate_neighbourhood(inst_small_table,1)
        n2.iterate_particles
        expect(n2.l_best_fitness).to eq(n2.particles_list[0].fitness)
        expect(n2.l_best_position).to eq(n2.particles_list[0].position)

        p = instantiate_particle(inst_small_table)
        invalid_position = Array.new(12){Array.new(3, 1)}
        p.position = invalid_position
        n2.add_particle(p)
        n2.iterate_particles

        best_pos = nil
        best_fitness = 0
        if n2.particles_list[0].fitness > n2.particles_list[1].fitness
          best_pos = n2.particles_list[0].position
          best_fitness = n2.particles_list[0].fitness
        else
          best_pos = n2.particles_list[1].position
          best_fitness = n2.particles_list[1].fitness
        end

        expect(n2.l_best_fitness).to eq(best_fitness)
        expect(n2.l_best_position).to eq(best_pos)
      end
    end
  end
end
