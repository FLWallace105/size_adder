#size_adder.rb
require 'dotenv'
Dotenv.load
require 'httparty'
#require 'resque'
require 'sinatra'
require 'active_record'
require "sinatra/activerecord"
#require_relative 'models/model'
#require_relative 'resque_helper'
Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }
Dir[File.join(__dir__, 'models', '*.rb')].each { |file| require file }



module FixSubInfo
  class SubUpdater
    include ReChargeLimits
    include OrderSize

    def initialize
      Dotenv.load
      recharge_regular = ENV['RECHARGE_ACCESS_TOKEN']
      @sleep_recharge = ENV['RECHARGE_SLEEP_TIME']
      @my_header = {
        "X-Recharge-Access-Token" => recharge_regular
      }
      @my_change_charge_header = {
        "X-Recharge-Access-Token" => recharge_regular,
        "Accept" => "application/json",
        "Content-Type" =>"application/json"
      }
      
    end

    def setup_subs_missing_sports_jacket_size
        puts "Starting"
        SubscriptionsUpdated.delete_all
        # Now reset index
        ActiveRecord::Base.connection.reset_pk_sequence!('subscriptions_next_month_updated')

        subs_update = "insert into subscriptions_updated (subscription_id, customer_id, updated_at, created_at, next_charge_scheduled_at, product_title, status, sku, shopify_product_id, shopify_variant_id, raw_line_items) select subscriptions.subscription_id, subscriptions.customer_id, subscriptions.updated_at, subscriptions.created_at, subscriptions.next_charge_scheduled_at, subscriptions.product_title, subscriptions.status, subscriptions.sku, subscriptions.shopify_product_id, subscriptions.shopify_variant_id, subscriptions.raw_line_item_properties from subscriptions, sub_collection_sizes where subscriptions.status = 'ACTIVE' and  sub_collection_sizes.subscription_id = subscriptions.subscription_id and sub_collection_sizes.sports_jacket is null"

        ActiveRecord::Base.connection.execute(subs_update)
        puts "All Done!"


    end

    def update_missing_size
        puts "Starting ..."
        my_subs = SubscriptionsUpdated.where("updated = ?", false)
        my_subs.each do |mys|
            puts "Subscription_id = #{mys.subscription_id}"
            temp_line_items = mys.raw_line_items
            puts "-------------------"
            puts temp_line_items.inspect
            puts "-----------------"
            new_json = add_missing_sub_size(temp_line_items)
            puts "Changes ...."
            puts "========================="
            puts new_json.inspect
            puts "========================="
            body = { "properties" => new_json }.to_json
            

            my_update_sub = HTTParty.put("https://api.rechargeapps.com/subscriptions/#{mys.subscription_id}", :headers => @my_change_charge_header, :body => body, :timeout => 80)
            puts my_update_sub.inspect
            recharge_header = my_update_sub.response["x-recharge-limit"]
            determine_limits(recharge_header, 0.65)

            if my_update_sub.code == 200
                mys.updated = true
                time_updated = DateTime.now
                time_updated_str = time_updated.strftime("%Y-%m-%d %H:%M:%S")
                mys.processed_at = time_updated_str
                mys.save
                puts "Updated subscription id #{mys.subscription_id}"
                

            else
                puts "WE could not process / update this subscription."
            end
            


        end

    end


    def setup_prepaid_orders
      puts "Starting set up prepaid orders with no sports-jacket size"
      UpdatePrepaidOrder.delete_all
            
      ActiveRecord::Base.connection.reset_pk_sequence!('update_prepaid')

      mysql = "insert into update_prepaid (order_id, transaction_id, charge_status, payment_processor, address_is_active, status, order_type, charge_id, address_id, shopify_id, shopify_order_id, shopify_cart_token, shipping_date, scheduled_at, shipped_date, processed_at, customer_id, first_name, last_name, is_prepaid, created_at, updated_at, email, line_items, total_price, shipping_address, billing_address, synced_at ) select orders.order_id, orders.transaction_id, orders.charge_status, orders.payment_processor, orders.address_is_active, orders.status, orders.order_type, orders.charge_id, orders.address_id, orders.shopify_id, orders.shopify_order_id, orders.shopify_cart_token, orders.shipping_date, orders.scheduled_at, orders.shipped_date, orders.processed_at, orders.customer_id, orders.first_name, orders.last_name, orders.is_prepaid, orders.created_at, orders.updated_at, orders.email, orders.line_items, orders.total_price, orders.shipping_address, orders.billing_address, orders.synced_at from orders, order_collection_sizes where orders.order_id = order_collection_sizes.order_id and order_collection_sizes.sports_jacket is null and orders.is_prepaid = '1' "

      ActiveRecord::Base.connection.execute(mysql)
      puts "All Done!"



    end

    def update_prepaid_orders_no_jacket_size
      puts "Starting update prepaid orders no sports jacket size"
      num_deleted = 0

      my_orders = UpdatePrepaidOrder.where("is_updated = ?", false)
      my_orders.each do |myord|
          #puts myord.inspect
          puts myord.order_id
          my_props = myord.line_items.first['properties']
          sports_jacket_size = my_props.detect{|x| x['name'] == 'sports-jacket'}&.dig('value')
          tops_size = my_props.detect{|x| x['name'] == 'tops'}&.dig('value')
          if !sports_jacket_size.nil?
              puts "sports-jacket size = #{sports_jacket_size}"
              num_deleted += 1
              myord.delete
          else
              puts "No sports-jacket size"
              my_props << {"name" => "sports-jacket", "value" => tops_size}
              puts my_props.inspect
              myord.line_items.first['properties'] = my_props
            puts "----- old line items --------"
            puts myord.line_items[0].inspect
            puts "-----------------------------"

            product_id = myord.line_items[0].dig('shopify_product_id')
            variant_id = myord.line_items[0].dig('shopify_variant_id')

            puts "product_id = #{product_id}"
            puts "variant_id = #{variant_id}"

            myord.line_items[0].tap {|myh| myh.delete('shopify_variant_id')}
            myord.line_items[0].tap {|myh| myh.delete('shopify_product_id')}
            myord.line_items[0].tap {|myh| myh.delete('images')}
            myord.line_items[0].tap {|myh| myh.delete('tax_lines')}

            myord.line_items[0]['product_id'] = product_id.to_i
            myord.line_items[0]['variant_id'] = variant_id.to_i
            myord.line_items[0]['quantity'] = 1

            puts "------ New Line Items ------------"
            puts myord.line_items.inspect
            puts "**********************************"
            


            my_data = { "line_items" => myord.line_items }
            my_update_order = HTTParty.put("https://api.rechargeapps.com/orders/#{myord.order_id}", :headers => @my_change_charge_header, :body => my_data.to_json, :timeout => 80)
            puts my_update_order.inspect

            recharge_header = my_update_order.response["x-recharge-limit"]
            determine_limits(recharge_header, 0.65)

            if my_update_order.code == 200
                myord.is_updated = true
                myord.save!
                puts "Updated order id #{myord.order_id}"
                

            else
                puts "WE could not process / update this prepaid order."
            end
            
                
          end
        end
    puts "All Done initial processing, deleted #{num_deleted} valid orders with sports-jacket size"

    end


  end
end