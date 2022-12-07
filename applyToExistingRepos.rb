require 'json'

# Create a personal access token (classic)
# and store it in ~/personal_access_token.txt
#
# Reference:
#   https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token



org = "TokyoDesmo"

token = `cat ~/personal_access_token.txt`.chomp
rule_json = `cat ~/branch_protection_rules.json`.gsub(/(\r\n?|\n| )/,"")

per_page = 10
max_pages = 100  # max 100

puts "You can apply the branch protection rules with this script."
puts "For the queries, answer by "
puts "  Y for Yes"
puts "  N for No"
puts "  S for Stop, which terminates the script."
puts

def apply_rule(token, rule_json, full_name, branch)
  url="https://api.github.com/repos/#{full_name}/branches/#{branch}/protection"

  protectCmd = <<~EOS
    curl -s \
    -X PUT \
    -H \"Accept: application/vnd.github+json\" \
    -H \"Authorization: Bearer #{token}\" \
    -H \"X-GitHub-Api-Version: 2022-11-28\" \
    #{url} \
    -d '#{rule_json}'
  EOS
  `#{protectCmd}`

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

  `#{issueCmd}`
end


for i in 1..max_pages do

  listCmd = <<~EOS
    curl \
    -s \
    -H \"Accept: application/vnd.github+json\" \
    -H \"Authorization: Bearer #{token}\" \
    -H \"X-GitHub-Api-Version: 2022-11-28\" \
    \"https://api.github.com/orgs/#{org}/repos?per_page=#{per_page}&page=#{i}\"
  EOS

  resp = `#{listCmd}`
  if resp.empty? then
    break
  end

  params = JSON.parse(resp)
  if params.empty?
    break
  end

  terminate = false

  params.each{
    |key,value|
    full_name = key.dig("full_name")
    is_private = key.dig("private")
    description = key.dig("description")
    default_branch = key.dig("default_branch")

    if is_private
      next
    end

#    puts "#{full_name}/#{default_branch}"
#    puts "[description:#{description}]"
    while true
      print "Apply branch protection on #{full_name}/#{default_branch}? [y|n|s]:"
      input = gets
      case input
      when /^[yY]/
        puts "YES: Applying the branch protection"
        apply_rule(token, rule_json, full_name, default_branch)
        break
      when /^[nN]/, /^$/
        puts "NO: Not applying the branch protection"
        break
      when /^[sS]/
        puts "Stop: Not applying and stop the operation"
        terminate = true
        break
      end
    end
    puts

    if terminate then
      break
    end

  }

  if terminate then
    break
  end

end
