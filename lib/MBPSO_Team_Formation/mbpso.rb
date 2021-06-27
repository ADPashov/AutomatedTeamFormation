# frozen_string_literal: true

require_relative 'neighbourhood'
require_relative 'validation'
require_relative 'mvh'
require 'fileutils'

module MBPSOTeamFormation
  # Containing the needed functionality for validating the input data, instantiating all needed objects and running tha algorithm
  class MBPSO

    def initialize(table, team_size: 4, max_iterations: 10000, num_particles: 20, \
                   gender_weight: 9, ethnicity_weight: 9, initial_inertia: 0.9, final_inertia: 0.2, \
                   control_param_personal: [0.2, 0.4, 0.4], control_param_local: [0.6, 0.2, 0.9], \
                   survival_number: nil, final_survival_number: 5, \
                   skill_table: {0..39 => 1, 40..49 => 2, 50..59 => 3, 60..69 => 4, 70..79 => 5, 80..100 => 6}, \
                   forbidden_pairs: nil, tolerate_missing_values: true, init_num_particles: 3, \
                   output_stats: false, output_stats_name: 'stats.csv', neigh_change_interval: 100, inertia_change_interval: 10, \
                   sn_change_interval: 10, particles_to_move: 2, inertia_changes: 300, sn_changes: 300, convergence_iterations: 300)

      validation = Validation.new
      mvh = MVH.new

      @table = validation.validate_dataset(table).dup
      @length = table.length # Extracting number of students

      @teams_size = validation\
               .validate_number(team_size, 'teams', 'pos_int')
      # Validating inputs
      @teams = (@length / @teams_size).to_i
      @max_iterations = validation\
                        .validate_number(max_iterations, 'max_iterations', 'pos_int')
      @num_particles = validation\
                       .validate_number(num_particles, 'num_particles', 'pos_int')
      @neigh_change_interval = validation\
                               .validate_number(neigh_change_interval, 'neigh_change_interval', 'pos_int')
      @init_num_particles = validation\
                            .validate_number(init_num_particles, 'init_num_particles', 'pos_int')
      @inertia_change_interval = validation\
                                 .validate_number(inertia_change_interval, 'inertia_change_interval', 'pos_int')
      @sn_change_interval = validation\
                            .validate_number(sn_change_interval, 'sn_change_interval', 'pos_int')
      @particles_to_move = validation\
                           .validate_number(particles_to_move, 'particles_to_move', 'pos_int')
      @final_survival_number = validation\
                               .validate_number(final_survival_number, 'final_survival_number', 'pos_int')
      @inertia_changes = validation\
                         .validate_number(inertia_changes, 'inertia_changes', 'pos_int')
      @sn_changes = validation\
                    .validate_number(sn_changes, 'sn_changes', 'pos_int')
      @convergence_iterations = validation\
                                .validate_number(convergence_iterations, 'convergence_iterations', 'pos_int')
      @gender_weight = validation\
                       .validate_number(gender_weight, 'gender_weight', 'nn_num')
      @ethnicity_weight = validation\
                          .validate_number(ethnicity_weight, 'ethnicity_weight', 'nn_num')
      @initial_inertia = validation\
                         .validate_number(initial_inertia, 'initial_inertia', 'nn_num')
      @final_inertia = validation\
                       .validate_number(final_inertia, 'final_inertia', 'nn_num')
      @control_param_personal = validation\
                                .validate_control_parameters(control_param_personal, 'personal')
      @control_param_local = validation\
                             .validate_control_parameters(control_param_local, 'local')
      if survival_number.nil?
        @survival_number = @length.to_f
      else
        @survival_number = validation\
                           .validate_survival_number(survival_number, @length).to_f
      end
      unless forbidden_pairs.nil?
        @forbidden_pairs = validation\
                           .validate_forbidden_pairs(forbidden_pairs).dup
      end

      @output_stats_name = output_stats_name.to_s
      @skill_table = validation\
                     .validate_skill_table(skill_table)
      @output_stats = validation\
                      .validate_bool(output_stats, 'output_stats')
      medians = mvh\
                .fill_missing_values(table, \
                                     validation.validate_bool(tolerate_missing_values, 'tolerate_missing_values'))

      # Variable that will hold the extra students, in case the class size
      # is not a multiple of the team size
      @separated = nil
      separate_students(medians)
      map_grades

      unless forbidden_pairs.nil?
        @forbidden_pairs = {}
        hash_forbidden_pairs(validation\
                             .validate_forbidden_pairs(forbidden_pairs))
      end


      # Calculating neighbourhood count and creating neighbours
      @num_neighbourhoods = (@num_particles / @init_num_particles).to_i
      # Adding additional neighbourhood when particles cannot be separated
      # into neighbourhoods of equal size
      if (@num_particles % @init_num_particles).positive?
        @num_neighbourhoods += 1
      end
      @neighbourhoods_list = Array.new(@num_neighbourhoods)
      initialise_neighbourhoods

      # Calculating by how much inertia and survival number
      # will be changed at each of their updates
      @inertia_step = ((@initial_inertia - @final_inertia) / @inertia_changes).abs
      @sn_step = ((@survival_number - @final_survival_number) / @sn_changes).abs

      # For move_particles method, so we dont always start adding
      # to the first neighbourhood, in case of unequal size neighbourhoods
      @iter = 0

      # Variables needed for outputting the values during tests
      @average_global_bests = []
      @global_bests = []

      # Current iteration indicator
      @iteration = 0
    end

    # Separating the needed number of students(between 1 and 3), which will be
    # added to teams at the last stage, by looking for students matching the
    # median values of each attributes
    def separate_students(medians)

      most_frequent_gender = medians[0]
      most_frequent_ethnicity = medians[1]
      mean = medians[2]
      stdev = medians[3]
      # Checking if the step is needed, terminating otherwise,
      # also holding the number of students that need to be separated
      remainder = @length % @teams_size
      return true if remainder.zero?

      @separated = CSV::Table.new([], headers: %w[id Gender Ethnicity Grade])
      # Searching for students with attributes matching the most frequent
      # non numeric values and mean +- the standard deviation grades
      (0..@length - 1).each do |x|
        # Safety preacution because of the @length update after
        # the number of iterations is calculated
        break if x == @length
        next unless @table[x]['Gender'] == most_frequent_gender

        next unless @table[x]['Ethnicity'] == most_frequent_ethnicity

        next unless (@table[x]['Grade'].to_f < mean + stdev) || (x['Grade'].to_f > mean - stdev)

        @separated << @table.delete(x)

        remainder -= 1
        @length -= 1
        # iterating until no more students are needed to be separated
        return true if remainder.zero?
      end

      # If not enough students are found
      # looks for students only having average grade
      (0..@length-1).each do |x|
        break if x == @length
        next unless (@table[x]['Grade'].to_f < mean + stdev) || (x['Grade'].to_f > mean - stdev)
        @separated << @table.delete(x)
        remainder -= 1
        @length -= 1
        return true if remainder.zero?
      end

      # If it fails again. randomly separates students
      (0..@length - 1).each do |x|
        break if x == @length
        y = rand(@table.length - 1)


        @separated << @table.delete(y)
        remainder -= 1
        @length -= 1
        return true if remainder.zero?
      end

    end

    # Replacing the grade entries in the data set variable with skill values
    # according to the skill mapping Hash
    def map_grades
      (0..@length - 1).each do |x|
        @table[x]['Grade'] = @skill_table\
                             .find { |r, _v| r.cover?(@table[x]['Grade'].to_i) }[1]
      end
    end

    # Reworking the forbidden pairs list, by making it a Hash where for every
    # students participating in at least one pair, there will be a key with
    # its ID and a corresponding list of IDs of students which this student
    # cannot be teamed up with
    def hash_forbidden_pairs(list)
      # Adding the reversed pairs of students to the list
      (0..list.length - 1).each do |x|
        list.push([list[x][1], list[x][0]])
      end

      # Making all unique first elements of the pairs in the list keys of the Hash
      keys = list.map(&:first).uniq
      # Adding the corresponding values, specified by the second elements in the pairs
      @forbidden_pairs = keys.map do |k|
        {k => list.select { |a| a[0] == k }.compact.map(&:last)}
      end
      @forbidden_pairs = @forbidden_pairs.reduce({}, :merge)
      # Removing unique values for each key
      @forbidden_pairs.keys.each do |x|
        @forbidden_pairs[x] = @forbidden_pairs[x].uniq
      end
    end

    # Initialising the needed number of initial neighbourhoods according to
    # the user-specified/default parameters
    def initialise_neighbourhoods

      # With the implementation below, there is
      # a danger of division by 0 exception
      # if a single neighbourhood needs to be formed
      if @num_neighbourhoods == 1
        @neighbourhoods_list[0] = Neighbourhood\
                                  .new(@length, @teams, @control_param_personal, @control_param_local, \
                                       @initial_inertia, @table, @ethnicity_weight, @gender_weight, \
                                       @init_num_particles, @forbidden_pairs, @survival_number)
      return true
      end

      # Initialising all full capacity neighbourhoods
      (0..@num_neighbourhoods - 2).each do |x|
        @neighbourhoods_list[x] = Neighbourhood\
                                  .new(@length, @teams, @control_param_personal, @control_param_local, \
                                       @initial_inertia, @table, @ethnicity_weight, @gender_weight, \
                                       @init_num_particles, @forbidden_pairs, @survival_number)

      end

      # Initialising the last neighbourhood which will hold a number
      # of particles equal to the remained of the division of
      # the particles number by the initial number of
      # particles in each neighbourhood
      @neighbourhoods_list[@num_neighbourhoods - 1] = Neighbourhood\
                                                      .new(@length, @teams, \
                                                           @control_param_personal, @control_param_local, @initial_inertia, @table, \
                                                           @ethnicity_weight, @gender_weight, (@num_particles % (@num_neighbourhoods - 1)), \
                                                           @forbidden_pairs, @survival_number)
    end

    # Moving the particles from the last neighbourhood
    # towards the other neighbourhoods
    def move_particles
      moved_particles = 0
      num_to_move = 2 #@neighbourhoods_list.last.particles_list.size
      @neighbourhoods_list[0].counter = 0

      while moved_particles != num_to_move && @neighbourhoods_list.length > 1
        temp = @neighbourhoods_list.last.remove_particle

        # Checking if a particle was removed, or the neighbourhood is empty
        if temp.nil?
          @neighbourhoods_list.pop
        else
          @neighbourhoods_list[@iter].add_particle(temp)

          # increase the counter indicating to which neighbourhood
          # the next particle will be added, so they're
          # added to different neighbourhoods on a roulette principle
          @iter += 1
          moved_particles += 1
        end

        # Start over if a particle was added to each neighbourhood
        @iter = 0 if @iter == @neighbourhoods_list.length - 1
      end
    end

    # Update inertia and topology, at the needed iterations
    def update_characteristics
      # Invoking method for topology update if needed
      if (@iteration % @neigh_change_interval).zero? && @neighbourhoods_list.length > 1
        move_particles
      end

      if (@iteration % @sn_change_interval).zero? && (@survival_number > @final_survival_number)
        @survival_number -= @sn_step
        @neighbourhoods_list.each do |x|
          x.update_sn(@survival_number.to_i)
        end
        @neighbourhoods_list[0].counter = 0
      end

      # Checking if inertia should be updated
      return unless (@iteration % @inertia_change_interval).zero? && (@initial_inertia - @inertia_step) > @final_inertia

      # Resetting converge check counter
      @neighbourhoods_list[0].counter = 0

      # Calculating new inertia with the precaution of not going past the final value

      @initial_inertia -= @inertia_step
      # Asking each neighbourhoods to update the inertia weights
      # of all the particles that belong to it
      @neighbourhoods_list.each do |x|
        x.update_inertia(@initial_inertia)
      end

    end

    # Writing the statistics about the algorithm run to an
    # external .csv file
    def export_data
      folder = "\data"
      FileUtils.mkdir_p folder
      CSV.open(File.join(folder, @output_stats_name), 'wb') do |csv|
        csv << @global_bests
        csv << @average_global_bests
        @neighbourhoods_list[0].report_particles.each do |x|
          csv << x
        end
      end
    end

    # Assigning the separated at the beginning students to random teams
    # If there were any separated students
    def assign_separated(result)
      prev_rand = 0
      (0..@separated.length-1).each do |x|
        curr_rand = rand(@teams)

        # Making sure that no more than one of the separated students
        # is added to a given team, regardless of the probability of that happening
        curr_rand = rand(@teams) while curr_rand == prev_rand
        result[curr_rand].append(@separated[x]['id'])
        prev_rand = curr_rand
      end
    end

    # Formatiing and returning the output
    #
    # @return [Array] Team allocation in the form of list of lists
    # containing the IDs of the students allocated to each team
    def return_teams
      result = Array.new(@teams) { [] }
      allocation = @neighbourhoods_list[0].l_best_position
      (0..@length - 1).each do |x|
        (0..@teams - 1).each do |y|
          result[y].append(@table[x]['id']) if allocation[x][y] == 1
        end
      end
      # If there are any separated students
      # Assign them to teams
      assign_separated(result) unless @separated.nil?
      result
    end

    # Starting the algorithm
    def run
      while @max_iterations > @iteration
        # Array that will contain the local bests for the current iteration
        temp = []

        # Get every neighbourhood to iterate all its particles
        @neighbourhoods_list.each do |x|
          x.iterate_particles
          temp.push(x.l_best_fitness)
        end

        # Add the global bests and the average local best fitness
        # to the values storing them
        @global_bests << temp.max
        @average_global_bests << (temp.sum / temp.length)
        @iteration += 1

        # Check if the first neighbourhood is signalling for
        # a long period with no improvements in the local best fitness
        if @neighbourhoods_list[0].counter > @convergence_iterations
          @iteration = @max_iterations
        end

        # Invoke the method that will check if the control
        # parameters need to be updated and will act accordingly
        update_characteristics
      end

      # Check if exporting the run statistics are desired by the user
      # and export if needed
      export_data if @output_stats

      # Printing the attributes of the best allcoation
      @neighbourhoods_list[0].print_best

      # Return the proposed allocation
      return_teams
    end

    private :separate_students, :map_grades, :hash_forbidden_pairs, :initialise_neighbourhoods, :move_particles
  end
end
