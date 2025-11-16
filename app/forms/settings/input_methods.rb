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

module Settings
  module InputMethods
    include ::SettingsHelper
    include FormHelper

    # Creates a text field input for a setting.
    #
    # The text field label is set from translating the key "setting_<name>".
    #
    # Any options passed to this method will override the default options.
    #
    # @param name [Symbol] The name of the setting
    # @param options [Hash] Additional options for the text field
    # @return [Object] The text field input
    def text_field(name:, **options)
      options.reverse_merge!(
        label: setting_label(name),
        value: setting_value(name),
        disabled: setting_disabled?(name)
      )
      object.text_field(name:, **options)
    end

    def text_area(name:, **options)
      value = setting_value(name)
      value = value.join("\n") if value.is_a?(Array)
      options.reverse_merge!(
        label: setting_label(name),
        value:,
        disabled: setting_disabled?(name)
      )
      object.text_area(name:, **options)
    end

    def rich_text_area(name:, **options)
      options.reverse_merge!(
        label: setting_label(name),
        value: setting_value(name),
        disabled: setting_disabled?(name)
      )
      object.rich_text_area(name:, **options)
    end

    def select_list(name:, values: nil, option_options: {}, **options, &) # rubocop:disable Metrics/AbcSize
      raise ArgumentError, "pass either values: or a block, not both" unless (!values.nil?) ^ block_given?

      options.reverse_merge!(
        label: setting_label(name),
        disabled: setting_disabled?(name)
      )
      return object.select_list(name:, **options, &) if values.nil?

      object.select_list(name:, **options) do |sl|
        values.each do |value|
          args = case value
                 in [l, v]
                   { label: l, value: v }
                 in [l, v, rest] if rest.is_a?(Hash)
                   { label: l, value: v, **rest }
                 in Hash => h
                   h.except(:name).reverse_merge(
                     label: setting_label(name, h[:name]),
                     caption: setting_caption(name, h[:name])
                   )
                 else
                   { value: }
                 end

          args.reverse_merge!(
            selected: setting_value(name) == args[:value],
            label: setting_label(name, args[:value]),
            caption: setting_caption(name, args[:value])
          )

          sl.option(**option_options.reverse_merge(args))
        end
      end
    end

    # Creates a check box input for a setting.
    #
    # The check box label is set from translating the key "setting_<name>".
    #
    # Any options passed to this method will override the default options.
    #
    # @param name [Symbol] The name of the setting
    # @param options [Hash] Additional options for the check box
    # @return [Object] The check box input
    def check_box(name:, **options, &)
      options.reverse_merge!(
        label: setting_label(name),
        checked: setting_value(name),
        disabled: setting_disabled?(name)
      )
      object.check_box(name:, **options, &)
    end

    # Creates a radio button group for a setting.
    #
    # The radio button group label is set from translating the key
    # "setting_<name>". The radio button label are set from translating the
    # key "setting_<name>_<value>". The caption is set from translating the
    # key "setting_<name>_<value>_caption_html", which will be rendered as HTML,
    # or "setting_<name>_<value>_caption", or nothing if none of the above
    # are defined.
    #
    # Any options passed to this method will override the default options.
    #
    # @param name [Symbol] The name of the setting
    # @param values [Hash|Array] The values for the radio buttons. Default to the
    #   setting's allowed values.
    #   If a hash is provided, it is assumed it provides a :name (to derive the labels) and a :value key.
    #   Other keys are used as arguments to the radio_button.
    # @param disabled [Boolean] Force the radio button group to be disabled when
    #  true, will be disabled if the setting is not writable when false (default)
    # @param button_options [Hash] Options for individual radio buttons
    # @param options [Hash] Additional options for the radio button group
    # @return [Object] The radio button group
    def radio_button_group(name:, values: nil, disabled: false, button_options: {}, **options) # rubocop:disable Metrics/AbcSize
      values = values.presence || setting_allowed_values(name)
      radio_group_options = options.reverse_merge(
        label: setting_label(name),
        disabled: disabled || setting_disabled?(name)
      )
      object.radio_button_group(
        name:,
        **radio_group_options
      ) do |radio_group|
        values.each do |value|
          args =
            if value.is_a?(Hash)
              value
                .except(:name) # Ensure to exclude name to not add another name input
                .reverse_merge(
                  checked: setting_value(name) == value[:value],
                  autocomplete: "off",
                  label: setting_label(name, value[:name]),
                  caption: setting_caption(name, value[:name])
                )
            else
              {
                value:,
                checked: setting_value(name) == value,
                autocomplete: "off",
                label: setting_label(name, value),
                caption: setting_caption(name, value)
              }
            end

          radio_group.radio_button(**button_options.reverse_merge(args))
        end
      end
    end

    def check_box_group(name: nil, values: nil, disabled: false, check_box_options: {}, **options, &) # rubocop:disable Metrics/AbcSize
      raise ArgumentError, "pass either values: or a block, not both" unless (!values.nil?) ^ block_given?
      return object.check_box_group(disabled:, **options, &) if name.nil?

      values = values.presence || setting_allowed_values(name)
      check_box_group_options = options.reverse_merge(
        label: setting_label(name),
        disabled: disabled || setting_disabled?(name)
      )

      object.check_box_group(
        name:,
        **check_box_group_options
      ) do |check_box_group|
        values.each do |value|
          args = case value
                 in [l, v]
                   { label: l, value: v }
                 in [l, v, rest] if rest.is_a?(Hash)
                   { label: l, value: v, **rest }
                 in Hash => h
                   h.except(:name).reverse_merge(
                     label: setting_label(name, h[:name]),
                     caption: setting_caption(name, h[:name])
                   )
                 else
                   { value: }
                 end

          args.reverse_merge!(
            checked: setting_value(name).include?(args[:value]),
            autocomplete: "off",
            label: setting_label(name, args[:value]),
            caption: setting_caption(name, args[:value])
          )

          check_box_group.check_box(**check_box_options.reverse_merge(args))
        end
      end
    end

    def multi_language_text_select(name:, current_language: I18n.locale.to_s)
      # Add select list to switch
      object.select_list(
        name: :"#{name}_lang", # Should be excluded by settings params
        input_width: :small,
        id: "lang-for-#{name}",
        class: "lang-select-switch",
        label: setting_label(name),
        caption: setting_caption(name),
        include_blank: false
      ) do |select|
        lang_options_for_select(false).each do |label, value|
          select.option(
            value:,
            label:,
            selected: value == current_language
          )
        end
      end

      object.fields_for(name) do |builder|
        MultiLangForm.new(builder, name:, current_language:)
      end
    end

    # Creates a save button to submit the form
    #
    # @return [Object] The submit button
    def submit(**options)
      options.reverse_merge!(
        name: "submit",
        label: I18n.t("button_save"),
        scheme: :primary
      )
      object.submit(**options)
    end
  end
end
