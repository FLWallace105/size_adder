#order_size.rb
module OrderSize

    def add_missing_size(my_json)
        #puts "here --- my_json = #{my_json}"
        leggings = my_json['properties'].select{|x| x['name'] == 'leggings'}
        tops = my_json['properties'].select{|x| x['name'] == 'tops'}
        sports_bra = my_json['properties'].select{|x| x['name'] == 'sports-bra'}
        sports_jacket = my_json['properties'].select{|x| x['name'] == 'sports-jacket'}

        #puts "sports_bra = #{sports_bra}"
        #puts "tops = #{tops}"
        #puts "***********"
        #Assuming we always have leggings
        if sports_jacket == [] && tops != []
            my_json['properties'] << { "name" => "sports-jacket", "value" => tops.first['value'].upcase }
        end

        if sports_bra == [] && tops != []
            #puts "FIXING missing sports-bra"
            my_json['properties'] << { "name" => "sports-bra", "value" => tops.first['value'].upcase }
        end

        if tops == [] && sports_bra != []
            my_json['properties'] << { "name" => "tops", "value" => sports_bra.first['value'].upcase }
        end

        return my_json
    end

    def add_missing_sub_size(my_json)
        leggings = my_json.select{|x| x['name'] == 'leggings'}
        tops = my_json.select{|x| x['name'] == 'tops'}
        sports_bra = my_json.select{|x| x['name'] == 'sports-bra'}
        sports_jacket = my_json.select{|x| x['name'] == 'sports-jacket'}

        #puts "sports_bra = #{sports_bra}"
        #puts "tops = #{tops}"
        #puts "***********"
        #Assuming we always have leggings
        if sports_jacket == [] && tops != []
            my_json << { "name" => "sports-jacket", "value" => tops.first['value'].upcase }
        end

        if sports_bra == [] && tops != []
            #puts "FIXING missing sports-bra"
            my_json << { "name" => "sports-bra", "value" => tops.first['value'].upcase }
        end

        if tops == [] && sports_bra != []
            my_json << { "name" => "tops", "value" => sports_bra.first['value'].upcase }
        end

        return my_json


    end

end