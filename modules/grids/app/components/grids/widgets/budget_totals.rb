# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Grids
  module Widgets
    class BudgetTotals < Grids::WidgetComponent
      param :project

      def title
        nil
      end

      def budget_total
        base_amounts + material_budget_amounts + labor_budget_amounts
      end

      def spent_ratio
        spent_total / budget_total
      end

      def spent_total
        spent_material + spent_labor
      end

      # budget - spent
      def remaining
        budget_total - spent_total
      end

      def wrapper_arguments
        { content_padding: :none, full_width: true }
      end

      private

      def spent_material
        CostEntry
          .joins("INNER JOIN work_packages ON work_packages.id = cost_entries.entity_id AND cost_entries.entity_type = 'WorkPackage'")
          .where(work_packages: { project_id: self_and_descendant_projects.select(:id) })
          .sum(:costs) # TODO support overridden costs
      end

      def spent_labor
        TimeEntry
          .joins("INNER JOIN work_packages ON work_packages.id = time_entries.entity_id AND time_entries.entity_type = 'WorkPackage'")
          .where(work_packages: { project_id: self_and_descendant_projects.select(:id) })
          .sum(:costs) # TODO support overridden costs
      end

      def base_amounts
        Budget
          .joins(:project)
          .merge(self_and_descendant_projects)
          .sum(:base_amount)
      end

      def material_budget_amounts
        MaterialBudgetItem
          .joins(budget: :project)
          .merge(self_and_descendant_projects)
          .sum(:amount)
      end

      def labor_budget_amounts
        LaborBudgetItem
          .joins(budget: :project)
          .merge(self_and_descendant_projects)
          .sum(:amount)
      end

      def self_and_descendant_projects
        project.self_and_descendants.reorder(nil)
      end
    end
  end
end
