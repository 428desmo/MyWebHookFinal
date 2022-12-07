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

  action = params.dig("action")
  full_name = params.dig("repository", "full_name")
  default_branch = params.dig("repository", "default_branch")

  if action == "created" && full_name && !full_name.empty? && default_branch && !default_branch.empty? then
    url="https://api.github.com/repos/#{full_name}/branches/#{default_branch}/protection"
    puts "url=#{url}"

    token = `cat ~/personal_access_token.txt`.chomp
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

    puts `#{protectCmd}`


    issueBody = "# Branch protection alert\n" \
                "This branch is protected with the following configuration.\n" \
                "Ask @428desmo for details.\n"
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
