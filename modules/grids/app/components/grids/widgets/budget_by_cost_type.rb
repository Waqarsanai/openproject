# frozen_string_literal: true

module Grids
  module Widgets
    class BudgetByCostType < Grids::WidgetComponent
      param :project

      def title
        t('.title')
      end

      def budget_count
        @budget_count ||= Budget
          .joins(:project)
          .merge(self_and_descendant_projects)
          .count
      end

      def workspace_counts
        @workspace_counts ||= self_and_descendant_projects
          .group(:workspace_type)
          .count
          .with_indifferent_access
      end

      private

      def self_and_descendant_projects
        project.self_and_descendants.reorder(nil)
      end
    end
  end
end
