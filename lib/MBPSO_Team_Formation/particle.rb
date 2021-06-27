module MBPSOTeamFormation
  class Particle
    attr_reader :p_best_fitness, :p_best_position, :stats, :fitness
    attr_accessor :position, :inertia, :survival_number

    def initialize(length, teams, \
                   control_param_personal, control_param_local, inertia, \
                   table, ethnicity_weight, gender_weight, \
                   survival_number, forbidden_pairs)
      @table = table

      @length = length
      @teams = teams

      @position = Array.new(length) { Array.new(teams, 0) }
      @velocity = Array.new(length) { Array.new(teams, 0) }
      @new_velocity = Array.new(length) { Array.new(teams, 0) }

      initial_particle_assignment

      @inertia = inertia
      @control_param_personal = control_param_personal
      @control_param_local = control_param_local
      @ethnicity_weight = ethnicity_weight
      @gender_weight = gender_weight

      @fitness = 0
      @p_best_fitness = -900_000
      @p_best_position = Array.new(length) { Array.new(teams, 0) }
      # Array holding the particle fitness along
      # the run of the algorithm, used for testing purposes
      @stats = []

      # Number of final swapping suggestions
      # to be considered when updating position
      @survival_number = survival_number

      # Probability threshold above which only @survival_number of values are left
      @threshold = 0
      @forbidden_pairs = forbidden_pairs
    end

    # Generating the initial position of the particle
    # by assigning each to student to a random team
    def initial_particle_assignment
      array = 0.upto(@length - 1).to_a
      array = array.shuffle
      (0..@length - 1).each do |x|
        student = array[x]
        @position[student][x % @teams] = 1
      end
    end

    # Calculate the fitness of the solution the particle represents
    def calculate_fitness
      total_fitness = 0

      # Arrays to hold the attribute values for each team
      gender = []
      ethnicity = []
      grade = []
      id = []

      (0..@teams - 1).each do |y| # Iterating through all teams
        (0..@length - 1).each do |x| # Iterating through all students
          next unless @position[x][y] == 1

          # Only checking for forbidden team formations
          # if there are any forbidden pairs at all
          unless @forbidden_pairs.nil?
            temp = [] # List with students that are forbidden to join the team

            # Checking if the particular student is already in
            # the list of forbidden students for the particular team

            if temp.include? @table[x]['id'] # If this student cannot be assigned to this team
              initial_particle_assignment # Change the current postion with a random one
              calculate_fitness #and calculate its new fitness
              return false # terminate the method
            end

            # Adding all forbidden mates of the student to the list with forbidden teammates
            if @forbidden_pairs.key?(@table[x]['id'])
              temp.append(@forbidden_pairs[@table[x]['id']])
            end
          end

          # Extract attributes of students in the team
          # into the temporary arrays so the distances can be computed
          gender.push(@table[x]['Gender'])
          ethnicity.push(@table[x]['Ethnicity'])
          grade.push(@table[x]['Grade'].to_i)
        end

        # Calculate the distances between students
        (0..grade.length - 2).each do |i|
          (i + 1..grade.length - 1).each do |index|
            dist = 0 # sum of distances
            # As this is non-numeric attribute represented however
            # by a numeric value, we're interested only if
            # they are different, not by how much as it is irrelevant
            dist += @gender_weight unless gender[i] == gender[index]
            dist += @ethnicity_weight unless ethnicity[i] == ethnicity[index]
            dist += (grade[i] - grade[index])**2

            # Adding the distances between students for
            # the current team to the total fitness
            dist.positive? ? total_fitness += Math.sqrt(dist) : total_fitness -= Math.sqrt(dist.abs)
          end
        end
        case grade.uniq.length
        when 1
          total_fitness -= 80
        when 2
          total_fitness -= 150
        when 1
          total_fitness -= 300
        end

        gender.clear
        ethnicity.clear
        grade.clear
      end

      @fitness = total_fitness
      # Check if the current fitness is better than the personal best one
      update_p_best
    end

    # Comparing current and local best fitness and updating accordingly
    def update_p_best
      return unless @fitness > p_best_fitness

      @p_best_fitness = @fitness
      @p_best_position = @position
    end

    # Generating the random components for updating velocities
    # The passing of parameter makes the method reusable for both
    # personal and local random factors
    #
    # @param [Array] param Control parameter according to
    # which the random component will be generated
    # @return [Array] The resulting random component
    def generate_random_vector(param)
      random_vector = Array.new(@length) { Array.new(@teams) { rand } } # Generate matrix of random values
      random_vector.each do |x|
        x.each do |y|
          # If the value is higher than the
          # threshold, put the specified probability there
          y = y > param[0] ? param[1] : 0
        end
      end
      random_vector
    end

    # Generate swapping suggestions for velocity updates by applying
    # logical XOR operator to the corresponding positions in
    # the current position and personal/local best position matrices
    # @param [Array] minuend The position to be compared with
    # the current position - personal or local best
    # @param [float] param Parameter according to which probabilities
    # will be updates on the places where swapping suggestions are found
    # @return [Array] The resulting probability matrix
    def subtract_position(minuend, param)
      result = Array.new(@length) { Array.new(@teams, 0) }

      # Iterate through the matrices and update the result matrix
      # according to the XOR operation output and specified parameter
      (0..@length - 1).each do |x|
        (0..@teams - 1).each do |y|
          result[x][y] = (@position[x][y] != minuend[x][y]) ? param : 0
        end
      end
      result
    end

    # Calculating the positional sums of the passed probability matrices
    # @param [Array] args Array of the probability matrices that are to be summed
    # @return [Array] Resulting probability matrix
    def sum_probability_matrices(*args)
      result = Array.new(@length) { Array.new(@teams, 0) }
      (0..@length - 1).each do |x|
        (0..@teams - 1).each do |y|
          (0..args.size - 1).each do |z|
            result[x][y] += args[z][x][y]
          end
        end
      end
      result
    end

    # Calculate and update particle's velocity
    #
    # @param [Array] l_best_position The neighbourhood's local best position.
    # It is passed to the method when called by the neighbourhood object
    # to avoid storing it for each particle, as well to conserve
    # the one way relationship between particle and neighbourhood
    # @return [Array] The resulting velocity
    def update_velocity(l_best_position)
      # Generating the second and third parameters in the velocity update equation
      term2 = sum_probability_matrices(generate_random_vector(@control_param_personal), subtract_position(@p_best_position, @control_param_personal[2]))
      term3 = sum_probability_matrices(generate_random_vector(@control_param_local), subtract_position(l_best_position, @control_param_local[2]))
      new_velocity = Array.new(@length) { Array.new(@teams, 0) }

      # Summing the current velocity with the weighted parameters
      (0..@length - 1).each do |x|
        (0..@teams - 1).each do |y|
          new_velocity[x][y] += (@velocity[x][y] * @inertia)
          new_velocity[x][y] += term2[x][y]
          new_velocity[x][y] += term3[x][y]
        end
      end

      # Normalising the velocity as a fraction
      # of the maximum value present in the matrix
      max_probability = new_velocity.flatten.max
      (0..@length - 1).each do |x|
        (0..@teams - 1).each do |y|
          new_velocity[x][y] = new_velocity[x][y] / max_probability
        end
      end

      @velocity = new_velocity
    end

    # Updating particle's position
    def update_position
      # Array holding the free slots in each team
      free_slots = Array.new(@teams, (@length / @teams).to_i)
      unassigned_students = []
      new_position = Array.new(@length) { Array.new(@teams, 0) }
      randomised_current_position = Array.new(@length) { Array.new(@teams, 0) }

      # Sum up current position and velocity
      @velocity = sum_probability_matrices(randomised_current_position, @velocity)

      # Calculate the survivability threshold
      @threshold = @velocity.flatten.max(@survival_number.to_i + 1).last

      (0..@length - 1).each do |x|
        # First assign students where velocity doesnt
        # suggest changes  to avoid extra swaps
        if @velocity[x].flatten.max < @threshold
          (0..@teams - 1).each do |y|
            new_position[x][y] = @position[x][y]
            free_slots[y] -= 1 if new_position[x][y] == 1
          end
        else
          unassigned_students.push(x)
        end
      end

      probabilities_indices = Array.new { Array.new }
      unassigned_students2 = []
      unassigned_students.each do |x|
        # List of indexes in order that when referenced relates to a sorted list
        probabilities_indices[x] = @velocity[x].map.with_index.sort.map(&:last)
        if free_slots[probabilities_indices[x][0]].positive?
          new_position[x][probabilities_indices[x][0]] = 1
          free_slots[probabilities_indices[x][0]] -= 1
        else
          unassigned_students2.push(x)
        end
      end
      # Implemented like that because in order to generate the indexes
      # the whole table has to be iterated once anyway
      # and then continue, therefore some needed actions are squeezed in

      index = 1 # Representing the index of the sorted probabilities
      temp = unassigned_students2
      while free_slots.sum.positive? && index < @teams
        unassigned_students2 = temp.dup
        temp.clear
        if index > 4
          until unassigned_students2[0].nil?
            (0..@teams - 1).each do |x|
              next unless free_slots[x].positive?

              new_position[unassigned_students2[0]][x] = 1
              free_slots[x] -= 1
              unassigned_students2.shift
            end
          end
        end
        unassigned_students2.each do |x|
          if free_slots[probabilities_indices[x][index]].positive?
            new_position[x][probabilities_indices[x][index]] = 1
            free_slots[probabilities_indices[x][index]] -= 1
          else
            temp.push(x)
          end
        end
        index += 1
      end
      @position = new_position
    end

    # Neatly printing a matrix
    # @param [Array] array Matrix to be printed
    def print(array)
      arr = array.transpose
      width = arr.flatten.max.to_s.size + 2
      #=> 4
      puts(arr.map { |a| a.map { |i| i.round(3).to_s.rjust(width) }.join })
    end

    # Adding current fitness to the list of stats
    def update_stats
      @stats.push(@fitness)
    end

    private :initial_particle_assignment, :update_p_best, \
            :generate_random_vector, :subtract_position, :sum_probability_matrices

  end
end