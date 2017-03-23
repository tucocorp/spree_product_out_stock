module Spree
  module Admin
    class ReportsController < Spree::Admin::BaseController
      respond_to :html

      AVAILABLE_REPORTS = {
        :sales_total => { :name => "sales total", :description =>"Sales Totals" },
        :out_of_stock => { :name => "Products out stock", :description => "This are products out stock" }
      }

      def index
        @reports = AVAILABLE_REPORTS
        respond_with(@reports)
      end

      def sales_total
        params[:q] = {} unless params[:q]

        if params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.zone.now.beginning_of_month
        else
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
        end

        if params[:q] && !params[:q][:created_at_lt].blank?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end

        if params[:q].delete(:completed_at_not_null) == "1"
          params[:q][:completed_at_not_null] = true
        else
          params[:q][:completed_at_not_null] = false
        end

        params[:q][:s] ||= "created_at desc"

        @search = Order.complete.ransack(params[:q])
        @orders = @search.result

        @totals = {}
        @orders.each do |order|
          @totals[order.currency] = { :item_total => ::Money.new(0, order.currency), :adjustment_total => ::Money.new(0, order.currency), :sales_total => ::Money.new(0, order.currency) } unless @totals[order.currency]
          @totals[order.currency][:item_total] += order.display_item_total.money
          @totals[order.currency][:adjustment_total] += order.display_adjustment_total.money
          @totals[order.currency][:sales_total] += order.display_total.money
        end
      end

      def out_of_stock
        params[:q] = {} unless params[:q]

        if params[:q][:created_at].blank?
          params[:q][:created_at] = Time.zone.now.beginning_of_month
        else
          params[:q][:created_at] = Time.zone.parse(params[:q][:created_at]).beginning_of_day rescue Time.zone.now.beginning_of_month
        end

        if params[:q] && !params[:q][:created_at].blank?
          params[:q][:created_at] = Time.zone.parse(params[:q][:created_at]).end_of_day rescue ""
        end

        @search = Product.joins(:variants_including_master).ransack(params[:q])
        @products = @search.result
      end

    end
  end
end
