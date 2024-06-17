class OrdersController < ApplicationController
  def index
    @orders = Order.where(user_id: current_user.id).order(created_at: :desc)
  end

  def new
    @order = Order.new
    @order.ordered_lists.build
    @items = Item.all.order(:created_at)
  end

  def create
    ActiveRecord::Base.transaction do
      @order = current_user.orders.build(order_params)
      # 全てのアイテムをロック
      @order.ordered_lists.each do |ordered_list|
        item = Item.lock.find(ordered_list.item_id)
        # 必要であれば、ここで item の数量チェックを行う
      end
      @order.save!
      @order.update_total_quantity
    end
    redirect_to orders_path
  rescue ActiveRecord::RecordInvalid => e
    # トランザクションが失敗した場合のエラーハンドリング
    flash[:error] = "Order creation failed: #{e.message}"
    render :new
  end

  private

  def order_params
    params.require(:order).permit(ordered_lists_attributes: [:item_id, :quantity])
  end
end
