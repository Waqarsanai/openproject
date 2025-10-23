class J
  def initialize(
        host:,
        username:,
        password:
      )
    @httpx = OpenProject
               .httpx
               .plugin(:basic_auth)
               .with(headers: { "accept" => "application/json" })
               .basic_auth(username, password)
    @host = host
  end

  def index_condition_summary
    @httpx.get("#{@host}/rest/api/2/index/summary").json
  end

  def server_info
    @httpx.get("#{@host}/rest/api/2/serverInfo").json
  end

  def all_cluster_nodes
    @httpx.get("#{@host}/rest/api/2/cluster/nodes").json
  end

  # .issues("project = 'KANBAN1'")
  # .issues("project = 'SCRUM1'")
  # .issues("project=MYPROJECT AND updated >= -1d")
  def issues(jql: nil,
             start_at: 0,
             max_results: 100)
    @httpx.get(
      "#{@host}/rest/api/2/search",
      params: {
        "jql" => jql,
        "startAt" => start_at,
        "maxResults" => max_results,
      }
    ).json
  end

  def projects(expand = "description,projectKeys")
    @httpx.get("#{@host}/rest/api/2/project", params: { "expand" => expand }).json
  end

  def project_types
    @httpx.get("#{@host}/rest/api/2/project/type").json
  end

  def issue_types
    @httpx.get("#{@host}/rest/api/2/issuetype").json
  end

  def issue_types_schemes
    @httpx.get("#{@host}/rest/api/2/issuetypescheme").json
  end

  def workflows
    @httpx.get("#{@host}/rest/api/2/workflow").json
  end

  def workflowschemes
    @httpx.get("#{@host}/rest/api/2/workflowscheme").json
  end

  def statuses
    @httpx.get("#{@host}/rest/api/2/status").json
  end

  def status_categories
    @httpx.get("#{@host}/rest/api/2/statuscategory").json
  end

  def permissions
    @httpx.get("#{@host}/rest/api/2/permissions").json
  end

  def permission_schemes
    @httpx.get("#{@host}/rest/api/2/permissionschemes").json
  end

  def priority
    @httpx.get("#{@host}/rest/api/2/priority").json
  end

  def permission_schemes
    @httpx.get("#{@host}/rest/api/2/priorityschemes").json
  end

  def roles
    @httpx.get("#{@host}/rest/api/2/role").json
  end

  def fields
    @httpx.get("#{@host}/rest/api/2/field").json
  end

  def users(username: ".", start_at: 0, max_results: 50)
    @httpx.get("#{@host}/rest/api/2/user/search", params: { "username" => username, startAt: start_at, maxResults: max_results }).json
  end

  def groups(query: ".", start_at: 0, max_results: 50)
    @httpx.get("#{@host}/rest/api/2/groups/picker", params: { query:,  startAt: start_at, maxResults: max_results }).json
  end
end
