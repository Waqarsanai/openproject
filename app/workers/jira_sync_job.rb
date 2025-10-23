class JiraSyncJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with(
    total_limit: 2,
    enqueue_limit: 1,
    perform_limit: 1,
    key: -> { "JiraSyncJob-#{arguments.last}" }
  )

=begin
jira= Jira.new
jira.host = "https://jira-software.local/"
jira.username = "pavel.balashou"
jira.password = "pavel.balashou"
jira.save
JiraSyncJob.new.perform(1)
=end
  def perform(jira_id)
    jira = Jira.find(jira_id)
    jira_sync_log = JiraSyncLog.find_or_create_by!(status: "init_sync_in_progress", jira_id: jira_id)
    jira_sync_log.sync_time_point ||= Time.now
    jira_sync_log.save
    jira_sync_log_id = jira_sync_log.id

    updated_at = Time.now
    created_at = updated_at

    # PROJECTS SYNC
    j = J.new(host: jira.host, username: jira.username, password: jira.password)
    projects_upsert_data = j.projects.map do |p|
      {
        payload: p,
        jira_id:,
        jira_project_id: p.fetch("id"),
        jira_sync_log_id: jira_sync_log.id,
        created_at:,
        updated_at:
      }
    end
    upsert_result = JiraProject.upsert_all(projects_upsert_data, unique_by: [:jira_id, :jira_project_id])


    # PROJECT ISSUES SYNC
    JiraProject.where(jira_id:).each do |jira_project|
      already_synced_issue_ids = JiraIssue.where(jira_sync_log_id:, jira_project_id: jira_project.id).pluck(Arel.sql("payload->>'id'"))
      jql = "project=#{jira_project.payload["key"]} AND updated <= '#{jira_sync_log.sync_time_point.strftime("%Y-%m-%d %H:%M")}'"
      # TODO having a long list of issues can exceed a server limit for request URI length
      jql << " AND id NOT IN (#{already_synced_issue_ids.join(",")})" if already_synced_issue_ids.any?
      result = j.issues(jql: ,
                        start_at: 0,
                        max_results: 5)
      total = result["total"]
      start_at = result["startAt"]
      max_results = result["maxResults"]
      issues = result["issues"]
      issues_upsert_data = result["issues"].map do |issue|
        {
          payload: issue,
          jira_id: jira_id,
          jira_project_id: jira_project.id,
          jira_issue_id: issue.fetch("id"),
          jira_sync_log_id: jira_sync_log.id,
          created_at:,
          updated_at:
        }
      end
      upsert_result = JiraIssue.upsert_all(issues_upsert_data, unique_by: [:jira_id, :jira_project_id, :jira_issue_id])
      while(total > start_at + max_results)
        start_at = start_at + max_results
        result = j.issues(jql:,
                          start_at:,
                          max_results: 5)
        total = result["total"]
        start_at = result["startAt"]
        max_results = result["maxResults"]
        issues = result["issues"]
        issues_upsert_data = result["issues"].map do |issue|
          {
            payload: issue,
            jira_id: jira_id,
            jira_project_id: jira_project.id,
            jira_issue_id: issue.fetch("id"),
            jira_sync_log_id: jira_sync_log.id,
            created_at:,
            updated_at:
          }
        end
        upsert_result = JiraIssue.upsert_all(issues_upsert_data, unique_by: [:jira_id, :jira_project_id, :jira_issue_id])
      end
    end

    # USERS SYNC
    start_at = 0
    max_results = 1 # It should 1000 to reduce the number of requests
    jira_users = j.users(start_at: , max_results: )
    users_upsert_data = jira_users.map do |user|
      {
        payload: user,
        jira_id: jira_id,
        jira_sync_log_id: jira_sync_log.id,
        jira_user_key: user.fetch("key"),
        created_at:,
        updated_at:
      }
    end
    upsert_result = JiraUser.upsert_all(users_upsert_data, unique_by: [:jira_id, :jira_user_key])

    while(jira_users.any?)
      start_at = start_at + jira_users.count
      jira_users = j.users(start_at: , max_results: )
      users_upsert_data = jira_users.map do |user|
        {
          payload: user,
          jira_id: jira_id,
          jira_sync_log_id: jira_sync_log.id,
          jira_user_key: user.fetch("key"),
          created_at:,
          updated_at:
        }
      end
      upsert_result = JiraUser.upsert_all(users_upsert_data, unique_by: [:jira_id, :jira_user_key])
    end

    jira_sync_log.status = "init_sync_done"
    jira_sync_log.save!
  end
end
