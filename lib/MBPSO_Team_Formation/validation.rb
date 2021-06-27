# frozen_string_literal: true

module MBPSOTeamFormation
  class Validation
    def raise_arg_error(text, condition)
      raise ArgumentError, text unless condition
    end

    def validate_number(var, name, type)
      case type
      when 'pos_int'
        text = "Argument '#{name}' is not a valid positive Integer"
        condition = (var.is_a?(Integer) &&
                     var.positive?)
      when 'nn_num'
        text = "Argument '#{name}' is not a valid non-negative integer or float"
        condition = ((var.is_a?(Integer) ||
                      var.is_a?(Float)) &&
                      (var >= 0))
      else
        text = 'Invalid validation call'
        condition = false
      end
      raise_arg_error(text, condition)
      var
    end

    def validate_survival_number(var, length)
      text = "Argument 'survival_number' is not a valid Integer."\
             ' Integer in the range [2:Number of students] expected'
      raise_arg_error(text, (var.is_a?(Integer) &&
                            (var >= 2) &&
                            (var <= length)))
      var
    end

    def validate_control_parameters(var, name)
      text = "Unrecognised parameter, 'local' or 'personal' required."
      raise_arg_error(text, ((name.is_a? String) &&
                             (%w[local personal].include? name)))

      text = "Argument '#{name}' is not in the required format."\
             ' Array with 3 floats in the range [0;1] expected'

      raise_arg_error(text, ((var.is_a? Array) && var.length == 3))

      raise_arg_error(text, (var[0].is_a?(Float) || Integer &&
                            (var[0] <= 1) &&
                            (var[0] >= 0)))

      raise_arg_error(text, (var[1].is_a?(Float) || Integer &&
                            (var[1] <= 1) &&
                            (var[1] >= 0)))

      raise_arg_error(text, (var[2].is_a?(Float) || Integer &&
                            (var[2] <= 1) &&
                            (var[2] >= 0)))
      var
    end

    def validate_skill_table(var)
      text = "Argument 'skill_table' has invalid value and/or invalid coverage of the grade range"
      temp = []

      # Making sure the parameter is the right type
      raise_arg_error(text, (var.is_a? Hash))
      # Expanding the ranges and adding them into a temporary array
      var.each_key.each do |key|
        # Making sure the keys of the Hash are valid Integer ranges,
        # as Range can be a String one, for example
        raise_arg_error(text, (key.is_a?(Range) &&
                               key.begin.is_a?(Integer) &&
                               key.end.is_a?(Integer)))
        temp.append(*key)
      end
      temp = temp.sort
      # Right size ==> No duplicates and full range covered
      raise_arg_error(text, (temp.length == 101))
      # Starts with zero
      raise_arg_error(text, temp[0].zero?)
      # Ends with 100
      raise_arg_error(text, temp.last == 100)

      # Checking the skill values grades will be mapped to
      var.values.each do |x|
        raise_arg_error(text,\
                        (x.is_a?(Integer) &&
                        (x >= 0)))
      end
      var
    end

    def validate_bool(var, name)
      text = "Argument '#{name}' is not in the required format."\
             ' Boolean expected'
      raise_arg_error(text,\
                      ([true, false].include? var))
      var
    end

    def validate_dataset(var)
      text = "Invalid format of data set. Required: 'CSV::var'"
      raise_arg_error(text, (var.is_a? CSV::Table))

      text = 'Ivalid number of columns, required 4'
      raise_arg_error(text, (var.headers.size == 4))

      text = "Invalid Headers. Required: 'id', 'Gender', 'Ethnicity' and 'Grade'"
      raise_arg_error(text, (var.headers.include?('id') &&
                             var.headers.include?('Gender') &&
                             var.headers.include?('Ethnicity') &&
                             var.headers.include?('Grade')))

      text = 'The data set contains duplicating student IDs'
      raise_arg_error(text,\
                      (var['id'].uniq.length == var['id'].length))

      # Regular expressions for each attribute
      gender_regex = /^(-1|0|1)$/
      ethnicity_regex = /^(-1|[0-4])$/
      grade_regex = /^(100|[1-9]?[0-9])$/

      (0..var.length - 1).each do |x|
        text_gender = "Invalid gender value for student with ID = #{var[x]['id']}"\
                      '.Required: integer in the range [-1:1]'
        text_ethn = "Invalid ethnicity value for student with ID = #{var[x]['id']}"\
                    '.Required: integer in the range [-1:4]'
        text_grade = "Invalid grade value for student with ID = #{var[x]['id']}"\
                     '.Required: integer in the range [0:100].'

        raise_arg_error(text_gender,\
                        (var[x]['Gender'].to_s =~ gender_regex ||
                                                  var[x]['Gender'].nil?))
        raise_arg_error(text_ethn,\
                        (var[x]['Ethnicity'].to_s =~ ethnicity_regex ||
                                                     var[x]['Ethnicity'].nil?))
        raise_arg_error(text_grade,\
                        (var[x]['Grade'].to_s =~ grade_regex ||
                                                 var[x]['Grade'].nil?))
      end
      var
    end

    def validate_forbidden_pairs(var)
      text = "Invalid format of the 'forbidden_pairs' argument."\
             'Array or CSV::Table required.'
      raise_arg_error(text,\
                      ((var.is_a? Array) ||
                       (var.is_a? CSV::Table)))

      flag = true
      (0..var.length - 1).each do |x|
        flag = false unless var[x].length == 2
        text = "Invalid size of sub-array at index #{x}."\
               ' Pair, i.e. array of two elements required.'
        raise_arg_error(text, flag)
      end
      var
    end

    private :raise_arg_error
  end
end
