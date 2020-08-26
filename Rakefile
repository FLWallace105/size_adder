require 'dotenv'
Dotenv.load

require 'active_record'

require 'sinatra/activerecord/rake'
require_relative 'size_adder'


namespace :sports_jacket do
desc 'set up subs with no sports jacket size'
task :setup_subs_sports_jacket do |t|
    FixSubInfo::SubUpdater.new.setup_subs_missing_sports_jacket_size
end

desc 'update subs with no sports-jacket size'
task :update_subs_sports_jacket do |t|
    FixSubInfo::SubUpdater.new.update_missing_size
end

desc 'set up prepaid orders with no sports-jacket size'
task :setup_prepaid_sports_jacket do |t|
    FixSubInfo::SubUpdater.new.setup_prepaid_orders
end

desc 'update prepaid orders with no sports-jacket size'
task :update_prepaid_orders_jacket do |t|
    FixSubInfo::SubUpdater.new.update_prepaid_orders_no_jacket_size
end

end