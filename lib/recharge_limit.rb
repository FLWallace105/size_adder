#recharge_limit.rb
module ReChargeLimits
    def determine_limits(recharge_header, limit)
      puts "sleeping 1"
      sleep 3
  
      puts "recharge_header = #{recharge_header}"
      my_numbers = recharge_header.split('/')
      my_numerator = my_numbers[0].to_f
      my_denominator = my_numbers[1].to_f
      my_limits = (my_numerator/ my_denominator)
  
      puts "We are using #{my_limits} % of our API calls"
      if my_limits > limit
        puts "Sleeping 10 seconds"
        sleep 10
      else
        puts "not sleeping at all"
      end
    end
  end
  