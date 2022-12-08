require 'sinatra'
require 'json'

# Create a personal access token (classic)
# and store it in ~/personal_access_token.txt
#
# Reference:
#   https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token

post '/payload', provides: :json do
  request.body.rewind
  params = JSON.parse(request.body.read)

  token = `cat ~/personal_access_token.txt`.chomp

  action = params.dig("action")
  full_name = params.dig("repository", "full_name")
  default_branch = params.dig("repository", "default_branch")
  is_private = params.dig("repository", "private")

  # Handle the valid "created" action only
  if action == "created" && full_name && !full_name.empty? && default_branch && !default_branch.empty? && !is_private then

    # Even if a repository is created,
    # it is possible that no branch is created at the same time.
    # Attempt to apply the branch protection rule only if the
    # default branch is created at the repository creation.
    branchListCmd = <<~EOS
      curl \
      -H \"Accept: application/vnd.github+json\" \
      -H \"Authorization: Bearer #{token}\" \
      -H \"X-GitHub-Api-Version: 2022-11-28\" \
      https://api.github.com/repos/#{full_name}/branches
    EOS

    branchList = `#{branchListCmd}`

    found = 0
    if branchList && !branchList.empty? then
      params = JSON.parse(branchList)
      params.each{
        |branch|
        name = branch.dig("name")
        if name && name == default_branch then
          found = 1
          break
        end
      }
    end

    if found == 0 then
      puts "No branch is found, so cannot apply branch protection rules"
      return
    end

    # OK, now prepare for branch protection rules
    url="https://api.github.com/repos/#{full_name}/branches/#{default_branch}/protection"
    puts "url=#{url}"

    json = `cat ~/branch_protection_rules.json`.gsub(/(\r\n?|\n| )/,"")

    protectCmd = <<~EOS
      curl -s \
      -X PUT \
      -H \"Accept: application/vnd.github+json\" \
      -H \"Authorization: Bearer #{token}\" \
      -H \"X-GitHub-Api-Version: 2022-11-28\" \
      #{url} \
      -d '#{json}'
    EOS

    # Execute the curl cmd to apply the protection rules
    puts `#{protectCmd}`


    # Next, I want to add an issue

    user_name = `cat ~/github_user_name.txt`.chomp

    issueBody = "# Branch protection alert\n" \
                "The default branch is protected with the following configuration.\n" \
                "Ask #{user_name} for details.\n"
    issueBody += "```\n" + `cat branch-protection-rule.json` + "\n```"
    
    issueHash = {"title":"Branch protection alert","body":"#{issueBody}"}
    issueJson = issueHash.to_json
    issueUrl="https://api.github.com/repos/#{full_name}/issues"
    issueCmd = <<~EOS
      curl -s \
      -X POST \
      -H \"Accept: application/vnd.github+json\" \
      -H \"Authorization: Bearer #{token}\" \
      -H \"X-GitHub-Api-Version: 2022-11-28\" \
      #{issueUrl} \
      -d '#{issueJson}'
    EOS

    #puts issueCmd
    
    puts `#{issueCmd}`
    

  end
end

get '/' do
  "running"
end
