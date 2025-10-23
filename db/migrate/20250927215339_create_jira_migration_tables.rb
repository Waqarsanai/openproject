# frozen_string_literal: true

class CreateJiraMigrationTables < ActiveRecord::Migration[8.0]
  def change
    create_table :jiras do |t|
      t.string :host
      t.string :username
      t.string :password

      t.timestamps
    end

    create_table :jira_sync_logs do |t|
      t.string :status
      t.timestamp :sync_time_point
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
    end

    create_table :jira_projects do |t|
      t.jsonb :payload
      t.string :jira_project_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_sync_log, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_project_id], unique: true

      t.timestamps
    end

    create_table :jira_project_types do |t|
      t.jsonb :payload
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }

      t.timestamps
    end

    create_table :jira_issues do |t|
      t.jsonb :payload
      t.string :jira_project_id
      t.string :jira_issue_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_sync_log, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_project_id, :jira_issue_id], unique: true

      t.timestamps
    end

    create_table :jira_issue_types do |t|
      t.jsonb :payload
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }

      t.timestamps
    end
    create_table :jira_statuses do |t|
      t.jsonb :payload
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }

      t.timestamps
    end

    create_table :jira_status_categories do |t|
      t.jsonb :payload
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }

      t.timestamps
    end

    create_table :jira_users do |t|
      t.jsonb :payload
      t.string :jira_user_key
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_sync_log, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_user_key], unique: true

      t.timestamps
    end
  end
end
