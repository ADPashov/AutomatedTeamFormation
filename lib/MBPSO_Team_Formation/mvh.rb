# frozen_string_literal: true
module MBPSOTeamFormation
  # Missing Values Handler
  class MVH


    # Checking for missing values in the data set
    def check_missing_values(table)
      temp = Array.new(3) { [] } # Array that will hold the results, each array
      # inside it holds the indexes for a particular attribute

      # Checking Genders
      (0..table['Gender'].length - 1).each do |x|
        temp[0].append(x) if table['Gender'][x].nil?
      end

      # Checking ethnicities
      (0..table['Ethnicity'].length - 1).each do |x|
        temp[1].append(x) if table['Ethnicity'][x].nil?
      end

      # Checking grades
      (0..table['Grade'].length - 1).each do |x|
        temp[2].append(x) if table['Grade'][x].nil?
      end

      # Checking results
      if !temp[0].empty? || !temp[1].empty? || !temp[2].empty?
        temp
      else
        false
      end
    end

    # Calculating the mean and standard deviation of data,
    # to be used when replacing missing grades
    def calculate_stdev(data)
      data = data.compact.map(&:to_i)
      mean = data.sum.to_f / data.size
      sum = 0

      data.each { |v| sum += (v - mean) ** 2 }
      stdev = Math.sqrt(sum / data.size)

      [mean, stdev]
    end

    # Replacing missing values by the most frequent values for non-numeric
    # attributes and keeping original distribution when it comes to grades
    def fill_missing_values(table, tolerate_missing_values)
      # Running only in case of missing values
      missing_values = check_missing_values(table)

      most_frequent_gender, most_frequent_ethnicity, mean_grade, stdev = nil

      mean_grade, stdev = calculate_stdev(table['Grade'])

      frequencies = table['Gender']\
                    .each_with_object(Hash.new(0)) { |v, h| h[v] += 1; }
      most_frequent_gender = table['Gender'].max_by { |v| frequencies[v] }

      frequencies = table['Ethnicity']\
                    .each_with_object(Hash.new(0)) { |v, h| h[v] += 1; }
      most_frequent_ethnicity = table['Ethnicity'].max_by { |v| frequencies[v] }

      return [most_frequent_gender, most_frequent_ethnicity, mean_grade, stdev, true] unless missing_values

      # Notifying the user for the missing values and proceeding
      # according to the tolerance parameter
      unless tolerate_missing_values
        raise ArgumentError, 'Missing values are present in the data set'
      end

      warn('WARNING! There are missing values in the data set,'\
           ' which will be automatically handled.')

      # Replacing missing gender values with the most frequent gender in the data set
      unless missing_values[0].empty?
        missing_values[0].each do |x|
          table[x]['Gender'] = most_frequent_gender
        end
      end

      # Replacing missing ethnicity values with the most frequent gender in the data set
      unless missing_values[1].empty?
        missing_values[1].each do |x|
          table[x]['Ethnicity'] = most_frequent_ethnicity
        end
      end

      # Replacing missing grade values according to the mean and standard
      # deviation of the data to keep the original distribution
      unless missing_values[2].empty?
        missing_values[2].each do |x|
          case (rand * 100).round
          when 0..1
            table[x]['Grade'] = [(mean_grade - 3 * stdev).round, 0].max
          when 2..9
            table[x]['Grade'] = [(mean_grade - 2 * stdev).round, 0].max
          when 10..33
            table[x]['Grade'] = (mean_grade - stdev).round
          when 34..66
            table[x]['Grade'] = mean_grade.round
          when 67..91
            table[x]['Grade'] = (mean_grade + stdev).round
          when 92..99
            table[x]['Grade'] = [(mean_grade + 2 * stdev).round, 100].min
          when 99..100
            table[x]['Grade'] = [(mean_grade - 3 * stdev).round, 100].min
          end
        end
      end
      # Returning the already calculated most statistical parameters to be
      # used for finding students with close to median attributes if necessary
      # puts "mean - #{mean}, stdev - #{stdev}"
      [most_frequent_gender, most_frequent_ethnicity, mean_grade, stdev]
    end

    private :check_missing_values, :calculate_stdev
  end
end