# frozen_string_literal: true

module Grids
  module Widgets
    class BudgetByCostType < Grids::WidgetComponent
      param :project

      def title
        t('.title')
      end
    end
  end
end
