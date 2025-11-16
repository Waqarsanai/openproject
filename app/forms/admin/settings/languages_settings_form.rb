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

module Admin
  module Settings
    class LanguagesSettingsForm < ApplicationForm
      include Redmine::I18n

      settings_form do |f|
        f.check_box_group(
          name: :available_languages,
          values: highlight_default_language(all_lang_options_for_select)
        )
      end

      private

      def highlight_default_language(lang_options)
        lang_options.map do |(language_name, code)|
          if code == Setting.default_language
            [I18n.t("settings.language_name_being_default", language_name:), code, { disabled: true, checked: true }]
          else
            [language_name, code]
          end
        end
      end

      def all_lang_options_for_select
        all_languages
          .map { |lang| translate_language(lang) }
          .sort_by(&:first)
      end

      # Returns the language name in its own language for a given locale
      #
      # @param lang_code [String] the locale for the desired language, like `en`,
      #   `de`, `fil`, `zh-CN`, and so on.
      # @return [String] the language name translated in its own language
      def translate_language(lang_code)
        # rename in-context translation language name for the language select box
        if lang_code.to_sym == Redmine::I18n::IN_CONTEXT_TRANSLATION_CODE &&
          ::I18n.locale != Redmine::I18n::IN_CONTEXT_TRANSLATION_CODE
          [Redmine::I18n::IN_CONTEXT_TRANSLATION_NAME, lang_code.to_s]
        else
          [I18n.t("cldr.language_name", locale: lang_code), lang_code.to_s]
        end
      end
    end
  end
end
