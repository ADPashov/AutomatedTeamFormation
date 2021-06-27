require_relative 'particle'
module MBPSOTeamFormation
  class Neighbourhood

    attr_reader :l_best_position, :l_best_fitness, :terminate, :ret_value, :particles_list
    attr_accessor :counter

    def initialize(length, teams, control_param_personal, control_param_local, \
                   inertia, table, ethnicity_weight, gender_weight, \
                   init_num_particles, forbidden_pairs, survival_number)
      @particles_list = []

      @l_best_fitness = -90_000
      @l_best_position = Array.new(length) { Array.new(teams, 0) }

      @length = length
      @teams = teams
      @init_num_particles = init_num_particles
      @table = table

      # Initialising particles
      initialise_particles(control_param_personal, control_param_local, inertia, \
table, ethnicity_weight, gender_weight, survival_number, forbidden_pairs)

      # Number of iterations without local best update
      @counter = 0
    end

    # Initialising the needed number of particles by adding
    # to the list of particles for the current neighbourhood object
    def initialise_particles(cpp, cpl, init_in, table, ew, gw, sn, fp)
      (0..@init_num_particles - 1).each do |_x|
        @particles_list.push(Particle\
                             .new(@length, @teams, cpp, cpl, init_in, \
                                  table, ew, gw, sn, fp))
      end
    end

    # Add particles to the neighbourhood
    def add_particle(particle)
      @particles_list.push(particle)
    end

    # Remove particles from the neighbourhood
    #
    # @return [Particle, nil] Return the particle if successfully removed\
    # or nil if the list of particles is empty
    def remove_particle
      @particles_list.pop
    end

    # Update the local best position and fitness if any of the particles
    # has fitness higher than the current local best
    def update_l_best
      # Indicator of whether the fitness has been updated at the current iteration
      @flag = false

      (0..@particles_list.length - 1).each do |x|
        next unless @particles_list[x].p_best_fitness > @l_best_fitness

        @l_best_fitness = @particles_list[x].p_best_fitness
        @l_best_position = @particles_list[x].p_best_position
        @flag = true
      end

      # Checking if local best has been updated to maintain
      # the counter of iterations with no improvement
      if @flag
        @counter = 0
      else
        @counter += 1
      end
    end

    def iterate_particles
      @particles_list.each do |x|
        x.update_velocity(@l_best_position)
        x.update_position
        x.calculate_fitness
        x.update_stats
      end
      update_l_best
      # puts "Global best: #{@l_best_fitness}"
    end

    #
    def update_inertia(inertia)
      @particles_list.each do |x|
        x.inertia = inertia
      end
    end

    def update_sn(survival_number)
      @particles_list.each do |x|
        x.survival_number = survival_number
      end
    end


    def report_particles
      array = Array.new(@particles_list.length)
      (0..@particles_list.length - 1).each do |x|
        array[x] = @particles_list[x].stats
      end
      array
    end

    # Prints the attributes of the resulted alocation
    def print_best
      gender = []
      ethnicity = []
      grade = []

      (0..@teams - 1).each do |y|
        (0..@length - 1).each do |x|
          next unless @l_best_position[x][y] == 1

          gender.push(@table[x]['Gender'])
          ethnicity.push(@table[x]['Ethnicity'])
          grade.push(@table[x]['Grade'].to_i)
        end
        puts " Team#{y}'s attributes arrays:\nGender: #{gender} \nEthnicity: #{ethnicity} \nGrade:#{grade}"
        gender.clear
        ethnicity.clear
        grade.clear
      end
    end


    private :update_l_best
  end
end